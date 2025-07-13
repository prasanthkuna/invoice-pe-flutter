import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

interface PaymentRequest {
  invoice_id: string
  amount: number
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get JWT from Authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    // Create Supabase client with service role for elevated access
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Create client with user JWT for user verification
    const supabaseUser = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // Verify user authentication
    const { data: { user }, error: authError } = await supabaseUser.auth.getUser()
    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    const { invoice_id, amount }: PaymentRequest = await req.json()

    // Validate invoice bInvoicePegs to user and is pending
    const { data: invoice, error: invoiceError } = await supabaseUser
      .from('invoices')
      .select('id, user_id, amount, status')
      .eq('id', invoice_id)
      .eq('user_id', user.id)
      .eq('status', 'pending')
      .single()

    if (invoiceError || !invoice) {
      throw new Error('Invoice not found or not pending')
    }

    if (invoice.amount !== amount) {
      throw new Error('Amount mismatch')
    }

    // PhonePe Configuration (YOUR_MERCHANT_ID - UAT Credentials)
    const merchantId = Deno.env.get('PHONEPE_MERCHANT_ID') || 'YOUR_MERCHANT_ID'
    const saltKey = Deno.env.get('PHONEPE_SALT_KEY') || 'your-salt-key-here'
    const saltIndex = Deno.env.get('PHONEPE_SALT_INDEX') || '1'
    const callbackUrl = `${Deno.env.get('SUPABASE_URL')}/functions/v1/process-payment`

    // Generate unique payment reference
    const paymentRef = `INV_${invoice_id}_${Date.now()}`
    const amountInPaise = Math.round(amount * 100) // Convert to paise

    // Create PhonePe payload
    const payload = {
      merchantId,
      merchantTransactionId: paymentRef,
      merchantUserId: user.id,
      amount: amountInPaise,
      redirectUrl: callbackUrl,
      redirectMode: "POST",
      callbackUrl,
      mobileNumber: "9999999999", // Will be updated with actual user phone
      paymentInstrument: {
        type: "PAY_PAGE"
      }
    }

    // Create Base64 encoded payload
    const base64Payload = btoa(JSON.stringify(payload))

    // Generate checksum: SHA256(base64Payload + "/pg/v1/pay" + saltKey) + "###" + saltIndex
    const stringToHash = base64Payload + "/pg/v1/pay" + saltKey
    const encoder = new TextEncoder()
    const data = encoder.encode(stringToHash)
    const hashBuffer = await crypto.subtle.digest('SHA-256', data)
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
    const checksum = hashHex + "###" + saltIndex

    // Create transaction record with 'initiated' status
    const { error: transactionError } = await supabaseAdmin
      .from('transactions')
      .insert({
        invoice_id,
        user_id: user.id,
        status: 'initiated',
        amount_paid: amount,
        fees_charged: Math.round(amount * 0.02 * 100) / 100, // 2% fee
        payment_gateway_ref: paymentRef,
        phonepe_transaction_id: paymentRef
      })

    if (transactionError) {
      throw new Error('Failed to create transaction record')
    }

    // Return PhonePe SDK compatible response
    return new Response(
      JSON.stringify({
        success: true,
        body: base64Payload,
        checksum,
        apiEndpoint: "/pg/v1/pay",
        merchantTransactionId: paymentRef,
        amount: amountInPaise,
        callbackUrl
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      }
    )
  }
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/initiate-payment' \
    --header 'Authorization: Bearer your-local-anon-key-here' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/

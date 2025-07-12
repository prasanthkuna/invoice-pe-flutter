import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

interface ProcessPaymentRequest {
  payment_gateway_ref: string
  phonepe_response: any
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

    // Create Supabase client with service role
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Create client with user JWT for verification
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

    const { payment_gateway_ref, phonepe_response }: ProcessPaymentRequest = await req.json()

    // Find the transaction record
    const { data: transaction, error: transactionError } = await supabaseAdmin
      .from('transactions')
      .select('id, invoice_id, user_id, status, amount_paid')
      .eq('payment_gateway_ref', payment_gateway_ref)
      .eq('user_id', user.id)
      .single()

    if (transactionError || !transaction) {
      throw new Error('Transaction not found')
    }

    if (transaction.status !== 'initiated') {
      throw new Error('Transaction already processed')
    }

    // Process PhonePe response
    const isPaymentSuccess = phonepe_response?.code === 'PAYMENT_SUCCESS'

    if (isPaymentSuccess) {
      // Update transaction to success
      const { error: updateTransactionError } = await supabaseAdmin
        .from('transactions')
        .update({
          status: 'success',
          rewards_earned_estimate: Math.round(transaction.amount_paid * 0.015 * 100) / 100 // 1.5% rewards estimate
        })
        .eq('id', transaction.id)

      if (updateTransactionError) {
        throw new Error('Failed to update transaction')
      }

      // Update invoice to paid
      const { error: updateInvoiceError } = await supabaseAdmin
        .from('invoices')
        .update({ status: 'paid' })
        .eq('id', transaction.invoice_id)

      if (updateInvoiceError) {
        throw new Error('Failed to update invoice')
      }

      return new Response(
        JSON.stringify({
          success: true,
          status: 'payment_successful',
          transaction_id: transaction.id
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )

    } else {
      // Payment failed
      const { error: updateTransactionError } = await supabaseAdmin
        .from('transactions')
        .update({
          status: 'failure',
          failure_reason: phonepe_response?.message || 'Payment failed'
        })
        .eq('id', transaction.id)

      if (updateTransactionError) {
        throw new Error('Failed to update transaction')
      }

      return new Response(
        JSON.stringify({
          success: false,
          status: 'payment_failed',
          message: phonepe_response?.message || 'Payment failed'
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

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

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/process-payment' \
    --header 'Authorization: Bearer your-local-anon-key-here' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/

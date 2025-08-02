import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get user from JWT token
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (userError || !user) {
      throw new Error('Invalid user token')
    }

    // Parse request body
    const { amount, vendor_id, vendor_name, invoice_id } = await req.json()

    console.log('📋 Creating PhonePe order:', {
      amount,
      vendor_id,
      vendor_name,
      invoice_id,
      user_id: user.id
    })

    // Validate input
    if (!amount || amount <= 0) {
      throw new Error('Invalid amount')
    }

    if (!vendor_id || !vendor_name) {
      throw new Error('Vendor information required')
    }

    // Get valid auth token
    const authTokenResponse = await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/phonepe-auth`, {
      method: 'POST',
      headers: {
        'Authorization': authHeader,
        'Content-Type': 'application/json',
      },
    })

    const authTokenData = await authTokenResponse.json()
    if (!authTokenData.success) {
      throw new Error('Failed to get PhonePe auth token')
    }

    const accessToken = authTokenData.token
    console.log('🔐 Got PhonePe auth token:', { source: authTokenData.source })

    // Generate unique merchant order ID
    const merchantOrderId = `INV_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    const merchantUserId = `USER_${user.id.replace(/-/g, '').substr(0, 16)}`

    // Determine API endpoint based on environment
    const environment = Deno.env.get('PHONEPE_ENVIRONMENT') || 'SANDBOX'
    const baseUrl = environment === 'PRODUCTION' 
      ? 'https://api.phonepe.com' 
      : 'https://api-preprod.phonepe.com'

    // Create order payload for PhonePe SDK 3.0.0
    const orderPayload = {
      merchantOrderId,
      amount, // Amount in paise
      paymentFlow: { 
        type: "PG_CHECKOUT" 
      },
      merchantUserId,
      callbackUrl: `${Deno.env.get('SUPABASE_URL')}/functions/v1/phonepe-webhook`,
      mobileNumber: "9999999999", // Will be updated with actual user phone
      deviceContext: {
        deviceOS: "ANDROID"
      }
    }

    console.log('📱 Creating PhonePe order with payload:', {
      merchantOrderId,
      amount,
      merchantUserId
    })

    // Create order with PhonePe API
    const orderResponse = await fetch(`${baseUrl}/apis/pg-sandbox/checkout/v2/sdk/order`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `O-Bearer ${accessToken}`,
        'X-VERIFY': Deno.env.get('PHONEPE_SALT_KEY') || '',
      },
      body: JSON.stringify(orderPayload),
    })

    if (!orderResponse.ok) {
      const errorText = await orderResponse.text()
      console.error('❌ PhonePe order creation failed:', errorText)
      throw new Error(`PhonePe order creation failed: ${orderResponse.status} ${errorText}`)
    }

    const orderData = await orderResponse.json()
    console.log('✅ PhonePe order created:', {
      orderId: orderData.orderId,
      hasToken: !!orderData.token
    })
    
    if (!orderData.orderId || !orderData.token) {
      throw new Error('Invalid PhonePe order response')
    }

    // Calculate fees and rewards
    const amountInRupees = amount / 100
    const fee = amountInRupees * 0.02 // 2% fee
    const rewards = amountInRupees * 0.015 // 1.5% rewards

    // Create transaction record in database
    const transactionData = {
      user_id: user.id,
      vendor_id,
      vendor_name,
      invoice_id,
      amount: amountInRupees,
      fee,
      rewards_earned: rewards,
      status: 'initiated',
      payment_method: 'PhonePe',
      phonepe_order_id: orderData.orderId,
      phonepe_order_token: orderData.token,
      phonepe_merchant_order_id: merchantOrderId,
      phonepe_order_status: 'CREATED',
      phonepe_response_data: orderData,
      auto_polling_enabled: true,
      created_at: new Date().toISOString(),
    }

    const { data: transaction, error: transactionError } = await supabaseClient
      .from('transactions')
      .insert(transactionData)
      .select('id')
      .single()

    if (transactionError) {
      console.error('❌ Failed to create transaction record:', transactionError)
      throw transactionError
    }

    console.log('✅ Transaction record created:', {
      transactionId: transaction.id,
      phonepeOrderId: orderData.orderId
    })

    // Update invoice status if provided
    if (invoice_id) {
      await supabaseClient
        .from('invoices')
        .update({
          status: 'payment_initiated',
          transaction_id: transaction.id,
        })
        .eq('id', invoice_id)
    }

    return new Response(JSON.stringify({
      success: true,
      orderId: orderData.orderId,
      token: orderData.token,
      transactionId: transaction.id,
      merchantOrderId,
      amount: amountInRupees,
      fee,
      rewards,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('❌ Create PhonePe order error:', error)
    
    return new Response(JSON.stringify({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

/* 
PhonePe Order Creation Service

This edge function creates PhonePe orders using SDK 3.0.0 Create Order API:

1. Validates user authentication and input data
2. Gets valid PhonePe auth token (cached or fresh)
3. Creates order using PhonePe Create Order API
4. Stores transaction record with PhonePe order details
5. Updates invoice status if applicable
6. Returns order ID and token for Flutter SDK

Flow:
1. Flutter calls this function with payment details
2. Function creates PhonePe order and gets order token
3. Flutter uses order token with PhonePe SDK
4. PhonePe SDK handles payment UI and processing
5. Webhook receives payment status updates

Environment Variables Required:
- PHONEPE_ENVIRONMENT: 'SANDBOX' or 'PRODUCTION'
- PHONEPE_SALT_KEY: PhonePe salt key for verification

Usage:
POST /functions/v1/create-phonepe-order
Body: { amount: 10000, vendor_id: "uuid", vendor_name: "Vendor", invoice_id: "uuid" }
Returns: { success: true, orderId: "OMO123", token: "token", transactionId: "uuid" }

Performance: ~800ms (includes auth token fetch + order creation + DB insert)
*/

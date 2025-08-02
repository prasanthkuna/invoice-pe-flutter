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

    // Parse request body
    const { orderId } = await req.json()

    console.log('🔍 Verifying PhonePe payment:', { orderId })

    if (!orderId) {
      throw new Error('Order ID is required')
    }

    // Get transaction record
    const { data: transaction, error: transactionError } = await supabaseClient
      .from('transactions')
      .select('*')
      .eq('phonepe_order_id', orderId)
      .single()

    if (transactionError || !transaction) {
      throw new Error('Transaction not found')
    }

    console.log('📋 Found transaction:', {
      transactionId: transaction.id,
      currentStatus: transaction.status,
      phonepeOrderStatus: transaction.phonepe_order_status
    })

    // Get valid auth token
    const authTokenResponse = await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/phonepe-auth`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    })

    const authTokenData = await authTokenResponse.json()
    if (!authTokenData.success) {
      throw new Error('Failed to get PhonePe auth token')
    }

    const accessToken = authTokenData.token
    console.log('🔐 Got PhonePe auth token for verification')

    // Determine API endpoint based on environment
    const environment = Deno.env.get('PHONEPE_ENVIRONMENT') || 'SANDBOX'
    const baseUrl = environment === 'PRODUCTION' 
      ? 'https://api.phonepe.com' 
      : 'https://api-preprod.phonepe.com'

    // Check order status with PhonePe API
    const statusResponse = await fetch(
      `${baseUrl}/apis/pg-sandbox/checkout/v2/order/${orderId}/status`,
      {
        method: 'GET',
        headers: {
          'Authorization': `O-Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
      }
    )

    if (!statusResponse.ok) {
      const errorText = await statusResponse.text()
      console.error('❌ PhonePe status check failed:', errorText)
      throw new Error(`PhonePe status check failed: ${statusResponse.status}`)
    }

    const statusData = await statusResponse.json()
    console.log('📱 PhonePe status response:', {
      orderId,
      status: statusData.status,
      state: statusData.state
    })

    // Map PhonePe status to our transaction status
    let transactionStatus = 'pending'
    let isVerified = false

    switch (statusData.status) {
      case 'SUCCESS':
        transactionStatus = 'success'
        isVerified = true
        break
      case 'FAILURE':
        transactionStatus = 'failure'
        break
      case 'CANCELLED':
        transactionStatus = 'cancelled'
        break
      case 'EXPIRED':
        transactionStatus = 'expired'
        break
      default:
        transactionStatus = 'pending'
    }

    // Update transaction record with verification results
    const updateData = {
      status: transactionStatus,
      phonepe_order_status: statusData.status,
      phonepe_response_data: statusData,
      last_status_check_at: new Date().toISOString(),
      status_check_count: (transaction.status_check_count || 0) + 1,
    }

    // Add completion timestamp for successful payments
    if (isVerified) {
      updateData.completed_at = new Date().toISOString()
    }

    const { data: updatedTransaction, error: updateError } = await supabaseClient
      .from('transactions')
      .update(updateData)
      .eq('phonepe_order_id', orderId)
      .select()
      .single()

    if (updateError) {
      console.error('❌ Failed to update transaction:', updateError)
      throw updateError
    }

    console.log('✅ Transaction updated:', {
      transactionId: updatedTransaction.id,
      newStatus: transactionStatus,
      isVerified
    })

    // Update invoice status for successful payments
    if (isVerified && transaction.invoice_id) {
      await supabaseClient
        .from('invoices')
        .update({
          status: 'paid',
          paid_at: new Date().toISOString(),
        })
        .eq('id', transaction.invoice_id)

      console.log('✅ Invoice marked as paid:', { invoiceId: transaction.invoice_id })
    }

    return new Response(JSON.stringify({
      verified: isVerified,
      transactionId: updatedTransaction.id,
      status: transactionStatus,
      phonepeStatus: statusData.status,
      orderId,
      amount: transaction.amount,
      timestamp: new Date().toISOString()
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('❌ PhonePe payment verification error:', error)
    
    return new Response(JSON.stringify({
      verified: false,
      error: error.message,
      timestamp: new Date().toISOString()
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

/* 
PhonePe Payment Verification Service

This edge function verifies PhonePe payment status using Order Status API:

1. Receives order ID from Flutter app after payment attempt
2. Gets valid PhonePe auth token for API access
3. Calls PhonePe Order Status API to get current payment status
4. Updates transaction record with verification results
5. Updates invoice status for successful payments
6. Returns verification result to Flutter app

Status Mapping:
- PhonePe SUCCESS → transaction 'success' (verified: true)
- PhonePe FAILURE → transaction 'failure' (verified: false)
- PhonePe CANCELLED → transaction 'cancelled' (verified: false)
- PhonePe EXPIRED → transaction 'expired' (verified: false)
- Other → transaction 'pending' (verified: false)

Environment Variables Required:
- PHONEPE_ENVIRONMENT: 'SANDBOX' or 'PRODUCTION'

Usage:
POST /functions/v1/verify-phonepe-payment
Body: { orderId: "OMO123456789" }
Returns: { verified: true, transactionId: "uuid", status: "success" }

Performance: ~600ms (includes auth token + status check + DB update)

This function is called:
1. Immediately after PhonePe SDK returns (Flutter app)
2. By webhook handler for real-time updates
3. By polling service for pending transactions
*/

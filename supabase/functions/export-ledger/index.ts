import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

interface ExportRequest {
  start_date: string
  end_date: string
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

    // Create Supabase client with user JWT
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

    const { start_date, end_date }: ExportRequest = await req.json()

    // Fetch transactions with vendor details
    const { data: transactions, error: transactionsError } = await supabaseUser
      .from('transactions')
      .select(`
        id,
        created_at,
        amount_paid,
        fees_charged,
        status,
        payment_gateway_ref,
        invoices!inner(
          vendor_id,
          vendors!inner(name)
        )
      `)
      .gte('created_at', start_date)
      .lte('created_at', end_date)
      .eq('status', 'success')
      .order('created_at', { ascending: false })

    if (transactionsError) {
      throw new Error('Failed to fetch transactions')
    }

    // Generate CSV content
    const csvHeader = 'Date,Transaction ID,Vendor Name,Amount,Fees,Status,Gateway Reference\n'

    const csvRows = transactions.map(transaction => {
      const date = new Date(transaction.created_at).toLocaleDateString()
      const vendorName = transaction.invoices.vendors.name.replace(/"/g, '""') // Escape quotes

      return `"${date}","${transaction.id}","${vendorName}","${transaction.amount_paid}","${transaction.fees_charged}","${transaction.status}","${transaction.payment_gateway_ref}"`
    }).join('\n')

    const csvContent = csvHeader + csvRows

    return new Response(
      csvContent,
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'text/csv',
          'Content-Disposition': `attachment; filename="invoicepe_ledger_${start_date}_to_${end_date}.csv"`
        }
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

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/export-ledger' \
    --header 'Authorization: Bearer your-local-anon-key-here' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/

// Supabase Edge Function: paystack-verify
// Verifies a Paystack transaction reference using PAYSTACK_SECRET_KEY and
// credits the authenticated user's wallet in `public.profiles` + `public.wallet_transactions`.
//
// Deploy with:
//   supabase secrets set PAYSTACK_SECRET_KEY=<your-live-secret-key>
//   supabase functions deploy paystack-verify

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ status: false, message: 'Missing Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { reference } = await req.json();
    if (!reference) {
      return new Response(JSON.stringify({ status: false, message: 'Missing transaction reference' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const paystackSecret = Deno.env.get('PAYSTACK_SECRET_KEY') ?? '';
    const verifyRes = await fetch(
      `https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,
      {
        headers: {
          Authorization: `Bearer ${paystackSecret}`,
          'Content-Type': 'application/json',
        },
      },
    );
    const verifyJson = await verifyRes.json();

    if (!verifyRes.ok || !verifyJson.status || verifyJson.data?.status !== 'success') {
      return new Response(
        JSON.stringify({
          status: false,
          message: verifyJson.message || 'Transaction not successful on Paystack',
          data: verifyJson.data,
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const amountNaira = Number(verifyJson.data.amount || 0) / 100;
    const channel = String(verifyJson.data.channel || 'paystack');

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: newBalance, error: rpcError } = await supabase.rpc('credit_wallet_paystack', {
      p_reference: reference,
      p_amount: amountNaira,
      p_payment_method: `Paystack (${channel})`,
      p_channel: channel,
      p_metadata: verifyJson.data,
    });

    if (rpcError) {
      return new Response(JSON.stringify({ status: false, message: rpcError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(
      JSON.stringify({
        status: true,
        message: 'Wallet credited successfully',
        data: {
          reference,
          amount_naira: amountNaira,
          channel,
          wallet_balance: newBalance,
        },
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    return new Response(JSON.stringify({ status: false, message: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

// Supabase Edge Function: bigisub-proxy
// Secure server-side proxy for Bigisub Marketing Hub (Social Media Boosting)
// & Education (Examination E-Pins) APIs (`https://api.bigisub.ng`).

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const FALLBACK_ENCODED_TOKEN =
  "NTJmMDcwZWNkZDcyNmIxZmUwNmRlZDI5NTU4NjgzNjZmZDAwZWU3Ng==";

function resolveBigisubToken(): string {
  const envToken = Deno.env.get("BIGISUB_API_TOKEN");
  if (envToken && envToken.trim().length > 0) {
    return envToken.trim();
  }
  return atob(FALLBACK_ENCODED_TOKEN);
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    const method = (payload.method || "GET").toUpperCase();
    const path = (payload.path || "").toString();
    const body = payload.body || undefined;

    // Strictly scope proxy to Marketing Hub and Education endpoints
    if (
      !path.startsWith("/api/v2/marketinghub/") &&
      !path.startsWith("/api/v2/bills/result-checker/") &&
      !path.startsWith("/api/v2/bills/education/")
    ) {
      return new Response(
        JSON.stringify({
          success: false,
          message:
            "Only Marketing Hub (Social Media Boosting) and Education (Examination E-Pins) endpoints are permitted.",
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const token = resolveBigisubToken();
    const targetUrl = `https://api.bigisub.ng${path}`;

    const upstreamRes = await fetch(targetUrl, {
      method,
      headers: {
        Authorization: `Token ${token}`,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: method === "POST" && body ? JSON.stringify(body) : undefined,
    });

    const data = await upstreamRes.json();
    return new Response(JSON.stringify(data), {
      status: upstreamRes.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({
        success: false,
        message: err instanceof Error ? err.message : "Proxy error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

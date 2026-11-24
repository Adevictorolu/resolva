// Supabase Edge Function: bigisub-proxy
// Secure server-side proxy for Bigisub Marketing Hub (Social Media Boosting)
// & Education (Examination E-Pins) APIs (`https://api.bigisub.ng`).
//
// Configure secret in Supabase Dashboard -> Edge Functions -> Secrets (or CLI):
//   supabase secrets set BIGISUB_API_TOKEN=<your-bigisub-token>

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function resolveBigisubToken(): string {
  return (Deno.env.get("BIGISUB_API_TOKEN") ?? "").trim();
}

function sanitizeText(text: string): string {
  if (!text) return text;
  return text
    .replace(/bigi\s*sub/gi, "Resolva Gateway")
    .replace(/bigisub/gi, "Resolva Gateway")
    .replace(/bilalsada\s*sub/gi, "Resolva Gateway")
    .replace(/bilalsadasub/gi, "Resolva Gateway")
    .replace(/marketing\s*hub/gi, "Resolva")
    .replace(/\bmarketing\b/gi, "Resolva")
    .replace(/api\.bigisub\.ng/gi, "gateway.resolva.ng")
    .replace(/api\.bilalsadasub\.com/gi, "gateway.resolva.ng");
}

function sanitizeDeep(obj: unknown): unknown {
  if (typeof obj === "string") return sanitizeText(obj);
  if (Array.isArray(obj)) return obj.map(sanitizeDeep);
  if (obj && typeof obj === "object") {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(obj as Record<string, unknown>)) {
      out[k] = sanitizeDeep(v);
    }
    return out;
  }
  return obj;
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
            "Only approved services (Social Media Boosting & Examination E-Pins) are permitted.",
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const token = resolveBigisubToken();
    if (!token) {
      return new Response(
        JSON.stringify({
          success: false,
          message:
            "Gateway configuration token is not set in Supabase Secrets.",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

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

    const rawData = await upstreamRes.json();
    const sanitizedData = sanitizeDeep(rawData);
    return new Response(JSON.stringify(sanitizedData), {
      status: upstreamRes.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({
        success: false,
        message: "Gateway service temporarily unavailable. Please try again.",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

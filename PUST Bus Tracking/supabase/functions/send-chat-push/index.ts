// =======================================================================
// Supabase Edge Function: send-chat-push
// Real Apple Push Notification Service (APNs) HTTP/2 Gateway
// Sends real push notifications to iPhones when the app is OUTSIDE / CLOSED / KILLED
// (No badge symbol on app icon)
// =======================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

// Apple Developer APNs Credentials
const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID") || ""; // e.g. 10-character Key ID (e.g. 9ABC1234DE)
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID") || ""; // e.g. 10-character Team ID (e.g. 8XYZ5678GH)
const APNS_PRIVATE_KEY = Deno.env.get("APNS_PRIVATE_KEY") || ""; // Contents of AuthKey_XXXXXXXXXX.p8 file
const APNS_BUNDLE_ID = Deno.env.get("APNS_BUNDLE_ID") || "edu.pust.bustracking";
const APNS_IS_PRODUCTION = Deno.env.get("APNS_ENVIRONMENT") === "production";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// Helper: Base64URL encoding
function base64UrlEncode(str: string | Uint8Array): string {
  const binary = typeof str === "string" ? new TextEncoder().encode(str) : str;
  let b64 = btoa(String.fromCharCode(...binary));
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

// Generate Apple APNs Provider Authentication JWT (ES256)
async function generateApnsJwt(): Promise<string | null> {
  if (!APNS_KEY_ID || !APNS_TEAM_ID || !APNS_PRIVATE_KEY) return null;

  try {
    const pemHeader = "-----BEGIN PRIVATE KEY-----";
    const pemFooter = "-----END PRIVATE KEY-----";
    let pemContents = APNS_PRIVATE_KEY.replace(pemHeader, "").replace(pemFooter, "").replace(/\s/g, "");
    const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

    const cryptoKey = await crypto.subtle.importKey(
      "pkcs8",
      binaryDer.buffer,
      { name: "ECDSA", namedCurve: "P-256" },
      false,
      ["sign"]
    );

    const header = JSON.stringify({ alg: "ES256", kid: APNS_KEY_ID });
    const now = Math.floor(Date.now() / 1000);
    const claims = JSON.stringify({ iss: APNS_TEAM_ID, iat: now });

    const encodedHeader = base64UrlEncode(header);
    const encodedClaims = base64UrlEncode(claims);
    const signingInput = `${encodedHeader}.${encodedClaims}`;

    const signature = await crypto.subtle.sign(
      { name: "ECDSA", hash: { name: "SHA-256" } },
      cryptoKey,
      new TextEncoder().encode(signingInput)
    );

    // Convert raw IEEE P1363 signature to DER or base64url
    const encodedSignature = base64UrlEncode(new Uint8Array(signature));
    return `${signingInput}.${encodedSignature}`;
  } catch (err) {
    console.error("Error generating APNs JWT:", err);
    return null;
  }
}

serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record || payload;
    const busN = record.bus_n;
    const sender = record.display_name || record.user_name || "যাত্রী";
    const text = record.message || record.body || "";

    if (!busN) {
      return new Response(JSON.stringify({ error: "Missing bus_n" }), { status: 400 });
    }

    // 1. Fetch all registered iPhone device tokens subscribed to this bus
    const { data: devices, error } = await supabase
      .from("device_push_tokens")
      .select("token")
      .contains("subscribed_buses", [busN]);

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }

    if (!devices || devices.length === 0) {
      return new Response(JSON.stringify({ message: "No offline devices subscribed to Bus " + busN }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const apnsJwt = await generateApnsJwt();
    const apnsHost = APNS_IS_PRODUCTION
      ? "https://api.push.apple.com"
      : "https://api.sandbox.push.apple.com";

    const pushPayload = {
      aps: {
        alert: {
          title: `🚌 বাস #${busN}`,
          subtitle: sender,
          body: text,
        },
        sound: "default",
        "interruption-level": "time-sensitive",
      },
      bus: busN,
    };

    let sentCount = 0;

    // Send HTTP/2 push request to Apple APNs for each device
    if (apnsJwt) {
      const promises = devices.map(async (d) => {
        try {
          const res = await fetch(`${apnsHost}/3/device/${d.token}`, {
            method: "POST",
            headers: {
              authorization: `bearer ${apnsJwt}`,
              "apns-topic": APNS_BUNDLE_ID,
              "apns-push-type": "alert",
              "apns-priority": "10",
              "Content-Type": "application/json",
            },
            body: JSON.stringify(pushPayload),
          });
          if (res.ok) sentCount++;
        } catch (e) {
          console.error("APNs push send failed for token:", d.token, e);
        }
      });
      await Promise.all(promises);
    }

    return new Response(
      JSON.stringify({
        success: true,
        subscribed_devices: devices.length,
        dispatched_apns: sentCount,
        bus: busN,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

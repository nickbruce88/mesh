// Mesh Sports — send-notification Edge Function
// Triggered by: announcement posted, message sent
// Sends Web Push to all relevant subscribers in a program

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const VAPID_PUBLIC_KEY  = 'BDY_NFZqCYMcObVxvkoU4Z3UDOk_5sAwhmi_CVwNer5pA3UZ-qt23QH1G_BvH9-Fm-JjIcCPC81IUYPqi2H4BQ0';
const VAPID_PRIVATE_KEY = Deno.env.get('VAPID_PRIVATE_KEY')!;
const VAPID_SUBJECT     = 'mailto:support@meshsports.co';

// ---------- VAPID helpers ----------

function base64urlToUint8Array(base64url: string): Uint8Array {
  const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64.padEnd(base64.length + (4 - base64.length % 4) % 4, '=');
  const binary = atob(padded);
  return Uint8Array.from(binary, c => c.charCodeAt(0));
}

function uint8ArrayToBase64url(arr: Uint8Array): string {
  return btoa(String.fromCharCode(...arr))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

async function buildVapidHeaders(endpoint: string): Promise<Record<string, string>> {
  const url = new URL(endpoint);
  const audience = `${url.protocol}//${url.host}`;
  const exp = Math.floor(Date.now() / 1000) + 12 * 3600;

  const header = uint8ArrayToBase64url(
    new TextEncoder().encode(JSON.stringify({ typ: 'JWT', alg: 'ES256' }))
  );
  const payload = uint8ArrayToBase64url(
    new TextEncoder().encode(JSON.stringify({ aud: audience, exp, sub: VAPID_SUBJECT }))
  );
  const sigInput = `${header}.${payload}`;

  const privKeyBytes = base64urlToUint8Array(VAPID_PRIVATE_KEY);
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    // Wrap raw EC private key bytes into PKCS8 DER
    (() => {
      // EC private key PKCS8 wrapper for P-256
      const prefix = new Uint8Array([
        0x30, 0x41, 0x02, 0x01, 0x00, 0x30, 0x13, 0x06,
        0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01,
        0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03,
        0x01, 0x07, 0x04, 0x27, 0x30, 0x25, 0x02, 0x01,
        0x01, 0x04, 0x20
      ]);
      const key = new Uint8Array(prefix.length + privKeyBytes.length);
      key.set(prefix);
      key.set(privKeyBytes, prefix.length);
      return key.buffer;
    })(),
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign']
  );

  const sig = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' },
    cryptoKey,
    new TextEncoder().encode(sigInput)
  );

  const jwt = `${sigInput}.${uint8ArrayToBase64url(new Uint8Array(sig))}`;

  return {
    'Authorization': `vapid t=${jwt}, k=${VAPID_PUBLIC_KEY}`,
    'Content-Type': 'application/octet-stream',
    'TTL': '86400',
  };
}

// ---------- Main handler ----------

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      }
    });
  }

  try {
    const { program_id, type, title, body, target_roles } = await req.json();
    // type: 'announcement' | 'message'
    // target_roles: ['coach','player','parent'] or subset

    if (!program_id || !type || !title) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), { status: 400 });
    }

    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Fetch all push subscriptions for this program filtered by role
    const roles = target_roles || ['coach', 'player', 'parent'];
    const { data: tokens, error } = await db
      .from('notification_tokens')
      .select('subscription, user_role')
      .eq('program_id', program_id)
      .in('user_role', roles);

    if (error) throw error;
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
    }

    // Send push to each subscriber
    const results = await Promise.allSettled(
      tokens.map(async (token) => {
        const sub = token.subscription;
        const headers = await buildVapidHeaders(sub.endpoint);
        const payloadStr = JSON.stringify({ title, body: body || '', tag: type });
        const payloadBytes = new TextEncoder().encode(payloadStr);

        const res = await fetch(sub.endpoint, {
          method: 'POST',
          headers,
          body: payloadBytes,
        });

        if (!res.ok && res.status !== 201) {
          // 410 = subscription expired — remove it
          if (res.status === 410) {
            await db.from('notification_tokens')
              .delete()
              .eq('subscription->>endpoint', sub.endpoint);
          }
          throw new Error(`Push failed: ${res.status}`);
        }
        return res.status;
      })
    );

    const sent = results.filter(r => r.status === 'fulfilled').length;
    const failed = results.filter(r => r.status === 'rejected').length;

    return new Response(JSON.stringify({ sent, failed }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (err) {
    console.error('[send-notification]', err);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});

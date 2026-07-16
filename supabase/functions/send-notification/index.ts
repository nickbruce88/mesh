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
    const { program_id, type, title, body, target_roles, target_user_ids, category, thread_id } = await req.json();
    // type: 'announcement' | 'message'
    // target_roles: ['coach','player','parent'] or subset  (broadcasts)
    // target_user_ids: ['<uuid>', ...]  (direct/witnessed messages — takes precedence)
    // category: notification-pref key to honor (e.g. 'messages'); thread_id: for per-thread mute

    if (!program_id || !type || !title) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), { status: 400 });
    }

    const db = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // ---------- AUTHORIZE THE CALLER ----------
    // verify_jwt is on, so the caller is *some* logged-in Mesh user — but that alone
    // let anyone push arbitrary title/body to ANY program's users and spoof a sender.
    // Resolve who they are and confirm they belong to program_id (and, for a DM,
    // that they're a participant of thread_id).
    const cors = { 'Access-Control-Allow-Origin': '*' };
    const authHeader = req.headers.get('Authorization') || '';
    const callerToken = authHeader.replace(/^Bearer\s+/i, '').trim();
    if (!callerToken) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: cors });
    }
    const authClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: `Bearer ${callerToken}` } } }
    );
    const { data: { user: caller }, error: callerErr } = await authClient.auth.getUser();
    if (callerErr || !caller) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: cors });
    }
    // Caller must belong to the program they're pushing to (checked with the
    // service role so RLS on profiles/players doesn't hide the row).
    const [{ data: prof }, { data: plyr }] = await Promise.all([
      db.from('profiles').select('program_id').eq('id', caller.id).maybeSingle(),
      db.from('players').select('program_id').eq('auth_uid', caller.id).maybeSingle(),
    ]);
    const callerProgram = prof?.program_id || plyr?.program_id || null;
    if (!callerProgram || callerProgram !== program_id) {
      return new Response(JSON.stringify({ error: 'Forbidden: not a member of this program' }), { status: 403, headers: cors });
    }
    // For a thread-scoped send (a DM), the caller must be a participant of that thread.
    if (thread_id) {
      const { data: part } = await db
        .from('thread_participants').select('user_id')
        .eq('thread_id', thread_id).eq('user_id', caller.id).maybeSingle();
      if (!part) {
        return new Response(JSON.stringify({ error: 'Forbidden: not a participant of this thread' }), { status: 403, headers: cors });
      }
    }

    // Fetch push subscriptions for this program.
    // If specific user ids are given (a DM), target ONLY those users; otherwise fall back to roles.
    let q = db
      .from('notification_tokens')
      .select('subscription, user_role, user_id')
      .eq('program_id', program_id);

    if (Array.isArray(target_user_ids) && target_user_ids.length > 0) {
      q = q.in('user_id', target_user_ids);
    } else {
      q = q.in('user_role', target_roles || ['coach', 'player', 'parent']);
    }

    const { data: tokens, error } = await q;

    if (error) throw error;
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
    }

    // Honor per-user notification prefs (category off) and per-thread mutes.
    let recipients = tokens;
    const uids = [...new Set(tokens.map((t) => t.user_id).filter(Boolean))];
    if (uids.length) {
      if (category) {
        const { data: prefRows } = await db
          .from('notification_prefs').select('user_id, prefs').in('user_id', uids);
        const disabled = new Set(
          (prefRows || []).filter((r) => r.prefs && r.prefs[category] === false).map((r) => r.user_id)
        );
        if (disabled.size) recipients = recipients.filter((t) => !disabled.has(t.user_id));
      }
      if (thread_id) {
        const { data: muteRows } = await db
          .from('thread_mutes').select('user_id').eq('thread_id', thread_id).in('user_id', uids);
        const muted = new Set((muteRows || []).map((r) => r.user_id));
        if (muted.size) recipients = recipients.filter((t) => !muted.has(t.user_id));
      }
    }
    if (recipients.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
    }

    // Send push to each subscriber
    const results = await Promise.allSettled(
      recipients.map(async (token) => {
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

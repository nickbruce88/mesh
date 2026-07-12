import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const EXPIRY_SECONDS = 31536000 // 1 year

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Verify the caller is authenticated
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Use anon client to verify the JWT
    const userClient = createClient(SUPABASE_URL, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: authHeader } }
    })
    const { data: { user }, error: authErr } = await userClient.auth.getUser()
    if (authErr || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // 2. Parse request body — accepts { path: string } or { paths: string[] }
    const body = await req.json()
    const paths: string[] = body.paths ?? (body.path ? [body.path] : [])
    if (!paths.length) {
      return new Response(JSON.stringify({ error: 'No paths provided' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // 3. Validate all paths are avatar paths (basic guard against abuse)
    // Each path must look like: {uuid}/avatar.jpg
    const uuidRegex = /^[0-9a-f-]{36}\/avatar\.jpg$/i
    for (const p of paths) {
      if (!uuidRegex.test(p)) {
        return new Response(JSON.stringify({ error: `Invalid path: ${p}` }), {
          status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
    }

    // 4. Sign using service role (bypasses RLS — can sign any file)
    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
    const { data: signed, error: signErr } = await adminClient.storage
      .from('avatars')
      .createSignedUrls(paths, EXPIRY_SECONDS)

    if (signErr) {
      return new Response(JSON.stringify({ error: signErr.message }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // 5. Return map of path → signedUrl
    const result: Record<string, string | null> = {}
    ;(signed ?? []).forEach((s, i) => { result[paths[i]] = s.signedUrl ?? null })

    return new Response(JSON.stringify({ data: result }), {
      status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
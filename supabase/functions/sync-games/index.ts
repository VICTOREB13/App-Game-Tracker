import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { action, userId, providerId } = await req.json();

    if (!userId) {
      throw new Error("Missing user ID");
    }

    let logs = [];
    let count = 0;

    // A. STEAM SYNC
    if (action === 'sync-steam') {
      const steamKey = Deno.env.get('STEAM_KEY');
      if (!steamKey) throw new Error("Missing STEAM_KEY in Edge Function envs");

      logs.push(`🔍 Buscando biblioteca en Steam (ID: ${providerId})`);
      const url = `http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=${steamKey}&steamid=${providerId}&format=json&include_appinfo=true`;
      
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Steam API devolvió código: ${response.status}`);
      }

      const data = await response.json();
      const games = data.response.games || [];
      
      for (const sg of games) {
        const title = sg.name;
        const hours = sg.playtime_forever / 60.0;
        const lastPlayedAt = sg.rtime_last_played 
            ? new Date(sg.rtime_last_played * 1000).toISOString()
            : null;

        await upsertGame(supabaseClient, userId, title, "PC", "Steam", hours, lastPlayedAt);
        count++;
      }
      logs.push(`✅ ${count} juegos de Steam importados.`);
    }

    // B. XBOX SYNC (Usando xbl.io)
    else if (action === 'sync-xbox') {
      const xblKey = Deno.env.get('OPENXBL_KEY');
      if (!xblKey) throw new Error("Missing OPENXBL_KEY");

      logs.push(`💚 Consultando OpenXBL API para GamerTag/XUID...`);
      // Note: Full Xbox logic requires XUID lookup then titlehistory.
      logs.push(`⚠️ Xbox via Edge Functions configurado. (Requiere XUID válido)`);
    }

    // LOGS AUDITORIA
    await supabaseClient.from('sync_logs').insert({
      user_id: userId,
      platform: action,
      status: 'Success',
      message: logs.join('\n')
    });

    return new Response(JSON.stringify({ success: true, count, logs }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});

async function upsertGame(supabase, userId, title, platform, provider, hours, lastPlayedAt) {
  // 1. Check existing
  const { data: existing } = await supabase
    .from('games')
    .select('id, hours_played, status, hltb_main')
    .eq('user_id', userId)
    .ilike('title', title)
    .single();

  let status = existing?.status || 'Por Jugar';
  const oldHours = existing?.hours_played || 0;
  const hltb = existing?.hltb_main || 0;

  if (hltb > 0 && Math.max(hours, oldHours) >= hltb) {
    status = 'Completado';
  } else if (hours > 0.1 && (status === 'Por Jugar' || status === 'Pausado')) {
    status = 'Jugando';
  }

  const payload = {
    user_id: userId,
    title,
    platform,
    provider,
    hours_played: hours > oldHours ? hours : oldHours,
    status,
    last_played_at: lastPlayedAt || undefined,
    updated_at: new Date().toISOString()
  };

  if (!existing) {
    const metadata = await fetchRawgMetadata(title);
    Object.assign(payload, metadata);
    await supabase.from('games').insert(payload);
  } else {
    await supabase.from('games').update(payload).eq('id', existing.id);
  }
}

async function fetchRawgMetadata(title: string) {
  const rawgKey = Deno.env.get('RAWG_KEY');
  if (!rawgKey) return {};

  try {
    const url = `https://api.rawg.io/api/games?key=${rawgKey}&search=${encodeURIComponent(title)}&page_size=1`;
    const response = await fetch(url);
    if (!response.ok) return {};
    
    const data = await response.json();
    if (data.results && data.results.length > 0) {
      const g = data.results[0];
      const genres = g.genres ? g.genres.map((e: any) => e.name).join(', ') : null;
      const tags = g.tags ? g.tags.map((e: any) => e.name).join(', ') : null;
      return {
        cover_url: g.background_image,
        genre: genres,
        tags: tags
      };
    }
  } catch (e) {
    // Silencioso, si falla solo insertamos sin meta
  }
  return {};
}

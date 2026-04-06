/**
 * Cliente Supabase — preencha url e anonKey (Dashboard → Settings → API).
 * Sem analytics. Sem rastreamento.
 */
(function (global) {
  var cfg = global.RODASDF_CONFIG || {};
  var url = cfg.url || '';
  var anonKey = cfg.anonKey || '';

  function ensureClient() {
    if (!global.supabase || !global.supabase.createClient) {
      console.error('Carregue @supabase/supabase-js antes de supabase-client.js');
      return null;
    }
    if (!url || !anonKey || url.indexOf('YOUR_') === 0) {
      console.warn('Configure RODASDF_CONFIG em cada página HTML (url + anonKey).');
    }
    return global.supabase.createClient(url, anonKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
      },
    });
  }

  global.getSupabase = function () {
    var cfg = global.RODASDF_CONFIG || {};
    var ver = String(cfg.url || '') + '|' + String(cfg.anonKey || '').slice(0, 12);
    if (global._sbCacheVer !== ver) {
      global._sb = null;
      global._sbCacheVer = ver;
    }
    if (!global._sb) global._sb = ensureClient();
    return global._sb;
  };
})(typeof window !== 'undefined' ? window : globalThis);

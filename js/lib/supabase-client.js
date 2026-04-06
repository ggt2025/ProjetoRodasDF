/**
 * Cliente Supabase — preencha url e anonKey (Dashboard → Settings → API).
 * Sem analytics. Sem rastreamento.
 */
(function (global) {
  var cfg = global.RODASDF_CONFIG || {};
  var url = cfg.url || '';
  var anonKey = cfg.anonKey || '';

  function isPlaceholderKey(k) {
    if (!k || typeof k !== 'string') return true;
    var t = k.trim();
    if (!t) return true;
    if (t.indexOf('YOUR_') === 0) return true;
    if (t === 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...') return true;
    return false;
  }

  function ensureClient() {
    if (!global.supabase || !global.supabase.createClient) {
      console.error('Carregue @supabase/supabase-js antes de supabase-client.js');
      return null;
    }
    var u = String(url || '').trim();
    var k = String(anonKey || '').trim();
    if (!u || !k || u.indexOf('YOUR_') === 0 || isPlaceholderKey(k)) {
      console.warn('Configure RODASDF_CONFIG (url + anonKey) em js/config.js.');
      return null;
    }
    return global.supabase.createClient(u, k, {
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

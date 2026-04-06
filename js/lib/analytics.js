/**
 * Registo de visualização de página no Supabase (analytics interno).
 * Requer tabela public.analytics_page_views (ver sql/projeto_rodas_df_completo.sql).
 */
(function (global) {
  global.trackPageView = async function () {
    var sb = global.getSupabase();
    if (!sb) return;
    var path = (global.location.pathname || '/') + (global.location.search || '');
    var h = global.location.hash || '';
    var uid = null;
    try {
      var sessionRes = await sb.auth.getSession();
      var sess = sessionRes.data && sessionRes.data.session;
      if (sess && sess.user) uid = sess.user.id;
    } catch (e) {}
    var ins = await sb.from('analytics_page_views').insert({
      path: path.slice(0, 500),
      page_hash: h.slice(0, 200) || null,
      user_id: uid,
    });
    if (ins.error && global.console && console.debug) console.debug('analytics:', ins.error.message);
  };
})(window);

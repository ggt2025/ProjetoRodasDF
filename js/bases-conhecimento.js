(function (global) {
  global.loadBasesLanding = async function (containerId) {
    var el = document.getElementById(containerId);
    if (!el) return;
    var sb = global.getSupabase();
    if (!sb) {
      el.innerHTML = '<p class="empty-state">Configure o Supabase.</p>';
      return;
    }
    var res = await sb
      .from('bases_conhecimento')
      .select('id,titulo,descricao,url,categoria')
      .eq('publicado', true)
      .order('titulo');
    if (res.error) {
      el.innerHTML = '<p class="empty-state">Erro ao carregar bases.</p>';
      return;
    }
    var rows = res.data || [];
    if (!rows.length) {
      el.innerHTML = '<p class="empty-state">Nenhum link cadastrado ainda.</p>';
      return;
    }
    el.innerHTML =
      '<div class="bases-list">' +
      rows
        .map(function (b) {
          var href = b.url && String(b.url).trim() ? b.url : '#';
          return (
            '<a class="base-link" href="' +
            global.escapeHtml(href) +
            '" target="_blank" rel="noopener noreferrer"><span>' +
            global.escapeHtml(b.titulo) +
            '</span><span style="font-size:12px;color:var(--gray-500);margin-left:auto">' +
            global.escapeHtml(b.categoria || 'Link') +
            '</span></a>'
          );
        })
        .join('') +
      '</div>';
  };
})(window);

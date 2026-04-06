(function (global) {
  global.loadNoticiasLanding = async function (containerId, limit) {
    var el = document.getElementById(containerId);
    if (!el) return;
    var sb = global.getSupabase();
    if (!sb) {
      el.innerHTML = '<p class="empty-state">Configure o Supabase.</p>';
      return;
    }
    var lim = limit || 6;
    var res = await sb
      .from('noticias')
      .select('id,titulo,resumo,conteudo,imagem_url,data_publicacao')
      .eq('publicado', true)
      .order('data_publicacao', { ascending: false })
      .limit(lim);
    if (res.error) {
      el.innerHTML = '<p class="empty-state">Erro ao carregar notícias.</p>';
      return;
    }
    var rows = res.data || [];
    if (!rows.length) {
      el.innerHTML = '<p class="empty-state">Nenhuma notícia publicada ainda.</p>';
      return;
    }
    el.innerHTML =
      '<div class="cards-grid">' +
      rows
        .map(function (n) {
          var img = n.imagem_url
            ? '<img src="' + global.escapeHtml(n.imagem_url) + '" alt="" loading="lazy">'
            : '';
          return (
            '<article class="card-n">' +
            img +
            '<div class="meta">' +
            global.formatDateBR(n.data_publicacao) +
            '</div><h3>' +
            global.escapeHtml(n.titulo) +
            '</h3><p>' +
            global.escapeHtml(n.resumo || '') +
            '</p></article>'
          );
        })
        .join('') +
      '</div>';
  };
})(window);

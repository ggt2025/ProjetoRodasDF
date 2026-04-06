(function (global) {
  global.loadEditaisLanding = async function (containerId) {
    var el = document.getElementById(containerId);
    if (!el) return;
    var sb = global.getSupabase();
    if (!sb) {
      el.innerHTML = '<p class="empty-state">Configure o Supabase.</p>';
      return;
    }
    var res = await sb
      .from('editais')
      .select('id,titulo,descricao,arquivo_url,data_abertura,data_encerramento')
      .eq('publicado', true)
      .order('created_at', { ascending: false });
    if (res.error) {
      el.innerHTML = '<p class="empty-state">Erro ao carregar editais.</p>';
      return;
    }
    var rows = res.data || [];
    if (!rows.length) {
      el.innerHTML = '<p class="empty-state">Nenhum edital publicado no momento.</p>';
      return;
    }
    el.innerHTML = rows
      .map(function (e) {
        var link =
          e.arquivo_url && String(e.arquivo_url).trim()
            ? '<a class="btn btn-secondary" href="' +
              global.escapeHtml(e.arquivo_url) +
              '" target="_blank" rel="noopener">Abrir documento</a>'
            : '';
        return (
          '<article class="card-n card-edital"><h3>' +
          global.escapeHtml(e.titulo) +
          '</h3><p>' +
          global.escapeHtml(e.descricao || '') +
          '</p><p style="font-size:12px;color:var(--gray-500)">Abertura: ' +
          global.formatDateBR(e.data_abertura) +
          ' · Encerramento: ' +
          global.formatDateBR(e.data_encerramento) +
          '</p>' +
          link +
          '</article>'
        );
      })
      .join('');
  };
})(window);

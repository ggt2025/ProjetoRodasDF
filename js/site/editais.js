(function (global) {
  function renderEditalCard(e, featured) {
    var link =
      e.arquivo_url && String(e.arquivo_url).trim()
        ? '<a class="btn btn-secondary" href="' +
          global.escapeHtml(e.arquivo_url) +
          '" target="_blank" rel="noopener">Abrir documento</a>'
        : '';
    var cls = 'card-n card-edital' + (featured ? ' card-edital--destaque' : '');
    return (
      '<article class="' +
      cls +
      '"><h3>' +
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
  }

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
      el.innerHTML = global.supabaseErrorBox
        ? global.supabaseErrorBox(res.error)
        : '<p class="empty-state">' + global.escapeHtml(res.error.message) + '</p>';
      return;
    }
    var rows = res.data || [];
    if (!rows.length) {
      el.innerHTML = '<p class="empty-state">Nenhum edital publicado no momento.</p>';
      return;
    }
    var featured =
      rows.find(function (r) {
        return /capacita/i.test(r.titulo || '');
      }) || rows[0];
    var rest = rows.filter(function (r) {
      return r.id !== featured.id;
    });
    var html = '';
    if (featured) {
      html +=
        '<p class="edital-destaque-label">Edital de capacitação em destaque</p>' + renderEditalCard(featured, true);
    }
    if (rest.length) {
      html += '<div class="editais-demais"><h3 class="editais-demais-h">Outros editais</h3>';
      html += rest.map(function (e) {
        return renderEditalCard(e, false);
      }).join('');
      html += '</div>';
    }
    el.innerHTML = html;
  };
})(window);

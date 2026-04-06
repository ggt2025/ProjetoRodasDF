/**
 * Área de gestão do projeto — painéis unificados (hash).
 */
(function (global) {
  async function ensureGestao() {
    var x = await global.getSessionUser();
    if (!x.user) {
      global.location.href = 'login.html?next=' + encodeURIComponent(global.location.pathname);
      return null;
    }
    var r = x.profile && x.profile.role;
    if (r !== 'gestao' && r !== 'admin') {
      global.toast('Acesso restrito à gestão.', 'err');
      global.location.href = 'dashboard-usuario.html';
      return null;
    }
    return x;
  }

  async function loadPainel() {
    var sb = global.getSupabase();
    if (!sb) return;
    var m = document.getElementById('mount-painel-kpi');
    if (!m) return;
    var r1 = await sb.from('rodas').select('*', { count: 'exact', head: true }).eq('status', 'pendente');
    var r2 = await sb.from('contatos').select('*', { count: 'exact', head: true }).eq('lido', false);
    var r3 = await sb.from('noticias').select('*', { count: 'exact', head: true }).eq('publicado', false);
    m.innerHTML =
      '<div class="dash-kpi-grid">' +
      '<div class="dash-kpi"><strong>' +
      (r1.count != null ? r1.count : '—') +
      '</strong><span>Rodas pendentes</span></div>' +
      '<div class="dash-kpi"><strong>' +
      (r2.count != null ? r2.count : '—') +
      '</strong><span>Contactos não lidos</span></div>' +
      '<div class="dash-kpi"><strong>' +
      (r3.count != null ? r3.count : '—') +
      '</strong><span>Notícias rascunho</span></div>' +
      '</div>' +
      '<p class="dash-muted">O cronograma e o calendário estão abaixo nesta mesma página. Participação dos visitantes: aba <strong>Participação</strong>.</p>';
  }

  async function loadAnalyticsGestao() {
    var el = document.getElementById('mount-analytics-gestao');
    if (!el) return;
    var sb = global.getSupabase();
    var res = await sb
      .from('analytics_page_views')
      .select('created_at,path,page_hash,user_id')
      .order('created_at', { ascending: false })
      .limit(200);
    if (res.error) {
      el.innerHTML =
        '<p class="dash-muted">Execute <code>sql/projeto_rodas_df_completo.sql</code> no Supabase (tabela analytics). ' +
        global.escapeHtml(res.error.message) +
        '</p>';
      return;
    }
    var rows = res.data || [];
    if (!rows.length) {
      el.innerHTML = '<p class="dash-muted">Ainda sem visitas registadas.</p>';
      return;
    }
    el.innerHTML =
      '<div class="dash-table-wrap"><table class="dash-table"><thead><tr><th>Quando</th><th>Página</th><th>Hash</th><th>User ID</th></tr></thead><tbody>' +
      rows
        .map(function (r) {
          return (
            '<tr><td>' +
            global.escapeHtml(global.formatDateTimeBR(r.created_at)) +
            '</td><td>' +
            global.escapeHtml(r.path || '') +
            '</td><td>' +
            global.escapeHtml(r.page_hash || '') +
            '</td><td style="font-size:11px">' +
            global.escapeHtml(r.user_id ? String(r.user_id).slice(0, 8) + '…' : '—') +
            '</td></tr>'
          );
        })
        .join('') +
      '</tbody></table></div>';
  }

  async function loadTable(mountId, table, cols) {
    var el = document.getElementById(mountId);
    if (!el) return;
    var sb = global.getSupabase();
    var res = await sb.from(table).select('*').limit(100);
    if (res.error) {
      el.innerHTML = '<p class="dash-muted">' + global.escapeHtml(res.error.message) + '</p>';
      return;
    }
    var rows = res.data || [];
    if (!rows.length) {
      el.innerHTML = '<p class="dash-muted">Sem registos.</p>';
      return;
    }
    var keys = cols || Object.keys(rows[0]);
    el.innerHTML =
      '<div class="dash-table-wrap"><table class="dash-table"><thead><tr>' +
      keys
        .map(function (k) {
          return '<th>' + global.escapeHtml(k) + '</th>';
        })
        .join('') +
      '</tr></thead><tbody>' +
      rows
        .map(function (row) {
          return (
            '<tr>' +
            keys
              .map(function (k) {
                var v = row[k];
                if (v != null && typeof v === 'object') v = JSON.stringify(v);
                return '<td>' + global.escapeHtml(String(v != null ? v : '')).slice(0, 200) + '</td>';
              })
              .join('') +
            '</tr>'
          );
        })
        .join('') +
      '</tbody></table></div>';
  }

  function renderMiniTable(rows, keys) {
    if (!rows.length) return '<p class="dash-muted">Sem dados.</p>';
    return (
      '<div class="dash-table-wrap"><table class="dash-table"><thead><tr>' +
      keys
        .map(function (k) {
          return '<th>' + global.escapeHtml(k) + '</th>';
        })
        .join('') +
      '</tr></thead><tbody>' +
      rows
        .map(function (row) {
          return (
            '<tr>' +
            keys
              .map(function (k) {
                return '<td>' + global.escapeHtml(String(row[k] != null ? row[k] : '')) + '</td>';
              })
              .join('') +
            '</tr>'
          );
        })
        .join('') +
      '</tbody></table></div>'
    );
  }

  async function loadSiteNoticiasEditais() {
    var a = document.getElementById('mount-site-noticias');
    var b = document.getElementById('mount-site-editais');
    var sb = global.getSupabase();
    if (a) {
      var n = await sb.from('noticias').select('titulo,publicado,data_publicacao').order('created_at', { ascending: false }).limit(30);
      a.innerHTML = n.error
        ? global.escapeHtml(n.error.message)
        : renderMiniTable(n.data || [], ['titulo', 'publicado', 'data_publicacao']);
    }
    if (b) {
      var e = await sb.from('editais').select('titulo,publicado,data_abertura').order('created_at', { ascending: false }).limit(30);
      b.innerHTML = e.error
        ? global.escapeHtml(e.error.message)
        : renderMiniTable(e.data || [], ['titulo', 'publicado', 'data_abertura']);
    }
  }

  async function loadForumPriv() {
    var el = document.getElementById('mount-forum-priv');
    if (!el) return;
    var sb = global.getSupabase();
    var res = await sb.from('forum_topicos').select('*').eq('tipo', 'privado').order('created_at', { ascending: false });
    if (res.error) {
      el.innerHTML = '<p class="dash-muted">' + global.escapeHtml(res.error.message) + '</p>';
      return;
    }
    var rows = res.data || [];
    el.innerHTML =
      '<p class="dash-panel-intro">Fórum <strong>privado</strong> da equipa — distinto do fórum público. Mensagens em implementação.</p><div class="dash-card-list">' +
      (rows.length
        ? rows
            .map(function (f) {
              return (
                '<article class="dash-info-card"><h3>' +
                global.escapeHtml(f.titulo) +
                '</h3><p style="font-size:14px">' +
                global.escapeHtml(f.descricao || '') +
                '</p></article>'
              );
            })
            .join('')
        : '<p class="dash-muted">Sem tópicos.</p>') +
      '</div>';
  }

  document.addEventListener('DOMContentLoaded', async function () {
    if (!document.getElementById('dash-gestao-root')) return;
    var ok = await ensureGestao();
    if (!ok) return;
    if (global.updateHeaderAuth) await global.updateHeaderAuth();

    var legacy = { '#painel': '#dashboard', '#cronograma': '#dashboard', '#calendario': '#dashboard' };
    var h = global.location.hash;
    if (legacy[h]) {
      global.history.replaceState(null, '', global.location.pathname + global.location.search + legacy[h]);
    }

    if (global.initDashPanels) {
      global.initDashPanels({
        navSelector: '.dash-sidebar [data-dash-tab]',
        panelsSelector: '[data-dash-panel]',
        defaultHash: '#dashboard',
      });
    }

    await loadPainel();
    await loadTable('mount-cronograma', 'cronograma');
    if (global.initCalendarSection) await global.initCalendarSection('mount-gestao-cal');
    await loadAnalyticsGestao();
    await loadTable('mount-encaminhamentos', 'encaminhamentos');
    await loadTable('mount-equipe', 'equipe_projeto');
    if (typeof global.initGestaoRedeBloco === 'function') await global.initGestaoRedeBloco();
    await loadSiteNoticiasEditais();
    await loadForumPriv();
    await loadTable('mount-registro', 'registro_atividades');
  });
})(window);

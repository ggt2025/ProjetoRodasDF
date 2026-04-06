/**
 * Área do utilizador comum — protótipos, Rede DF, fórum público (leitura).
 */
(function (global) {
  async function loadPrototipos(mountId) {
    var el = document.getElementById(mountId);
    if (!el) return;
    var sb = global.getSupabase();
    if (!sb) {
      el.innerHTML = '<p class="dash-muted">Supabase não configurado.</p>';
      return;
    }
    var res = await sb.from('prototipos_redes').select('*').eq('publicado', true).order('created_at', { ascending: false });
    if (res.error) {
      el.innerHTML = '<p class="dash-muted">' + global.escapeHtml(res.error.message) + '</p>';
      return;
    }
    var rows = res.data || [];
    if (!rows.length) {
      el.innerHTML = '<p class="dash-muted">Nenhum conteúdo publicado.</p>';
      return;
    }
    el.innerHTML =
      '<div class="dash-card-list">' +
      rows
        .map(function (p) {
          return (
            '<article class="dash-info-card"><span class="dash-badge">' +
            global.escapeHtml(p.tipo || '—') +
            '</span><h3>' +
            global.escapeHtml(p.titulo) +
            '</h3><p style="font-size:14px;color:var(--gray-600)">' +
            global.escapeHtml(p.descricao || '') +
            '</p></article>'
          );
        })
        .join('') +
      '</div>';
  }

  async function loadRedeDf(mountId) {
    var el = document.getElementById(mountId);
    if (!el) return;
    var sb = global.getSupabase();
    if (!sb) return;
    var res = await sb.from('rede_df').select('*').order('circunscricao').limit(200);
    if (res.error) {
      el.innerHTML = '<p class="dash-muted">' + global.escapeHtml(res.error.message) + '</p>';
      return;
    }
    var rows = res.data || [];
    if (!rows.length) {
      el.innerHTML =
        '<p class="dash-muted">A rede de equipamentos no DF será carregada pela gestão. Mapa mais amplo do que as rodas de conversa.</p>';
      return;
    }
    el.innerHTML =
      '<p class="dash-panel-intro">Panorama de equipamentos e pontos da rede (articulação com rodas e pontes). Dados consultivos — confirme na instituição.</p><div class="dash-card-list">' +
      rows
        .map(function (r) {
          return (
            '<article class="dash-info-card"><h3>' +
            global.escapeHtml(r.nome) +
            '</h3><p style="font-size:13px;color:var(--gray-600)">' +
            global.escapeHtml(r.circunscricao || '') +
            ' · ' +
            global.escapeHtml(r.tipo_equipamento || '') +
            '</p><p style="font-size:13px">' +
            global.escapeHtml((r.descricao || '').slice(0, 280)) +
            (r.descricao && r.descricao.length > 280 ? '…' : '') +
            '</p></article>'
          );
        })
        .join('') +
      '</div>';
  }

  async function loadForumPublico(mountId) {
    var el = document.getElementById(mountId);
    if (!el) return;
    var sb = global.getSupabase();
    if (!sb) return;
    var res = await sb.from('forum_topicos').select('*').eq('tipo', 'publico').order('created_at', { ascending: false });
    if (res.error) {
      el.innerHTML = '<p class="dash-muted">' + global.escapeHtml(res.error.message) + '</p>';
      return;
    }
    var rows = res.data || [];
    el.innerHTML =
      '<p class="dash-panel-intro">Fórum de debate <strong>público</strong> — textos genéricos; discussão em implementação. Foco distinto do fórum privado da gestão.</p><div class="dash-card-list">' +
      (rows.length
        ? rows
            .map(function (f) {
              return (
                '<article class="dash-info-card"><h3>' +
                global.escapeHtml(f.titulo) +
                '</h3><p style="font-size:14px">' +
                global.escapeHtml(f.descricao || '') +
                '</p><p class="dash-muted">Estado: ' +
                global.escapeHtml(f.status || '') +
                '</p></article>'
              );
            })
            .join('')
        : '<p class="dash-muted">Sem tópicos.</p>') +
      '</div>';
  }

  document.addEventListener('DOMContentLoaded', async function () {
    if (!document.getElementById('dash-usuario-root')) return;
    var u = await global.requireAuth();
    if (!u) return;
    if (global.updateHeaderAuth) await global.updateHeaderAuth();
    if (global.initDashPanels) {
      global.initDashPanels({
        navSelector: '.dash-sidebar [data-dash-tab]',
        panelsSelector: '[data-dash-panel]',
        defaultHash: '#rodas',
      });
    }
    await loadPrototipos('mount-proto');
    await loadRedeDf('mount-rede-df');
    await loadForumPublico('mount-forum-pub');
  });
})(window);

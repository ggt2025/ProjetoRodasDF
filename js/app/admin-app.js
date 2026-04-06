/**
 * Administração — papéis de utilizador + analytics interno.
 */
(function (global) {
  async function ensureAdmin() {
    var x = await global.getSessionUser();
    if (!x.user) {
      global.location.href = 'login.html?next=' + encodeURIComponent(global.location.pathname);
      return null;
    }
    if (!x.profile || x.profile.role !== 'admin') {
      global.toast('Acesso restrito a administradores.', 'err');
      global.location.href = 'dashboard-usuario.html';
      return null;
    }
    return x;
  }

  async function loadProfiles() {
    var el = document.getElementById('mount-admin-profiles');
    if (!el) return;
    var sb = global.getSupabase();
    var res = await sb.from('profiles').select('id,email,nome,role,created_at').order('email');
    if (res.error) {
      el.innerHTML = '<p class="dash-muted">' + global.escapeHtml(res.error.message) + '</p>';
      return;
    }
    var rows = res.data || [];
    el.innerHTML =
      '<div class="dash-table-wrap"><table class="dash-table"><thead><tr><th>E-mail</th><th>Nome</th><th>Papel</th><th></th></tr></thead><tbody>' +
      rows
        .map(function (p) {
          return (
            '<tr data-uid="' +
            global.escapeHtml(p.id) +
            '"><td>' +
            global.escapeHtml(p.email || '') +
            '</td><td>' +
            global.escapeHtml(p.nome || '') +
            '</td><td><select class="admin-role-sel" data-uid="' +
            global.escapeHtml(p.id) +
            '">' +
            ['comum', 'gestao', 'admin']
              .map(function (r) {
                return (
                  '<option value="' +
                  r +
                  '"' +
                  (p.role === r ? ' selected' : '') +
                  '>' +
                  r +
                  '</option>'
                );
              })
              .join('') +
            '</select></td><td><button type="button" class="btn btn-primary admin-save-role" data-uid="' +
            global.escapeHtml(p.id) +
            '">Guardar</button></td></tr>'
          );
        })
        .join('') +
      '</tbody></table></div>' +
      '<p class="dash-muted" style="margin-top:12px">Atribua <strong>gestao</strong> à equipa do projeto; <strong>comum</strong> para utilizadores externos. Apenas um pequeno conjunto deve ser <strong>admin</strong>.</p>';

    el.querySelectorAll('.admin-save-role').forEach(function (btn) {
      btn.addEventListener('click', async function () {
        var tr = btn.closest('tr');
        var uid = btn.getAttribute('data-uid');
        var sel = tr ? tr.querySelector('select.admin-role-sel') : null;
        if (!sel) return;
        var role = sel.value;
        var up = await sb.from('profiles').update({ role: role }).eq('id', uid);
        if (up.error) {
          global.toast(up.error.message, 'err');
          return;
        }
        global.toast('Papel atualizado.', 'ok');
      });
    });
  }

  async function loadAnalytics() {
    var el = document.getElementById('mount-admin-analytics');
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

  document.addEventListener('DOMContentLoaded', async function () {
    if (!document.getElementById('admin-root')) return;
    var ok = await ensureAdmin();
    if (!ok) return;
    if (global.updateHeaderAuth) await global.updateHeaderAuth();
    await loadProfiles();
    await loadAnalytics();
  });
})(window);

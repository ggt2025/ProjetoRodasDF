(function (global) {
  global.initPerfilPage = async function () {
    var loadEl = global.qs('#pf-loading');
    var guestEl = global.qs('#pf-guest');
    var regEl = global.qs('#pf-registered');
    var sb = global.getSupabase();
    var { user } = await global.getSessionUser();
    if (loadEl) loadEl.hidden = true;
    if (!user) {
      if (guestEl) guestEl.hidden = false;
      if (regEl) regEl.hidden = true;
      return;
    }
    if (guestEl) guestEl.hidden = true;
    if (regEl) regEl.hidden = false;
    if (!sb) {
      global.toast('Supabase não configurado.', 'err');
      return;
    }

    var res = await sb.from('profiles').select('*').eq('id', user.id).maybeSingle();
    if (res.error || !res.data) {
      global.toast('Perfil não encontrado.', 'err');
      return;
    }
    var p = res.data;
    var nome = global.qs('#pf-nome');
    var email = global.qs('#pf-email');
    var tel = global.qs('#pf-tel');
    var circ = global.qs('#pf-circ');
    var bio = global.qs('#pf-bio');
    var roleEl = global.qs('#pf-role');
    if (nome) nome.value = p.nome || '';
    if (email) email.value = (p.email || user.email || '').trim();
    if (tel) tel.value = p.telefone || '';
    if (circ) circ.value = p.circunscricao || '';
    if (bio) bio.value = p.bio || '';
    if (roleEl) roleEl.textContent = p.role || 'comum';

    var listEl = global.qs('#pf-rodas-list');
    if (listEl) {
      var vr = await sb.from('usuario_rodas').select('roda_id').eq('user_id', user.id);
      var ids = (vr.data || []).map(function (x) {
        return x.roda_id;
      });
      if (vr.error || !ids.length) {
        listEl.innerHTML = '<p class="empty-state">Nenhuma roda vinculada.</p>';
      } else {
        var rr = await sb.from('rodas').select('nome,circunscricao,dia_semana').in('id', ids);
        var rows = rr.data || [];
        listEl.innerHTML = rows
          .map(function (r) {
            return (
              '<div class="card-n" style="margin-bottom:10px"><strong>' +
              global.escapeHtml(r.nome) +
              '</strong><br><span style="font-size:13px;color:var(--gray-600)">' +
              global.escapeHtml(r.circunscricao || '') +
              ' · ' +
              global.escapeHtml(r.dia_semana || '') +
              '</span></div>'
            );
          })
          .join('');
      }
    }

    var form = global.qs('#form-perfil');
    if (form) {
      form.addEventListener('submit', async function (ev) {
        ev.preventDefault();
        var body = {
          nome: nome && nome.value.trim(),
          telefone: tel && tel.value.trim(),
          circunscricao: circ && circ.value.trim(),
          bio: bio && bio.value.trim(),
          updated_at: new Date().toISOString(),
        };
        var up = await sb.from('profiles').update(body).eq('id', user.id);
        if (up.error) {
          global.toast('Erro ao salvar: ' + up.error.message, 'err');
          return;
        }
        global.toast('Perfil atualizado.', 'ok');
      });
    }
  };
})(window);

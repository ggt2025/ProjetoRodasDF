/**
 * D.4 — Parceiros / levantamento + Rede DF + pontes (edição na gestão; dados no Supabase).
 */
(function (global) {
  var TIPOS_EQUIP = [
    ['espaco_acolher', 'Espaço acolher'],
    ['ceam', 'CEAM'],
    ['crmb', 'CRMB'],
    ['direito_delas', 'Direito delas'],
    ['comite_protecao', 'Comitê proteção'],
    ['cepav', 'CEPAV'],
    ['cmb', 'CMB'],
    ['rede_elas', 'Rede ELAS'],
    ['projeto_todas_elas', 'Projeto Todas Elas'],
    ['outro', 'Outro'],
  ];

  var STATUS_REDE = [
    ['ativo', 'Ativo'],
    ['inativo', 'Inativo'],
    ['em_implantacao', 'Em implantação'],
  ];

  var STATUS_PONTE = [
    ['identificada', 'Identificada'],
    ['contatada', 'Contatada'],
    ['parceira_confirmada', 'Parceira confirmada'],
    ['inativa', 'Inativa'],
  ];

  function selOptions(arr, cur) {
    return arr
      .map(function (o) {
        return (
          '<option value="' +
          global.escapeHtml(o[0]) +
          '"' +
          (cur === o[0] ? ' selected' : '') +
          '>' +
          global.escapeHtml(o[1]) +
          '</option>'
        );
      })
      .join('');
  }

  async function loadParceirosTab(mountId) {
    var el = document.getElementById(mountId);
    if (!el) return;
    var sb = global.getSupabase();
    var p = await sb.from('parceiros_pontes').select('*').order('nome').limit(120);
    if (p.error) {
      el.innerHTML = '<p class="dash-muted">' + global.escapeHtml(p.error.message) + '</p>';
      return;
    }
    var rows = p.data || [];
    el.innerHTML =
      '<p class="dash-muted" style="margin-top:0">Parceiros institucionais, pontes de contacto e levantamento de campo. Edição avançada no Supabase se necessário.</p>' +
      (rows.length
        ? '<div class="dash-table-wrap"><table class="dash-table"><thead><tr><th>Nome</th><th>Tipo</th><th>Circunscrição</th><th>Estado</th></tr></thead><tbody>' +
          rows
            .map(function (r) {
              return (
                '<tr><td>' +
                global.escapeHtml(r.nome || '') +
                '</td><td>' +
                global.escapeHtml(r.tipo || '') +
                '</td><td>' +
                global.escapeHtml(r.circunscricao || '') +
                '</td><td>' +
                global.escapeHtml(r.status || '') +
                '</td></tr>'
              );
            })
            .join('') +
          '</tbody></table></div>'
        : '<p class="dash-muted">Sem registos em parceiros_pontes.</p>');
  }

  async function refreshRedeDf(mountId, sb) {
    var el = document.getElementById(mountId);
    if (!el) return;
    var res = await sb.from('rede_df').select('*').order('circunscricao').limit(200);
    if (res.error) {
      el.innerHTML = '<p class="dash-muted">' + global.escapeHtml(res.error.message) + '</p>';
      return;
    }
    var rows = res.data || [];

    var table =
      rows.length === 0
        ? '<p class="dash-muted">Sem equipamentos. Utilize o formulário abaixo.</p>'
        : '<div class="dash-table-wrap"><table class="dash-table"><thead><tr><th>Nome</th><th>Circunscrição</th><th>Tipo</th><th>Estado</th><th></th></tr></thead><tbody>' +
          rows
            .map(function (r) {
              return (
                '<tr><td>' +
                global.escapeHtml(r.nome || '') +
                '</td><td>' +
                global.escapeHtml(r.circunscricao || '') +
                '</td><td>' +
                global.escapeHtml(r.tipo_equipamento || '') +
                '</td><td>' +
                global.escapeHtml(r.status || '') +
                '</td><td><button type="button" class="btn btn-secondary btn-sm" data-rede-edit="' +
                global.escapeHtml(r.id) +
                '">Editar</button> <button type="button" class="link-btn" data-rede-del="' +
                global.escapeHtml(r.id) +
                '">Apagar</button></td></tr>'
              );
            })
            .join('') +
          '</tbody></table></div>';

    var head =
      '<h2 class="dash-h2" style="margin-top:0">Rede DF — equipamentos (editável)</h2>' +
      '<p class="dash-muted">Panorama mais amplo que as rodas: articula com <strong>pontes</strong> e verificação de contactos. Os dados são os mesmos da base <code>rede_df</code>.</p>' +
      table +
      '<h3 id="rede-df-form-title" class="dash-h3-form">Novo equipamento na Rede DF</h3>' +
      '<form id="form-rede-df" class="dash-stack-form">' +
      '<input type="hidden" id="rede-df-id" value="">' +
      '<div class="form-row-2">' +
      '<div class="form-group"><label for="rede-nome">Nome *</label><input id="rede-nome" required maxlength="300"></div>' +
      '<div class="form-group"><label for="rede-circ">Circunscrição *</label><input id="rede-circ" required maxlength="200"></div></div>' +
      '<div class="form-row-2">' +
      '<div class="form-group"><label for="rede-tipo">Tipo de equipamento *</label><select id="rede-tipo" required>' +
      selOptions(TIPOS_EQUIP, '') +
      '</select></div>' +
      '<div class="form-group"><label for="rede-status">Estado</label><select id="rede-status">' +
      selOptions(STATUS_REDE, 'ativo') +
      '</select></div></div>' +
      '<div class="form-group"><label for="rede-inst">Instituição</label><input id="rede-inst" maxlength="300"></div>' +
      '<div class="form-group"><label for="rede-end">Endereço</label><input id="rede-end" maxlength="500"></div>' +
      '<div class="form-group"><label for="rede-desc">Descrição</label><textarea id="rede-desc" maxlength="2000" rows="3"></textarea></div>' +
      '<div class="form-actions"><button type="submit" class="btn btn-primary">Guardar equipamento</button> ' +
      '<button type="button" class="btn btn-secondary" id="btn-rede-df-clear">Limpar</button></div></form>';

    el.innerHTML = head;

    var formEl = document.getElementById('form-rede-df');
    if (formEl) {
      formEl.addEventListener('submit', async function (ev) {
        ev.preventDefault();
        var id = (document.getElementById('rede-df-id') || {}).value || '';
        var body = {
          nome: (document.getElementById('rede-nome') || {}).value.trim(),
          circunscricao: (document.getElementById('rede-circ') || {}).value.trim(),
          tipo_equipamento: (document.getElementById('rede-tipo') || {}).value,
          status: (document.getElementById('rede-status') || {}).value,
          instituicao: (document.getElementById('rede-inst') || {}).value.trim() || null,
          endereco: (document.getElementById('rede-end') || {}).value.trim() || null,
          descricao: (document.getElementById('rede-desc') || {}).value.trim() || null,
          updated_at: new Date().toISOString(),
        };
        if (!body.nome || !body.circunscricao || !body.tipo_equipamento) return;
        var q = id
          ? await sb.from('rede_df').update(body).eq('id', id)
          : await sb.from('rede_df').insert(body);
        if (q.error) {
          global.toast(q.error.message, 'err');
          return;
        }
        global.toast('Rede DF atualizada.', 'ok');
        await refreshRedeDf(mountId, sb);
        await refreshPontes('mount-pontes-edit', sb);
      });
    }
    var clr = document.getElementById('btn-rede-df-clear');
    if (clr) {
      clr.addEventListener('click', function () {
        var f = document.getElementById('form-rede-df');
        if (f) f.reset();
        var idf = document.getElementById('rede-df-id');
        if (idf) idf.value = '';
        var t = document.getElementById('rede-df-form-title');
        if (t) t.textContent = 'Novo equipamento na Rede DF';
      });
    }
    el.querySelectorAll('[data-rede-edit]').forEach(function (btn) {
      btn.addEventListener('click', async function () {
        var rid = btn.getAttribute('data-rede-edit');
        var one = await sb.from('rede_df').select('*').eq('id', rid).maybeSingle();
        if (one.error || !one.data) {
          global.toast('Registo não encontrado.', 'err');
          return;
        }
        var d = one.data;
        var idf = document.getElementById('rede-df-id');
        if (idf) idf.value = d.id;
        var set = function (id, v) {
          var x = document.getElementById(id);
          if (x) x.value = v != null ? v : '';
        };
        set('rede-nome', d.nome);
        set('rede-circ', d.circunscricao);
        set('rede-tipo', d.tipo_equipamento);
        set('rede-status', d.status);
        set('rede-inst', d.instituicao);
        set('rede-end', d.endereco);
        set('rede-desc', d.descricao);
        var ft = document.getElementById('rede-df-form-title');
        if (ft) ft.textContent = 'Editar equipamento';
        var fEl = document.getElementById('form-rede-df');
        if (fEl && fEl.scrollIntoView) fEl.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      });
    });
    el.querySelectorAll('[data-rede-del]').forEach(function (btn) {
      btn.addEventListener('click', async function () {
        var rid = btn.getAttribute('data-rede-del');
        if (!global.confirm('Apagar este equipamento e as respetivas pontes?')) return;
        var del = await sb.from('rede_df').delete().eq('id', rid);
        if (del.error) {
          global.toast(del.error.message, 'err');
          return;
        }
        global.toast('Removido.', 'ok');
        await refreshRedeDf(mountId, sb);
        await refreshPontes('mount-pontes-edit', sb);
      });
    });
  }

  async function refreshPontes(mountId, sb) {
    var el = document.getElementById(mountId);
    if (!el) return;
    var res = await sb.from('rede_df_pontes').select('*').order('created_at', { ascending: false }).limit(150);
    var rr = await sb.from('rede_df').select('id,nome,circunscricao').order('nome').limit(300);
    if (res.error) {
      el.innerHTML = '<p class="dash-muted">' + global.escapeHtml(res.error.message) + '</p>';
      return;
    }
    var nomePorId = {};
    (rr.data || []).forEach(function (x) {
      nomePorId[x.id] = x.nome || x.id;
    });
    var rows = res.data || [];
    var opts =
      '<option value="">— Equipamento —</option>' +
      (rr.data || [])
        .map(function (x) {
          return '<option value="' + global.escapeHtml(x.id) + '">' + global.escapeHtml(x.nome || '') + '</option>';
        })
        .join('');

    var table =
      rows.length === 0
        ? '<p class="dash-muted">Sem pontes. Crie abaixo (ligação a um equipamento da Rede DF).</p>'
        : '<div class="dash-table-wrap"><table class="dash-table"><thead><tr><th>Equipamento</th><th>Estado da ponte</th><th>Último contacto</th><th></th></tr></thead><tbody>' +
          rows
            .map(function (p) {
              return (
                '<tr><td>' +
                global.escapeHtml(nomePorId[p.rede_df_id] || p.rede_df_id) +
                '</td><td>' +
                global.escapeHtml(p.status_ponte || '') +
                '</td><td>' +
                global.escapeHtml(p.data_ultimo_contato || '') +
                '</td><td><button type="button" class="btn btn-secondary btn-sm" data-ponte-edit="' +
                global.escapeHtml(p.id) +
                '">Editar</button> <button type="button" class="link-btn" data-ponte-del="' +
                global.escapeHtml(p.id) +
                '">Apagar</button></td></tr>'
              );
            })
            .join('') +
          '</tbody></table></div>';

    el.innerHTML =
      '<h2 class="dash-h2" style="margin-top:0">Pontes (rede_df_pontes)</h2>' +
      '<p class="dash-muted">Liga cada equipamento da Rede DF ao acompanhamento de contactos e parcerias. Converge com a verificação de rodas no território.</p>' +
      table +
      '<h3 id="ponte-form-title" class="dash-h3-form">Nova ponte</h3>' +
      '<form id="form-ponte" class="dash-stack-form">' +
      '<input type="hidden" id="ponte-id" value="">' +
      '<div class="form-group"><label for="ponte-rede">Equipamento Rede DF *</label><select id="ponte-rede" required>' +
      opts +
      '</select></div>' +
      '<div class="form-row-2">' +
      '<div class="form-group"><label for="ponte-status">Estado da ponte *</label><select id="ponte-status" required>' +
      selOptions(STATUS_PONTE, 'identificada') +
      '</select></div>' +
      '<div class="form-group"><label for="ponte-data">Data último contacto</label><input id="ponte-data" type="date"></div></div>' +
      '<div class="form-group"><label for="ponte-obs">Observações</label><textarea id="ponte-obs" maxlength="2000" rows="3"></textarea></div>' +
      '<div class="form-actions"><button type="submit" class="btn btn-primary">Guardar ponte</button> ' +
      '<button type="button" class="btn btn-secondary" id="btn-ponte-clear">Limpar</button></div></form>';

    var formEl = document.getElementById('form-ponte');
    if (formEl) {
      formEl.addEventListener('submit', async function (ev) {
        ev.preventDefault();
        var id = (document.getElementById('ponte-id') || {}).value || '';
        var body = {
          rede_df_id: (document.getElementById('ponte-rede') || {}).value,
          status_ponte: (document.getElementById('ponte-status') || {}).value,
          observacoes: (document.getElementById('ponte-obs') || {}).value.trim() || null,
          data_ultimo_contato: (document.getElementById('ponte-data') || {}).value || null,
          updated_at: new Date().toISOString(),
        };
        if (!body.rede_df_id || !body.status_ponte) return;
        var q = id
          ? await sb.from('rede_df_pontes').update(body).eq('id', id)
          : await sb.from('rede_df_pontes').insert(body);
        if (q.error) {
          global.toast(q.error.message, 'err');
          return;
        }
        global.toast('Ponte guardada.', 'ok');
        await refreshPontes(mountId, sb);
      });
    }
    var c = document.getElementById('btn-ponte-clear');
    if (c) {
      c.addEventListener('click', function () {
        var f = document.getElementById('form-ponte');
        if (f) f.reset();
        var idf = document.getElementById('ponte-id');
        if (idf) idf.value = '';
        var t = document.getElementById('ponte-form-title');
        if (t) t.textContent = 'Nova ponte';
      });
    }
    el.querySelectorAll('[data-ponte-edit]').forEach(function (btn) {
      btn.addEventListener('click', async function () {
        var pid = btn.getAttribute('data-ponte-edit');
        var one = await sb.from('rede_df_pontes').select('*').eq('id', pid).maybeSingle();
        if (one.error || !one.data) {
          global.toast('Registo não encontrado.', 'err');
          return;
        }
        var d = one.data;
        var idf = document.getElementById('ponte-id');
        if (idf) idf.value = d.id;
        var sr = document.getElementById('ponte-rede');
        if (sr) sr.value = d.rede_df_id;
        var st = document.getElementById('ponte-status');
        if (st) st.value = d.status_ponte;
        var dt = document.getElementById('ponte-data');
        if (dt) dt.value = d.data_ultimo_contato || '';
        var ob = document.getElementById('ponte-obs');
        if (ob) ob.value = d.observacoes || '';
        var ft = document.getElementById('ponte-form-title');
        if (ft) ft.textContent = 'Editar ponte';
      });
    });
    el.querySelectorAll('[data-ponte-del]').forEach(function (btn) {
      btn.addEventListener('click', async function () {
        var pid = btn.getAttribute('data-ponte-del');
        if (!global.confirm('Apagar esta ponte?')) return;
        var del = await sb.from('rede_df_pontes').delete().eq('id', pid);
        if (del.error) {
          global.toast(del.error.message, 'err');
          return;
        }
        global.toast('Ponte removida.', 'ok');
        await refreshPontes(mountId, sb);
      });
    });
  }

  global.initGestaoRedeBloco = async function () {
    var sb = global.getSupabase();
    if (!sb) return;
    await loadParceirosTab('mount-parceiros-tab');
    await refreshRedeDf('mount-rede-df-edit', sb);
    await refreshPontes('mount-pontes-edit', sb);
  };
})(window);

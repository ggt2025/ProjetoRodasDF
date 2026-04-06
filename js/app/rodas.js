/**
 * CRUD de rodas — área do utilizador (dashboard-usuario.html).
 */
(function (global) {
  function emptyToNull(v) {
    var s = (v == null ? '' : String(v)).trim();
    return s === '' ? null : s;
  }

  function normalizeInstagram(v) {
    var s = (v == null ? '' : String(v)).trim();
    if (!s) return null;
    return s[0] === '@' ? s : '@' + s;
  }

  function fillCircSelect(sel) {
    if (!sel) return;
    var list = global.CIRCUNSCRICOES_DF || [];
    sel.innerHTML = '';
    list.forEach(function (c) {
      var o = document.createElement('option');
      o.value = c;
      o.textContent = c;
      sel.appendChild(o);
    });
  }

  function clearForm(form) {
    form.reset();
    var hid = document.getElementById('roda-id');
    if (hid) hid.value = '';
    var t = document.getElementById('titulo-form-roda');
    if (t) t.textContent = 'Nova roda';
    var tipo = form.querySelector('input[name="tipo"][value="permanente"]');
    if (tipo) tipo.checked = true;
    var freq = form.querySelector('input[name="frequencia"][value="semanal"]');
    if (freq) freq.checked = true;
  }

  function fillFormFromRow(row) {
    var form = document.getElementById('form-roda');
    if (!form || !row) return;
    document.getElementById('roda-id').value = row.id || '';
    document.getElementById('titulo-form-roda').textContent = 'Editar roda';
    document.getElementById('roda-circunscricao').value = row.circunscricao || '';
    document.getElementById('roda-nome').value = row.nome || '';
    var tr = form.querySelectorAll('input[name="tipo"]');
    tr.forEach(function (r) {
      r.checked = r.value === row.tipo;
    });
    document.getElementById('roda-instituicao').value = row.instituicao || '';
    document.getElementById('roda-responsavel').value = row.responsavel || '';
    document.getElementById('roda-dia-semana').value = row.dia_semana || 'terca';
    if (row.horario_inicio) {
      var t = String(row.horario_inicio).slice(0, 5);
      document.getElementById('roda-horario-inicio').value = t;
    }
    if (row.horario_fim) {
      document.getElementById('roda-horario-fim').value = String(row.horario_fim).slice(0, 5);
    } else {
      document.getElementById('roda-horario-fim').value = '';
    }
    var fr = form.querySelectorAll('input[name="frequencia"]');
    fr.forEach(function (r) {
      r.checked = r.value === row.frequencia;
    });
    document.getElementById('roda-obs-freq').value = row.observacao_frequencia || '';
    document.getElementById('roda-endereco').value = row.endereco || '';
    document.getElementById('roda-bairro').value = row.bairro || '';
    document.getElementById('roda-cep').value = row.cep || '';
    document.getElementById('roda-telefone').value = row.telefone || '';
    document.getElementById('roda-whatsapp').value = row.whatsapp || '';
    document.getElementById('roda-email').value = row.email || '';
    document.getElementById('roda-instagram').value = row.instagram || '';
    document.getElementById('roda-site').value = row.site || '';
    document.getElementById('roda-descricao').value = row.descricao || '';
    document.getElementById('roda-historico').value = row.historico || '';
  }

  function buildPayload(form) {
    var fd = new FormData(form);
    return {
      circunscricao: (fd.get('circunscricao') || '').toString().trim(),
      nome: (fd.get('nome') || '').toString().trim(),
      tipo: fd.get('tipo'),
      instituicao: emptyToNull(fd.get('instituicao')),
      responsavel: emptyToNull(fd.get('responsavel')),
      dia_semana: fd.get('dia_semana'),
      horario_inicio: fd.get('horario_inicio'),
      horario_fim: emptyToNull(fd.get('horario_fim')),
      frequencia: fd.get('frequencia'),
      observacao_frequencia: emptyToNull(fd.get('observacao_frequencia')),
      endereco: (fd.get('endereco') || '').toString().trim(),
      bairro: emptyToNull(fd.get('bairro')),
      cep: emptyToNull(fd.get('cep')),
      telefone: emptyToNull(fd.get('telefone')),
      whatsapp: emptyToNull(fd.get('whatsapp')),
      email: emptyToNull(fd.get('email')),
      instagram: normalizeInstagram(fd.get('instagram')),
      site: emptyToNull(fd.get('site')),
      descricao: emptyToNull(fd.get('descricao')),
      historico: emptyToNull(fd.get('historico')),
    };
  }

  function renderLista(mount, rows, onEdit, onEncerrar) {
    if (!rows || !rows.length) {
      mount.innerHTML = '<p class="dash-placeholder">Nenhuma roda cadastrada ainda. Use <strong>Cadastrar nova roda</strong>.</p>';
      return;
    }
    mount.innerHTML = rows
      .map(function (r) {
        var st =
          r.status === 'confirmada'
            ? 'Confirmada'
            : r.status === 'pendente'
              ? 'Pendente'
              : 'Encerrada';
        var actions =
          r.status === 'encerrada'
            ? ''
            : '<div class="dash-roda-actions">' +
              '<button type="button" class="btn btn-secondary" data-edit="' +
              r.id +
              '">Editar</button>' +
              '<button type="button" class="btn btn-secondary" data-encerrar="' +
              r.id +
              '">Solicitar encerramento</button></div>';
        return (
          '<article class="dash-roda-card" data-id="' +
          global.escapeHtml(r.id) +
          '"><h3>' +
          global.escapeHtml(r.nome) +
          '</h3><p class="dash-roda-meta">' +
          global.escapeHtml(r.circunscricao || '') +
          ' · ' +
          st +
          ' · ' +
          global.fmtTime(r.horario_inicio) +
          '</p>' +
          actions +
          '</article>'
        );
      })
      .join('');

    mount.querySelectorAll('[data-edit]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        onEdit(btn.getAttribute('data-edit'));
      });
    });
    mount.querySelectorAll('[data-encerrar]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        onEncerrar(btn.getAttribute('data-encerrar'));
      });
    });
  }

  document.addEventListener('DOMContentLoaded', async function () {
    if (!document.getElementById('form-roda')) return;

    var user = await global.requireAuth();
    if (!user) return;

    var sb = global.getSupabase();
    if (!sb) {
      global.toast('Supabase não configurado.', 'err');
      return;
    }

    if (global.updateHeaderAuth) await global.updateHeaderAuth();

    var form = document.getElementById('form-roda');
    var secForm = document.getElementById('sec-form-roda');
    var mount = document.getElementById('mount-minhas-rodas');
    fillCircSelect(document.getElementById('roda-circunscricao'));

    async function loadList() {
      var res = await sb.from('rodas').select('*').eq('user_id', user.id).order('created_at', { ascending: false });
      if (res.error) {
        mount.innerHTML = '<p class="dash-placeholder">Erro ao carregar: ' + global.escapeHtml(res.error.message) + '</p>';
        return;
      }
      renderLista(
        mount,
        res.data || [],
        async function (id) {
          var r = await sb.from('rodas').select('*').eq('id', id).maybeSingle();
          if (r.error || !r.data) {
            global.toast('Roda não encontrada.', 'err');
            return;
          }
          if (r.data.user_id !== user.id) {
            global.toast('Sem permissão.', 'err');
            return;
          }
          fillFormFromRow(r.data);
          secForm.hidden = false;
          secForm.scrollIntoView({ behavior: 'smooth' });
        },
        async function (id) {
          if (!confirm('Marcar esta roda como encerrada? Ela deixará de aparecer no calendário público.')) return;
          var up = await sb.from('rodas').update({ status: 'encerrada' }).eq('id', id).eq('user_id', user.id);
          if (up.error) {
            global.toast(up.error.message, 'err');
            return;
          }
          global.toast('Roda encerrada.', 'ok');
          await loadList();
        }
      );
    }

    document.getElementById('btnNovaRoda').addEventListener('click', function () {
      clearForm(form);
      secForm.hidden = false;
      secForm.scrollIntoView({ behavior: 'smooth' });
    });

    document.getElementById('btnCancelarForm').addEventListener('click', function () {
      secForm.hidden = true;
      clearForm(form);
    });

    form.addEventListener('submit', async function (ev) {
      ev.preventDefault();
      var payload = buildPayload(form);
      if (!payload.circunscricao || !payload.nome || !payload.endereco || !payload.dia_semana || !payload.horario_inicio || !payload.frequencia) {
        global.toast('Preencha os campos obrigatórios.', 'err');
        return;
      }
      var id = document.getElementById('roda-id').value;
      if (id) {
        var up = await sb.from('rodas').update(payload).eq('id', id).eq('user_id', user.id).select();
        if (up.error) {
          global.toast(up.error.message, 'err');
          return;
        }
        global.toast('Roda atualizada.', 'ok');
      } else {
        var ins = await sb
          .from('rodas')
          .insert(
            Object.assign({}, payload, {
              user_id: user.id,
              status: 'pendente',
            })
          )
          .select();
        if (ins.error) {
          global.toast(ins.error.message, 'err');
          return;
        }
        global.toast('Roda criada como pendente. A gestão pode confirmar depois.', 'ok');
      }
      secForm.hidden = true;
      clearForm(form);
      await loadList();
    });

    var params = new URLSearchParams(window.location.search);
    var editId = params.get('editar');
    if (editId) {
      var one = await sb.from('rodas').select('*').eq('id', editId).maybeSingle();
      if (!one.error && one.data && one.data.user_id === user.id) {
        fillFormFromRow(one.data);
        secForm.hidden = false;
      }
    }

    await loadList();
  });
})(window);

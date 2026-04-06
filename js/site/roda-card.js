/**
 * Card único de roda — compacto (calendário) e detalhe (modal).
 */
(function (global) {
  global._rodaDetailCache = {};

  function diaLabel(d) {
    var map = {
      segunda: 'Segunda-feira',
      terca: 'Terça-feira',
      quarta: 'Quarta-feira',
      quinta: 'Quinta-feira',
      sexta: 'Sexta-feira',
      sabado: 'Sábado',
      domingo: 'Domingo',
    };
    return map[d] || d || '';
  }

  function badgeTipo(t) {
    if (t === 'permanente')
      return '<span class="roda-badge roda-badge--tipo roda-badge--perm" title="Tipo">Permanente</span>';
    if (t === 'recorrente')
      return '<span class="roda-badge roda-badge--tipo roda-badge--rec" title="Tipo">Recorrente / Itinerante</span>';
    return '<span class="roda-badge roda-badge--tipo roda-badge--pont" title="Tipo">Pontual</span>';
  }

  function badgeStatus(s) {
    if (s === 'confirmada')
      return '<span class="roda-badge roda-badge--status roda-badge--ok" title="Status">Confirmada</span>';
    if (s === 'pendente')
      return '<span class="roda-badge roda-badge--status roda-badge--pend" title="Status">Pendente</span>';
    return '<span class="roda-badge roda-badge--status roda-badge--off" title="Status">Encerrada</span>';
  }

  function trunc(s, n) {
    if (!s) return '';
    s = String(s);
    if (s.length <= n) return s;
    return s.slice(0, n - 1) + '…';
  }

  function compactTipoShort(t) {
    if (t === 'permanente') return 'Permanente';
    if (t === 'recorrente') return 'Recorrente';
    return 'Pontual';
  }

  /**
   * Botão para célula do calendário (usa cache por id).
   */
  global.renderRodaCardCompact = function (r) {
    if (r && r.id) global._rodaDetailCache[r.id] = r;
    var cls = 'roda-card-compact';
    if (r.tipo === 'permanente') cls += ' roda-card-compact--perm';
    else if (r.tipo === 'recorrente') cls += ' roda-card-compact--rec';
    else cls += ' roda-card-compact--pont';
    if (r.status === 'confirmada') cls += ' roda-card-compact--st-ok';
    else if (r.status === 'pendente') cls += ' roda-card-compact--st-pend';
    else cls += ' roda-card-compact--st-off';
    var nome = global.escapeHtml(trunc(r.nome, 38));
    var tipoShort = global.escapeHtml(compactTipoShort(r.tipo));
    var stMark = r.status === 'confirmada' ? '✓' : r.status === 'pendente' ? '⏳' : '✕';
    return (
      '<button type="button" class="' +
      cls +
      '" data-roda-id="' +
      global.escapeHtml(r.id) +
      '" aria-label="' +
      global.escapeHtml(r.nome) +
      '">' +
      '<span class="roda-card-compact__badges"><span class="roda-card-compact__tipo">' +
      tipoShort +
      '</span><span class="roda-card-compact__status" aria-hidden="true">' +
      stMark +
      '</span></span>' +
      '<span class="roda-card-compact__title">' +
      nome +
      '</span>' +
      '<span class="roda-card-compact__meta">' +
      global.fmtTime(r.horario_inicio) +
      (r.horario_fim ? '–' + global.fmtTime(r.horario_fim) : '') +
      ' · ' +
      global.escapeHtml(r.circunscricao || '') +
      '</span></button>'
    );
  };

  function buildModalBody(r, canEdit) {
    var freq =
      r.frequencia === 'quinzenal' ? 'Quinzenal' : r.frequencia === 'semanal' ? 'Semanal' : r.frequencia || '';
    var agendaPlain =
      diaLabel(r.dia_semana) +
      ', ' +
      global.fmtTime(r.horario_inicio) +
      (r.horario_fim ? ' – ' + global.fmtTime(r.horario_fim) : '') +
      ' · ' +
      freq +
      (r.observacao_frequencia ? ' · ' + r.observacao_frequencia : '');

    var desc = r.descricao
      ? '<div class="roda-modal__block"><span class="roda-modal__label">Descrição</span><p class="roda-modal__text">' +
        global.escapeHtml(r.descricao) +
        '</p></div>'
      : '';
    var hist = r.historico
      ? '<div class="roda-modal__block"><span class="roda-modal__label">Histórico</span><p class="roda-modal__text">' +
        global.escapeHtml(r.historico) +
        '</p></div>'
      : '';

    var contacts = [];
    if (r.telefone) contacts.push('📞 ' + global.escapeHtml(r.telefone));
    if (r.whatsapp) contacts.push('WhatsApp: ' + global.escapeHtml(r.whatsapp));
    if (r.email) contacts.push('✉ ' + global.escapeHtml(r.email));
    if (r.instagram) contacts.push('📷 ' + global.escapeHtml(r.instagram));
    if (r.site) contacts.push('🌐 ' + global.escapeHtml(r.site));
    var contactBlock =
      contacts.length > 0
        ? '<div class="roda-modal__block"><span class="roda-modal__label">Contato</span><p class="roda-modal__text">' +
          contacts.join('<br>') +
          '</p></div>'
        : '';

    var editBtn = canEdit
      ? '<a class="btn btn-primary roda-modal__edit" href="dashboard-usuario.html?editar=' +
        encodeURIComponent(r.id) +
        '">Editar roda</a>'
      : '';

    var foot =
      '<p class="roda-modal__foot">🕐 ' +
      (r.historico ? 'Ref.: histórico acima. ' : '') +
      'Atualizado em ' +
      global.formatDateTimeBR(r.updated_at || r.created_at) +
      '</p>';

    return (
      '<div class="roda-modal__head">' +
      badgeTipo(r.tipo) +
      ' ' +
      badgeStatus(r.status) +
      '</div>' +
      '<h3 class="roda-modal__title">' +
      global.escapeHtml(r.nome) +
      '</h3>' +
      '<p class="roda-modal__line"><strong>Circunscrição:</strong> ' +
      global.escapeHtml(r.circunscricao || '') +
      '</p>' +
      (r.instituicao
        ? '<p class="roda-modal__line"><strong>Instituição:</strong> ' + global.escapeHtml(r.instituicao) + '</p>'
        : '') +
      (r.responsavel
        ? '<p class="roda-modal__line"><strong>Responsável:</strong> ' + global.escapeHtml(r.responsavel) + '</p>'
        : '') +
      '<p class="roda-modal__agenda"><span aria-hidden="true">📅 </span>' +
      global.escapeHtml(agendaPlain) +
      '</p>' +
      '<p class="roda-modal__line"><strong>Endereço:</strong> ' +
      global.escapeHtml(r.endereco || '') +
      '</p>' +
      (r.bairro ? '<p class="roda-modal__line"><strong>Bairro:</strong> ' + global.escapeHtml(r.bairro) + '</p>' : '') +
      (r.cep ? '<p class="roda-modal__line"><strong>CEP:</strong> ' + global.escapeHtml(r.cep) + '</p>' : '') +
      desc +
      contactBlock +
      hist +
      foot +
      editBtn
    );
  }

  global.openRodaDetailModal = async function (r) {
    if (!r || !r.id) return;
    global._rodaDetailCache[r.id] = r;
    var user = null;
    var profile = null;
    try {
      var s = await global.getSessionUser();
      user = s.user;
      profile = s.profile;
    } catch (e) {}
    var canEdit = false;
    if (user && r.status !== 'encerrada') {
      if (profile && (profile.role === 'gestao' || profile.role === 'admin')) canEdit = true;
      else if (r.user_id && user.id === r.user_id) canEdit = true;
    }

    var back = document.createElement('div');
    back.className = 'roda-modal-backdrop';
    back.setAttribute('role', 'presentation');
    var modal = document.createElement('div');
    modal.className = 'roda-modal';
    modal.setAttribute('role', 'dialog');
    modal.setAttribute('aria-modal', 'true');
    modal.setAttribute('aria-labelledby', 'roda-modal-title');
    modal.innerHTML =
      '<button type="button" class="roda-modal__close" aria-label="Fechar">×</button>' +
      '<div class="roda-modal__inner" id="roda-modal-title">' +
      buildModalBody(r, canEdit) +
      '</div>';

    var close = function () {
      back.remove();
      modal.remove();
    };
    back.addEventListener('click', close);
    modal.querySelector('.roda-modal__close').addEventListener('click', close);

    document.body.appendChild(back);
    document.body.appendChild(modal);
  };

  global.attachRodaCardClickDelegate = function (root) {
    if (!root || root._rodaDelegate) return;
    root._rodaDelegate = true;
    root.addEventListener('click', function (ev) {
      var btn = ev.target.closest('[data-roda-id]');
      if (!btn) return;
      var id = btn.getAttribute('data-roda-id');
      var r = global._rodaDetailCache[id];
      if (r) global.openRodaDetailModal(r);
    });
  };
})(window);

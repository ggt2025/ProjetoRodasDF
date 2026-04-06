/**
 * Calendário semanal de rodas — landing e reutilização futura.
 * Realtime: atualiza ao mudar a tabela public.rodas.
 */
(function (global) {
  var DAYS = ['segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado', 'domingo'];
  var DAY_LABELS = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  var DAY_LABELS_LONG = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  var state = {
    rows: [],
    filtCirc: '',
    filtTipo: '',
    filtStatus: '',
    channel: null,
  };

  function applyFilters(list) {
    return list.filter(function (r) {
      if (r.tipo === 'pontual') return false;
      if (r.status === 'encerrada') return false;
      if (state.filtCirc && r.circunscricao !== state.filtCirc) return false;
      if (state.filtTipo && r.tipo !== state.filtTipo) return false;
      if (state.filtStatus && r.status !== state.filtStatus) return false;
      return true;
    });
  }

  function renderDesktop(el, rodas) {
    var desk = el.querySelector('[data-cal-desktop]');
    if (!desk) return;
    if (!rodas.length) {
      desk.innerHTML =
        '<p class="cal-empty">Nenhuma roda recorrente encontrada para os filtros. Ajuste ou cadastre novas rodas após entrar na conta.</p>';
      return;
    }
    var hours = rodas.map(function (r) {
      return global.parseTimeHour(r.horario_inicio);
    });
    var minH = Math.max(7, Math.min.apply(null, hours));
    var maxH = Math.min(22, Math.max.apply(null, hours) + 1);
    var html =
      '<div class="cal-scroll"><table class="cal-table"><thead><tr><th class="cal-th-time"></th>';
    DAY_LABELS.forEach(function (d) {
      html += '<th class="cal-th-day">' + d + '</th>';
    });
    html += '</tr></thead><tbody>';
    for (var h = minH; h <= maxH; h++) {
      var rowRodas = rodas.filter(function (r) {
        return global.parseTimeHour(r.horario_inicio) === h;
      });
      if (!rowRodas.length && h !== minH && h !== maxH) continue;
      html += '<tr><td class="cal-time-cell">' + String(h).padStart(2, '0') + 'h</td>';
      DAYS.forEach(function (day) {
        var cell = rodas.filter(function (r) {
          return r.dia_semana === day && global.parseTimeHour(r.horario_inicio) === h;
        });
        html += '<td class="cal-cell">';
        cell.forEach(function (r) {
          var cls = 'cal-card';
          if (r.tipo === 'permanente') cls += ' cal-card--perm';
          else if (r.tipo === 'recorrente') cls += ' cal-card--rec';
          var sd = r.status === 'confirmada' ? '✓' : '⏳';
          html +=
            '<button type="button" class="' +
            cls +
            '" title="' +
            global.escapeHtml(r.nome) +
            '">' +
            '<div class="cal-card-name">' +
            global.escapeHtml(r.nome.length > 36 ? r.nome.slice(0, 34) + '…' : r.nome) +
            '</div>' +
            '<div class="cal-card-meta">' +
            global.fmtTime(r.horario_inicio) +
            (r.horario_fim ? '–' + global.fmtTime(r.horario_fim) : '') +
            ' ' +
            sd +
            '</div></button>';
        });
        html += '</td>';
      });
      html += '</tr>';
    }
    html += '</tbody></table></div>';
    desk.innerHTML = html;
  }

  function renderMobile(el, rodas) {
    var wrap = el.querySelector('[data-cal-mobile]');
    if (!wrap) return;
    if (!rodas.length) {
      wrap.innerHTML = '';
      return;
    }
    var html = '';
    DAYS.forEach(function (day, i) {
      var dayRodas = rodas
        .filter(function (r) {
          return r.dia_semana === day;
        })
        .sort(function (a, b) {
          return global.parseTimeHour(a.horario_inicio) - global.parseTimeHour(b.horario_inicio);
        });
      if (!dayRodas.length) return;
      html += '<div class="cal-day-block"><h3 class="cal-day-title">' + DAY_LABELS_LONG[i] + '</h3>';
      dayRodas.forEach(function (r) {
        html +=
          '<div class="cal-m-card"><h4>' +
          global.escapeHtml(r.nome) +
          '</h4>' +
          '<div class="cal-m-meta">' +
          global.escapeHtml(r.circunscricao || '') +
          ' · ' +
          global.fmtTime(r.horario_inicio) +
          (r.horario_fim ? '–' + global.fmtTime(r.horario_fim) : '') +
          '</div>' +
          '<div class="cal-m-meta">' +
          global.escapeHtml(r.endereco || '') +
          '</div></div>';
      });
      html += '</div>';
    });
    wrap.innerHTML = html || '<p class="cal-empty">Nenhuma roda nesta visualização.</p>';
  }

  function fillCircOptions(el, rows) {
    var sel = el.querySelector('[data-filt-circ]');
    if (!sel) return;
    var set = {};
    rows.forEach(function (r) {
      if (r.circunscricao) set[r.circunscricao] = true;
    });
    var opts = Object.keys(set).sort(function (a, b) {
      return a.localeCompare(b, 'pt');
    });
    var cur = sel.value;
    sel.innerHTML = '<option value="">Todas as regiões</option>';
    opts.forEach(function (c) {
      sel.innerHTML += '<option value="' + global.escapeHtml(c) + '">' + global.escapeHtml(c) + '</option>';
    });
    sel.value = cur;
  }

  global.initCalendarSection = async function (mountId) {
    var el = document.getElementById(mountId);
    if (!el) return;
    var sb = global.getSupabase();
    if (!sb) {
      el.innerHTML = '<p class="cal-empty" style="padding:24px">Configure RODASDF_CONFIG (url + anonKey) para ver o calendário.</p>';
      return;
    }

    async function load() {
      var res = await sb.from('rodas').select('*').order('horario_inicio', { ascending: true });
      if (res.error) {
        console.error(res.error);
        if (global.toast) global.toast('Erro ao carregar rodas: ' + res.error.message, 'err');
        state.rows = [];
      } else {
        state.rows = res.data || [];
      }
      fillCircOptions(el, state.rows);
      var rodas = applyFilters(state.rows);
      renderDesktop(el, rodas);
      renderMobile(el, rodas);
    }

    el.innerHTML =
      '<div class="cal-filters">' +
      '<label>Região <select data-filt-circ><option value="">Todas</option></select></label>' +
      '<label>Tipo <select data-filt-tipo>' +
      '<option value="">Todos</option><option value="permanente">Permanente</option><option value="recorrente">Recorrente</option>' +
      '</select></label>' +
      '<label>Status <select data-filt-status">' +
      '<option value="">Todos</option><option value="confirmada">Confirmada</option><option value="pendente">Pendente</option>' +
      '</select></label></div>' +
      '<div class="cal-desktop" data-cal-desktop></div>' +
      '<div class="cal-mobile" data-cal-mobile></div>';

    el.querySelector('[data-filt-circ]').addEventListener('change', function () {
      state.filtCirc = this.value;
      load();
    });
    el.querySelector('[data-filt-tipo]').addEventListener('change', function () {
      state.filtTipo = this.value;
      load();
    });
    el.querySelector('[data-filt-status]').addEventListener('change', function () {
      state.filtStatus = this.value;
      load();
    });

    await load();

    if (state.channel) {
      try {
        sb.removeChannel(state.channel);
      } catch (e) {}
    }
    state.channel = sb
      .channel('rodas-realtime-' + Date.now())
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'rodas' },
        function () {
          load();
        }
      )
      .subscribe();
  };
})(window);

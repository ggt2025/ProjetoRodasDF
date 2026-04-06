/**
 * Calendário semanal de rodas — cards reutilizáveis + Realtime.
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
    filtQuinzenalWeek: false,
    channel: null,
  };

  function applyFilters(list) {
    return list.filter(function (r) {
      if (r.tipo === 'pontual') return false;
      if (r.status === 'encerrada') return false;
      if (state.filtCirc && r.circunscricao !== state.filtCirc) return false;
      if (state.filtTipo && r.tipo !== state.filtTipo) return false;
      if (state.filtStatus && r.status !== state.filtStatus) return false;
      if (state.filtQuinzenalWeek && r.frequencia === 'quinzenal') {
        if (global.quinzenalMatchesThisWeek && !global.quinzenalMatchesThisWeek(r)) return false;
      }
      return true;
    });
  }

  function renderDesktop(el, rodas) {
    var desk = el.querySelector('[data-cal-desktop]');
    if (!desk) return;
    if (!global.renderRodaCardCompact) {
      desk.innerHTML = '<p class="cal-empty">Carregue roda-card.js antes do calendário.</p>';
      return;
    }
    if (!rodas.length) {
      desk.innerHTML =
        '<p class="cal-empty">Nenhuma roda recorrente encontrada para os filtros. <a href="login.html">Entre</a> ou <a href="dashboard-usuario.html">cadastre uma roda</a>.</p>';
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
        var stack = cell.length > 1 ? ' cal-cell--stack' : '';
        html += '<td class="cal-cell' + stack + '">';
        cell.forEach(function (r) {
          html += global.renderRodaCardCompact(r);
        });
        html += '</td>';
      });
      html += '</tr>';
    }
    html += '</tbody></table></div>';
    desk.innerHTML = html;
    if (global.attachRodaCardClickDelegate) global.attachRodaCardClickDelegate(desk);
  }

  function renderMobile(el, rodas) {
    var wrap = el.querySelector('[data-cal-mobile]');
    if (!wrap) return;
    if (!global.renderRodaCardCompact) return;
    if (!rodas.length) {
      wrap.innerHTML =
        '<p class="cal-empty">Nenhuma roda para estes filtros. <a href="login.html">Entre</a> para cadastrar.</p>';
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
        html += '<div class="cal-m-slot">' + global.renderRodaCardCompact(r) + '</div>';
      });
      html += '</div>';
    });
    wrap.innerHTML = html || '<p class="cal-empty">Nenhuma roda nesta visualização.</p>';
    if (global.attachRodaCardClickDelegate) global.attachRodaCardClickDelegate(wrap);
  }

  function fillCircOptions(el) {
    var sel = el.querySelector('[data-filt-circ]');
    if (!sel) return;
    var cur = sel.value;
    var list = global.CIRCUNSCRICOES_DF || [];
    sel.innerHTML = '<option value="">Todas as circunscrições</option>';
    list.forEach(function (c) {
      sel.innerHTML += '<option value="' + global.escapeHtml(c) + '">' + global.escapeHtml(c) + '</option>';
    });
    sel.value = cur;
  }

  global.initCalendarSection = async function (mountId) {
    var el = document.getElementById(mountId);
    if (!el) return;
    var sb = global.getSupabase();
    if (!sb) {
      el.innerHTML =
        '<p class="cal-empty" style="padding:24px">Configure RODASDF_CONFIG (url + anonKey) para ver o calendário.</p>';
      return;
    }

    async function load(isInitial) {
      var res = await sb.from('rodas').select('*').order('horario_inicio', { ascending: true });
      if (res.error) {
        console.error(res.error);
        state.rows = [];
        var hint = global.formatSupabaseError ? global.formatSupabaseError(res.error) : res.error.message;
        if (global.toast) global.toast('Rodas: ' + hint, 'err');
        if (isInitial) {
          el.innerHTML = global.supabaseErrorBox
            ? global.supabaseErrorBox(res.error)
            : '<div class="supabase-error" role="alert"><strong>Não foi possível carregar as rodas.</strong><p class="supabase-error-msg">' +
              global.escapeHtml(hint) +
              '</p></div>';
          return false;
        }
        fillCircOptions(el);
        renderDesktop(el, []);
        renderMobile(el, []);
        return false;
      }
      var DAY_ORDER = { segunda: 0, terca: 1, quarta: 2, quinta: 3, sexta: 4, sabado: 5, domingo: 6 };
      state.rows = (res.data || []).slice().sort(function (a, b) {
        var da = DAY_ORDER[a.dia_semana] != null ? DAY_ORDER[a.dia_semana] : 99;
        var db = DAY_ORDER[b.dia_semana] != null ? DAY_ORDER[b.dia_semana] : 99;
        if (da !== db) return da - db;
        return global.parseTimeHour(a.horario_inicio) - global.parseTimeHour(b.horario_inicio);
      });
      fillCircOptions(el);
      var rodas = applyFilters(state.rows);
      renderDesktop(el, rodas);
      renderMobile(el, rodas);
      return true;
    }

    el.innerHTML =
      '<div class="cal-filters">' +
      '<label>Circunscrição <select data-filt-circ><option value="">Todas</option></select></label>' +
      '<label>Tipo <select data-filt-tipo>' +
      '<option value="">Todos</option><option value="permanente">Permanente</option><option value="recorrente">Recorrente</option>' +
      '</select></label>' +
      '<label>Status <select data-filt-status">' +
      '<option value="">Todos</option><option value="confirmada">Confirmada</option><option value="pendente">Pendente</option>' +
      '</select></label>' +
      '<label class="cal-filters-check"><input type="checkbox" data-filt-quinzenal /> Semana atual (quinzenais)</label>' +
      '</div>' +
      '<div class="cal-desktop" data-cal-desktop></div>' +
      '<div class="cal-mobile" data-cal-mobile></div>';

    fillCircOptions(el);

    el.querySelector('[data-filt-circ]').addEventListener('change', function () {
      state.filtCirc = this.value;
      load(false);
    });
    el.querySelector('[data-filt-tipo]').addEventListener('change', function () {
      state.filtTipo = this.value;
      load(false);
    });
    el.querySelector('[data-filt-status]').addEventListener('change', function () {
      state.filtStatus = this.value;
      load(false);
    });
    var qz = el.querySelector('[data-filt-quinzenal]');
    if (qz) {
      qz.addEventListener('change', function () {
        state.filtQuinzenalWeek = !!this.checked;
        var rodas = applyFilters(state.rows);
        renderDesktop(el, rodas);
        renderMobile(el, rodas);
      });
    }

    var ok = await load(true);
    if (!ok) return;

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
          load(false);
        }
      )
      .subscribe();
  };
})(window);

(function (global) {
  global.qs = function (sel, root) {
    return (root || document).querySelector(sel);
  };
  global.qsa = function (sel, root) {
    return [].slice.call((root || document).querySelectorAll(sel));
  };

  global.escapeHtml = function (s) {
    if (s == null) return '';
    var d = document.createElement('div');
    d.textContent = String(s);
    return d.innerHTML;
  };

  global.toast = function (msg, type) {
    var root = document.getElementById('toast-root');
    if (!root) {
      root = document.createElement('div');
      root.id = 'toast-root';
      document.body.appendChild(root);
    }
    var el = document.createElement('div');
    el.className = 'toast ' + (type === 'err' ? 'err' : 'ok');
    el.textContent = msg;
    root.appendChild(el);
    setTimeout(function () {
      el.remove();
    }, 4200);
  };

  global.formatDateBR = function (d) {
    if (!d) return '';
    var x = String(d).slice(0, 10);
    var p = x.split('-');
    if (p.length === 3) return p[2] + '/' + p[1] + '/' + p[0];
    return x;
  };

  global.parseTimeHour = function (t) {
    if (!t) return 0;
    var s = String(t);
    var h = parseInt(s.split(':')[0], 10);
    return isNaN(h) ? 0 : h;
  };

  global.fmtTime = function (t) {
    if (!t) return '';
    return String(t).slice(0, 5);
  };

  /** Número da semana ISO (1–53). */
  global.getISOWeek = function (date) {
    var d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    var dayNum = d.getUTCDay() || 7;
    d.setUTCDate(d.getUTCDate() + 4 - dayNum);
    var yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
    return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
  };

  /** Data/hora curta para `updated_at` (ISO). */
  global.formatDateTimeBR = function (iso) {
    if (!iso) return '';
    var d = new Date(iso);
    if (isNaN(d.getTime())) return String(iso).slice(0, 16);
    var dd = String(d.getDate()).padStart(2, '0');
    var mm = String(d.getMonth() + 1).padStart(2, '0');
    var yy = d.getFullYear();
    var hh = String(d.getHours()).padStart(2, '0');
    var mi = String(d.getMinutes()).padStart(2, '0');
    return dd + '/' + mm + '/' + yy + ' ' + hh + ':' + mi;
  };

  /**
   * Quinzenal visível “nesta” semana conforme paridade ISO e texto da observação.
   * Usado quando o filtro “só semana atual (quinzenais)” está ligado.
   */
  global.quinzenalMatchesThisWeek = function (roda) {
    if (!roda || roda.frequencia !== 'quinzenal') return true;
    var w = global.getISOWeek(new Date());
    var odd = w % 2 === 1;
    var obs = String(roda.observacao_frequencia || '').toLowerCase();
    if (/ímpar|impar|ímpares|impares/.test(obs)) return odd;
    if (/\bpares\b|\bpar\b/.test(obs) && !/ímpar|impar/.test(obs)) return !odd;
    return !odd;
  };

  /** Mensagem amigável para erros do PostgREST / Supabase (debug na landing). */
  global.formatSupabaseError = function (err) {
    if (!err) return 'Erro desconhecido.';
    var msg = String(err.message || err);
    var code = err.code ? String(err.code) : '';
    if (/Failed to fetch|NetworkError|Load failed|network/i.test(msg)) {
      return (
        msg +
        ' — Verifique a internet. Se abriu o HTML em file://, use um servidor local ou o deploy (HTTPS).'
      );
    }
    if (/JWT|Invalid API key|invalid_grant|401|permission denied for/i.test(msg + code)) {
      return (
        msg +
        ' — Confira no Supabase: Project Settings → API → copie a chave anon (eyJ…) e a URL do projeto.'
      );
    }
    if (/does not exist|42P01|PGRST205|schema cache/i.test(msg + code)) {
      return (
        msg +
        ' — As tabelas ainda não existem neste projeto. No SQL Editor do Supabase, execute sql/projeto_rodas_df_completo.sql.'
      );
    }
    return msg;
  };

  global.supabaseErrorBox = function (err) {
    var text = global.formatSupabaseError(err);
    return (
      '<div class="supabase-error" role="alert">' +
      '<strong>Não foi possível carregar os dados.</strong>' +
      '<p class="supabase-error-msg">' +
      global.escapeHtml(text) +
      '</p></div>'
    );
  };

  /**
   * Ajuda contextual. ctas: [{ label, href, primary?: boolean }]
   * Fecha com botão ×, clique fora ou tecla Escape.
   */
  global.openHelp = function (title, htmlOrText, ctas) {
    var back = document.createElement('div');
    back.className = 'help-backdrop';
    var pop = document.createElement('div');
    pop.className = 'help-popover';
    pop.setAttribute('role', 'dialog');
    pop.setAttribute('aria-modal', 'true');
    pop.setAttribute('aria-labelledby', 'help-pop-title');
    pop.style.top = '50%';
    pop.style.left = '50%';
    pop.style.transform = 'translate(-50%,-50%)';
    var html =
      '<button type="button" class="help-popover-close" aria-label="Fechar ajuda">×</button>' +
      '<h4 id="help-pop-title">' +
      global.escapeHtml(title) +
      '</h4><p style="margin:0;white-space:pre-wrap">' +
      global.escapeHtml(htmlOrText) +
      '</p>';
    if (ctas && ctas.length) {
      html += '<div class="help-pop-ctas">';
      for (var i = 0; i < ctas.length; i++) {
        var c = ctas[i];
        if (!c) continue;
        var cls = c.primary === false ? 'btn btn-secondary' : 'btn btn-primary';
        html +=
          '<a class="' +
          cls +
          '" href="' +
          global.escapeHtml(c.href || '#') +
          '">' +
          global.escapeHtml(c.label || 'OK') +
          '</a>';
      }
      html += '</div>';
    }
    pop.innerHTML = html;
    var close = function () {
      document.removeEventListener('keydown', onKey);
      if (back.parentNode) back.remove();
      if (pop.parentNode) pop.remove();
    };
    var onKey = function (e) {
      if (e.key === 'Escape') close();
    };
    pop.addEventListener('click', function (e) {
      e.stopPropagation();
    });
    back.addEventListener('click', close);
    document.addEventListener('keydown', onKey);
    var btnX = pop.querySelector('.help-popover-close');
    if (btnX) btnX.addEventListener('click', close);
    document.body.appendChild(back);
    document.body.appendChild(pop);
  };
})(window);

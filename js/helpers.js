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

  global.openHelp = function (title, htmlOrText) {
    var back = document.createElement('div');
    back.className = 'help-backdrop';
    var pop = document.createElement('div');
    pop.className = 'help-popover';
    pop.style.top = '50%';
    pop.style.left = '50%';
    pop.style.transform = 'translate(-50%,-50%)';
    pop.innerHTML =
      '<h4>' + global.escapeHtml(title) + '</h4><p style="margin:0">' + global.escapeHtml(htmlOrText) + '</p>';
    var close = function () {
      back.remove();
      pop.remove();
    };
    back.addEventListener('click', close);
    document.body.appendChild(back);
    document.body.appendChild(pop);
  };
})(window);

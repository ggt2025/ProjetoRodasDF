/**
 * Landing (index): âncoras internas usam pushState para o histórico do navegador
 * alinhar com Voltar/Avançar (secções, CTAs com href="#...").
 */
(function (global) {
  function scrollToId(id, smooth) {
    if (!id) return;
    var el = document.getElementById(id);
    if (!el) return;
    el.scrollIntoView({ behavior: smooth ? 'smooth' : 'auto', block: 'start' });
  }

  function init() {
    var root = document.querySelector('main.landing-wrap');
    if (!root || root.id !== 'main-content') return;

    root.addEventListener('click', function (ev) {
      var a = ev.target.closest('a[href^="#"]');
      if (!a || !a.getAttribute('href') || a.getAttribute('href').length < 2) return;
      if (a.getAttribute('href').indexOf('#') !== 0) return;
      var raw = a.getAttribute('href').slice(1);
      if (!raw || raw.indexOf('/') >= 0) return;
      var id = decodeURIComponent(raw);
      if (!document.getElementById(id)) return;
      ev.preventDefault();
      if (global.location.hash !== '#' + id) {
        global.history.pushState({ landingSection: 1 }, '', global.location.pathname + global.location.search + '#' + id);
      }
      scrollToId(id, true);
      if (typeof global.syncNavHistoryUI === 'function') global.syncNavHistoryUI();
    });

    global.addEventListener('popstate', function () {
      var id = (global.location.hash || '').replace(/^#/, '');
      scrollToId(decodeURIComponent(id), false);
      if (typeof global.syncNavHistoryUI === 'function') global.syncNavHistoryUI();
    });

    var hid = (global.location.hash || '').replace(/^#/, '');
    if (hid) global.setTimeout(function () { scrollToId(decodeURIComponent(hid), false); }, 0);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})(typeof window !== 'undefined' ? window : globalThis);

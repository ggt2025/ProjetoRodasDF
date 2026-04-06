/**
 * Navegação por âncoras / hash nos dashboards (UX: uma página, vários painéis).
 */
(function (global) {
  global.initDashPanels = function (options) {
    var nav = options.navSelector || '.dash-sidebar [data-dash-tab]';
    var panels = options.panelsSelector || '[data-dash-panel]';
    var defaultHash = options.defaultHash || '#painel';

    function show(id) {
      var hid = id.replace(/^#/, '');
      global.qsa(panels).forEach(function (p) {
        p.hidden = p.getAttribute('data-dash-panel') !== hid;
      });
      global.qsa(nav).forEach(function (a) {
        var on = a.getAttribute('href') === '#' + hid || a.getAttribute('data-dash-tab') === hid;
        a.classList.toggle('active', !!on);
        if (a.getAttribute('href') === '#' + hid) a.setAttribute('aria-current', on ? 'page' : 'false');
      });
    }

    function fromHash() {
      var h = global.location.hash || defaultHash;
      if (h === '#' || h === '') h = defaultHash;
      show(h);
    }

    global.qsa(nav).forEach(function (a) {
      a.addEventListener('click', function (ev) {
        var href = a.getAttribute('href');
        if (href && href.indexOf('#') === 0) {
          ev.preventDefault();
          global.location.hash = href;
          fromHash();
        }
      });
    });
    global.addEventListener('hashchange', fromHash);
    fromHash();
  };
})(window);

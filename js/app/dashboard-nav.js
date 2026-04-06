/**
 * Navegação por hash nos dashboards — cada separador grava entrada no histórico
 * (history.pushState) para o botão «Voltar» do navegador e a barra do site funcionarem.
 */
(function (global) {
  global.initDashPanels = function (options) {
    var nav = options.navSelector || '.dash-sidebar [data-dash-tab]';
    var panels = options.panelsSelector || '[data-dash-panel]';
    var defaultHash = options.defaultHash || '#painel';

    function panelIds() {
      var ids = [];
      global.qsa(panels).forEach(function (p) {
        var id = p.getAttribute('data-dash-panel');
        if (id) ids.push(id);
      });
      return ids;
    }

    function normalizeHash(h) {
      if (!h || h === '#' || h === '') return defaultHash;
      return h.charAt(0) === '#' ? h : '#' + h;
    }

    function showFromLocation() {
      var full = normalizeHash(global.location.hash);
      var hid = full.replace(/^#/, '');
      var ids = panelIds();
      if (ids.length && ids.indexOf(hid) === -1) {
        full = normalizeHash(defaultHash);
        hid = full.replace(/^#/, '');
        global.history.replaceState(
          { dashPanels: 1 },
          '',
          global.location.pathname + global.location.search + full
        );
      }
      global.qsa(panels).forEach(function (p) {
        p.hidden = p.getAttribute('data-dash-panel') !== hid;
      });
      global.qsa(nav).forEach(function (a) {
        var on = a.getAttribute('href') === '#' + hid || a.getAttribute('data-dash-tab') === hid;
        a.classList.toggle('active', !!on);
        if (a.getAttribute('href') === '#' + hid) {
          a.setAttribute('aria-current', on ? 'page' : 'false');
        } else {
          a.removeAttribute('aria-current');
        }
      });
      if (typeof global.syncNavHistoryUI === 'function') global.syncNavHistoryUI();
    }

    /** Igual a clicar num separador: regista histórico do navegador. */
    global.navigateDashPanel = function (hash) {
      var full = normalizeHash(hash);
      if (global.location.hash === full) {
        showFromLocation();
        return;
      }
      global.history.pushState({ dashPanels: 1 }, '', global.location.pathname + global.location.search + full);
      showFromLocation();
    };

    global.qsa(nav).forEach(function (a) {
      a.addEventListener('click', function (ev) {
        var href = a.getAttribute('href');
        if (!href || href.indexOf('#') !== 0) return;
        ev.preventDefault();
        global.navigateDashPanel(href);
      });
    });

    function initUrl() {
      var h = global.location.hash;
      if (!h || h === '#' || h === '') {
        global.history.replaceState(
          { dashPanels: 1 },
          '',
          global.location.pathname + global.location.search + defaultHash
        );
      }
      showFromLocation();
    }

    global.addEventListener('popstate', showFromLocation);
    global.addEventListener('hashchange', showFromLocation);

    initUrl();
  };
})(window);

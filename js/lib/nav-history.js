/**
 * Voltar / Avançar (histórico do separador) + Início.
 * HTML: #nav-history-back, #nav-history-forward, a.nav-history-home
 * body[data-nav-home="true"] na página inicial — Voltar desativado se não há histórico.
 */
(function (global) {
  function homeHref() {
    var el = document.querySelector('.nav-history-home');
    return (el && el.getAttribute('href')) || 'index.html';
  }

  function sync(backBtn, fwdBtn) {
    if (!backBtn || !fwdBtn) return;
    var isHome = document.body.dataset.navHome === 'true';
    var shallow = global.history.length <= 1;

    if (isHome) {
      backBtn.disabled = shallow;
      backBtn.title = shallow ? 'Está na página inicial do site' : 'Página anterior neste separador';
    } else {
      backBtn.disabled = false;
      backBtn.title = shallow
        ? 'Voltar ao início (abriu esta página diretamente neste separador)'
        : 'Página anterior neste separador';
    }

    if (global.navigation && typeof global.navigation.canGoForward === 'boolean') {
      fwdBtn.disabled = !global.navigation.canGoForward;
      fwdBtn.title = fwdBtn.disabled ? 'Não há página seguinte' : 'Página seguinte neste separador';
    } else {
      fwdBtn.disabled = false;
      fwdBtn.title = 'Página seguinte neste separador';
    }
  }

  global.syncNavHistoryUI = function () {
    var backBtn = document.getElementById('nav-history-back');
    var fwdBtn = document.getElementById('nav-history-forward');
    sync(backBtn, fwdBtn);
  };

  function init() {
    var backBtn = document.getElementById('nav-history-back');
    var fwdBtn = document.getElementById('nav-history-forward');
    if (!backBtn || !fwdBtn) return;

    backBtn.addEventListener('click', function () {
      if (backBtn.disabled) return;
      if (global.history.length <= 1) {
        global.location.href = homeHref();
        return;
      }
      global.history.back();
    });

    fwdBtn.addEventListener('click', function () {
      if (fwdBtn.disabled) return;
      global.history.forward();
    });

    global.addEventListener('popstate', function () {
      sync(backBtn, fwdBtn);
    });

    sync(backBtn, fwdBtn);

    if (global.navigation && global.navigation.addEventListener) {
      try {
        global.navigation.addEventListener('navigate', function () {
          global.setTimeout(function () {
            sync(backBtn, fwdBtn);
          }, 0);
        });
      } catch (e) {}
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})(typeof window !== 'undefined' ? window : globalThis);

/**
 * Redireciona após login conforme role em profiles.
 */
(function (global) {
  global.redirectAfterLogin = async function () {
    var { user, profile } = await global.getSessionUser();
    if (!user) {
      window.location.href = 'login.html';
      return;
    }
    var role = (profile && profile.role) || 'comum';
    var next = new URLSearchParams(window.location.search).get('next');
    if (next && next.indexOf('/') === 0 && next.indexOf('//') < 0) {
      window.location.href = next;
      return;
    }
    if (role === 'admin') {
      window.location.href = 'admin.html';
      return;
    }
    if (role === 'gestao') {
      window.location.href = 'dashboard-gestao.html';
      return;
    }
    window.location.href = 'dashboard-usuario.html';
  };

  global.goHome = function () {
    window.location.href = 'index.html';
  };
})(window);

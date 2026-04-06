/**
 * Auth: email/senha + Google. Roles em public.profiles.
 */
(function (global) {
  async function getProfileRow(uid) {
    var sb = global.getSupabase();
    if (!sb || !uid) return null;
    var r = await sb.from('profiles').select('*').eq('id', uid).maybeSingle();
    if (r.error) {
      console.warn(r.error);
      return null;
    }
    return r.data;
  }

  global.getSessionUser = async function () {
    var sb = global.getSupabase();
    if (!sb) return { user: null, profile: null };
    var sessionRes = await sb.auth.getSession();
    var session = sessionRes.data && sessionRes.data.session;
    if (!session || !session.user) return { user: null, profile: null };
    var profile = await getProfileRow(session.user.id);
    return { user: session.user, profile: profile };
  };

  global.signInEmail = async function (email, password) {
    var sb = global.getSupabase();
    if (!sb) throw new Error('Supabase não configurado');
    var res = await sb.auth.signInWithPassword({ email: email.trim(), password: password });
    if (res.error) throw res.error;
    return res.data;
  };

  global.signUpEmail = async function (email, password) {
    var sb = global.getSupabase();
    if (!sb) throw new Error('Supabase não configurado');
    var res = await sb.auth.signUp({ email: email.trim(), password: password });
    if (res.error) throw res.error;
    return res.data;
  };

  global.signInGoogle = async function () {
    var sb = global.getSupabase();
    if (!sb) throw new Error('Supabase não configurado');
    var redir = global.location.origin + '/login.html';
    var res = await sb.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: redir },
    });
    if (res.error) throw res.error;
    return res.data;
  };

  global.signOut = async function () {
    var sb = global.getSupabase();
    if (!sb) return;
    await sb.auth.signOut();
  };

  global.updateHeaderAuth = async function () {
    var slot = global.qs('[data-auth-slot]');
    if (!slot) return;
    var sb = global.getSupabase();
    if (!sb) {
      slot.innerHTML =
        '<a href="login.html">Entrar</a> <span style="opacity:.6">·</span> <a href="login.html#cadastro">Cadastrar</a>';
      return;
    }
    var { user, profile } = await global.getSessionUser();
    if (!user) {
      slot.innerHTML =
        '<a href="login.html">Entrar</a> <span style="opacity:.6">·</span> <a href="login.html#cadastro">Cadastrar</a>';
      return;
    }
    var nome = (profile && profile.nome) || user.email || 'Conta';
    slot.innerHTML =
      'Olá, <strong>' +
      global.escapeHtml(nome) +
      '</strong> · <a href="perfil.html">Perfil</a> · <button type="button" class="link-btn" id="btnLogoutHeader">Sair</button>';
    var btn = global.qs('#btnLogoutHeader');
    if (btn)
      btn.addEventListener('click', async function () {
        await global.signOut();
        window.location.href = 'index.html';
      });
  };

  global.requireAuth = async function () {
    var { user } = await global.getSessionUser();
    if (!user) {
      window.location.href = 'login.html?next=' + encodeURIComponent(window.location.pathname);
      return null;
    }
    return user;
  };

  document.addEventListener('DOMContentLoaded', function () {
    var sb = global.getSupabase();
    if (!sb) return;
    sb.auth.onAuthStateChange(function () {
      if (typeof global.updateHeaderAuth === 'function') global.updateHeaderAuth();
    });
  });
})(window);

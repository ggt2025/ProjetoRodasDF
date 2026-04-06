(function (global) {
  global.initContatoForm = function (formId) {
    var form = document.getElementById(formId);
    if (!form) return;
    form.addEventListener('submit', async function (ev) {
      ev.preventDefault();
      var sb = global.getSupabase();
      if (!sb) {
        global.toast('Configure o Supabase.', 'err');
        return;
      }
      var fd = new FormData(form);
      var nome = (fd.get('nome') || '').toString().trim();
      var email = (fd.get('email') || '').toString().trim();
      var mensagem = (fd.get('mensagem') || '').toString().trim();
      if (!nome || !email || !mensagem) {
        global.toast('Preencha nome, e-mail e mensagem.', 'err');
        return;
      }
      var res = await sb.from('contatos').insert({ nome: nome, email: email, mensagem: mensagem });
      if (res.error) {
        global.toast('Erro ao enviar: ' + res.error.message, 'err');
        return;
      }
      global.toast('Mensagem enviada. A gestão retornará quando possível.', 'ok');
      form.reset();
    });
  };
})(window);

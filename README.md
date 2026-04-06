# Rede de Rodas do DF

Site estático multi-página (HTML + CSS + JS) com [Supabase](https://supabase.com) (Auth, Postgres, Realtime). Deploy recomendado: Netlify (raiz do repositório).

## Configuração rápida

1. **Supabase** — Criar projeto → SQL Editor → executar [`sql/schema_completo.sql`](sql/schema_completo.sql) (schema único; ver [`sql/README.md`](sql/README.md)).
2. **Chaves** — Editar [`js/config.js`](js/config.js): `url` do projeto e `anon` key (Settings → API). Pode copiar de [`js/config.example.js`](js/config.example.js).
3. **Auth** — Authentication → URL configuration: adicionar URL do site (ex.: `https://seu-site.netlify.app`) e `http://localhost:8080` para testes locais. Ativar Google OAuth se usar o botão Google.
4. **Deploy** — Publicar a raiz (`publish = "."` no `netlify.toml`).

## Estrutura principal

| Caminho | Descrição |
|--------|-----------|
| `index.html` | Landing pública (hero, calendário de rodas, notícias, editais, bases, contato) |
| `login.html` | Login e cadastro (e-mail + Google) |
| `perfil.html` | Perfil do utilizador e rodas vinculadas |
| `dashboard-usuario.html` / `dashboard-gestao.html` / `admin.html` | Áreas internas (stubs expandidos nos blocos seguintes) |
| `css/` | Estilos globais e por área |
| `js/config.js` | **Único** ficheiro de configuração Supabase |
| `js/` | Cliente Supabase, auth, calendário, conteúdos, módulos futuros |
| `sql/schema_completo.sql` | Schema completo (sem analytics) |
| `assets/` | Logotipo e recursos estáticos |

Não há scripts de analytics nem rastreamento de terceiros no código base.

## Desenvolvimento local

Servir a raiz com qualquer servidor estático, por exemplo:

```bash
npx serve .
```

Abrir `http://localhost:3000` (ou a porta indicada).

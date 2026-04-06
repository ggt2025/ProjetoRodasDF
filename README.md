# Rede de Rodas do DF

Site estático multi-página (HTML + CSS + JS) com [Supabase](https://supabase.com) (Auth, Postgres, Realtime). Deploy recomendado: Netlify (raiz do repositório).

## Configuração rápida

1. **Supabase** — Criar projeto → SQL Editor → executar [`sql/projeto_rodas_df_completo.sql`](sql/projeto_rodas_df_completo.sql) (schema único; ver [`sql/README.md`](sql/README.md)).
2. **Chaves** — Editar [`js/config.js`](js/config.js): `url` do projeto e `anon` key (Settings → API). Pode copiar de [`js/config.example.js`](js/config.example.js).
3. **Auth** — Authentication → URL configuration: adicionar URL do site (ex.: `https://seu-site.netlify.app`) e `http://localhost:8080` para testes locais. Ativar Google OAuth se usar o botão Google.
4. **Deploy** — Publicar a raiz (`publish = "."` no `netlify.toml`).

## Estrutura principal

| Caminho | Descrição |
|--------|-----------|
| `index.html` | Landing pública (hero, calendário de rodas, notícias, editais, bases, contato) |
| `login.html` | Login e cadastro (e-mail + Google) |
| `perfil.html` | A · Perfil (visitante vê convite a entrar; autenticado edita dados) |
| `dashboard-usuario.html` | C · Utilizador comum: Rodas DF, protótipos, Rede DF, fórum público (textos no Supabase) |
| `dashboard-gestao.html` | D · Gestão: dashboard unificado, participação (analytics), encaminhamentos, equipa, parceiros/rede/pontes, site, fórum privado, registo |
| `admin.html` | B · Admin: papéis (comum / gestão / admin) e tabela de visitas |
| `css/` | Estilos (ver [`css/README.md`](css/README.md)) |
| `js/config.js` | **Único** ficheiro de configuração Supabase (raiz de `js/`) |
| `js/lib/` | Cliente Supabase, helpers, constantes, analytics |
| `js/auth/` | Sessão e redirecionamento pós-login |
| `js/site/` | Landing: calendário, cards, notícias, editais, bases, contato |
| `js/app/` | Dashboards, rodas, perfil, gestão, admin |
| [`js/README.md`](js/README.md) | Mapa completo das pastas `lib`, `auth`, `site`, `app` |
| `js/archive/` | Stubs e dados antigos não carregados pelo site (ver `js/archive/README.md`) |
| `sql/projeto_rodas_df_completo.sql` | **Único** script SQL: tabelas, RLS, compatibilidade `rodas`, analytics, seeds |
| `sql/archive/` | Apenas nota de arquivo (scripts antigos unificados; ver `sql/archive/README.md`) |
| `assets/` | `logotiporodas.png` (favicon); outros em `assets/archive/` se não usados |

### Áreas do produto (UX)

| Letra | Quem | Onde |
|-----|------|------|
| **A** | Perfil (todos os autenticados; visitante vê convite) | `perfil.html` |
| **B** | Administração (papéis + analytics global) | `admin.html` |
| **C** | Utilizador comum (rodas, protótipos, Rede DF, fórum público) | `dashboard-usuario.html` |
| **D** | Gestão do projeto (painel, participação, rede/pontes, site, fórum privado…) | `dashboard-gestao.html` |

**Analytics interno** (sem cookies de terceiros): `js/lib/analytics.js` grava visitas em `analytics_page_views` em todas as páginas HTML; leitura em **D · Participação** e **B · Admin** após executar o SQL único no Supabase.

## Desenvolvimento local

Servir a raiz com qualquer servidor estático, por exemplo:

```bash
npx serve .
```

Abrir `http://localhost:3000` (ou a porta indicada).

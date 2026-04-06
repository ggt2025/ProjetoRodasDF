# JavaScript — organização

| Pasta | Conteúdo |
|--------|----------|
| **Raiz** | `config.js`, `config.example.js` — credenciais Supabase (único sítio a editar para API). |
| **`lib/`** | `supabase-client.js`, `helpers.js`, `constants.js`, `analytics.js` — infra partilhada. |
| **`auth/`** | `auth.js` (cabeçalho, login), `router.js` (redirect após login). |
| **`site/`** | Página pública: `calendar.js`, `roda-card.js`, `noticias.js`, `editais.js`, `bases-conhecimento.js`, `contato.js`. |
| **`app/`** | Áreas autenticadas: `dashboard-nav.js`, `dashboard-usuario.js`, `rodas.js`, `perfil.js`, `gestao-app.js`, `gestao-rede.js`, `admin-app.js`. |
| **`archive/`** | Código antigo não referenciado pelo site (ver `archive/README.md`). |

Ordem típica nos HTML: `config.js` → CDN Supabase → `lib/*` → `auth/*` → `site/*` ou `app/*`.

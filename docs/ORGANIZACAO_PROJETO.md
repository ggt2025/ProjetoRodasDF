# Organização do projeto — Rede de Rodas do DF

Documento de referência: **páginas, painéis** e **ligação ao Supabase**. O modelo de base de dados alvo é o ficheiro único **`sql/projeto_rodas_df_completo.sql`** (executar no Supabase conforme o README em `sql/`).

---

## 1. Áreas do produto (A–D)

| Área | Página | Quem acede | Função resumida |
|------|--------|------------|-----------------|
| **A** | `perfil.html` | Qualquer visitante; edição com login | Perfil (`profiles`), vínculo com rodas (`usuario_rodas` + `rodas`). |
| **B** | `admin.html` | `role` admin | Papéis em `profiles`, leitura de `analytics_page_views`. |
| **C** | `dashboard-usuario.html` | Utilizador autenticado | Rodas (`rodas`), materiais (`prototipos_redes`), mapa `rede_df`, fórum público (`forum_topicos` com `tipo = publico`). |
| **D** | `dashboard-gestao.html` | `role` gestão ou admin | Painéis D.1–D.7: operação, rede, site, fórum privado, etc. |
| **Site público** | `index.html` | Qualquer visitante | Calendário (`rodas`), notícias, editais, bases, NotebookLM (estático), contato, analytics. |

Autenticação: `js/auth/auth.js` (carrega `profiles` pelo `id` do utilizador Supabase Auth).

---

## 2. Site público (`index.html`)

| Secção | ID / montagem | Origem dos dados |
|--------|----------------|------------------|
| Hero + navegação rápida | `#sec-hero`, `.landing-quick-nav` | Estático + `openHelp`. |
| Calendário | `#mount-calendario` | **Supabase** `rodas` — `js/site/calendar.js`. |
| Notícias | `#mount-noticias` | **Supabase** `noticias` — `js/site/noticias.js`. |
| Editais | `#mount-editais` | **Supabase** `editais` — `js/site/editais.js`. |
| NotebookLM | `#sec-notebooklm` | Links estáticos (Google NotebookLM). |
| Outras bases | `#mount-bases` | **Supabase** `bases_conhecimento` — `js/site/bases-conhecimento.js`. |
| Contato | `#form-contato` | **Supabase** `contatos` — `js/site/contato.js`. |
| Visitas | — | **Supabase** `analytics_page_views` — `js/lib/analytics.js`. |

Barra **Voltar / Avançar / Início**: `css/nav-history.css`, `js/lib/nav-history.js`. Na página inicial, `body[data-nav-home="true"]`.

---

## 3. Painel de gestão (`dashboard-gestao.html`)

Navegação por **hash**, em `js/app/dashboard-nav.js` e arranque em `js/app/gestao-app.js`.

### 3.1 Separadores laterais (resumo)

| Hash | Conteúdo principal |
|------|-------------------|
| `#dashboard` | KPIs, `cronograma` (tabela genérica), calendário de rodas, analytics. |
| `#participacao` | Participação / analytics (área dedicada no HTML atual). |
| `#encaminhamentos` | Tabela **`encaminhamentos`** via `loadTable` (visualização/edição genérica). |
| `#equipe` | Tabela **`equipe_projeto`** via `loadTable`. |
| `#parceiros` | `rede_df`, **`rede_df_pontes`** (pontes), `parceiros_pontes` — `js/app/gestao-rede.js`. |
| `#site` | Resumo `noticias` / `editais`. |
| `#forum-priv` | `forum_topicos` com `tipo = 'privado'`. |
| `#registro` | Tabela **`registro_atividades`** via `loadTable` (se existir no projeto). |

**Importante:** o código de gestão de rede usa a tabela **`rede_df_pontes`**, não `pontes`.

### 3.2 O que não está neste repositório (extensão futura)

- Painel rico de tarefas com `tasks` / `comments` / `team_members` (modelo do projeto «unificado» antigo).
- Protótipos metodológicos com `proto_notes` no painel D.8 (pode existir conteúdo estático na área C em evoluções futuras).
- `levantamento.js` + dados estáticos em massa: estão em `js/archive/` como referência, não ligados ao painel atual.

---

## 4. Outras páginas

| Página | Scripts | Supabase (típico) |
|--------|---------|-------------------|
| `perfil.html` | `perfil.js` | `profiles`, `usuario_rodas`, `rodas` |
| `rodas.js` | com `dashboard-usuario.js` | `rodas` |
| `admin-app.js` | | `profiles`, `analytics_page_views` |

---

## 5. Tabelas referenciadas pelo front (mapa rápido)

| Tabela | Uso principal |
|--------|----------------|
| `rodas` | Calendário, área C, KPI gestão |
| `profiles` | Auth, perfil, admin |
| `usuario_rodas` | Perfil |
| `noticias`, `editais`, `contatos`, `bases_conhecimento` | Site + gestão D.5 |
| `analytics_page_views` | Analytics |
| `rede_df` | C.3, gestão D.4 |
| **`rede_df_pontes`** | Gestão D.4 (pontes) |
| `parceiros_pontes` | Gestão D.4 (contexto) |
| `prototipos_redes` | C.2 |
| `forum_topicos` | C.4 (público), D.6 (privado) |
| `encaminhamentos`, `equipe_projeto` | D.2, D.3 (`loadTable`) |
| `cronograma`, `registro_atividades` | D.1, D.7 (se existirem) |

Configuração Supabase: `js/config.js` + `js/lib/supabase-client.js`.

---

## 6. Checklist Supabase

1. URL e chave anon corretas em `js/config.js`.
2. Executar **`sql/projeto_rodas_df_completo.sql`** (e políticas RLS indicadas na documentação SQL).
3. Realtime opcional na tabela `rodas` para o calendário.
4. Garantir que as tabelas usadas por `loadTable` existem ou aceitar mensagens de erro até serem criadas.

---

*Documento alinhado ao código na raiz do repositório (não ao subdiretório `NOVO RODAS/`).*

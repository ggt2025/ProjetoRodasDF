# Rede de Rodas do DF — visão geral (raiz)

Documento enxuto: o que é o projeto, mapa de páginas e separadores, fluxo sugerido por perfil, e pedidos ainda não totalmente atendidos.

---

## 1. O que é este projeto

É um **site estático multi-página** (HTML, CSS, JavaScript) para a **Rede de Rodas do DF**: mapeamento público de rodas de conversa (calendário semanal), comunicação institucional (notícias, editais, bases de conhecimento, NotebookLM como links), contacto com a gestão, e **áreas autenticadas** para utilizadores externos, equipa de gestão e administradores.

Os dados vivem no **Supabase** (Postgres, Auth, opcional Realtime). O modelo de base está concentrado no ficheiro **`sql/projeto_rodas_df_completo.sql`**. A URL e a chave anónima configuram-se em **`js/config.js`**.

---

## 2. Páginas, separadores (abas) e sequência UX/UI por perfil

### 2.1 Inventário de páginas (ficheiros na raiz do site)

```
index.html              — Site público (uma página, várias secções)
login.html              — Entrar e cadastrar (e-mail / Google)
perfil.html             — Área A · Perfil (visitante ou autenticado)
dashboard-usuario.html  — Área C · Utilizador comum (painéis por hash)
dashboard-gestao.html   — Área D · Gestão do projeto (painéis por hash)
admin.html              — Área B · Administração
```

Não há outras páginas HTML de aplicação na raiz além destas seis.

---

### 2.2 Site público — `index.html` (secções, ordem no ecrã)

Ordem vertical típica (UI):

1. Cabeçalho global (marca, navegação de sessão, barra Voltar/Avançar/Início)
2. Hero (`#sec-hero`) — apresentação e CTAs
3. Navegação rápida entre secções
4. Mapeamento semanal (`#sec-calendario`)
5. Notícias (`#sec-noticias`)
6. Edital (`#sec-editais`)
7. Bases de conhecimento — NotebookLM (`#sec-notebooklm`) + lista Supabase (`#sec-bases-outros` / `mount-bases`)
8. Contato (`#sec-contato`)
9. Rodapé (links para áreas internas, canais MPDFT, linha 180)

Fluxo UX sugerido **visitante**: Hero → Calendário (consultar rodas) → Notícias/Edital/Conhecimento conforme interesse → Contato; **Entrar** quando quiser cadastrar roda ou usar área C.

---

### 2.3 Autenticação — `login.html`

- Formulário de login e bloco de cadastro (`#cadastro`)
- Após sucesso, o site redireciona conforme papel: **admin** → `admin.html`, **gestão** → `dashboard-gestao.html`, **comum** → `dashboard-usuario.html` (lógica em `js/auth/router.js` e auth)

---

### 2.4 Área A — `perfil.html`

- Visitante: mensagem para entrar ou criar conta
- Autenticado: dados do perfil (`profiles`) e rodas associadas (`usuario_rodas` / `rodas`)

---

### 2.5 Área C — `dashboard-usuario.html` (separadores na barra lateral)

| Hash / separador | Conteúdo resumido |
|------------------|-------------------|
| `#rodas` (default) | C.1 · Rodas DF — lista e formulário das minhas rodas (Supabase `rodas`) |
| `#proto` | C.2 · Protótipos e redes — materiais `prototipos_redes` |
| `#rede` | C.3 · Rede DF — leitura `rede_df` |
| `#forum` | C.4 · Fórum público — tópicos `forum_topicos` tipo público |

Links fixos na sidebar: **Perfil**, **Site público**. Cabeçalho: ligações para gestão/admin quando aplicável.

---

### 2.6 Área D — `dashboard-gestao.html` (separadores na barra lateral)

| Hash / separador | Conteúdo resumido |
|------------------|-------------------|
| `#dashboard` (default) | D.1 · KPIs, tabela `cronograma`, calendário de rodas |
| `#participacao` | Visitas (`analytics_page_views`) |
| `#encaminhamentos` | D.2 · Tabela `encaminhamentos` (vista genérica) |
| `#equipe` | D.3 · Tabela `equipe_projeto` (vista genérica) |
| `#parceiros` | D.4 · Parceiros, Rede DF editável, pontes `rede_df_pontes` |
| `#site` | D.5 · Resumo notícias / editais |
| `#forum-priv` | D.6 · Fórum privado (`forum_topicos` privado) |
| `#registro` | D.7 · Tabela `registro_atividades` (se existir) |

Links fixos: **Área do utilizador**, **Perfil**, **Site público**.  
Hashes antigos `#painel`, `#cronograma`, `#calendario` são normalizados para `#dashboard`.

---

### 2.7 Área B — `admin.html`

- Secção utilizadores e papéis (`profiles` — comum / gestão / admin)
- Secção analytics (visitas)
- Sidebar: atalhos para `dashboard-usuario.html`, `dashboard-gestao.html`, `perfil.html`, site público

---

### 2.8 Sequência UX/UI recomendada por perfil (os quatro perfis)

**Perfil 1 — Visitante (sem sessão)**  
`index.html` (explorar conteúdo e calendário) → `login.html` se quiser conta → pode abrir `perfil.html` (vê convite a autenticar).

**Perfil 2 — Utilizador comum (`role` comum)**  
`login.html` → `dashboard-usuario.html` (por omissão **C.1 Rodas**) → **C.2–C.4** conforme necessidade → `perfil.html` para dados pessoais → `index.html` para ver calendário público.

**Perfil 3 — Gestão (`role` gestão)**  
`login.html` → `dashboard-gestao.html` (por omissão **D.1**) → **D.2–D.7** conforme operação (rede/pontes em **D.4**, participação em **Participação**) → pode usar `dashboard-usuario.html` e `perfil.html` pelos atalhos.

**Perfil 4 — Admin (`role` admin)**  
`login.html` → `admin.html` para papéis e analytics global → `dashboard-gestao.html` para operação do projeto → demais páginas pelos atalhos (utilizador comum, perfil, site público).

*(UI: cabeçalho roxo + barra de histórico do separador + sidebar nos painéis C/D/B; ajuda contextual nos botões «?» onde existem.)*

---

## 3. Pedidos que ficaram por cumprir ou só parcialmente

Lista baseada no que foi pedido ao longo do trabalho (merge com o projeto «unificado», «gerar o projeto completamente», e critérios explícitos de exclusão). Serve para acompanhamento; não substitui issues ou notas em `docs/`.

### 3.1 Não integrado de forma completa (ou de propósito não misturado ao schema atual)

- **Levantamento tipo unificado** — módulo com `levantamento.js` + dados massivos em `rodas_levantamento.js` + `localStorage`, como no projeto de referência em `NOVO RODAS/`, **não** foi ligado ao painel D.4 (o rótulo menciona levantamento; a UI dedicada não foi portada).
- **Painel D.8 «Protótipos metodológicos» na gestão** — no unificado existia com capítulos estáticos + `proto_notes` no Supabase; **não** há separador D.8 em `dashboard-gestao.html` nem `gestao-prototipos.js` na árvore atual (a área C tem protótipos via `prototipos_redes`, que é outro conceito).
- **Encaminhamentos e equipa «ricos»** — modelo com `tasks`, `comments`, `team_members` do unificado **não** foi adotado; mantêm-se tabelas **`encaminhamentos`** e **`equipe_projeto`** com visualização genérica (`loadTable`), sem aquele fluxo de tarefas/comentários.
- **Tabela `pontes` em vez de `rede_df_pontes`** — foi acordado **não** trocar: o código de gestão usa **`rede_df_pontes`** alinhado ao SQL único; não houve convergência para o nome `pontes` do outro repo.
- **Fonte principal `NOVO RODAS/deploy-69d2cdf...`** — snapshot antigo; **não** foi usado como base (pedido explícito).

### 3.2 Parcial ou dependente de ficheiros / SQL / evolução futura

- **«Gerar o projeto completamente»** — entregues melhorias grandes (organização, nav-history, NotebookLM na landing, histórico do navegador nas abas, `docs/ORGANIZACAO_PROJETO.md`), mas **não** o pacote completo do unificado (itens da secção 3.1).
- **Imagens QR no rodapé** — o HTML referencia `assets/qrcode_ouvidoria_mpdft.png` e `assets/qrcode_www_mpdft.png`; se os ficheiros **não** estiverem na pasta `assets/`, os QR **não** aparecem (comportamento com `onerror`).
- **Tabelas opcionais** — `cronograma`, `registro_atividades`, `encaminhamentos`, `equipe_projeto`: se **não** existirem no Supabase após o SQL, os respetivos blocos mostram erro ou vazio até criarem/migrarem.
- **D.5 Site público** — vista resumida de notícias/editais; edição completa no próprio painel **não** foi fechada como produto final (o texto do painel admite evolução / Supabase).
- **Documentação de organização na raiz** — existe **`docs/ORGANIZACAO_PROJETO.md`**, não um ficheiro homónimo na raiz (foi colocado em `docs/`).

### 3.3 Itens que **não** entram aqui como «não cumpridos»

- Ajustes já feitos e commitados (perfil para visitante, admin UX, sidebar C, dashboard gestão unificado + Participação, compatibilidade SQL `dia_semana`, analytics, `rede_df_pontes` em `gestao-rede.js`, etc.) **não** são listados como falhas nesta secção.

---

Para configuração técnica (Supabase, deploy, estrutura de pastas), use **`sql/README.md`**, **`js/README.md`** e **`docs/ORGANIZACAO_PROJETO.md`**.

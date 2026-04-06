# SQL — Projeto Rodas DF

## Ficheiro único

Execute no Supabase **SQL Editor** (Run) o ficheiro:

**[`projeto_rodas_df_completo.sql`](projeto_rodas_df_completo.sql)**

Inclui, num só script:

- extensões, remoção de políticas antigas (re-run seguro), trigger `handle_new_user` em `auth.users`;
- todas as tabelas públicas, RLS, índices, **analytics** (`analytics_page_views`), política de **admin** em `profiles`;
- compatibilidade com bases antigas (colunas em `rodas`, incl. `dia_semana`);
- grants, Realtime em `rodas`, seeds (rodas, fóruns genéricos, notícias, rede DF, etc.).

Re-execução: o script remove políticas listadas em `pg_policies` e recria; tabelas usam `CREATE TABLE IF NOT EXISTS`.

## Após executar o SQL

1. Authentication → URL configuration → Site URL e Redirect URLs com a URL de produção e `login.html`.
2. Authentication → Providers → Google (opcional).
3. Database → Replication → confirmar que `rodas` está na publicação `supabase_realtime` (o script tenta adicionar).

## Histórico

Scripts SQL antigos foram unificados; não há migrações separadas.

## Ver também

No repositório, [`README.md`](../README.md) descreve as **áreas A–D** do produto e o fluxo com Supabase.

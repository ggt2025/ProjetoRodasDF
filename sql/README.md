# SQL — Projeto Rodas DF

## Ficheiro a usar

Execute **apenas** [`schema_completo.sql`](schema_completo.sql) no Supabase SQL Editor (Run).

- Inclui tabelas, RLS, trigger `handle_new_user` em `auth.users`, grants, índices, backfill de `profiles` para utilizadores já existentes em `auth.users`, publicação Realtime da tabela `rodas`, e dados de exemplo.
- Re-execução: o script remove políticas listadas em `pg_policies` e recria; tabelas usam `CREATE TABLE IF NOT EXISTS`.

Os ficheiros `00_*`, `01_*`, `02_*` e `legacy/` são **históricos**; não são necessários para novos ambientes.

## Após executar o SQL

1. Authentication → URL configuration → Site URL e Redirect URLs com a URL de produção e `login.html`.
2. Authentication → Providers → Google (opcional).
3. Database → Replication → confirmar que `rodas` está na publicação `supabase_realtime` (o script tenta adicionar).

## Sem analytics

Não existem tabelas nem políticas de analytics neste schema.

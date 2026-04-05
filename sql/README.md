# SQL — Rede de Rodas do DF

## Arquivo principal

- **`00_schema_final_completo.sql`** — schema único para Supabase (PostgreSQL 15+): tabelas base, fórum, rede, site público (`public_rodas_site`, `public_edital_site`), pontes, RLS, grants e seeds. Rode este arquivo no SQL Editor quando for configurar ou atualizar o banco.

## Pasta `legacy/`

Scripts antigos ou incrementais, mantidos só para histórico ou referência. O conteúdo relevante foi incorporado ao `00_schema_final_completo.sql`. Não é necessário rodar os arquivos de `legacy/` em um projeto novo que já use o schema final.

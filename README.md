# Rede de Rodas do DF — site e painel SAAD

Site estático (página pública + painel de gestão) com backend opcional em [Supabase](https://supabase.com).

## Estrutura do repositório

| Caminho | Descrição |
|--------|-----------|
| `index.html` | Aplicação completa (HTML, CSS, JavaScript). Ponto de entrada do deploy. |
| `js/rodas_levantamento.js` | Dados do levantamento «Rodas DF» (tabelas por partes); expõe `window.RODAS_LEV`. |
| `assets/` | Imagens: logotipo (`logotiporodas.png`) e QR codes de referência institucional. |
| `sql/00_schema_final_completo.sql` | Schema PostgreSQL/Supabase (rodar no SQL Editor). Ver `sql/README.md`. |
| `sql/legacy/` | Migrações antigas (referência). |
| `netlify.toml` / `_redirects` | Configuração de deploy Netlify (site estático na raiz). |

## Deploy

Publicar a **raiz** do repositório como site estático (já configurado no `netlify.toml` com `publish = "."`).

## Banco de dados

1. Criar projeto no Supabase.  
2. Executar `sql/00_schema_final_completo.sql` no SQL Editor.  
3. Colar URL do projeto e chave `anon` em `index.html` (constantes `RODASDF_SUPABASE_*`).

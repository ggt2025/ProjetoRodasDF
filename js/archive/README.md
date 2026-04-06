# JS arquivado (stubs e dados estáticos)

Módulos **não** referenciados pelas páginas HTML atuais. Mantidos para futura integração (painéis gestão/admin) ou referência.

| Ficheiro | Conteúdo |
|----------|----------|
| `gestao-*.js`, `admin-*.js`, `rede-df.js` | Stubs de uma linha (`window.*Module = { ready: false }`). |
| `rodas_levantamento.js` | Dados estáticos grandes (`window.RODAS_LEV`) para levantamento; não carregado no `index.html` atual. |

Para usar `rodas_levantamento.js` de novo: `<script src="js/archive/rodas_levantamento.js" defer></script>` (ajustar caminho).

-- ============================================================
-- Rede de Rodas do DF — página pública: rodas + edital (Supabase)
-- Rode no SQL Editor após public_news e demais tabelas base.
--
-- Tabelas:
--   public_rodas_site   → cards «Rodas e encontros» (dia, horário, onde, contato)
--   public_edital_site  → um único registro (id = 1) «Edital de capacitação»
--
-- O painel HTML (aba «Site público») usa JWT authenticated para CRUD.
-- A página inicial lê com anon (mesma anon key do app).
-- ============================================================

-- 1) Rodas / encontros na inicial
CREATE TABLE IF NOT EXISTS public_rodas_site (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL DEFAULT '',
  day_label text DEFAULT '',
  time_text text DEFAULT '',
  place_text text DEFAULT '',
  contact_text text DEFAULT '',
  note_text text DEFAULT '',
  sort_order int NOT NULL DEFAULT 0,
  is_visible boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_public_rodas_site_sort ON public_rodas_site (sort_order);

-- 2) Edital (singleton)
CREATE TABLE IF NOT EXISTS public_edital_site (
  id smallint PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  titulo text NOT NULL DEFAULT 'Edital de capacitação',
  aberto boolean NOT NULL DEFAULT true,
  inscricoes_ate text DEFAULT '',
  resumo text DEFAULT '',
  texto text DEFAULT '',
  link_url text DEFAULT '',
  link_label text DEFAULT 'Abrir edital (PDF ou página)',
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public_edital_site (id) VALUES (1)
ON CONFLICT (id) DO NOTHING;

-- 3) RLS
ALTER TABLE public_rodas_site ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_edital_site ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_rodas_site_select_visible" ON public_rodas_site;
CREATE POLICY "public_rodas_site_select_visible"
  ON public_rodas_site FOR SELECT TO anon, authenticated
  USING (is_visible = true);

DROP POLICY IF EXISTS "public_rodas_site_auth_all" ON public_rodas_site;
CREATE POLICY "public_rodas_site_auth_all"
  ON public_rodas_site FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "public_edital_site_select" ON public_edital_site;
CREATE POLICY "public_edital_site_select"
  ON public_edital_site FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "public_edital_site_auth_all" ON public_edital_site;
CREATE POLICY "public_edital_site_auth_all"
  ON public_edital_site FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

-- 4) Permissões REST (ajuste se não usar anon no app)
GRANT SELECT ON public_rodas_site TO anon;
GRANT SELECT ON public_edital_site TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public_rodas_site TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public_edital_site TO authenticated;

-- 5) Seed opcional (só insere se a tabela de rodas estiver vazia)
INSERT INTO public_rodas_site (title, day_label, time_text, place_text, contact_text, note_text, sort_order, is_visible)
SELECT 'Roda comunitária — referência CEAM / articulação rede', 'Quintas', '14h–16h (exemplo)',
  'DF — local divulgado pelas parceiras de campo', 'Articulação: equipe via canal institucional (MPDFT / parceiros)',
  'Horário e endereço podem variar por território; confirme com a rede local antes de encaminhar mulheres.', 0, true
WHERE NOT EXISTS (SELECT 1 FROM public_rodas_site LIMIT 1);

INSERT INTO public_rodas_site (title, day_label, time_text, place_text, contact_text, note_text, sort_order, is_visible)
SELECT 'Espaço de planejamento da rede (equipe)', 'Sob demanda', 'A combinar', 'Reuniões online ou presenciais no DF',
  'Acesso restrito — use o painel de gestão', 'Para voluntárias e parceiras já vinculadas ao projeto.', 1, true
WHERE (SELECT count(*) FROM public_rodas_site) = 1;

INSERT INTO public_rodas_site (title, day_label, time_text, place_text, contact_text, note_text, sort_order, is_visible)
SELECT 'Capacitação de facilitadoras (piloto)', 'Previsto Fase 1', 'A definir (edital)', 'Distrito Federal',
  'Inscrição pelo edital de capacitação nesta página', 'Cronograma alinhado ao currículo em construção; vagas e requisitos no instrumento oficial quando publicado.', 2, true
WHERE (SELECT count(*) FROM public_rodas_site) = 2;

UPDATE public_edital_site SET
  titulo = 'Capacitação de facilitadoras — ciclo 2026',
  aberto = true,
  inscricoes_ate = '30 de maio de 2026 (referência — ajuste no painel)',
  resumo = 'Formação para atuar em rodas multidisciplinares de acolhimento a mulheres em situação de vulnerabilidade no DF, com eixos de escuta, direitos e fortalecimento comunitário.',
  texto = 'Os critérios de seleção, carga horária e documentação serão detalhados no edital oficial (PDF ou página parceira). Este resumo serve para comunicação no site até a publicação.' || E'\n\n' || 'Interessadas: acompanhem esta seção ou o canal institucional que divulgar o processo.',
  updated_at = now()
WHERE id = 1 AND (texto IS NULL OR trim(texto) = '');

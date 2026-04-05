-- =============================================================================
-- REDE DE RODAS DO DF — Migração incremental v6
-- PostgreSQL 15+ / Supabase
--
-- O QUE FAZ
--   • Cria public_eventos_cal  (calendário público — bolinhas verde/amarelo)
--   • Cria proto_notes          (observações por capítulo dos Protótipos)
--   • Safe ALTER em tasks, public_news e pontes (colunas que podem faltar em
--     instâncias criadas com schema v3 ou v4)
--   • Ativa RLS + políticas + GRANTs para as duas novas tabelas
--   • Semeia eventos iniciais do calendário (idempotente)
--
-- COMO RODAR
--   Supabase → SQL Editor → colar este arquivo → Run
--   (Pode ser executado sobre qualquer versão do schema anterior sem risco)
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1) CALENDÁRIO PÚBLICO DE EVENTOS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public_eventos_cal (
  id          uuid  PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo      text  NOT NULL DEFAULT '',
  data_evento date  NOT NULL,
  hora        text  DEFAULT '',
  local       text  DEFAULT '',
  tipo        text  NOT NULL DEFAULT 'outro'
    CHECK (tipo IN ('reuniao','roda','capacitacao','articulacao','outro')),
  descricao   text  DEFAULT '',
  confirmado  boolean NOT NULL DEFAULT false,
  is_visible  boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public_eventos_cal IS
  'Calendário de eventos exibido na página pública. confirmado=true → bolinha verde; false → bolinha amarela.';

CREATE INDEX IF NOT EXISTS idx_eventos_cal_data    ON public_eventos_cal (data_evento);
CREATE INDEX IF NOT EXISTS idx_eventos_cal_visible ON public_eventos_cal (is_visible, data_evento);

ALTER TABLE public_eventos_cal ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS pub_eventos_select_visible ON public_eventos_cal;
  DROP POLICY IF EXISTS pub_eventos_auth_all       ON public_eventos_cal;
  EXCEPTION WHEN others THEN NULL;
END $$;

CREATE POLICY "pub_eventos_select_visible"
  ON public_eventos_cal FOR SELECT TO anon, authenticated
  USING (is_visible = true);

CREATE POLICY "pub_eventos_auth_all"
  ON public_eventos_cal FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

GRANT SELECT                            ON public_eventos_cal TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE    ON public_eventos_cal TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2) OBSERVAÇÕES E PRÁTICAS LOCAIS — PROTÓTIPOS METODOLÓGICOS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS proto_notes (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id       text NOT NULL,
  section_title    text DEFAULT '',
  author           text NOT NULL DEFAULT '',
  author_member_id uuid REFERENCES team_members (id) ON DELETE SET NULL,
  text             text NOT NULL DEFAULT '',
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE proto_notes IS
  'Observações e práticas locais registradas pela equipe em cada capítulo dos Protótipos Metodológicos. section_id corresponde ao id do protótipo no frontend (ex.: proto-p1, proto-p2 …).';

CREATE INDEX IF NOT EXISTS idx_proto_notes_section    ON proto_notes (section_id);
CREATE INDEX IF NOT EXISTS idx_proto_notes_created_at ON proto_notes (created_at DESC);

ALTER TABLE proto_notes ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS proto_notes_auth_all ON proto_notes;
  DROP POLICY IF EXISTS proto_notes_anon_sel ON proto_notes;
  EXCEPTION WHEN others THEN NULL;
END $$;

CREATE POLICY "proto_notes_auth_all"
  ON proto_notes FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

CREATE POLICY "proto_notes_anon_sel"
  ON proto_notes FOR SELECT TO anon
  USING (true);

GRANT SELECT                            ON proto_notes TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE    ON proto_notes TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3) SAFE ALTER — colunas que podem faltar em instâncias antigas
-- ─────────────────────────────────────────────────────────────────────────────

DO $$ BEGIN
  -- tasks.delivery_helper_id (v4+)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='tasks' AND column_name='delivery_helper_id'
  ) THEN
    ALTER TABLE tasks ADD COLUMN delivery_helper_id uuid
      REFERENCES team_members (id) ON DELETE SET NULL;
  END IF;

  -- tasks.start_date (v4+)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='tasks' AND column_name='start_date'
  ) THEN
    ALTER TABLE tasks ADD COLUMN start_date date;
  END IF;

  -- tasks.completed_at (v5+)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='tasks' AND column_name='completed_at'
  ) THEN
    ALTER TABLE tasks ADD COLUMN completed_at date;
  END IF;

  -- public_news.sort_order (v4+)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='public_news' AND column_name='sort_order'
  ) THEN
    ALTER TABLE public_news ADD COLUMN sort_order int DEFAULT 0;
  END IF;

  -- public_news.is_published (v4+)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='public_news' AND column_name='is_published'
  ) THEN
    ALTER TABLE public_news ADD COLUMN is_published boolean NOT NULL DEFAULT true;
  END IF;

  -- pontes.funcao (v5+)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='pontes' AND column_name='funcao'
  ) THEN
    BEGIN
      ALTER TABLE pontes ADD COLUMN funcao text DEFAULT '';
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4) SEED — Calendário inicial (idempotente)
-- ─────────────────────────────────────────────────────────────────────────────

-- Fase 0 — maio/2026
INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado)
SELECT 'Contato com Ouvidoria das Mulheres (MPDFT)', '2026-05-08', 'A confirmar',
       'MPDFT — Brasília/DF', 'articulacao',
       'Canal fixo de denúncias via QR Code nas rodas.', false
WHERE NOT EXISTS (
  SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%Ouvidoria das Mulheres%'
);

INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado)
SELECT 'Falar com Adalgiza — Núcleo de Gênero (MPDFT)', '2026-05-11', 'A confirmar',
       'MPDFT — Brasília/DF', 'articulacao',
       'Articulação Todas Elas; capacitação e encaminhamentos.', false
WHERE NOT EXISTS (
  SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%Adalgiza%'
);

INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado)
SELECT 'Reunião de alinhamento — equipe fundadora', '2026-05-12', 'A confirmar',
       'MPDFT — Brasília/DF', 'reuniao',
       'Alinhar visão, responsabilidades e cronograma.', false
WHERE NOT EXISTS (
  SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%alinhamento%equipe fundadora%'
);

INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado)
SELECT 'Apresentação à Secretaria da Mulher (DF)', '2026-05-14', 'A confirmar',
       'Secretaria da Mulher do DF', 'articulacao',
       'Apresentação institucional GDF/MPDFT.', false
WHERE NOT EXISTS (
  SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%Secretaria da Mulher%'
);

INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado)
SELECT 'Formalizar diálogo com IMS', '2026-05-16', 'A confirmar',
       'Instituto Mãos Solidárias — DF', 'reuniao',
       'Apresentar projeto e propor parceria para piloto.', false
WHERE NOT EXISTS (
  SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%diálogo com IMS%'
);

-- Fase 1 — jun–jul/2026
INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado)
SELECT '1ª turma de capacitação (piloto) — início', '2026-06-15', 'A definir',
       'Distrito Federal', 'capacitacao',
       '10–15 participantes, currículo de 40 horas. Fase 1.', false
WHERE NOT EXISTS (
  SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%1ª turma de capacitação%'
);

INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado)
SELECT 'Rodas-piloto — Instituto Mãos Solidárias', '2026-07-01', 'A definir',
       'IMS — DF', 'roda',
       'Meta: 8 sessões, 40+ mulheres. QR Code Ouvidoria MPDFT. Fase 1.', false
WHERE NOT EXISTS (
  SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%Rodas-piloto%IMS%'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- FIM — Validação rápida após execução:
--   SELECT count(*) FROM public_eventos_cal;  → ≥ 7
--   SELECT count(*) FROM proto_notes;         → 0 (populado pelo frontend)
--   \d proto_notes                            → ver colunas e FK
-- ─────────────────────────────────────────────────────────────────────────────

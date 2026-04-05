-- =============================================================================
-- REDE DE RODAS DO DF — SCHEMA COMPLETO FINAL (v7)
-- Sistema de Articulação, Apoio e Deliberação
-- PostgreSQL 15+ / Supabase
--
-- COBRE (23 tabelas)
--   team_members, partners, tasks (c/ delivery_helper_id, start_date, completed_at),
--   comments, activity_log, public_news,
--   forum_categories, forum_topics, forum_replies,
--   rede_servicos, rede_articulacoes, rede_ferramentas, rede_fluxos,
--   rede_legislacao, rede_publicacoes, rede_sites,
--   public_rodas_site, public_edital_site, public_eventos_cal,
--   pontes, proto_notes,
--   rodas_mapeadas, member_rodas
--
--   Índices, RLS, GRANTs, seeds (equipe, parceiros, tarefas, fórum,
--   rede de serviços, pontes, calendário público, site público,
--   levantamento de rodas existentes no DF)
--
-- COMO RODAR (instalação do zero)
--   1) Supabase → SQL Editor → New query → colar este arquivo → Run
--   2) Settings → API → copiar URL e anon key para o index.html
--   3) IF NOT EXISTS em todo lugar → seguro re-executar
--
-- ATUALIZAÇÃO DE INSTÂNCIA EXISTENTE
--   Rode sql/01_update_v6_proto_notes_eventos.sql em vez deste arquivo.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ═══════════════════════════════════════════════════════════════════
-- 1) TABELAS BASE
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS team_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text,
  organization text,
  role text NOT NULL DEFAULT 'voluntaria',
  avatar_color text DEFAULT '#7c3aed',
  expertise text[] NOT NULL DEFAULT '{}',
  is_active boolean NOT NULL DEFAULT true,
  notes text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS partners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  type text NOT NULL DEFAULT 'institucional',
  contact_person text DEFAULT '',
  status text NOT NULL DEFAULT 'pendente',
  contribution text DEFAULT '',
  receives text DEFAULT '',
  notes text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text DEFAULT '',
  phase text NOT NULL DEFAULT 'fase_0_semente',
  status text NOT NULL DEFAULT 'pendente',
  priority text NOT NULL DEFAULT 'media',
  assigned_to uuid REFERENCES team_members (id) ON DELETE SET NULL,
  delivery_helper_id uuid REFERENCES team_members (id) ON DELETE SET NULL,
  due_date date,
  start_date date,
  notes text DEFAULT '',
  completed_at date,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------
-- SAFE ALTER: adiciona colunas que podem faltar em tabelas antigas
-- ---------------------------------------------------------------
DO $$ BEGIN
  -- tasks.delivery_helper_id
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tasks' AND column_name='delivery_helper_id') THEN
    ALTER TABLE tasks ADD COLUMN delivery_helper_id uuid REFERENCES team_members (id) ON DELETE SET NULL;
  END IF;
  -- tasks.start_date
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tasks' AND column_name='start_date') THEN
    ALTER TABLE tasks ADD COLUMN start_date date;
  END IF;
  -- tasks.completed_at
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tasks' AND column_name='completed_at') THEN
    ALTER TABLE tasks ADD COLUMN completed_at date;
  END IF;
  -- public_news.sort_order
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='public_news' AND column_name='sort_order') THEN
    ALTER TABLE public_news ADD COLUMN sort_order int DEFAULT 0;
  END IF;
  -- public_news.is_published
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='public_news' AND column_name='is_published') THEN
    ALTER TABLE public_news ADD COLUMN is_published boolean NOT NULL DEFAULT true;
  END IF;
  -- pontes.funcao
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='pontes' AND column_name='funcao') THEN
    BEGIN ALTER TABLE pontes ADD COLUMN funcao text DEFAULT ''; EXCEPTION WHEN undefined_table THEN NULL; END;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL REFERENCES tasks (id) ON DELETE CASCADE,
  user_name text NOT NULL DEFAULT '',
  content text NOT NULL DEFAULT '',
  is_system boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS activity_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  user_name text,
  actor_name text,
  description text,
  action text,
  message text,
  detail text,
  entity_type text,
  task_id uuid REFERENCES tasks (id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS public_news (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  published_on date NOT NULL DEFAULT (CURRENT_DATE),
  title text NOT NULL,
  excerpt text DEFAULT '',
  body text DEFAULT '',
  image_url text DEFAULT '',
  is_published boolean NOT NULL DEFAULT true,
  sort_order int DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════
-- 2) FÓRUM — Sistema de Discussão (SAAD: Deliberação + Articulação)
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS forum_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  icon text DEFAULT '💬',
  color text DEFAULT '#7c3aed',
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS forum_topics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid NOT NULL REFERENCES forum_categories (id) ON DELETE CASCADE,
  title text NOT NULL,
  body text NOT NULL DEFAULT '',
  author_name text NOT NULL DEFAULT '',
  author_member_id uuid REFERENCES team_members (id) ON DELETE SET NULL,
  is_pinned boolean NOT NULL DEFAULT false,
  is_locked boolean NOT NULL DEFAULT false,
  view_count int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS forum_replies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id uuid NOT NULL REFERENCES forum_topics (id) ON DELETE CASCADE,
  body text NOT NULL DEFAULT '',
  author_name text NOT NULL DEFAULT '',
  author_member_id uuid REFERENCES team_members (id) ON DELETE SET NULL,
  parent_reply_id uuid REFERENCES forum_replies (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════
-- 3) REDE UNIFICADA — Serviços e Articulações Territoriais
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS rede_servicos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  tipo text NOT NULL DEFAULT 'outro',
  circunscricao text DEFAULT '',
  endereco text DEFAULT '',
  telefones text DEFAULT '',
  horario text DEFAULT '',
  frequencia text DEFAULT 'permanente',
  instituicao text DEFAULT '',
  responsavel text DEFAULT '',
  notas text DEFAULT '',
  status text NOT NULL DEFAULT 'ativo',
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE rede_servicos IS 'Serviços fixos: CEAM, Espaço Acolher, Comitê de Proteção, CRMB, Cepav, Delegacia, Casa da Mulher. tipo: ceam|espaco_acolher|comite_protecao|crmb|cepav|delegacia|casa_mulher|outro. status: ativo|em_formacao|inativo. frequencia: continuado|permanente|periodico|pontual.';

CREATE TABLE IF NOT EXISTS rede_articulacoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  nivel text NOT NULL DEFAULT 'territorial',
  circunscricoes text DEFAULT '',
  coordenacao text DEFAULT '',
  membros text DEFAULT '',
  base_legal text DEFAULT '',
  frequencia text DEFAULT '',
  contato text DEFAULT '',
  status_atual text DEFAULT '',
  notas text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE rede_articulacoes IS 'Comitês gestores, redes territoriais e articulações. nivel: federal|distrital|territorial.';

CREATE TABLE IF NOT EXISTS rede_ferramentas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  orgao text DEFAULT '',
  tipo text NOT NULL DEFAULT 'outro',
  url text DEFAULT '',
  funcao text DEFAULT '',
  novidades text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE rede_ferramentas IS 'Ferramentas digitais, SaaS, portais de dados, apps de proteção. tipo: portal_dados|sistema|plataforma_intel|dispositivo|app_mobile|portal_denuncia|portal_agendamento|formulario|portal_gis|outro.';

CREATE TABLE IF NOT EXISTS rede_fluxos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  abrangencia text DEFAULT '',
  status text NOT NULL DEFAULT 'em_formacao',
  referencia text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE rede_fluxos IS 'Fluxos de atendimento formalizados por circunscrição. status: consolidado|em_finalizacao|em_revisao|em_mobilizacao|em_formacao.';

CREATE TABLE IF NOT EXISTS rede_legislacao (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  norma text NOT NULL,
  data text DEFAULT '',
  conteudo text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE rede_legislacao IS 'Legislação relevante 2024-2026: leis, decretos, portarias e PLs.';

CREATE TABLE IF NOT EXISTS rede_publicacoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo text NOT NULL,
  orgao text DEFAULT '',
  data text DEFAULT '',
  tipo text NOT NULL DEFAULT 'outro',
  url text DEFAULT '',
  nota text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE rede_publicacoes IS 'Publicações, relatórios, guias e cartilhas. tipo: relatorio|guia|nota_tecnica|cartilha|catalogo|plataforma|outro.';

CREATE TABLE IF NOT EXISTS rede_sites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  orgao text DEFAULT '',
  url text DEFAULT '',
  descricao text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE rede_sites IS 'Sites e portais institucionais de referência.';

-- ═══════════════════════════════════════════════════════════════════
-- 4) SITE PÚBLICO — Rodas, Encontros e Edital de Capacitação
-- ═══════════════════════════════════════════════════════════════════

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
COMMENT ON TABLE public_rodas_site IS 'Cards «Rodas e encontros» exibidos na página pública. is_visible controla se o visitante vê o card.';

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
COMMENT ON TABLE public_edital_site IS 'Singleton (id=1). Texto do edital de capacitação na página pública.';

INSERT INTO public_edital_site (id) VALUES (1)
ON CONFLICT (id) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════
-- 4b) CALENDÁRIO PÚBLICO DE EVENTOS
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public_eventos_cal (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo text NOT NULL DEFAULT '',
  data_evento date NOT NULL,
  hora text DEFAULT '',
  local text DEFAULT '',
  tipo text NOT NULL DEFAULT 'outro'
    CHECK (tipo IN ('reuniao','roda','capacitacao','articulacao','outro')),
  descricao text DEFAULT '',
  confirmado boolean NOT NULL DEFAULT false,
  is_visible boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public_eventos_cal IS
  'Calendário de eventos exibido na página pública. confirmado = true → bolinha verde; false → bolinha amarela.';

-- ═══════════════════════════════════════════════════════════════════
-- 5) PONTES — Articulações Institucionais (aba Pontes no painel)
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pontes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  grupo text DEFAULT '',
  funcao text DEFAULT '',
  ponte text NOT NULL DEFAULT '',
  responsavel text NOT NULL DEFAULT '',
  notas text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE pontes IS 'Articulações institucionais da rede — cada registro é uma «ponte» com órgão, rede ou parceiro, agrupada por eixo (grupo).';

-- ═══════════════════════════════════════════════════════════════════
-- 5c) OBSERVAÇÕES E PRÁTICAS LOCAIS — PROTÓTIPOS METODOLÓGICOS
-- ═══════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════
-- 5d) MAPEAMENTO DE RODAS EXISTENTES NO DF
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS rodas_mapeadas (
  id               uuid  PRIMARY KEY DEFAULT gen_random_uuid(),
  nome             text  NOT NULL DEFAULT '',
  tipo             text  NOT NULL DEFAULT 'outro'
    CHECK (tipo IN (
      'espaco_acolher','ceam','crmb','cepav',
      'direito_delas','comite_protecao','casa_mulher',
      'rede_territorial','projeto','outro'
    )),
  instituicao      text  DEFAULT '',
  circunscricao    text  NOT NULL DEFAULT '',
  endereco         text  DEFAULT '',
  telefone         text  DEFAULT '',
  email            text  DEFAULT '',
  horario          text  DEFAULT '',
  frequencia       text  NOT NULL DEFAULT 'permanente'
    CHECK (frequencia IN ('permanente','mensal','semanal','quinzenal','pontual','a_confirmar')),
  descricao        text  DEFAULT '',
  cobertura        text  DEFAULT '',
  confirmado_rede  boolean NOT NULL DEFAULT false,
  is_visible       boolean NOT NULL DEFAULT true,
  sort_order       int   NOT NULL DEFAULT 0,
  created_at       timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE rodas_mapeadas IS
  'Equipamentos e iniciativas permanentes de apoio a mulheres no DF — levantamento Rodas DF (abril/2026). confirmado_rede=true indica que a rede local confirmou os dados.';

CREATE TABLE IF NOT EXISTS member_rodas (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id  uuid NOT NULL REFERENCES team_members  (id) ON DELETE CASCADE,
  roda_id    uuid NOT NULL REFERENCES rodas_mapeadas (id) ON DELETE CASCADE,
  papel      text DEFAULT 'participante',
  notas      text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (member_id, roda_id)
);
COMMENT ON TABLE member_rodas IS
  'Vínculo entre membros da equipe e rodas/equipamentos mapeados. Indica que o membro conhece, articula ou participa daquele espaço.';

-- ═══════════════════════════════════════════════════════════════════
-- 6) ÍNDICES
-- ═══════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_eventos_cal_data       ON public_eventos_cal (data_evento);
CREATE INDEX IF NOT EXISTS idx_eventos_cal_visible     ON public_eventos_cal (is_visible, data_evento);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to     ON tasks (assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_delivery_helper  ON tasks (delivery_helper_id);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date         ON tasks (due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_phase            ON tasks (phase);
CREATE INDEX IF NOT EXISTS idx_comments_task_id       ON comments (task_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_created   ON activity_log (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_log_entity    ON activity_log (entity_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_forum_topics_cat       ON forum_topics (category_id);
CREATE INDEX IF NOT EXISTS idx_forum_topics_pinned    ON forum_topics (is_pinned DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_forum_replies_topic    ON forum_replies (topic_id, created_at);
CREATE INDEX IF NOT EXISTS idx_rede_servicos_tipo     ON rede_servicos (tipo);
CREATE INDEX IF NOT EXISTS idx_rede_servicos_circ     ON rede_servicos (circunscricao);
CREATE INDEX IF NOT EXISTS idx_rede_artic_nivel       ON rede_articulacoes (nivel);
CREATE INDEX IF NOT EXISTS idx_rede_ferramentas_tipo   ON rede_ferramentas (tipo);
CREATE INDEX IF NOT EXISTS idx_rede_fluxos_status      ON rede_fluxos (status);
CREATE INDEX IF NOT EXISTS idx_rede_publicacoes_tipo   ON rede_publicacoes (tipo);
CREATE INDEX IF NOT EXISTS idx_public_rodas_site_sort  ON public_rodas_site (sort_order);
CREATE INDEX IF NOT EXISTS idx_pontes_grupo            ON pontes (grupo);
CREATE INDEX IF NOT EXISTS idx_proto_notes_section     ON proto_notes (section_id);
CREATE INDEX IF NOT EXISTS idx_proto_notes_created     ON proto_notes (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rodas_mapeadas_circ     ON rodas_mapeadas (circunscricao);
CREATE INDEX IF NOT EXISTS idx_rodas_mapeadas_tipo     ON rodas_mapeadas (tipo);
CREATE INDEX IF NOT EXISTS idx_rodas_mapeadas_vis      ON rodas_mapeadas (is_visible, circunscricao);
CREATE INDEX IF NOT EXISTS idx_member_rodas_member     ON member_rodas (member_id);
CREATE INDEX IF NOT EXISTS idx_member_rodas_roda       ON member_rodas (roda_id);

-- ═══════════════════════════════════════════════════════════════════
-- 7) ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE team_members      ENABLE ROW LEVEL SECURITY;
ALTER TABLE partners          ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks             ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments          ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_news       ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_categories  ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_topics      ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_replies     ENABLE ROW LEVEL SECURITY;
ALTER TABLE rede_servicos     ENABLE ROW LEVEL SECURITY;
ALTER TABLE rede_articulacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE rede_ferramentas  ENABLE ROW LEVEL SECURITY;
ALTER TABLE rede_fluxos       ENABLE ROW LEVEL SECURITY;
ALTER TABLE rede_legislacao   ENABLE ROW LEVEL SECURITY;
ALTER TABLE rede_publicacoes  ENABLE ROW LEVEL SECURITY;
ALTER TABLE rede_sites        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_rodas_site ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_edital_site ENABLE ROW LEVEL SECURITY;
ALTER TABLE pontes             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_eventos_cal ENABLE ROW LEVEL SECURITY;
ALTER TABLE proto_notes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE rodas_mapeadas     ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_rodas       ENABLE ROW LEVEL SECURITY;

-- Limpa nomes anteriores se reexecutar
DO $$ DECLARE _t text; _p text;
BEGIN
  FOR _t, _p IN
    VALUES
      ('team_members','rrdf_auth_all_team'),('team_members','rrdf_anon_all_team'),
      ('partners','rrdf_auth_all_partners'),('partners','rrdf_anon_all_partners'),
      ('tasks','rrdf_auth_all_tasks'),('tasks','rrdf_anon_all_tasks'),
      ('comments','rrdf_auth_all_comments'),('comments','rrdf_anon_all_comments'),
      ('activity_log','rrdf_auth_all_activity'),('activity_log','rrdf_anon_all_activity'),
      ('public_news','public_news_select_published'),('public_news','public_news_auth_all'),
      ('forum_categories','rrdf_auth_forum_cat'),('forum_categories','rrdf_anon_forum_cat'),
      ('forum_topics','rrdf_auth_forum_topic'),('forum_topics','rrdf_anon_forum_topic'),
      ('forum_replies','rrdf_auth_forum_reply'),('forum_replies','rrdf_anon_forum_reply'),
      ('rede_servicos','rrdf_auth_rede_serv'),('rede_servicos','rrdf_anon_rede_serv'),
      ('rede_articulacoes','rrdf_auth_rede_art'),('rede_articulacoes','rrdf_anon_rede_art'),
      ('rede_ferramentas','rrdf_auth_rede_ferr'),('rede_ferramentas','rrdf_anon_rede_ferr'),
      ('rede_fluxos','rrdf_auth_rede_flux'),('rede_fluxos','rrdf_anon_rede_flux'),
      ('rede_legislacao','rrdf_auth_rede_leg'),('rede_legislacao','rrdf_anon_rede_leg'),
      ('rede_publicacoes','rrdf_auth_rede_pub'),('rede_publicacoes','rrdf_anon_rede_pub'),
      ('rede_sites','rrdf_auth_rede_site'),('rede_sites','rrdf_anon_rede_site'),
      ('public_rodas_site','public_rodas_site_select_visible'),('public_rodas_site','public_rodas_site_auth_all'),
      ('public_edital_site','public_edital_site_select'),('public_edital_site','public_edital_site_auth_all'),
      ('pontes','rrdf_auth_pontes'),('pontes','rrdf_anon_pontes'),
      ('public_eventos_cal','pub_eventos_select_visible'),('public_eventos_cal','pub_eventos_auth_all'),
      ('proto_notes','proto_notes_auth_all'),('proto_notes','proto_notes_anon_sel'),
      ('rodas_mapeadas','rodas_mapeadas_auth_all'),('rodas_mapeadas','rodas_mapeadas_anon_sel'),
      ('member_rodas','member_rodas_auth_all'),('member_rodas','member_rodas_anon_sel')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', _p, _t);
  END LOOP;
END $$;

CREATE POLICY "rrdf_auth_all_team"     ON team_members     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_team"     ON team_members     FOR ALL TO anon         USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_auth_all_partners" ON partners         FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_partners" ON partners         FOR ALL TO anon         USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_auth_all_tasks"    ON tasks            FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_tasks"    ON tasks            FOR ALL TO anon         USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_auth_all_comments" ON comments         FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_comments" ON comments         FOR ALL TO anon         USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_auth_all_activity" ON activity_log     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_activity" ON activity_log     FOR ALL TO anon         USING (true) WITH CHECK (true);

CREATE POLICY "public_news_select_published" ON public_news FOR SELECT TO anon, authenticated USING (is_published = true);
CREATE POLICY "public_news_auth_all"         ON public_news FOR ALL    TO authenticated      USING (true) WITH CHECK (true);

CREATE POLICY "rrdf_auth_forum_cat"   ON forum_categories FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_forum_cat"   ON forum_categories FOR SELECT TO anon USING (true);
CREATE POLICY "rrdf_auth_forum_topic" ON forum_topics     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_forum_topic" ON forum_topics     FOR SELECT TO anon USING (true);
CREATE POLICY "rrdf_auth_forum_reply" ON forum_replies    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_forum_reply" ON forum_replies    FOR SELECT TO anon USING (true);

CREATE POLICY "rrdf_auth_rede_serv"   ON rede_servicos     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_rede_serv"   ON rede_servicos     FOR SELECT TO anon USING (true);
CREATE POLICY "rrdf_auth_rede_art"    ON rede_articulacoes FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_rede_art"    ON rede_articulacoes FOR SELECT TO anon USING (true);

CREATE POLICY "rrdf_auth_rede_ferr"  ON rede_ferramentas  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_rede_ferr"  ON rede_ferramentas  FOR SELECT TO anon USING (true);
CREATE POLICY "rrdf_auth_rede_flux"  ON rede_fluxos       FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_rede_flux"  ON rede_fluxos       FOR SELECT TO anon USING (true);
CREATE POLICY "rrdf_auth_rede_leg"   ON rede_legislacao   FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_rede_leg"   ON rede_legislacao   FOR SELECT TO anon USING (true);
CREATE POLICY "rrdf_auth_rede_pub"   ON rede_publicacoes  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_rede_pub"   ON rede_publicacoes  FOR SELECT TO anon USING (true);
CREATE POLICY "rrdf_auth_rede_site"  ON rede_sites        FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_rede_site"  ON rede_sites        FOR SELECT TO anon USING (true);

CREATE POLICY "public_rodas_site_select_visible" ON public_rodas_site FOR SELECT TO anon, authenticated USING (is_visible = true);
CREATE POLICY "public_rodas_site_auth_all"       ON public_rodas_site FOR ALL    TO authenticated      USING (true) WITH CHECK (true);

CREATE POLICY "public_edital_site_select"   ON public_edital_site FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "public_edital_site_auth_all" ON public_edital_site FOR ALL    TO authenticated      USING (true) WITH CHECK (true);

CREATE POLICY "rrdf_auth_pontes" ON pontes FOR ALL    TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_pontes" ON pontes FOR SELECT TO anon USING (true);

CREATE POLICY "pub_eventos_select_visible" ON public_eventos_cal FOR SELECT TO anon, authenticated USING (is_visible = true);
CREATE POLICY "pub_eventos_auth_all"       ON public_eventos_cal FOR ALL    TO authenticated      USING (true) WITH CHECK (true);

CREATE POLICY "proto_notes_auth_all"    ON proto_notes    FOR ALL    TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "proto_notes_anon_sel"    ON proto_notes    FOR SELECT TO anon          USING (true);
CREATE POLICY "rodas_mapeadas_auth_all" ON rodas_mapeadas FOR ALL    TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rodas_mapeadas_anon_sel" ON rodas_mapeadas FOR SELECT TO anon          USING (is_visible = true);
CREATE POLICY "member_rodas_auth_all"   ON member_rodas   FOR ALL    TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "member_rodas_anon_sel"   ON member_rodas   FOR SELECT TO anon          USING (true);

-- ═══════════════════════════════════════════════════════════════════
-- 8) GRANTS
-- ═══════════════════════════════════════════════════════════════════

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON
  team_members, partners, tasks, comments, activity_log,
  forum_categories, forum_topics, forum_replies,
  rede_servicos, rede_articulacoes,
  rede_ferramentas, rede_fluxos, rede_legislacao, rede_publicacoes, rede_sites,
  pontes
TO anon, authenticated;
GRANT SELECT ON public_news TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public_news TO authenticated;
GRANT SELECT ON public_rodas_site TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public_rodas_site TO authenticated;
GRANT SELECT ON public_edital_site TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public_edital_site TO authenticated;
GRANT SELECT ON public_eventos_cal TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public_eventos_cal TO authenticated;
GRANT SELECT ON proto_notes TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON proto_notes TO authenticated;
GRANT SELECT ON rodas_mapeadas TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON rodas_mapeadas TO authenticated;
GRANT SELECT ON member_rodas TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON member_rodas TO authenticated;

-- ═══════════════════════════════════════════════════════════════════
-- 9) SEED — Equipe
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO team_members (name, email, organization, role, avatar_color, expertise, is_active, notes) SELECT 'Natalie', NULL, 'Rede de Rodas do DF', 'coordenadora', '#e11d48', ARRAY['direito','articulacao']::text[], true, 'Advogada. Coordenadora de execução da Rede de Rodas do DF. Participa de rodas de conversa no DF. Autora dos protótipos metodológicos.' WHERE NOT EXISTS (SELECT 1 FROM team_members WHERE name='Natalie');
INSERT INTO team_members (name, email, organization, role, avatar_color, expertise, is_active, notes) SELECT 'Thaís', NULL, 'MPDFT', 'coordenadora', '#7c3aed', ARRAY['direito','articulacao_institucional']::text[], true, 'Coordenação MPDFT e articulação institucional.' WHERE NOT EXISTS (SELECT 1 FROM team_members WHERE name='Thaís');
INSERT INTO team_members (name, email, organization, role, avatar_color, expertise, is_active, notes) SELECT 'Giselle', 'giselle.trevizo@gmail.com', 'MPDFT', 'apoio_tecnico', '#2563eb', ARRAY['tecnologia','desenvolvimento','formacao']::text[], true, 'Apoio tecnológico ao painel e ferramentas digitais.' WHERE NOT EXISTS (SELECT 1 FROM team_members WHERE name='Giselle');
INSERT INTO team_members (name, email, organization, role, avatar_color, expertise, is_active, notes) SELECT 'Cândida', NULL, 'UNB', 'docente', '#059669', ARRAY['psicologia']::text[], true, 'Professora Psicologia UNB.' WHERE NOT EXISTS (SELECT 1 FROM team_members WHERE name='Cândida');
INSERT INTO team_members (name, email, organization, role, avatar_color, expertise, is_active, notes) SELECT 'Laura', NULL, 'A confirmar', 'docente', '#d97706', ARRAY['psicologia']::text[], true, 'Psicóloga. Contato via Natalie.' WHERE NOT EXISTS (SELECT 1 FROM team_members WHERE name='Laura');
INSERT INTO team_members (name, email, organization, role, avatar_color, expertise, is_active, notes) SELECT 'Márcia', NULL, 'IML', 'docente', '#0891b2', ARRAY['psicologia']::text[], true, 'Psicóloga IML. Contribuição técnica pontual.' WHERE NOT EXISTS (SELECT 1 FROM team_members WHERE name='Márcia');

-- ═══════════════════════════════════════════════════════════════════
-- 10) SEED — Parceiros
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes) SELECT 'MPDFT', 'institucional', 'Thaís', 'em_andamento', 'Espaço físico, apoio técnico, co-certificação', 'Ampliação rede de proteção, dados de mapeamento', 'Parceiro principal.' WHERE NOT EXISTS (SELECT 1 FROM partners WHERE name ILIKE 'MPDFT');
INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes) SELECT 'Instituto Mãos Solidárias (IMS)', 'ong_parceira', '—', 'pendente', 'Casas sociais com mulheres; espaço para rodas-piloto', 'Rodas de acolhimento para beneficiárias', 'Local do piloto.' WHERE NOT EXISTS (SELECT 1 FROM partners WHERE name ILIKE '%Mãos Solidárias%');
INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes) SELECT 'UNB — Pós-graduação Psicologia', 'academico', 'Thaís', 'pendente', 'Estudantes facilitadoras; validação de horas', 'Campo de prática; dados para pesquisa', 'Parceria em negociação.' WHERE NOT EXISTS (SELECT 1 FROM partners WHERE name ILIKE '%UNB%Psicologia%');
INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes) SELECT 'Ouvidoria das Mulheres — MPDFT', 'institucional', '(a identificar)', 'pendente', 'Canal fixo de denúncias via QR Code nas rodas', 'Denúncias qualificadas; capilaridade', 'QR Code obrigatório em toda roda.' WHERE NOT EXISTS (SELECT 1 FROM partners WHERE name ILIKE '%Ouvidoria das Mulheres%');
INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes) SELECT 'Núcleo de Gênero — MPDFT', 'institucional', 'Adalgiza', 'pendente', 'Políticas de gênero, ponte com Todas Elas', 'Integração com rede de proteção', 'Thaís articula.' WHERE NOT EXISTS (SELECT 1 FROM partners WHERE name ILIKE '%Núcleo de Gênero%');
INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes) SELECT 'Projeto Maria da Penha — MPDFT', 'institucional', 'Lívia Gimines', 'pendente', 'Interface com políticas Maria da Penha', 'Convergência com capacitação e rodas', 'Natalie retoma quando estruturado.' WHERE NOT EXISTS (SELECT 1 FROM partners WHERE name ILIKE '%Maria da Penha%');
INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes) SELECT 'Secretaria da Mulher do DF (SMDF)', 'institucional', 'Sec. Giselle Ferreira', 'pendente', 'Políticas públicas, CEAMs, Espaços Acolher, Comitês de Proteção', 'Capilaridade territorial das rodas', 'Articulação via Thaís (MPDFT).' WHERE NOT EXISTS (SELECT 1 FROM partners WHERE name ILIKE '%Secretaria da Mulher%');
INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes) SELECT 'TJDFT — NJM/CMVD', 'institucional', 'Amanda Rabêlo / Juíza Luciana Rocha', 'pendente', 'Rede de Proteção, Semanas Paz em Casa, Ouvidoria para Elas', 'Encaminhamentos qualificados via rodas', 'Coord. Amanda Rabêlo de Mesquita Pelles.' WHERE NOT EXISTS (SELECT 1 FROM partners WHERE name ILIKE '%TJDFT%NJM%');
INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes) SELECT 'Sejus-DF — Programa Direito Delas', 'institucional', 'Sec. Marcela Passamani', 'pendente', '11 núcleos de atendimento jurídico nas RAs', 'Integração com rodas para encaminhamento jurídico', 'Direito Delas: 11 postos em RAs diversas.' WHERE NOT EXISTS (SELECT 1 FROM partners WHERE name ILIKE '%Direito Delas%');
INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes) SELECT 'DPDF — Nudem', 'institucional', 'Coord. Nudem', 'pendente', 'Assistência jurídica especializada, Campanha Entrelace, Dia da Mulher mensal', 'Encaminhamentos diretos via rodas', 'Central DPDF: 129 / WhatsApp (61) 99359-0072.' WHERE NOT EXISTS (SELECT 1 FROM partners WHERE name ILIKE '%DPDF%Nudem%');

-- ═══════════════════════════════════════════════════════════════════
-- 11) SEED — Tarefas representativas
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO tasks (title, phase, status, priority, assigned_to, due_date, notes) SELECT 'Organizar atuação inicial como pessoas físicas', 'fase_0_semente', 'pendente', 'urgente', m.id, '2026-05-20', 'Fase 0. Atuação inicial como pessoas físicas.' FROM team_members m WHERE m.name='Natalie' AND NOT EXISTS (SELECT 1 FROM tasks WHERE title ILIKE '%pessoas físicas%') LIMIT 1;
INSERT INTO tasks (title, phase, status, priority, assigned_to, due_date, start_date, notes) SELECT 'Organizar estrutura do curso', 'fase_0_semente', 'em_andamento', 'urgente', m.id, '2026-06-10', '2026-05-01', 'Currículo 40 h. Módulo Psicologia/UNB: Cândida. Módulo violência: Márcia pontual.' FROM team_members m WHERE m.name='Thaís' AND NOT EXISTS (SELECT 1 FROM tasks WHERE title='Organizar estrutura do curso') LIMIT 1;
INSERT INTO tasks (title, phase, status, priority, assigned_to, due_date, notes) SELECT 'Apresentar projeto à Secretaria da Mulher (DF)', 'fase_0_semente', 'pendente', 'urgente', m.id, '2026-05-14', 'Articulação GDF/MPDFT.' FROM team_members m WHERE m.name='Thaís' AND NOT EXISTS (SELECT 1 FROM tasks WHERE title ILIKE '%Secretaria da Mulher%') LIMIT 1;
INSERT INTO tasks (title, phase, status, priority, assigned_to, due_date, start_date, notes) SELECT '1ª turma de capacitação (piloto)', 'fase_1_piloto', 'pendente', 'alta', m.id, '2026-07-20', '2026-06-15', 'Fase 2 — jun–jul/2026. 10-15 participantes, 40 h.' FROM team_members m WHERE m.name='Thaís' AND NOT EXISTS (SELECT 1 FROM tasks WHERE title ILIKE '%1ª turma de capacitação%') LIMIT 1;
INSERT INTO tasks (title, phase, status, priority, assigned_to, due_date, start_date, notes) SELECT 'Implantar rodas-piloto no IMS', 'fase_1_piloto', 'pendente', 'alta', m.id, '2026-08-05', '2026-07-01', 'Fase 2 — jul–ago/2026. Meta: 8 sessões, 40+ mulheres. QR Ouvidoria.' FROM team_members m WHERE m.name='Natalie' AND NOT EXISTS (SELECT 1 FROM tasks WHERE title ILIKE '%rodas-piloto no IMS%') LIMIT 1;
INSERT INTO tasks (title, phase, status, priority, assigned_to, due_date, notes) SELECT 'Falar com Adalgiza — Núcleo de Gênero (MPDFT)', 'fase_0_semente', 'pendente', 'alta', m.id, '2026-05-11', 'Articular com Adalgiza: apresentar a Rede, alinhar capacitação. Ponte com Todas Elas.' FROM team_members m WHERE m.name='Thaís' AND NOT EXISTS (SELECT 1 FROM tasks WHERE title ILIKE '%Adalgiza%') LIMIT 1;
INSERT INTO tasks (title, phase, status, priority, assigned_to, due_date, notes) SELECT 'Formalizar diálogo com IMS', 'fase_0_semente', 'pendente', 'alta', m.id, '2026-05-16', 'Fase 0 — mai/2026. Casas sociais com mulheres. Responsável: Thaís.' FROM team_members m WHERE m.name='Thaís' AND NOT EXISTS (SELECT 1 FROM tasks WHERE title ILIKE '%Formalizar diálogo com IMS%') LIMIT 1;
INSERT INTO tasks (title, phase, status, priority, assigned_to, due_date, notes) SELECT 'Termo de Cooperação MPDFT', 'fase_2_enraizamento', 'pendente', 'alta', m.id, '2026-08-25', 'Fase 3 — ago/2026. Thaís articula.' FROM team_members m WHERE m.name='Thaís' AND NOT EXISTS (SELECT 1 FROM tasks WHERE title ILIKE '%Termo de Cooperação MPDFT%') LIMIT 1;
INSERT INTO tasks (title, phase, status, priority, assigned_to, due_date, notes) SELECT 'Fase final: consolidar fluxo e plano de novas rodas', 'fase_5_sustentabilidade', 'pendente', 'alta', m.id, '2026-10-25', 'Pós-piloto — out/2026. Fluxo, rede, novas rodas para demanda reprimida.' FROM team_members m WHERE m.name='Thaís' AND NOT EXISTS (SELECT 1 FROM tasks WHERE title ILIKE '%Fase final%consolidar%') LIMIT 1;

-- ═══════════════════════════════════════════════════════════════════
-- 11b) SEED — Calendário de eventos (public_eventos_cal)
-- ═══════════════════════════════════════════════════════════════════
-- Fase 0 — mai/2026 (reuniões e articulações iniciais)
INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado) SELECT 'Contato com Ouvidoria das Mulheres (MPDFT)', '2026-05-08', 'A confirmar', 'MPDFT — Brasília/DF', 'articulacao', 'Canal fixo de denúncias via QR Code nas rodas.', false WHERE NOT EXISTS (SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%Ouvidoria das Mulheres%');
INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado) SELECT 'Falar com Adalgiza — Núcleo de Gênero (MPDFT)', '2026-05-11', 'A confirmar', 'MPDFT — Brasília/DF', 'articulacao', 'Articulação Todas Elas; capacitação e encaminhamentos.', false WHERE NOT EXISTS (SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%Adalgiza%');
INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado) SELECT 'Reunião de alinhamento — equipe fundadora', '2026-05-12', 'A confirmar', 'MPDFT — Brasília/DF', 'reuniao', 'Alinhar visão, responsabilidades e cronograma.', false WHERE NOT EXISTS (SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%alinhamento%equipe fundadora%');
INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado) SELECT 'Apresentação à Secretaria da Mulher (DF)', '2026-05-14', 'A confirmar', 'Secretaria da Mulher do DF', 'articulacao', 'Apresentação institucional GDF/MPDFT.', false WHERE NOT EXISTS (SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%Secretaria da Mulher%');
INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado) SELECT 'Formalizar diálogo com IMS', '2026-05-16', 'A confirmar', 'Instituto Mãos Solidárias — DF', 'reuniao', 'Apresentar projeto e propor parceria para piloto.', false WHERE NOT EXISTS (SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%diálogo com IMS%');
-- Fase 1 — ago–set/2026
INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado) SELECT '1ª turma de capacitação (piloto) — início', '2026-06-15', 'A definir', 'Distrito Federal', 'capacitacao', '10–15 participantes, currículo de 40 horas. Fase 2.', false WHERE NOT EXISTS (SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%1ª turma de capacitação%');
INSERT INTO public_eventos_cal (titulo, data_evento, hora, local, tipo, descricao, confirmado) SELECT 'Rodas-piloto — Instituto Mãos Solidárias', '2026-07-01', 'A definir', 'IMS — DF', 'roda', 'Meta: 8 sessões, 40+ mulheres. QR Code Ouvidoria MPDFT. Fase 2.', false WHERE NOT EXISTS (SELECT 1 FROM public_eventos_cal WHERE titulo ILIKE '%Rodas-piloto%IMS%');

-- ═══════════════════════════════════════════════════════════════════
-- 12) SEED — Categorias do Fórum
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO forum_categories (name, description, icon, color, sort_order) SELECT 'Informativo', 'Comunicados, avisos e atualizações oficiais da rede', '📢', '#7c3aed', 1 WHERE NOT EXISTS (SELECT 1 FROM forum_categories WHERE name='Informativo');
INSERT INTO forum_categories (name, description, icon, color, sort_order) SELECT 'Articulação', 'Coordenação entre serviços, parceiros e territórios', '🤝', '#2563eb', 2 WHERE NOT EXISTS (SELECT 1 FROM forum_categories WHERE name='Articulação');
INSERT INTO forum_categories (name, description, icon, color, sort_order) SELECT 'Deliberação', 'Decisões coletivas, votações e encaminhamentos do grupo', '⚖️', '#059669', 3 WHERE NOT EXISTS (SELECT 1 FROM forum_categories WHERE name='Deliberação');
INSERT INTO forum_categories (name, description, icon, color, sort_order) SELECT 'Capacitação', 'Materiais, dúvidas e troca de experiências sobre formação', '📚', '#d97706', 4 WHERE NOT EXISTS (SELECT 1 FROM forum_categories WHERE name='Capacitação');
INSERT INTO forum_categories (name, description, icon, color, sort_order) SELECT 'Livre', 'Espaço aberto para qualquer assunto da equipe', '💬', '#78716c', 5 WHERE NOT EXISTS (SELECT 1 FROM forum_categories WHERE name='Livre');

-- ═══════════════════════════════════════════════════════════════════
-- 13) SEED — Tópicos do Fórum
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO forum_topics (category_id, title, body, author_name, is_pinned) SELECT c.id, 'Bem-vindas ao fórum da Rede de Rodas do DF', 'Este é o espaço de discussão e deliberação da equipe. Use as categorias para organizar os assuntos: Informativo para comunicados, Articulação para coordenação entre serviços, Deliberação para decisões coletivas, Capacitação para formação e Livre para tudo mais.', 'Natalie', true FROM forum_categories c WHERE c.name='Informativo' AND NOT EXISTS (SELECT 1 FROM forum_topics WHERE title ILIKE '%Bem-vindas ao fórum%') LIMIT 1;
INSERT INTO forum_topics (category_id, title, body, author_name) SELECT c.id, 'Calendário de contatos institucionais — maio/2026', 'Precisamos alinhar a ordem dos contatos para não sobrecarregar os mesmos interlocutores. Proposta: Secretaria da Mulher (Thaís, até 14/mai), Ouvidoria MPDFT (Thaís, até 08/mai), Adalgiza/NG (Thaís, até 11/mai), IMS (Natalie, até 16/mai). Comentem se discordarem.', 'Thaís' FROM forum_categories c WHERE c.name='Articulação' AND NOT EXISTS (SELECT 1 FROM forum_topics WHERE title ILIKE '%Calendário de contatos%') LIMIT 1;
INSERT INTO forum_topics (category_id, title, body, author_name) SELECT c.id, 'Formato do módulo de Psicologia — sugestões', 'A Cândida (UNB) ainda não confirmou. Se confirmar: 12 h teóricas + 4 h práticas (simulação de roda). Se não: precisamos de um plano B. Laura pode cobrir a parte prática? Ideias?', 'Thaís' FROM forum_categories c WHERE c.name='Capacitação' AND NOT EXISTS (SELECT 1 FROM forum_topics WHERE title ILIKE '%módulo de Psicologia%') LIMIT 1;

-- ═══════════════════════════════════════════════════════════════════
-- 14) SEED — Serviços da Rede (CEAMs, Espaços Acolher, Comitês, CRMBs, DEAMs, Cepav, Casa da Mulher)
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'CEAM 102 Sul', 'ceam', 'Plano Piloto', 'Estação Metrô 102 Sul, Asa Sul', '(61) 3181-2245 / 99183-6454', 'Seg–Sex 8h–18h', 'continuado', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='CEAM 102 Sul');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'CEAM Planaltina', 'ceam', 'Planaltina', 'Jardim Roriz, AE (Entrequadras 1 e 2, Lt.3/5)', '(61) 3181-2249 / 99202-6376', 'Seg–Sex 8h–18h', 'continuado', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='CEAM Planaltina');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'CEAM IV (CIOB)', 'ceam', 'Plano Piloto', 'SDN Conj. A, Ed. Sede do CIOB', '(61) 3181-2251 / 98199-1198', 'Seg–Sex 8h–18h', 'continuado', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='CEAM IV (CIOB)');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Casa da Mulher Brasileira', 'casa_mulher', 'Ceilândia', 'CNM 1, Bl. I, Lt. 3, CEP 72215-110', '(61) 3181-1474 / 3181-2232 / 3181-2233', '24 h, 7 dias', 'continuado', 'SMDF / Gov. Federal', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='Casa da Mulher Brasileira');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Casa Abrigo (endereço sigiloso)', 'outro', 'Sigiloso', 'Endereço sigiloso', '(61) 3181-1445 (via SMDF)', '24 h ininterrupto', 'continuado', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome ILIKE '%Casa Abrigo%');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Espaço Acolher — Plano Piloto', 'espaco_acolher', 'Plano Piloto', 'Fórum SMAS Tr.3, Lt.4/6, Bl.5, Térreo', '(61) 3181-2236 / 99323-6567', 'Seg–Sex', 'continuado', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='Espaço Acolher — Plano Piloto');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Espaço Acolher — Brazlândia', 'espaco_acolher', 'Brazlândia', 'Fórum de Brazlândia, AE 04, 1º andar', '(61) 3181-2236 / 99103-0058', 'Seg–Sex', 'continuado', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='Espaço Acolher — Brazlândia');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Espaço Acolher — Ceilândia', 'espaco_acolher', 'Ceilândia', 'QNM 02, Conj. F, Lt.1/3', '(61) 3181-2240 / 98314-0882', 'Seg–Sex', 'continuado', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='Espaço Acolher — Ceilândia');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Espaço Acolher — Gama', 'espaco_acolher', 'Gama', 'Promotoria do Gama, Q.01, Lt.860/800, Subsolo', '(61) 3181-2239', 'Seg–Sex', 'continuado', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='Espaço Acolher — Gama');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Espaço Acolher — Paranoá', 'espaco_acolher', 'Paranoá', 'Promotoria de Justiça do Paranoá, Q.04, Conj. B, Sl.111', '(61) 3181-2249', 'Seg–Sex', 'continuado', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='Espaço Acolher — Paranoá');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Espaço Acolher — Planaltina', 'espaco_acolher', 'Planaltina', 'Promotoria de Planaltina, AE 10/A, Térreo', '(61) 3388-1095 / 3181-2242', 'Seg–Sex', 'continuado', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='Espaço Acolher — Planaltina');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Espaço Acolher — Santa Maria', 'espaco_acolher', 'Santa Maria', 'Promotoria de Santa Maria, QR 211, Conj. A, Lt.14', '(61) 3181-2238 / 99516-1772', 'Seg–Sex', 'continuado', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='Espaço Acolher — Santa Maria');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Espaço Acolher — Sobradinho', 'espaco_acolher', 'Sobradinho', 'Q.3, Lt. Especial 05, Ed. Gran Via, 1º andar, Sl.115', '(61) 3181-2241', 'Seg–Sex', 'continuado', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='Espaço Acolher — Sobradinho');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Espaço Acolher — Samambaia', 'espaco_acolher', 'Samambaia', 'Arena Mall, QS 406, Conj. E, Lt.3, Lj.4', '(61) 3458-1433 / 3181-2237', 'Seg–Sex', 'continuado', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='Espaço Acolher — Samambaia');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Comitê de Proteção — Itapoã', 'comite_protecao', 'Itapoã', 'QD 378, AE 4, Conj. A – Admin. Regional', '(61) 3181-2688 / 98312-0284', 'Seg–Sex 8h–18h', 'permanente', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome ILIKE '%Comitê%Itapoã%');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Comitê de Proteção — Ceilândia', 'comite_protecao', 'Ceilândia', 'QNM 13, AE – Admin. Regional Sul', '(61) 3181-2689 / 98312-0136', 'Seg–Sex 8h–18h', 'permanente', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome ILIKE '%Comitê%Ceilândia%');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Comitê de Proteção — Lago Norte', 'comite_protecao', 'Lago Norte', 'Admin. Regional Lago Norte (acima Shopping Deck Norte)', '(61) 3181-2685 / 98312-0245', 'Seg–Sex 8h–18h', 'permanente', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome ILIKE '%Comitê%Lago Norte%');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Comitê de Proteção — Estrutural (SCIA)', 'comite_protecao', 'Estrutural', 'Admin. Regional SCIA/Estrutural, Setor Central, AE 5', '(61) 3181-2686 / 98312-0285', 'Seg–Sex 8h–18h', 'permanente', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome ILIKE '%Comitê%Estrutural%');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Comitê de Proteção — Sobradinho', 'comite_protecao', 'Sobradinho', 'Feira Modelo de Sobradinho', '(61) 3181-2687 / 98279-0713', 'Seg–Sex 8h–18h', 'permanente', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome ILIKE '%Comitê%Sobradinho%');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Comitê de Proteção — Águas Claras', 'comite_protecao', 'Águas Claras', 'Biblioteca Pública, R. Araribá, Praça Park Sul', '(61) 3181-3104 / 98312-0138', 'Seg–Sex 8h–18h', 'permanente', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome ILIKE '%Comitê%Águas Claras%');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Comitê de Proteção — Santa Maria', 'comite_protecao', 'Santa Maria', 'Admin. Regional, Qd. Central 01, Conj. H''A', '(61) 3181-3105 / 98312-0135', 'Seg–Sex 8h–18h', 'permanente', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome ILIKE '%Comitê%Santa Maria%');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'CRMB Recanto das Emas', 'crmb', 'Recanto das Emas', 'Av. Buritis, Q.203, Lt.14', '(61) 3181-2665 / 3181-2666', 'Seg–Sex 9h–18h', 'permanente', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='CRMB Recanto das Emas');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'CRMB Sol Nascente', 'crmb', 'Sol Nascente', 'Tr.02, Q.100, Conj. A, Lt. SC1, Pôr do Sol', '(61) 3181-2255 / 3181-2660', 'Seg–Sex 9h–18h', 'permanente', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='CRMB Sol Nascente');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'CRMB São Sebastião', 'crmb', 'São Sebastião', 'AE 11, Centro de Múltiplas Atividades', '(61) 3181-2668', 'Seg–Sex 9h–18h', 'permanente', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='CRMB São Sebastião');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'CRMB Sobradinho II', 'crmb', 'Sobradinho II', 'AE 06 COER, Q.01, Setor Oeste', '(61) 3181-2668', 'Seg–Sex 9h–18h', 'permanente', 'SMDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='CRMB Sobradinho II');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'Cepav Flor do Cerrado', 'cepav', 'Santa Maria', 'Hospital Regional de Santa Maria', '(61) 3319-3400', 'Seg–Sex 7h–18h', 'continuado', 'SES-DF / IgesDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='Cepav Flor do Cerrado');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'DEAM I (Asa Sul)', 'delegacia', 'Plano Piloto', 'EQS 204/205, Asa Sul, CEP 70234-400', '(61) 3207-6195 / 98494-9302', '24 h', 'permanente', 'PCDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='DEAM I (Asa Sul)');
INSERT INTO rede_servicos (nome, tipo, circunscricao, endereco, telefones, horario, frequencia, instituicao, responsavel, status) SELECT 'DEAM II (Ceilândia)', 'delegacia', 'Ceilândia', 'QNM 02, Conj. F', '(61) 3207-7391 / 3207-7408', '24 h', 'permanente', 'PCDF', '', 'ativo' WHERE NOT EXISTS (SELECT 1 FROM rede_servicos WHERE nome='DEAM II (Ceilândia)');

-- ═══════════════════════════════════════════════════════════════════
-- 15) SEED — Articulações e Comitês
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO rede_articulacoes (nome, nivel, circunscricoes, coordenacao, frequencia, contato, status_atual) SELECT 'Comitê Gestor do Sistema Distrital de Avaliação de Risco', 'distrital', 'Todo o DF', 'SSP-DF (Sec. Sandro Avelar)', 'Bimestral', '(61) 3190-5000', 'Ativo — DODF 24/09/2025' WHERE NOT EXISTS (SELECT 1 FROM rede_articulacoes WHERE nome ILIKE '%Avaliação de Risco%');
INSERT INTO rede_articulacoes (nome, nivel, circunscricoes, coordenacao, frequencia, contato, status_atual) SELECT 'Observatório de Violência contra a Mulher e Feminicídio', 'distrital', 'Todo o DF', 'SMDF — Jackeline Aguiar', 'Trimestral', '(61) 3181-1445', 'Ativo — publica dados trimestrais' WHERE NOT EXISTS (SELECT 1 FROM rede_articulacoes WHERE nome ILIKE '%Observatório%');
INSERT INTO rede_articulacoes (nome, nivel, circunscricoes, coordenacao, frequencia, contato, status_atual) SELECT 'Comitê Gestor do Protocolo "Por Todas Elas"', 'distrital', 'Todo o DF', 'Sejus-DF — Sec. Marcela Passamani', 'Por demanda', '(61) 3344-2222', 'Ativo — Portaria 109/2025' WHERE NOT EXISTS (SELECT 1 FROM rede_articulacoes WHERE nome ILIKE '%Por Todas Elas%');
INSERT INTO rede_articulacoes (nome, nivel, circunscricoes, coordenacao, frequencia, contato, status_atual) SELECT 'Rede Elas (Gama / Santa Maria)', 'territorial', 'Gama, Santa Maria', 'MPDFT (Promotoria do Gama)', 'Mensal', '(61) 3343-9601 / @elas_rede_de_enfrentamento', 'Consolidada — 10 anos; fluxo publicado' WHERE NOT EXISTS (SELECT 1 FROM rede_articulacoes WHERE nome ILIKE '%Rede Elas%');
INSERT INTO rede_articulacoes (nome, nivel, circunscricoes, coordenacao, frequencia, contato, status_atual) SELECT 'Projeto Todas Elas (MPDFT)', 'territorial', 'Gama, Santa Maria, Ceilândia, Riacho Fundo, Planaltina, Brasília, Brazlândia, N. Bandeirante', 'Adalgiza Aguiar (Núcleo de Gênero)', 'Mensal por circunscrição', '(61) 3343-9601', 'Gama/SM consolidado; Ceilândia em finalização; Planaltina em formação' WHERE NOT EXISTS (SELECT 1 FROM rede_articulacoes WHERE nome ILIKE '%Todas Elas%');
INSERT INTO rede_articulacoes (nome, nivel, circunscricoes, coordenacao, frequencia, contato, status_atual) SELECT 'Rede Unid@s (Brazlândia)', 'territorial', 'Brazlândia', 'MPDFT Brazlândia', 'Semestral', '(61) 3343-9601', 'Ativa — 6º Encontro mar/2026' WHERE NOT EXISTS (SELECT 1 FROM rede_articulacoes WHERE nome ILIKE '%Unid@%');
INSERT INTO rede_articulacoes (nome, nivel, circunscricoes, coordenacao, frequencia, contato, status_atual) SELECT 'Pacto Brasil contra o Feminicídio', 'federal', 'Nacional (com efeito no DF)', 'SRI — Min. Gleisi Hoffmann', 'Bimestral', '(61) 3411-3802', 'Decreto 12.839 de 04/02/2026' WHERE NOT EXISTS (SELECT 1 FROM rede_articulacoes WHERE nome ILIKE '%Pacto Brasil%');
INSERT INTO rede_articulacoes (nome, nivel, circunscricoes, coordenacao, frequencia, contato, status_atual) SELECT 'Comitê Interinstitucional de Gestão (Pacto)', 'federal', 'Nacional', 'SRI + Casa Civil', 'Bimestral', '(61) 3411-3802', 'Criado pelo Decreto 12.839/2026' WHERE NOT EXISTS (SELECT 1 FROM rede_articulacoes WHERE nome ILIKE '%Interinstitucional de Gestão%');
INSERT INTO rede_articulacoes (nome, nivel, circunscricoes, coordenacao, frequencia, contato, status_atual) SELECT 'Rede de Proteção às Mulheres — TJDFT/CMVD', 'distrital', 'Todo o DF + Entorno', 'Juíza Luciana Rocha (CMVD)', 'Semanas Paz em Casa (3×/ano)', '(61) 3103-7014', 'Ativa — catálogo de serviços atualizado' WHERE NOT EXISTS (SELECT 1 FROM rede_articulacoes WHERE nome ILIKE '%CMVD%');
INSERT INTO rede_articulacoes (nome, nivel, circunscricoes, coordenacao, frequencia, contato, status_atual) SELECT 'Coletivo Territorial de Defesa dos Direitos da Mulher', 'distrital', 'Plano Piloto (DEAM I)', 'MPDFT — Núcleo de Gênero', 'Em formação', '(61) 3343-9601', 'Em formação — 1ª reunião 13/01/2026' WHERE NOT EXISTS (SELECT 1 FROM rede_articulacoes WHERE nome ILIKE '%Coletivo Territorial%');

-- ═══════════════════════════════════════════════════════════════════
-- 16) SEED — Ferramentas Digitais (rede_ferramentas)
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO rede_ferramentas (nome, orgao, tipo, url, funcao, novidades) SELECT 'Observatório da Mulher DF', 'SMDF', 'portal_dados', 'observatoriodamulher.df.gov.br', 'Painéis trimestrais: atendimentos, tipos de violência, por equipamento (CEAM, Espaço Acolher, CMB).', '6ª reunião Comitê Gestor (out/2025); dados jan–dez 2025 publicados.' WHERE NOT EXISTS (SELECT 1 FROM rede_ferramentas WHERE nome ILIKE '%Observatório da Mulher%');
INSERT INTO rede_ferramentas (nome, orgao, tipo, url, funcao, novidades) SELECT 'Painel da Violência Doméstica (CNJ)', 'CNJ', 'portal_dados', 'justica-em-numeros.cnj.jus.br/painel-violencia-contra-mulher/', 'Processos judiciais, medidas protetivas, feminicídios por UF/tribunal.', 'Novo painel lançado 11/03/2025 com dados até 2025.' WHERE NOT EXISTS (SELECT 1 FROM rede_ferramentas WHERE nome ILIKE '%Painel da Violência%');
INSERT INTO rede_ferramentas (nome, orgao, tipo, url, funcao, novidades) SELECT 'Fonar Digital (PDPJ-Br)', 'CNJ + CNMP', 'sistema', 'fonar.pdpj.jus.br', 'Formulário Nacional de Avaliação de Risco digital, integrado ao PJe.', 'Disponível ago/2025; versão ampliada fev/2026. Guia Interinstitucional UNDP+CNJ (nov/2025).' WHERE NOT EXISTS (SELECT 1 FROM rede_ferramentas WHERE nome ILIKE '%Fonar%');
INSERT INTO rede_ferramentas (nome, orgao, tipo, url, funcao, novidades) SELECT 'Sistema Distrital de Avaliação de Risco', 'SSP-DF', 'sistema', 'Interno (não público)', 'Integra dados de SSP, PCDF, PMDF, SMDF, SES, Sejus, Sedes sobre risco de violência.', 'Comitê Gestor criado set/2025; GTs temáticos previstos.' WHERE NOT EXISTS (SELECT 1 FROM rede_ferramentas WHERE nome ILIKE '%Distrital de Avaliação%');
INSERT INTO rede_ferramentas (nome, orgao, tipo, url, funcao, novidades) SELECT 'CIMS — Centro Integrado Mulher Segura', 'MJSP (Senasp)', 'plataforma_intel', 'gov.br/mj/pt-br/.../CIMS', 'Integra bases nacionais para antecipar feminicídios. R$ 28 mi investidos.', 'Lançado 25/03/2026. 28,4% dos feminicídios 2025 ocorreram na residência da vítima.' WHERE NOT EXISTS (SELECT 1 FROM rede_ferramentas WHERE nome ILIKE '%CIMS%');
INSERT INTO rede_ferramentas (nome, orgao, tipo, url, funcao, novidades) SELECT 'Programa Viva Flor', 'SSP-DF + TJDFT + MPDFT + PCDF', 'dispositivo', '—', 'Botão do pânico: mulher aciona e central envia viatura. Monitoramento 24 h.', '64 prisões em 2025; nenhuma monitorada sofreu feminicídio. TCT renovado out/2025.' WHERE NOT EXISTS (SELECT 1 FROM rede_ferramentas WHERE nome ILIKE '%Viva Flor%');
INSERT INTO rede_ferramentas (nome, orgao, tipo, url, funcao, novidades) SELECT 'Tornozeleira Eletrônica (agressores)', 'SSP-DF', 'dispositivo', '—', 'Monitora agressor para cumprimento de medida protetiva de distância.', 'DF completa 5 anos em 2026. Câmara aprovou uso obrigatório mar/2026.' WHERE NOT EXISTS (SELECT 1 FROM rede_ferramentas WHERE nome ILIKE '%Tornozeleira%');
INSERT INTO rede_ferramentas (nome, orgao, tipo, url, funcao, novidades) SELECT 'Maria da Penha On-line (Delegacia Eletrônica)', 'PCDF', 'portal_denuncia', 'pcdf.df.gov.br/servicos/delegacia-eletronica', 'B.O. de violência doméstica 100% on-line. Funciona 24 h.', 'Serviço prioritário da Delegacia Eletrônica (set/2025).' WHERE NOT EXISTS (SELECT 1 FROM rede_ferramentas WHERE nome ILIKE '%Maria da Penha On%');
INSERT INTO rede_ferramentas (nome, orgao, tipo, url, funcao, novidades) SELECT 'App Proteja-se', 'Sejus-DF', 'app_mobile', 'Play Store / App Store', 'Denúncia via chat ou Libras; integra Disque 100, Ligue 180 e PCDF.', 'Ativo desde 2021.' WHERE NOT EXISTS (SELECT 1 FROM rede_ferramentas WHERE nome ILIKE '%Proteja-se%');
INSERT INTO rede_ferramentas (nome, orgao, tipo, url, funcao, novidades) SELECT 'Agenda DF (agendamento CEAM)', 'GDF (Egov)', 'portal_agendamento', 'agenda.df.gov.br', 'Agendamento de atendimento psicossocial nos CEAMs. Também porta aberta.', 'Ativo para todos os CEAMs.' WHERE NOT EXISTS (SELECT 1 FROM rede_ferramentas WHERE nome ILIKE '%Agenda DF%');

-- ═══════════════════════════════════════════════════════════════════
-- 17) SEED — Fluxos Formalizados (rede_fluxos)
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO rede_fluxos (nome, abrangencia, status, referencia) SELECT 'Fluxo Regional Gama + Santa Maria', 'Gama, Santa Maria', 'consolidado', 'Publicado pela Rede Elas; modelo para o DF.' WHERE NOT EXISTS (SELECT 1 FROM rede_fluxos WHERE nome ILIKE '%Gama%Santa Maria%');
INSERT INTO rede_fluxos (nome, abrangencia, status, referencia) SELECT 'Fluxo de Atendimento Ceilândia', 'Ceilândia + Sol Nascente', 'em_finalizacao', 'MPDFT/NG — Todas Elas. Apresentado 18/06/2025 (IESB).' WHERE NOT EXISTS (SELECT 1 FROM rede_fluxos WHERE nome ILIKE '%Ceilândia%');
INSERT INTO rede_fluxos (nome, abrangencia, status, referencia) SELECT 'Fluxo Riacho Fundo', 'Riacho Fundo I e II', 'em_revisao', 'MPDFT/NG. Ames previsto jun/2025.' WHERE NOT EXISTS (SELECT 1 FROM rede_fluxos WHERE nome ILIKE '%Riacho Fundo%');
INSERT INTO rede_fluxos (nome, abrangencia, status, referencia) SELECT 'Fluxo Brasília', 'Plano Piloto', 'em_mobilizacao', 'MPDFT/NG. Apresentação 24/06/2025 sede MPDFT.' WHERE NOT EXISTS (SELECT 1 FROM rede_fluxos WHERE nome ILIKE '%Fluxo Brasília%');
INSERT INTO rede_fluxos (nome, abrangencia, status, referencia) SELECT 'Fluxo Planaltina', 'Planaltina', 'em_formacao', 'Grupo condutor formado; mapeamento em curso.' WHERE NOT EXISTS (SELECT 1 FROM rede_fluxos WHERE nome ILIKE '%Fluxo Planaltina%');
INSERT INTO rede_fluxos (nome, abrangencia, status, referencia) SELECT 'Fluxo Viva Flor', 'Todo o DF', 'consolidado', 'TCT SSP/TJDFT/MPDFT/PCDF 10/10/2025 — inclusão, emergência, retirada.' WHERE NOT EXISTS (SELECT 1 FROM rede_fluxos WHERE nome ILIKE '%Viva Flor%');
INSERT INTO rede_fluxos (nome, abrangencia, status, referencia) SELECT 'Protocolo "Por Todas Elas" (lazer)', 'Estabelecimentos de lazer no DF', 'consolidado', 'Decreto Lei 7.241/2023 (DODF 27/02/2025); Portaria 109 (12/06/2025).' WHERE NOT EXISTS (SELECT 1 FROM rede_fluxos WHERE nome ILIKE '%Por Todas Elas%');
INSERT INTO rede_fluxos (nome, abrangencia, status, referencia) SELECT 'Fluxo Comitês de Proteção → Rede', 'Todo o DF', 'consolidado', 'Art. 7º, Decreto 45.984/2024. Forças de segurança comunicam Comitê.' WHERE NOT EXISTS (SELECT 1 FROM rede_fluxos WHERE nome ILIKE '%Comitês de Proteção%');

-- ═══════════════════════════════════════════════════════════════════
-- 18) SEED — Legislação (rede_legislacao)
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO rede_legislacao (norma, data, conteudo) SELECT 'Decreto 45.984/2024 (DF)', '08/07/2024', 'Regulamenta Comitês de Proteção à Mulher (Lei 7.266/2023).' WHERE NOT EXISTS (SELECT 1 FROM rede_legislacao WHERE norma ILIKE '%45.984%');
INSERT INTO rede_legislacao (norma, data, conteudo) SELECT 'Decreto regulamentador Lei 7.241/2023 (DF)', '27/02/2025', 'Protocolo "Por Todas Elas" em casas de lazer.' WHERE NOT EXISTS (SELECT 1 FROM rede_legislacao WHERE norma ILIKE '%7.241%');
INSERT INTO rede_legislacao (norma, data, conteudo) SELECT 'Lei 7.699/2025 (DF)', '09/06/2025', 'Institui Relatório e Diagnóstico Socioeconômico Anual da Mulher no DF.' WHERE NOT EXISTS (SELECT 1 FROM rede_legislacao WHERE norma ILIKE '%7.699%');
INSERT INTO rede_legislacao (norma, data, conteudo) SELECT 'Portaria 109/2025 (Sejus-DF)', '12/06/2025', 'Recompõe Comitê Gestor do Protocolo Por Todas Elas.' WHERE NOT EXISTS (SELECT 1 FROM rede_legislacao WHERE norma ILIKE '%Portaria 109%');
INSERT INTO rede_legislacao (norma, data, conteudo) SELECT 'Portaria 182/2025 (DPDF)', '27/06/2025', 'Institui Projeto "Dia da Mulher" — atendimento jurídico mensal itinerante.' WHERE NOT EXISTS (SELECT 1 FROM rede_legislacao WHERE norma ILIKE '%Portaria 182%');
INSERT INTO rede_legislacao (norma, data, conteudo) SELECT 'DODF 24/09/2025 — Comitê Avaliação de Risco', '24/09/2025', 'Cria Comitê Gestor do Sistema Distrital de Avaliação de Risco (SSP-DF).' WHERE NOT EXISTS (SELECT 1 FROM rede_legislacao WHERE norma ILIKE '%24/09/2025%');
INSERT INTO rede_legislacao (norma, data, conteudo) SELECT 'Decreto nº 12.839/2026 (Federal)', '04/02/2026', 'Pacto Brasil entre os Três Poderes contra o Feminicídio + Comitê Interinstitucional de Gestão.' WHERE NOT EXISTS (SELECT 1 FROM rede_legislacao WHERE norma ILIKE '%12.839%');
INSERT INTO rede_legislacao (norma, data, conteudo) SELECT 'PL 3.880/2024 — Violência Vicária (Senado)', '25/03/2026', 'Inclui violência vicária na Lei Maria da Penha.' WHERE NOT EXISTS (SELECT 1 FROM rede_legislacao WHERE norma ILIKE '%3.880%');

-- ═══════════════════════════════════════════════════════════════════
-- 19) SEED — Publicações e Relatórios (rede_publicacoes)
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO rede_publicacoes (titulo, orgao, data, tipo, url, nota) SELECT '2º Anuário de Segurança Pública do DF', 'SSP-DF', '24/03/2026', 'relatorio', 'ssp.df.gov.br', '28 feminicídios em 2025 (+27%); 11,3 mil casos de violência doméstica.' WHERE NOT EXISTS (SELECT 1 FROM rede_publicacoes WHERE titulo ILIKE '%2º Anuário%');
INSERT INTO rede_publicacoes (titulo, orgao, data, tipo, url, nota) SELECT '1º Anuário de Segurança Pública do DF', 'SSP-DF', 'Jun/2025', 'relatorio', 'ssp.df.gov.br/wp-conteudo/uploads/2025/06/Anuario_SSP-2025.pdf', 'Dados de 2024.' WHERE NOT EXISTS (SELECT 1 FROM rede_publicacoes WHERE titulo ILIKE '%1º Anuário%');
INSERT INTO rede_publicacoes (titulo, orgao, data, tipo, url, nota) SELECT 'Relatório Anual SMDF 2025', 'SMDF', 'Jan/2026', 'relatorio', 'vice.df.gov.br', '>172 mil impactadas, >70 mil atendimentos diretos em 2025.' WHERE NOT EXISTS (SELECT 1 FROM rede_publicacoes WHERE titulo ILIKE '%Relatório Anual SMDF%');
INSERT INTO rede_publicacoes (titulo, orgao, data, tipo, url, nota) SELECT 'Relatório Comissão de Feminicídio MPDFT', 'MPDFT', 'Set/2025', 'relatorio', 'mpdft.mp.br', 'Análise de 234 feminicídios no DF (2015–2025).' WHERE NOT EXISTS (SELECT 1 FROM rede_publicacoes WHERE titulo ILIKE '%Comissão de Feminicídio%');
INSERT INTO rede_publicacoes (titulo, orgao, data, tipo, url, nota) SELECT 'Guia Interinstitucional Fonar (CNJ + UNDP)', 'CNJ + UNDP', 'Nov/2025', 'guia', 'undp.org/pt/brazil/publications/guia-interinstitucional-de-avaliacao-de-risco', 'Guia técnico para aplicação do Fonar.' WHERE NOT EXISTS (SELECT 1 FROM rede_publicacoes WHERE titulo ILIKE '%Guia%Fonar%');
INSERT INTO rede_publicacoes (titulo, orgao, data, tipo, url, nota) SELECT 'Nota Técnica "Retrato dos Feminicídios no Brasil"', 'FBSP', '02/03/2026', 'nota_tecnica', 'forumseguranca.org.br', '1.568 vítimas em 2025, +4,7%.' WHERE NOT EXISTS (SELECT 1 FROM rede_publicacoes WHERE titulo ILIKE '%Retrato dos Feminicídios%');
INSERT INTO rede_publicacoes (titulo, orgao, data, tipo, url, nota) SELECT '"Vamos Conversar?" — Cartilha de Enfrentamento', 'CMVD/TJDFT + ONU Mulheres', 'Set/2025', 'cartilha', 'tjdft.jus.br', 'Enfrentamento da violência doméstica.' WHERE NOT EXISTS (SELECT 1 FROM rede_publicacoes WHERE titulo ILIKE '%Vamos Conversar%');
INSERT INTO rede_publicacoes (titulo, orgao, data, tipo, url, nota) SELECT 'Catálogo da Rede de Proteção às Mulheres do DF', 'TJDFT + MPDFT', 'Atualizado', 'catalogo', 'mpdft.mp.br/portal/images/pdf/nucleos/nucleo_genero/Contato_Rede_de_Protecao_VD.pdf', 'Contatos e endereços da rede completa.' WHERE NOT EXISTS (SELECT 1 FROM rede_publicacoes WHERE titulo ILIKE '%Catálogo da Rede%');

-- ═══════════════════════════════════════════════════════════════════
-- 20) SEED — Sites Institucionais (rede_sites)
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO rede_sites (nome, orgao, url, descricao) SELECT 'Observatório da Mulher DF', 'SMDF', 'observatoriodamulher.df.gov.br', 'Painéis de dados trimestrais, publicações, rede de enfrentamento.' WHERE NOT EXISTS (SELECT 1 FROM rede_sites WHERE nome ILIKE '%Observatório da Mulher%');
INSERT INTO rede_sites (nome, orgao, url, descricao) SELECT 'Secretaria da Mulher DF', 'SMDF', 'mulher.df.gov.br', 'Notícias, calendário de eventos, telefones, relatórios.' WHERE NOT EXISTS (SELECT 1 FROM rede_sites WHERE nome ILIKE '%Secretaria da Mulher%');
INSERT INTO rede_sites (nome, orgao, url, descricao) SELECT 'NJM/CMVD — TJDFT', 'TJDFT', 'tjdft.jus.br/informacoes/cidadania/nucleo-judiciario-da-mulher', 'Cartilhas, catálogo Rede, Fonar PDF, Semanas Paz em Casa.' WHERE NOT EXISTS (SELECT 1 FROM rede_sites WHERE nome ILIKE '%NJM%');
INSERT INTO rede_sites (nome, orgao, url, descricao) SELECT 'Rede de Proteção — MPDFT', 'MPDFT', 'mpdft.mp.br/portal/.../nucleo-de-genero/634-rede-de-protecao', 'Rede intersetorial, catálogo TJDFT, contatos.' WHERE NOT EXISTS (SELECT 1 FROM rede_sites WHERE nome ILIKE '%Rede de Proteção — MPDFT%');
INSERT INTO rede_sites (nome, orgao, url, descricao) SELECT 'PCDF — Violência contra Mulher', 'PCDF', 'pcdf.df.gov.br/servicos/197/violencia-contra-mulher', 'Guia de perguntas, passo a passo para denúncia.' WHERE NOT EXISTS (SELECT 1 FROM rede_sites WHERE nome ILIKE '%PCDF%Violência%');
INSERT INTO rede_sites (nome, orgao, url, descricao) SELECT 'Nudem — DPDF', 'DPDF', 'defensoria.df.gov.br/nucleo/defesa-das-mulheres/', 'Assistência jurídica especializada.' WHERE NOT EXISTS (SELECT 1 FROM rede_sites WHERE nome ILIKE '%Nudem%DPDF%');
INSERT INTO rede_sites (nome, orgao, url, descricao) SELECT 'Observatório da Mulher — CLDF', 'CLDF', 'cl.df.gov.br/web/observatorio-da-mulher', 'Estudos, pesquisas, mapeamento de legislação (Lei 7.699/2025).' WHERE NOT EXISTS (SELECT 1 FROM rede_sites WHERE nome ILIKE '%CLDF%');
INSERT INTO rede_sites (nome, orgao, url, descricao) SELECT 'CIMS — Mulher Segura', 'MJSP', 'gov.br/mj/pt-br/.../CIMS', 'Dados nacionais de feminicídio, padrões de risco (lançado mar/2026).' WHERE NOT EXISTS (SELECT 1 FROM rede_sites WHERE nome ILIKE '%CIMS%');

-- ═══════════════════════════════════════════════════════════════════
-- 21) SEED — NOTÍCIAS PÚBLICAS — Estado atual das Rodas, Rede e contexto DF
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO public_news (published_on, title, excerpt, body, is_published, sort_order)
SELECT '2026-04-04',
  'Rede de Rodas do DF: por que precisamos de rodas de conversa para mulheres em situação de violência',
  'O DF registrou 28 feminicídios em 2025 — aumento de 27%. Grupos de apoio e rodas de conversa são fundamentais para romper ciclos de violência.',
  'O 2º Anuário de Segurança Pública do DF (SSP-DF, março/2026) revelou que o Distrito Federal registrou 28 feminicídios em 2025, um aumento de 27% em relação a 2024. Foram mais de 11,3 mil ocorrências de violência doméstica no período.

Diante desse cenário, a Rede de Rodas do DF nasce como iniciativa de apoio grupal: rodas de conversa terapêuticas facilitadas por profissionais capacitadas, voltadas para mulheres em situação de violência doméstica. A metodologia é baseada em protótipos validados que combinam acolhimento emocional, escuta qualificada e encaminhamento para a rede de proteção.

A rede integra esforços do MPDFT, universidades e organizações da sociedade civil, com o objetivo de chegar onde os serviços fixos ainda não chegam — especialmente nas circunscrições sem Comitê de Proteção ou sem fluxo de atendimento formalizado, como Fercal, Paranoá, Guará e Recanto das Emas.',
  true, 1
WHERE NOT EXISTS (SELECT 1 FROM public_news WHERE title ILIKE '%por que precisamos de rodas%');

INSERT INTO public_news (published_on, title, excerpt, body, is_published, sort_order)
SELECT '2026-04-03',
  'Panorama da rede de proteção à mulher no DF: 3 CEAMs, 9 Espaços Acolher, 7 Comitês e muito por fazer',
  'O DF conta com uma rede institucional ampla, mas fragmentada. Conheça os equipamentos, as lacunas e onde as rodas se encaixam.',
  'A rede de proteção à mulher no Distrito Federal é composta por múltiplas camadas:

ATENDIMENTO DIRETO: 3 CEAMs (102 Sul, Planaltina, IV/CIOB), 9 Espaços Acolher (em fóruns do MPDFT), a Casa da Mulher Brasileira (24h, Ceilândia), 4 CRMBs (Recanto, Sol Nascente, São Sebastião, Sobradinho II), 7 Comitês de Proteção (Itapoã, Ceilândia, Lago Norte, Estrutural, Sobradinho, Águas Claras, Santa Maria), 2 DEAMs e o Cepav Flor do Cerrado.

ARTICULAÇÃO: 11 núcleos Direito Delas (Sejus-DF), NJM/CMVD do TJDFT com 4 polos (Norte, Sul, Leste, Oeste), Ouvidoria para Elas (0800 614 6466, 24h), Núcleo de Gênero do MPDFT, Nudem da DPDF e o PROVID (17º BPM, Águas Claras).

LACUNAS: Fercal, Paranoá, Guará, Recanto das Emas, Samambaia e Planaltina não possuem Comitê de Proteção instalado nem rede local formalizada. A expansão é prevista no Art. 5º do Decreto 45.984, mas depende de orçamento da SMDF.

As rodas de conversa da Rede de Rodas do DF são pensadas justamente para preencher essas lacunas: levar acolhimento grupal, escuta qualificada e encaminhamento para onde a rede fixa ainda não chegou.',
  true, 2
WHERE NOT EXISTS (SELECT 1 FROM public_news WHERE title ILIKE '%Panorama da rede de proteção%');

INSERT INTO public_news (published_on, title, excerpt, body, is_published, sort_order)
SELECT '2026-04-02',
  'Rodas de conversa que já existem no DF: quem faz, onde e como funciona',
  'Pelo menos 15 iniciativas de rodas e apoio grupal já operam no DF — de CEAMs a projetos como Desabafe Aqui e Entrelace.',
  'O levantamento mais recente (2025–2026) identificou diversas iniciativas de rodas de conversa e apoio grupal para mulheres em situação de violência no DF:

SMDF/CEAMs: Rodas periódicas nos 3 CEAMs, incluindo rodas no Agosto Lilás e Março Mais Mulher (>180 atividades, >170 mil mulheres em mar/2026).

ESPAÇOS ACOLHER: Grupos de acolhimento para mulheres com medida protetiva em todos os 9 Espaços Acolher da SMDF (GEAFAVD).

DPDF — CAMPANHA ENTRELACE (fev/2026+): Rodas itinerantes com atendimento jurídico pelo Nudem; "Dia da Mulher" mensal (Portaria 182/2025) — 1.627 atendimentos na 1ª edição 2026.

PROJETO DESABAFE AQUI (Sejus + Instituto Bethel): Terapia Comunitária Integrativa para 60 mulheres em Sobradinho II (jan–fev/2026, R$ 100 mil).

CONVERSA COM ELES (SMDF): Rodas em empresas com homens sobre masculinidades — >3 mil colaboradores em 2025.

FALANDO DELAS COM ELES (CLDF): Rodas em escolas com estudantes do sexo masculino — 6 edições em Ceilândia, Taguatinga, Sobradinho II, Recanto, Estrutural e Águas Claras.

A Rede de Rodas do DF se diferencia por oferecer formação padronizada de facilitadoras (40h), metodologia própria com protótipos validados, QR Code de denúncia obrigatório e integração direta com a rede de proteção via MPDFT.',
  true, 3
WHERE NOT EXISTS (SELECT 1 FROM public_news WHERE title ILIKE '%Rodas de conversa que já existem%');

INSERT INTO public_news (published_on, title, excerpt, body, is_published, sort_order)
SELECT '2026-04-01',
  'CIMS, Fonar Digital e Viva Flor: as ferramentas digitais que protegem mulheres no DF',
  'Tecnologia a serviço da proteção — conheça as plataformas, apps e dispositivos que compõem o ecossistema digital do DF.',
  'O ecossistema digital de proteção à mulher no DF tem evoluído rapidamente:

CIMS — CENTRO INTEGRADO MULHER SEGURA (MJSP, lançado 25/03/2026): plataforma nacional que integra bases de ocorrências, medidas protetivas, Fonar e tornozeleiras para identificar padrões de risco e antecipar feminicídios. Revelou que 28,4% dos feminicídios em 2025 ocorreram na residência da vítima. R$ 28 mi investidos.

FONAR DIGITAL (CNJ + CNMP): o Formulário Nacional de Avaliação de Risco agora é digital e integrado ao PJe. Versão ampliada em fev/2026. O Guia Interinstitucional (UNDP + CNJ, nov/2025) orienta sua aplicação por delegados, promotores e juízes.

VIVA FLOR (SSP-DF + TJDFT + MPDFT + PCDF): dispositivo tipo celular com "botão do pânico". Em 2025: 64 prisões e nenhuma mulher monitorada sofreu feminicídio. TCT renovado em out/2025.

TORNOZELEIRA ELETRÔNICA: monitoramento de agressores — DF completa 5 anos em 2026. Câmara aprovou uso obrigatório (mar/2026).

MARIA DA PENHA ON-LINE (PCDF): B.O. de violência doméstica 100% digital, 24h.

OBSERVATÓRIO DA MULHER DF (SMDF): painéis trimestrais com dados de atendimentos, equipamentos e tipos de violência. Comitê Gestor atuante.

O desafio: essas ferramentas são robustas, mas fragmentadas — cada órgão mantém a sua. O Sistema Distrital de Avaliação de Risco (SSP-DF, set/2025) e o CIMS são as primeiras tentativas de integração real.',
  true, 4
WHERE NOT EXISTS (SELECT 1 FROM public_news WHERE title ILIKE '%CIMS, Fonar Digital%');

INSERT INTO public_news (published_on, title, excerpt, body, is_published, sort_order)
SELECT '2026-03-30',
  'Pacto Brasil contra o Feminicídio e a nova legislação que impacta o DF',
  'Decreto federal, leis distritais e PLs aprovados em 2025–2026 fortalecem a rede — mas a implementação depende de articulação local.',
  'A legislação recente tem ampliado o arcabouço de proteção:

FEDERAL: O Decreto nº 12.839/2026 (04/02/2026) instituiu o Pacto Brasil entre os Três Poderes contra o Feminicídio, com Comitê Interinstitucional de Gestão (SRI + Casa Civil) e reuniões bimestrais. O PL 3.880/2024, aprovado pelo Senado em 25/03/2026, inclui violência vicária na Lei Maria da Penha.

DISTRITAL: O Decreto 45.984/2024 regulamentou os Comitês de Proteção à Mulher (Lei 7.266/2023) — 7 já instalados. A Lei 7.699/2025 institui o Relatório e Diagnóstico Socioeconômico Anual da Mulher (1ª edição prevista para 2026, SMDF + IPEDF). O Protocolo "Por Todas Elas" (Decreto Lei 7.241/2023, regulamentado em fev/2025) obriga casas de lazer a manter canal de denúncia.

SSP-DF: Em set/2025, criou o Comitê Gestor do Sistema Distrital de Avaliação de Risco, integrando SSP, PCDF, PMDF, SMDF, SES, Sejus e Sedes.

A Rede de Rodas do DF opera nesse contexto: cada roda é uma oportunidade de implementar na ponta o que a legislação prevê — acolhimento, encaminhamento e prevenção.',
  true, 5
WHERE NOT EXISTS (SELECT 1 FROM public_news WHERE title ILIKE '%Pacto Brasil contra o Feminicídio%');

INSERT INTO public_news (published_on, title, excerpt, body, is_published, sort_order)
SELECT '2026-03-28',
  'Próximos passos da Rede de Rodas do DF: capacitação, piloto e expansão',
  'A rede está em fase de estruturação (Fase 0 — Semente) com meta de primeira turma de capacitação em junho/2026.',
  'A Rede de Rodas do DF segue um plano em 5 fases:

FASE 0 — SEMENTE (atual, abr–mai/2026): Estruturação da equipe, articulação institucional (MPDFT, SMDF, TJDFT, Sejus, DPDF), desenho do currículo de 40h para capacitação de facilitadoras e organização jurídica.

FASE 1 — PILOTO (jun–jul/2026): 1ª turma de capacitação (10–15 participantes) e implantação de rodas-piloto no Instituto Mãos Solidárias. Meta: 8 sessões, 40+ mulheres atendidas. QR Code da Ouvidoria MPDFT obrigatório.

FASE 2 — AVALIAÇÃO: Coleta de dados, ajuste metodológico e validação dos protótipos.

FASE 3 — EXPANSÃO: Novas turmas, novos territórios — prioridade para circunscrições sem cobertura (Fercal, Paranoá, Guará, Recanto).

FASE 5 — SUSTENTABILIDADE: Consolidação do fluxo de atendimento, integração formal com a rede de proteção e plano de novas rodas para atender demanda reprimida.

Acompanhe o andamento pelo painel SAAD (Sistema de Articulação, Apoio e Deliberação) neste site.',
  true, 6
WHERE NOT EXISTS (SELECT 1 FROM public_news WHERE title ILIKE '%Próximos passos da Rede%');

-- ═══════════════════════════════════════════════════════════════════
-- 22) SEED — Site público: Rodas e Edital
-- ═══════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════
-- 23) SEED — Pontes (articulações institucionais — aba Pontes)
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'ONGs', 'Mapear e formalizar diálogo com organizações que atendem mulheres (abrigo, serviços, campo para rodas).', 'Articulação com a rede de ONGs do DF: identificar interlocutores, combinar encaminhamentos e parcerias operacionais (incl. espaços com mulheres em situação de vulnerabilidade e piloto institucional).', 'A definir', 'Ex.: IMS e demais parceiras previstas no plano.' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='ONGs' AND ponte ILIKE '%rede de ONGs%');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'TJDFT', 'Articulação judiciária — CMVD, varas e políticas (ex.: Paz em Casa, rodas comunitárias).', 'Contato com Coordenadoria da Mulher (CMVD/TJDFT), pontos de articulação com magistratura e ações de prevenção no DF alinhadas à metodologia das rodas.', 'A definir', 'Levantamento «Rodas DF» traz referências CMVD/TJDFT.' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='TJDFT');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'PROVID / PMDF', 'Segurança pública — PROVAD/PROVID e interface com a Polícia Militar do DF.', 'Ponte com a rede feminina da segurança (PROVAD/PROVID) e PMDF: reuniões de rede, encaminhamentos e calendário territorial (ex.: Provid / 17º BPM — Águas Claras, conforme articulação MPDFT).', 'A definir', '' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='PROVID / PMDF');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'PCDF', 'Polícia Civil — DEAM e delegacias especializadas.', 'Articulação com PCDF: DEAM (incl. canal 24h), delegacias e fluxos de atendimento conectados às rodas e à capacitação — linguagem, encaminhamento seguro e rede de proteção.', 'A definir', '' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='PCDF');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'Rede do Executivo (DF)', 'Secretaria da Mulher (SMDF) — políticas; Parte 1 do levantamento (CEAM, CMB, CRMB).', 'Apresentação da Rede de Rodas do DF e alinhamento com a SMDF: coordenação com CEAM, Casa da Mulher Brasileira (CMB), CRMB e calendário conjunto com o GDF — espelha equipamentos continuados do levantamento.', 'Thaís', 'Paralelo à tarefa de apresentação à Secretaria da Mulher. Comitês regionais: ver também grupo «Comitês de proteção».' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='Rede do Executivo (DF)' AND ponte ILIKE '%SMDF%');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'Rede do Executivo (DF)', 'Programa Direito Delas (Sejus-DF).', 'Interface com Direito Delas: oficinas, ações comunitárias (ex.: «Mentes em Movimento»), rodas e encaminhamentos — encaixe com a metodologia e o cronograma da rede.', 'A definir', 'Referência: Sejus-DF / Direito Delas (levantamento Rodas DF).' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='Rede do Executivo (DF)' AND ponte ILIKE '%Direito Delas%');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'Rede do Executivo (DF)', 'Espaço Acolher — rede psicossocial (SMDF) nos fóruns e promotorias.', 'Articulação com os Espaços Acolher: grupos de mulheres, acolhimento psicossocial e fluxo entre capacitação, rodas do projeto e atendimento especializado no território.', 'A definir', 'Vários pontos no levantamento «Rodas DF».' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='Rede do Executivo (DF)' AND ponte ILIKE '%Espaços Acolher%');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'Rede do Executivo (DF)', 'CEPAV / saúde mental — SES-DF e rede hospitalar.', 'Ponte com CEPAV (ex.: Flor do Cerrado — HRSM): rodas terapêuticas, grupo de mulheres e interface entre atenção à saúde e projeto (encaminhamentos, linguagem comum).', 'A definir', 'Alinhado à Parte 1 do levantamento «Rodas DF» (SES-DF / IgesDF).' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='Rede do Executivo (DF)' AND ponte ILIKE '%CEPAV%');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'Comitês de proteção (SMDF)', 'Parte 2 do levantamento — acolhimento, escuta e encaminhamento (portas abertas, seg–sex).', 'Articulação com comitês regionais de proteção à mulher (Itapoã, Ceilândia, Lago Norte, Estrutural, Sobradinho, Águas Claras, Santa Maria, etc.): fluxo com as rodas da rede, cadastro de interlocutores e remissão aos telefones do levantamento.', 'A definir', 'Ver aba «Rodas DF» — Parte 2; coordenação geral Comitê (61) 98279-0396.' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='Comitês de proteção (SMDF)');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'SSP-DF / Conseg', 'Parte 3 — segurança pública e Conselhos Comunitários (palestras, Agosto Lilás, território).', 'Ponte com SSP-DF e Consegs: ciclos de palestras e ações de prevenção conectadas a rodas e calendário comunitário (ex.: Ceilândia/Sol Nascente, Gama, Guará, Samambaia, Águas Claras no levantamento).', 'A definir', 'Tel. ref. SSP (61) 3190-5000 — Parte 3 «Rodas DF».' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='SSP-DF / Conseg');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'Redes territoriais (Todas Elas etc.)', 'Parte 4 — redes locais articuladas (reuniões regulares da rede de proteção).', 'Interface com Rede Elas (Gama/Santa Maria), Rede Mulher de Ceilândia, Todas Elas (Riacho Fundo, Brasília, Planaltina/N. Bandeirante/Brazlândia em implementação), Rede Unid@s (Brazlândia): calendário de encontros, encaminhamentos e coerência com o projeto. Ponte institucional: Adalgiza (Núcleo de Gênero / MPDFT) com o projeto Todas Elas, via articulação com Thaís.', 'A definir', 'MPDFT NG (61) 3343-9601; coord. Brazlândia (61) 3391-1402 — Parte 4.' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='Redes territoriais (Todas Elas etc.)');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'Defensoria Pública (DPDF)', 'Núcleo da Mulher — acesso à justiça e encaminhamentos da rede.', 'Articulação com a Defensoria Pública do DF / Núcleo da Mulher: orientação, encaminhamentos consentidos e alinhamento com a metodologia das rodas.', 'A definir', '(61) 3318-4800 — tabela «Contatos gerais» do levantamento.' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='Defensoria Pública (DPDF)');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'MPDFT (rede próxima)', 'Ouvidoria das Mulheres — canal e QR Code nas rodas.', 'Definir contato nominal na Ouvidoria; divulgar QR Code fixo em todas as rodas para denúncias qualificadas e capilaridade da rede MPDFT.', 'Thaís', 'Obrigatório em toda roda (projeto).' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='MPDFT (rede próxima)' AND ponte ILIKE '%Ouvidoria%');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'MPDFT (rede próxima)', 'Parceria acadêmica — UNB / pós-graduação em Psicologia.', 'Interlocução com a UNB (Prof.ª Cândida): campo de prática, estudantes facilitadoras e validação de horas — dependente de retorno institucional.', 'Thaís', 'Retorno UNB ainda pendente.' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='MPDFT (rede próxima)' AND ponte ILIKE '%UNB%');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'MPDFT (rede próxima)', 'Núcleo de Gênero do MPDFT.', 'Articulação com Adalgiza / Núcleo de Gênero: capacitação, encaminhamentos e políticas de gênero alinhadas ao projeto. Adalgiza pode fazer ponte com o projeto Todas Elas (rede territorial, Parte 4).', 'Thaís', 'Tarefa «Falar com Adalgiza» no painel. Projeto Maria da Penha (Lívia Gimines): ver parceiros — Natalie quando estruturado.' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='MPDFT (rede próxima)' AND ponte ILIKE '%Núcleo de Gênero%');

INSERT INTO pontes (grupo, funcao, ponte, responsavel, notas) SELECT 'MPDFT (rede próxima)', 'SEPS — Setor Psicossocial do MPDFT.', 'Ponte possível com o setor psicossocial (SEPS): alinhar linguagem de acolhimento, apoio técnico à capacitação, encaminhamentos e continuidade de cuidado com mulheres em situação de violência — coerente com metodologia das rodas e com rede interinstitucional.', 'A definir', 'Confirmar interlocução nominal no MPDFT-DF.' WHERE NOT EXISTS (SELECT 1 FROM pontes WHERE grupo='MPDFT (rede próxima)' AND ponte ILIKE '%SEPS%');

-- ═══════════════════════════════════════════════════════════════════
-- FIM — Validação rápida pós-execução:
--   SELECT count(*) FROM team_members;                   → 6
--   SELECT count(*) FROM partners;                       → 10
--   SELECT count(*) FROM tasks;                          → 8
--   SELECT count(*) FROM forum_categories;               → 5
--   SELECT count(*) FROM public_news WHERE is_published; → 6
--   SELECT count(*) FROM rede_servicos;                  → ~30
--   SELECT count(*) FROM rede_articulacoes;              → 10
--   SELECT count(*) FROM rede_ferramentas;               → 10
--   SELECT count(*) FROM rede_fluxos;                    → 8
--   SELECT count(*) FROM rede_legislacao;                → 8
--   SELECT count(*) FROM rede_publicacoes;               → 8
--   SELECT count(*) FROM rede_sites;                     → 8
--   SELECT count(*) FROM public_rodas_site;              → 3
--   SELECT count(*) FROM public_edital_site;             → 1
--   SELECT count(*) FROM public_eventos_cal;             → 7
--   SELECT count(*) FROM pontes;                         → 16
--   SELECT count(*) FROM proto_notes;                    → 0 (populado pelo frontend)
--   SELECT count(*) FROM rodas_mapeadas;                 → 55 (levantamento abril/2026)
--   SELECT count(*) FROM member_rodas;                   → 0 (populado pelo frontend)
-- TOTAL: 23 tabelas + extensão pgcrypto
-- ═══════════════════════════════════════════════════════════════════

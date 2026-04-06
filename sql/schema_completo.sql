-- ============================================================
-- PROJETO RODAS DF — SQL COMPLETO E ÚNICO
-- PostgreSQL 15+ / Supabase
-- Execute no SQL Editor (Run). Re-execução: políticas recriadas.
-- Sem analytics. Sem tabelas de rastreamento.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ----------------------------------------------------------------
-- Limpar políticas antigas (mesmos nomes) para permitir re-run
-- ----------------------------------------------------------------
DO $$
DECLARE r record;
BEGIN
  FOR r IN (
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN (
        'profiles','rodas','usuario_rodas','rede_df','rede_df_pontes','noticias','editais',
        'bases_conhecimento','contatos','prototipos_redes','forum_topicos','cronograma',
        'atividades_gestao','encaminhamentos','equipe_projeto','parceiros_pontes','registro_atividades'
      )
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
  END LOOP;
END $$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 1. PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  nome text,
  email text,
  telefone text,
  circunscricao text,
  bio text,
  role text NOT NULL DEFAULT 'comum' CHECK (role IN ('comum','gestao','admin'))
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, nome, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
    CASE WHEN new.email = 'giselle.trevizo@gmail.com' THEN 'admin' ELSE 'comum' END
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 2. RODAS
CREATE TABLE IF NOT EXISTS public.rodas (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  circunscricao text NOT NULL,
  tipo text NOT NULL CHECK (tipo IN ('permanente','recorrente','pontual')),
  status text NOT NULL DEFAULT 'pendente' CHECK (status IN ('confirmada','pendente','encerrada')),
  nome text NOT NULL,
  instituicao text,
  responsavel text,
  dia_semana text NOT NULL CHECK (dia_semana IN ('segunda','terca','quarta','quinta','sexta','sabado','domingo')),
  horario_inicio time NOT NULL,
  horario_fim time,
  frequencia text NOT NULL CHECK (frequencia IN ('semanal','quinzenal')),
  observacao_frequencia text,
  endereco text NOT NULL,
  bairro text,
  cep text,
  telefone text,
  whatsapp text,
  email text,
  instagram text,
  site text,
  descricao text,
  historico text,
  user_id uuid REFERENCES auth.users(id)
);

ALTER TABLE public.rodas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rodas_select" ON public.rodas FOR SELECT USING (true);
CREATE POLICY "rodas_insert" ON public.rodas FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "rodas_update" ON public.rodas FOR UPDATE USING (
  auth.uid() = user_id OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);
CREATE POLICY "rodas_delete" ON public.rodas FOR DELETE USING (
  auth.uid() = user_id OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- 3. VINCULAÇÃO USUÁRIO ↔ RODA
CREATE TABLE IF NOT EXISTS public.usuario_rodas (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  roda_id uuid REFERENCES public.rodas(id) ON DELETE CASCADE NOT NULL,
  UNIQUE(user_id, roda_id)
);

ALTER TABLE public.usuario_rodas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vinculos_select" ON public.usuario_rodas FOR SELECT USING (true);
CREATE POLICY "vinculos_insert" ON public.usuario_rodas FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "vinculos_delete" ON public.usuario_rodas FOR DELETE USING (auth.uid() = user_id);

-- 4. REDE DF
CREATE TABLE IF NOT EXISTS public.rede_df (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  circunscricao text NOT NULL,
  tipo_equipamento text NOT NULL CHECK (tipo_equipamento IN (
    'espaco_acolher','ceam','crmb','direito_delas','comite_protecao','cepav','cmb','rede_elas','projeto_todas_elas','outro'
  )),
  nome text NOT NULL,
  instituicao text,
  responsavel text,
  endereco text,
  bairro text,
  cep text,
  telefone text,
  whatsapp text,
  email text,
  instagram text,
  site text,
  horario_funcionamento text,
  descricao text,
  historico text,
  status text NOT NULL DEFAULT 'ativo' CHECK (status IN ('ativo','inativo','em_implantacao'))
);

ALTER TABLE public.rede_df ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rede_select" ON public.rede_df FOR SELECT USING (true);
CREATE POLICY "rede_manage" ON public.rede_df FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- 5. PONTES
CREATE TABLE IF NOT EXISTS public.rede_df_pontes (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  rede_df_id uuid REFERENCES public.rede_df(id) ON DELETE CASCADE NOT NULL,
  status_ponte text NOT NULL DEFAULT 'identificada' CHECK (status_ponte IN ('identificada','contatada','parceira_confirmada','inativa')),
  observacoes text,
  data_ultimo_contato date,
  responsavel_contato uuid REFERENCES auth.users(id)
);

ALTER TABLE public.rede_df_pontes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pontes_gestao" ON public.rede_df_pontes FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- 6. NOTÍCIAS
CREATE TABLE IF NOT EXISTS public.noticias (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  titulo text NOT NULL,
  resumo text,
  conteudo text,
  imagem_url text,
  data_publicacao date DEFAULT CURRENT_DATE,
  publicado boolean DEFAULT false,
  user_id uuid REFERENCES auth.users(id)
);

ALTER TABLE public.noticias ENABLE ROW LEVEL SECURITY;

CREATE POLICY "noticias_select" ON public.noticias FOR SELECT USING (
  publicado = true OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);
CREATE POLICY "noticias_manage" ON public.noticias FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- 7. EDITAIS
CREATE TABLE IF NOT EXISTS public.editais (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  titulo text NOT NULL,
  descricao text,
  arquivo_url text,
  data_abertura date,
  data_encerramento date,
  publicado boolean DEFAULT false,
  user_id uuid REFERENCES auth.users(id)
);

ALTER TABLE public.editais ENABLE ROW LEVEL SECURITY;

CREATE POLICY "editais_select" ON public.editais FOR SELECT USING (
  publicado = true OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);
CREATE POLICY "editais_manage" ON public.editais FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- 8. BASES DE CONHECIMENTO
CREATE TABLE IF NOT EXISTS public.bases_conhecimento (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  titulo text NOT NULL,
  descricao text,
  url text,
  categoria text,
  publicado boolean DEFAULT true
);

ALTER TABLE public.bases_conhecimento ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bases_select" ON public.bases_conhecimento FOR SELECT USING (publicado = true);
CREATE POLICY "bases_manage" ON public.bases_conhecimento FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- 9. CONTATOS
CREATE TABLE IF NOT EXISTS public.contatos (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  nome text NOT NULL,
  email text NOT NULL,
  mensagem text NOT NULL,
  lido boolean DEFAULT false
);

ALTER TABLE public.contatos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "contatos_insert" ON public.contatos FOR INSERT WITH CHECK (true);
CREATE POLICY "contatos_read" ON public.contatos FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);
CREATE POLICY "contatos_update" ON public.contatos FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- 10. PROTÓTIPOS E REDES
CREATE TABLE IF NOT EXISTS public.prototipos_redes (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  titulo text NOT NULL,
  descricao text,
  conteudo text,
  tipo text CHECK (tipo IN ('prototipo','modelo_rede','referencia')),
  publicado boolean DEFAULT true
);

ALTER TABLE public.prototipos_redes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "proto_select" ON public.prototipos_redes FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "proto_manage" ON public.prototipos_redes FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- 11. FÓRUM (placeholder)
CREATE TABLE IF NOT EXISTS public.forum_topicos (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  titulo text NOT NULL,
  descricao text,
  tipo text NOT NULL CHECK (tipo IN ('publico','privado')),
  status text NOT NULL DEFAULT 'em_breve' CHECK (status IN ('ativo','em_breve','encerrado')),
  user_id uuid REFERENCES auth.users(id)
);

ALTER TABLE public.forum_topicos ENABLE ROW LEVEL SECURITY;

-- Fórum público: leitura para qualquer um (incl. visitante anon), só tópicos tipo público
CREATE POLICY "forum_pub_select" ON public.forum_topicos FOR SELECT USING (tipo = 'publico');
CREATE POLICY "forum_priv_select" ON public.forum_topicos FOR SELECT USING (
  tipo = 'privado' AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);
CREATE POLICY "forum_manage" ON public.forum_topicos FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- 12. CRONOGRAMA
CREATE TABLE IF NOT EXISTS public.cronograma (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  titulo text NOT NULL,
  descricao text,
  data_inicio date,
  data_fim date,
  status text NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','em_andamento','concluido','atrasado')),
  responsavel uuid REFERENCES auth.users(id),
  ordem integer DEFAULT 0
);

ALTER TABLE public.cronograma ENABLE ROW LEVEL SECURITY;

CREATE POLICY "crono_gestao" ON public.cronograma FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- 13. ATIVIDADES DA GESTÃO
CREATE TABLE IF NOT EXISTS public.atividades_gestao (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  titulo text NOT NULL,
  descricao text,
  data_atividade date NOT NULL,
  horario_inicio time,
  horario_fim time,
  tipo text CHECK (tipo IN ('reuniao','prazo','acao','evento','outro')),
  responsavel uuid REFERENCES auth.users(id),
  status text DEFAULT 'agendada' CHECK (status IN ('agendada','realizada','cancelada'))
);

ALTER TABLE public.atividades_gestao ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ativ_gestao" ON public.atividades_gestao FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- 14. ENCAMINHAMENTOS
CREATE TABLE IF NOT EXISTS public.encaminhamentos (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  origem text NOT NULL,
  destino text NOT NULL,
  servico text,
  circunscricao text,
  descricao text,
  data_encaminhamento date DEFAULT CURRENT_DATE,
  status text NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','em_andamento','concluido','cancelado')),
  responsavel uuid REFERENCES auth.users(id),
  observacoes text
);

ALTER TABLE public.encaminhamentos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "encam_gestao" ON public.encaminhamentos FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- 15. EQUIPE DO PROJETO
CREATE TABLE IF NOT EXISTS public.equipe_projeto (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  user_id uuid REFERENCES auth.users(id),
  nome text NOT NULL,
  funcao text,
  contato text,
  circunscricao text,
  status text DEFAULT 'ativo' CHECK (status IN ('ativo','inativo'))
);

ALTER TABLE public.equipe_projeto ENABLE ROW LEVEL SECURITY;

CREATE POLICY "equipe_gestao" ON public.equipe_projeto FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- 16. PARCEIROS / PONTES / LEVANTAMENTO
CREATE TABLE IF NOT EXISTS public.parceiros_pontes (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  nome text NOT NULL,
  tipo text NOT NULL CHECK (tipo IN ('parceiro','ponte','levantamento')),
  circunscricao text,
  descricao text,
  contato text,
  status text DEFAULT 'identificado' CHECK (status IN ('identificado','em_contato','confirmado','inativo')),
  data_ultimo_contato date,
  observacoes text,
  responsavel uuid REFERENCES auth.users(id)
);

ALTER TABLE public.parceiros_pontes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "parceiros_gestao" ON public.parceiros_pontes FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- 17. REGISTRO DE ATIVIDADES
CREATE TABLE IF NOT EXISTS public.registro_atividades (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  data_atividade date NOT NULL DEFAULT CURRENT_DATE,
  responsavel uuid REFERENCES auth.users(id),
  tipo_atividade text,
  circunscricao text,
  descricao text NOT NULL,
  resultados text,
  proximos_passos text
);

ALTER TABLE public.registro_atividades ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reg_ativ_gestao" ON public.registro_atividades FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('gestao','admin'))
);

-- Índices (consultas e filtros)
CREATE INDEX IF NOT EXISTS idx_rodas_circ ON public.rodas (circunscricao);
CREATE INDEX IF NOT EXISTS idx_rodas_dia ON public.rodas (dia_semana);
CREATE INDEX IF NOT EXISTS idx_rodas_status ON public.rodas (status);
CREATE INDEX IF NOT EXISTS idx_rodas_horario ON public.rodas (horario_inicio);
CREATE INDEX IF NOT EXISTS idx_noticias_pub ON public.noticias (publicado);
CREATE INDEX IF NOT EXISTS idx_noticias_created ON public.noticias (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_editais_pub ON public.editais (publicado);
CREATE INDEX IF NOT EXISTS idx_editais_created ON public.editais (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usuario_rodas_user ON public.usuario_rodas (user_id);
CREATE INDEX IF NOT EXISTS idx_usuario_rodas_roda ON public.usuario_rodas (roda_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles (role);
CREATE INDEX IF NOT EXISTS idx_rede_df_circ ON public.rede_df (circunscricao);
CREATE INDEX IF NOT EXISTS idx_rede_df_tipo ON public.rede_df (tipo_equipamento);

-- Perfis em falta (utilizadores auth criados antes do trigger / migrações)
INSERT INTO public.profiles (id, email, nome, role)
SELECT
  u.id,
  u.email,
  COALESCE(u.raw_user_meta_data->>'full_name', split_part(COALESCE(u.email, 'user'), '@', 1)),
  CASE WHEN u.email = 'giselle.trevizo@gmail.com' THEN 'admin' ELSE 'comum' END
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
ON CONFLICT (id) DO NOTHING;

-- GRANTS (Supabase REST + anon)
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;

-- Anon: inserções públicas permitidas por RLS
GRANT INSERT ON public.contatos TO anon;
GRANT INSERT ON public.rodas TO anon;
GRANT INSERT ON public.usuario_rodas TO anon;
GRANT INSERT ON public.profiles TO anon;

-- Realtime: calendário público
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'rodas'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rodas;
  END IF;
END $$;

-- SEED: 1 RODA EXEMPLO
INSERT INTO public.rodas (
  circunscricao, tipo, status, nome, instituicao, responsavel,
  dia_semana, horario_inicio, horario_fim, frequencia, observacao_frequencia,
  endereco, bairro, telefone, instagram, descricao, historico
)
SELECT
  'Gama', 'permanente', 'confirmada', 'Rede ELAS – Roda Mensal',
  'MPDFT / Rede de Enfrentamento à Violência contra a Mulher do Gama',
  'Coordenação da Rede ELAS', 'terca', '19:00', '21:00', 'quinzenal',
  'Última terça-feira de cada mês',
  'Promotoria de Justiça do Gama – Setor Leste Industrial', 'Gama',
  '(61) 3343-9500', '@elas_rede_de_enfrentamento',
  'Roda interinstitucional de diálogo sobre enfrentamento à violência contra a mulher. Reúne justiça, segurança pública, saúde, educação e assistência social.',
  'Ativa desde fevereiro de 2015. Mais de 10 anos de funcionamento contínuo.'
WHERE NOT EXISTS (SELECT 1 FROM public.rodas WHERE nome = 'Rede ELAS – Roda Mensal');

-- SEED: FÓRUM PLACEHOLDERS
INSERT INTO public.forum_topicos (titulo, descricao, tipo, status)
SELECT 'Fórum Público – Rede de Mulheres DF',
  'Espaço futuro de debate aberto sobre enfrentamento à violência contra a mulher no DF. Aberto a todas as participantes da rede. Tópicos: políticas públicas, experiências, sugestões.',
  'publico', 'em_breve'
WHERE NOT EXISTS (SELECT 1 FROM public.forum_topicos WHERE titulo = 'Fórum Público – Rede de Mulheres DF');

INSERT INTO public.forum_topicos (titulo, descricao, tipo, status)
SELECT 'Fórum Privado – Equipe do Projeto Rodas',
  'Espaço reservado para debates internos da equipe de gestão. Foco: decisões estratégicas, alinhamento, discussões sensíveis do projeto.',
  'privado', 'em_breve'
WHERE NOT EXISTS (SELECT 1 FROM public.forum_topicos WHERE titulo = 'Fórum Privado – Equipe do Projeto Rodas');

-- Exemplos para a landing (opcional)
INSERT INTO public.noticias (titulo, resumo, conteudo, publicado, data_publicacao)
SELECT
  'Bem-vinda à Rede de Rodas do DF',
  'Articulação, apoio e fortalecimento de rodas de conversa para mulheres no DF.',
  'Este é um conteúdo de exemplo. Substitua ou publique novas notícias pela área de gestão.',
  true,
  CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM public.noticias WHERE titulo = 'Bem-vinda à Rede de Rodas do DF');

INSERT INTO public.editais (titulo, descricao, publicado, data_abertura, data_encerramento)
SELECT
  'Capacitação de facilitadoras — ciclo em aberto',
  'Edital de referência. Atualize datas e link do arquivo na gestão.',
  true,
  CURRENT_DATE,
  CURRENT_DATE + 60
WHERE NOT EXISTS (SELECT 1 FROM public.editais WHERE titulo ILIKE '%Capacitação de facilitadoras%');

INSERT INTO public.bases_conhecimento (titulo, descricao, url, categoria, publicado)
SELECT
  'NotebookLM — bases do projeto',
  'Organize materiais e referências em bases de conhecimento (Google NotebookLM).',
  'https://notebooklm.google.com/',
  'Ferramenta',
  true
WHERE NOT EXISTS (SELECT 1 FROM public.bases_conhecimento WHERE titulo ILIKE '%NotebookLM%');

-- ----------------------------------------------------------------
-- Fim do schema. Verificações úteis (SQL Editor):
--   SELECT tablename, policyname FROM pg_policies WHERE schemaname='public' ORDER BY tablename;
--   SELECT COUNT(*) FROM public.profiles;
--   SELECT COUNT(*) FROM public.rodas;
-- Se o trigger on_auth_user_created falhar: em PG antigo use EXECUTE PROCEDURE em vez de EXECUTE FUNCTION.
-- ----------------------------------------------------------------

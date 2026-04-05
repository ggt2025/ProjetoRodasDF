-- =============================================================================
-- Rede de Rodas do DF — schema + dados iniciais + RLS (Supabase / PostgreSQL)
-- Arquivo único na raiz do projeto para provisionar tudo que o painel HTML usa.
--
-- O QUE COBRE
--   • Tabelas: team_members, partners, tasks, comments, activity_log, public_news
--   • Coluna tasks.start_date (cronograma)
--   • Políticas RLS permissivas (authenticated + anon) — equipe fechada; revise em produção
--   • Seeds: equipe, parceiros, encaminhamentos, comentários de exemplo, notícia pública
--
-- O QUE NÃO ESTÁ NO BANCO (fica no navegador)
--   • Aba «Rodas DF» (rodas_levantamento.js + localStorage rdf_rodas_rows_v1)
--   • Aba «Pontes» (localStorage rdf_pontes_v1)
--
-- COMO RODAR
--   1) Supabase → SQL → New query → colar este arquivo → Run
--   2) Authentication: criar usuários; em Settings → API copiar URL e anon key no index.html
--   3) Se o projeto já tinha tabelas, o script usa IF NOT EXISTS / NOT EXISTS para evitar duplicar linhas
-- =============================================================================

-- Extensão para gen_random_uuid() (já habilitada na maioria dos projetos Supabase)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =============================================================================
-- 1) TABELAS
-- =============================================================================

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
  is_published boolean NOT NULL DEFAULT true,
  sort_order int DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public_news ADD COLUMN IF NOT EXISTS image_url text DEFAULT '';
COMMENT ON COLUMN public_news.image_url IS 'URL da imagem do card na página inicial (carrossel).';

-- Coluna usada pelo cronograma (timeline) no painel
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS start_date date;
COMMENT ON COLUMN tasks.start_date IS 'Início da barra no cronograma; se NULL, o app usa ~3 semanas antes de due_date.';

CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks (assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks (due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_phase ON tasks (phase);

ALTER TABLE tasks ADD COLUMN IF NOT EXISTS delivery_helper_id uuid REFERENCES team_members (id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_delivery_helper ON tasks (delivery_helper_id);
COMMENT ON COLUMN tasks.delivery_helper_id IS 'Apoio à entrega / peer: acompanha prazo e apoia o responsável direto; sorteio diverso no app.';
CREATE INDEX IF NOT EXISTS idx_comments_task_id ON comments (task_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_created ON activity_log (created_at DESC);

-- =============================================================================
-- 2) SEED — equipe (alinhado ao DEMO_TEAM do index.html)
-- =============================================================================

INSERT INTO team_members (name, email, organization, role, avatar_color, expertise, is_active, notes)
SELECT 'Natalie', NULL, 'Rede de Rodas do DF', 'coordenadora', '#e11d48', ARRAY['gestao','articulacao']::text[], true,
  'Coordenação da rede (fase inicial como pessoas físicas; constituição formal de associação/ONG prevista como etapa posterior). Contatos: Laura (psicóloga). Articulação com o Projeto Maria da Penha (Lívia Gimines): retomar conversa quando o arranjo institucional estiver estruturado. Autora dos protótipos metodológicos na aba «Protótipos» (triagem, pactuação, fluxo, lista segura, MPP, ex ante).'
WHERE NOT EXISTS (SELECT 1 FROM team_members tm WHERE tm.name = 'Natalie');

INSERT INTO team_members (name, email, organization, role, avatar_color, expertise, is_active, notes)
SELECT 'Thaís', NULL, 'MPDFT', 'coordenadora', '#7c3aed', ARRAY['direito','articulacao_institucional']::text[], true,
  'Coordenação MPDFT e articulação institucional. Contatos: UNB (Prof.ª Cândida), Ouvidoria das Mulheres, Secretaria da Mulher (DF). Adalgiza (Núcleo de Gênero): pode fazer ponte com o projeto Todas Elas; interlocução via Thaís. Projeto Maria da Penha: Lívia Gimines — Natalie retoma quando estruturado. Com Giselle: frente SEMA na tarefa de cadastro do projeto / cesta básica (Giselle com COGE).'
WHERE NOT EXISTS (SELECT 1 FROM team_members tm WHERE tm.name = 'Thaís');

INSERT INTO team_members (name, email, organization, role, avatar_color, expertise, is_active, notes)
SELECT 'Giselle', 'giselle.trevizo@gmail.com', 'MPDFT', 'apoio_tecnico', '#2563eb', ARRAY['tecnologia','desenvolvimento','formacao']::text[], true,
  'Apoio tecnológico ao painel e ferramentas digitais; participação na capacitação (turma piloto e módulos acordados no currículo). Com Thaís: falar com o COGE para cadastro do projeto e possibilidade de cesta básica / apoio em espécie (Thaís articula a frente SEMA). Fora essa dupla, sem pontes institucionais de articulação.'
WHERE NOT EXISTS (SELECT 1 FROM team_members tm WHERE tm.name = 'Giselle');

INSERT INTO team_members (name, email, organization, role, avatar_color, expertise, is_active, notes)
SELECT 'Cândida', NULL, 'UNB', 'docente', '#059669', ARRAY['psicologia']::text[], true,
  'Professora titular Psicologia UNB (contato via Thaís). Nada confirmado formalmente até o momento.'
WHERE NOT EXISTS (SELECT 1 FROM team_members tm WHERE tm.name = 'Cândida');

INSERT INTO team_members (name, email, organization, role, avatar_color, expertise, is_active, notes)
SELECT 'Laura', NULL, 'A confirmar', 'docente', '#d97706', ARRAY['psicologia']::text[], true,
  'Psicóloga. Contato via Natalie. Aguardando confirmação.'
WHERE NOT EXISTS (SELECT 1 FROM team_members tm WHERE tm.name = 'Laura');

INSERT INTO team_members (name, email, organization, role, avatar_color, expertise, is_active, notes)
SELECT 'Márcia', NULL, 'IML', 'docente', '#0891b2', ARRAY['psicologia']::text[], true,
  'Psicóloga no IML (Instituto de Medicina Legal). Possível contribuição técnica pontual no módulo de violência, a título pessoal/profissional. Não há parceria institucional com o IML — o projeto não tem vínculo com o órgão.'
WHERE NOT EXISTS (SELECT 1 FROM team_members tm WHERE tm.name = 'Márcia');

-- =============================================================================
-- 3) SEED — parceiros (alinhado ao DEMO_PARTNERS; sem linha “IML” como parceiro)
-- =============================================================================

INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes)
SELECT 'MPDFT', 'institucional', 'Thaís', 'em_andamento',
  'Espaço físico, apoio técnico, co-certificação, legitimidade institucional',
  'Ampliação rede de proteção, dados de mapeamento',
  'Parceiro principal. Contato institucional: Thaís. Giselle: painel digital e participação na capacitação (conteúdo/módulos definidos com a equipe).'
WHERE NOT EXISTS (SELECT 1 FROM partners p WHERE p.name ILIKE 'MPDFT');

INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes)
SELECT 'Instituto Mãos Solidárias (IMS)', 'ong_parceira', '—', 'pendente',
  'Casas sociais com mulheres; espaço para rodas-piloto',
  'Rodas de acolhimento para beneficiárias',
  'Local do piloto.'
WHERE NOT EXISTS (SELECT 1 FROM partners p WHERE p.name ILIKE '%Mãos Solidárias%' OR p.name ILIKE '%(IMS)%');

INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes)
SELECT 'UNB — Pós-graduação Psicologia', 'academico',
  'Thaís (interlocução UNB; Prof.ª Cândida — sem confirmação)', 'pendente',
  'Estudantes facilitadoras; validação de horas; rede de alunos',
  'Campo de prática; dados para pesquisa',
  'Parceria acadêmica em negociação. Contato e follow-up: Thaís. Retorno da UNB/Cândida ainda pendente.'
WHERE NOT EXISTS (SELECT 1 FROM partners p WHERE p.name ILIKE '%UNB%' AND p.name ILIKE '%Psicologia%');

INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes)
SELECT 'Ouvidoria das Mulheres — MPDFT', 'institucional', 'Ouvidora (a identificar)', 'pendente',
  'Canal fixo de denúncias via QR Code nas rodas',
  'Denúncias qualificadas; capilaridade',
  'QR Code obrigatório em toda roda.'
WHERE NOT EXISTS (SELECT 1 FROM partners p WHERE p.name ILIKE '%Ouvidoria das Mulheres%');

INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes)
SELECT 'Abrigos de mulheres do DF', 'abrigo', '—', 'pendente',
  'Acesso às mulheres abrigadas; espaço para rodas',
  'Rodas regulares',
  'Mapear na Fase 2.'
WHERE NOT EXISTS (SELECT 1 FROM partners p WHERE p.name ILIKE '%Abrigos de mulheres%');

INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes)
SELECT 'Núcleo de Gênero — MPDFT', 'institucional', 'Adalgiza (interlocução: Thaís)', 'pendente',
  'Políticas de gênero, alinhamento institucional com rodas e capacitação; ponte com a rede territorial Todas Elas (via Adalgiza, conforme articulação).',
  'Integração com rede de proteção e projeto',
  'Thaís articula com Adalgiza. Adalgiza pode fazer ponte com o projeto Todas Elas. Fase 0 — maio/2026.'
WHERE NOT EXISTS (SELECT 1 FROM partners p WHERE p.name ILIKE '%Núcleo de Gênero%');

INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes)
SELECT 'Projeto Maria da Penha — MPDFT', 'institucional', 'Lívia Gimines', 'pendente',
  'Interface com políticas e ações do projeto Maria da Penha no âmbito do MPDFT',
  'Convergência com capacitação, rodas e psicoeducação em direitos',
  'Natalie retoma contato com Lívia quando o fluxo estiver estruturado. Thaís pode apoiar alinhamento institucional.'
WHERE NOT EXISTS (SELECT 1 FROM partners p WHERE p.name ILIKE '%Projeto Maria da Penha%');

-- =============================================================================
-- 4) SEED — encaminhamentos / tasks (alinhado ao DEMO_TASKS do index.html)
-- =============================================================================

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Organizar atuação inicial como pessoas físicas (pré-associação)',
  'Definir como o grupo atua juridicamente e operacionalmente sem CNPJ: papéis (coordenação, contratos cedentes, parcerias via MPDFT/piloto), registros e prestações de contas compatíveis com pessoa física até consolidar o teste de campo.',
  'fase_0_semente', 'pendente', 'urgente', m.id, '2026-05-20', NULL,
  'Fase 0 — maio/2026. Primeiro: validar piloto e articulação institucional no modelo PF. Constituir associação/ONG (estatuto e CNPJ) fica como passo posterior — ver encaminhamento na Fase 2.'
FROM team_members m
WHERE m.name = 'Natalie'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Organizar atuação inicial como pessoas físicas (pré-associação)')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Constituir associação/ONG — estatuto e CNPJ',
  'Redigir estatuto social, registrar em cartório, obter CNPJ — depois de validar a atuação como pessoas físicas e o piloto no terreno.',
  'fase_2_enraizamento', 'pendente', 'alta', m.id, '2026-07-31', NULL,
  'Passo à frente: não é pré-requisito para a turma piloto nem para as rodas-piloto com apoio MPDFT. Modelo típico: associação civil sem fins lucrativos.'
FROM team_members m
WHERE m.name = 'Natalie'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Constituir associação/ONG — estatuto e CNPJ')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Análise de cobertura territorial e demandas reprimidas',
  'Estudar onde existe roda ou equipamento mas o alcance não cobre zona rural, núcleos isolados ou bairros periféricos; cruzar oferta do levantamento com relatos de lacuna (transporte, divulgação, medo, horário). Documentar na aba Levantamento e subsidiar decisões de itinerância/parcerias.',
  'fase_0_semente', 'pendente', 'alta', m.id, '2026-05-25', NULL,
  'Fase de análise pré-capacitação. Ver Protótipos §9 e Parte 5 «lacunas» no Rodas DF como ponto de partida, sem substituir escuta no território.'
FROM team_members m
WHERE m.name = 'Natalie'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Análise de cobertura territorial e demandas reprimidas')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Fase final: consolidar fluxo, rede e plano de novas rodas (demanda reprimida)',
  'Documentar fluxo operacional consolidado; mapear rede de parcerias e calendário territorial; priorizar e formular novas rodas ou itinerâncias para territórios com demanda reprimida identificados no levantamento (§9), com critérios ex ante por local.',
  'fase_5_sustentabilidade', 'pendente', 'alta', m.id, '2026-10-25', '2026-10-01',
  'Fase 5 (out/2026). Protótipos §10. Articulação institucional: Thaís; desenho de novas rodas: equipe com Natalie. Ajustar datas conforme cronograma real.'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Fase final: consolidar fluxo, rede e plano de novas rodas (demanda reprimida)')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Falar com Laura (psicóloga)', 'Natalie entra em contato com Laura para convidar como docente.', 'fase_0_semente', 'pendente', 'alta', m.id, '2026-05-18', NULL,
  'Fase 0 — maio/2026. Confirmar contato até o fim do mês.'
FROM team_members m
WHERE m.name = 'Natalie'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Falar com Laura (psicóloga)')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Falar com Cândida (UNB)', 'Thaís conduz o contato com a Prof.ª Cândida (UNB) para apresentar o projeto e negociar parceria acadêmica.', 'fase_0_semente', 'pendente', 'alta', m.id, '2026-05-22', NULL,
  'Fase 0 — maio/2026. Aguardando resposta/confirmação da UNB.'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Falar com Cândida (UNB)')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Apresentar projeto à Secretaria da Mulher (DF)', 'Agendar e realizar apresentação institucional da Rede de Rodas do DF junto à Secretaria da Mulher do Distrito Federal (articulação GDF/MPDFT conforme calendário).', 'fase_0_semente', 'pendente', 'urgente', m.id, '2026-05-14', NULL,
  'Fase 0 — maio/2026. Responsável: Thaís (articulação institucional).'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%Secretaria da Mulher%')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Falar com Ouvidora das Mulheres do MPDFT', 'Canal fixo de denúncias via QR Code nas rodas.', 'fase_0_semente', 'pendente', 'urgente', m.id, '2026-05-08', NULL,
  'Fase 0 — maio/2026. QR obrigatório em toda roda.'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%Ouvidora das Mulheres%')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Falar com Adalgiza — Núcleo de Gênero (MPDFT)',
  'Articular com Adalgiza do Núcleo de Gênero do MPDFT: apresentar a Rede de Rodas do DF, alinhar capacitação, encaminhamentos e visão de gênero no projeto. Explorar Adalgiza como ponte com o projeto Todas Elas (rede territorial). Em paralelo: Projeto Maria da Penha (Lívia Gimines) — Natalie retoma quando estiver estruturado.',
  'fase_0_semente', 'pendente', 'alta', m.id, '2026-05-11', NULL,
  'Fase 0 — maio/2026. Responsável: Thaís. Todas Elas: via Adalgiza/NG. Maria da Penha/Lívia: Natalie após estruturação.'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%Adalgiza%')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Projeto Maria da Penha — retomar com Lívia Gimines',
  'Quando o arranjo institucional estiver estruturado, Natalie retoma o diálogo com Lívia Gimines (Projeto Maria da Penha / MPDFT) para alinhar convergência com capacitação, rodas e psicoeducação em direitos.',
  'fase_0_semente', 'pendente', 'media', m.id, '2026-06-30', NULL,
  'Aguardar estruturação. Thaís pode apoiar contexto institucional MPDFT.'
FROM team_members m
WHERE m.name = 'Natalie'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%Maria da Penha%' AND t.title ILIKE '%Lívia%')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'SEMA e COGE — cadastro do projeto, cesta básica e apoio',
  'Articulação conjunta: Thaís puxa a frente com a SEMA (Secretaria / interlocução acordada no MPDFT–GDF). Giselle trata com o COGE o cadastro formal do projeto e o que for necessário para viabilizar apoio em espécie (ex.: cesta básica), conforme regramento do órgão.',
  'fase_0_semente', 'pendente', 'alta', m.id, '2026-05-29', NULL,
  'Tarefa em dupla. Thaís: SEMA. Giselle: COGE (falar para destravar cadastro e possibilidade de cesta básica). Alinhar entre si antes de comprometer prazos.'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%SEMA%' AND t.title ILIKE '%COGE%')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Contatar Dra. Sofia — MP/PJ (Henry Borel)', 'Ligar ou agendar contato com a Dra. Sofia na promotoria (Ministério Público) no âmbito do caso Henry Borel — alinhar possível articulação ou informações úteis à Rede de Rodas do DF.', 'fase_0_semente', 'pendente', 'alta', m.id, '2026-04-18', NULL,
  'Responsável: Giselle. Registrar retorno nas notas da tarefa.'
FROM team_members m
WHERE m.name = 'Giselle'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%Henry Borel%' OR t.title ILIKE '%Dra. Sofia%')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Acordo técnico com o NUAV (MPDFT)', 'Formalizar ou alinhar acordo técnico com o NUAV (Núcleo de Apoio à Vítima / atenção à vítima no MPDFT-DF): fluxos de encaminhamento, linguagem de acolhimento e interface com capacitação e rodas — sem sobrepor competências.', 'fase_1_piloto', 'pendente', 'alta', m.id, '2026-06-15', '2026-06-01',
  'Fase correta: Fase 1 (piloto) — coincidir com 1ª turma e preparação das rodas-piloto. Responsável: Thaís. Ajustar prazo se a coordenação fixar outra etapa.'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%NUAV%')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Organizar estrutura do curso', 'Currículo 40h, selecionar docentes, cronograma.', 'fase_0_semente', 'em_andamento', 'urgente', m.id, '2026-05-28', '2026-05-01',
  'Fase 0 — maio/2026. Módulo Psicologia/UNB: Cândida (Thaís). Módulo violência: Márcia (IML) só apoio pontual — sem parceria IML. Giselle: material digital do painel e participação na capacitação (módulos acordados).'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Organizar estrutura do curso')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Alinhar rede de alunos UNB com Cândida', 'Após retorno da UNB: captação de estudantes de pós-graduação.', 'fase_0_semente', 'pendente', 'alta', m.id, '2026-05-26', NULL,
  'Fase 0 — maio/2026. Contato: Thaís. Depende de confirmação UNB e carta de intenções.'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Alinhar rede de alunos UNB com Cândida')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Elaborar palestras de Direito', 'Lei Maria da Penha, medidas protetivas, rede DF.', 'fase_0_semente', 'pendente', 'alta', m.id, '2026-05-24', NULL,
  'Fase 0 — maio/2026. Integrar com Módulo 3. Coordenação MPDFT (Thaís).'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Elaborar palestras de Direito')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Reunião de alinhamento — equipe fundadora', 'Alinhar visão, responsabilidades e cronograma.', 'fase_0_semente', 'pendente', 'urgente', m.id, '2026-05-12', NULL,
  'Fase 0 — maio/2026. Presencial no MPDFT. Condução: Thaís.'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Reunião de alinhamento — equipe fundadora')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Formalizar diálogo com IMS', 'Apresentar projeto e propor parceria para piloto.', 'fase_0_semente', 'pendente', 'alta', m.id, '2026-05-16', NULL,
  'Fase 0 — maio/2026. Casas sociais com mulheres.'
FROM team_members m
WHERE m.name = 'Natalie'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Formalizar diálogo com IMS')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Criar identidade visual', 'Logo, cores, templates, QR Code.', 'fase_0_semente', 'pendente', 'media', m.id, '2026-05-30', NULL,
  'Fase 0 — maio/2026. Canva.'
FROM team_members m
WHERE m.name = 'Natalie'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Criar identidade visual')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT '1ª turma de capacitação (piloto)', '10-15 participantes, 40h.', 'fase_1_piloto', 'pendente', 'alta', m.id, '2026-06-20', '2026-06-01',
  'Fase 1 — jun/2026. Depende do currículo (Fase 0). Logística e condução institucional: Thaís. Giselle participa da capacitação (conteúdo/presença conforme currículo) e apoio aos materiais digitais.'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%1ª turma de capacitação%')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Implantar rodas-piloto no IMS', '2+ rodas regulares com QR da Ouvidoria.', 'fase_1_piloto', 'pendente', 'alta', m.id, '2026-06-28', '2026-06-10',
  'Fase 1 — jun/2026. Meta: 8 sessões, 40+ mulheres.'
FROM team_members m
WHERE m.name = 'Natalie'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%rodas-piloto no IMS%')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Avaliar metodologia pós-piloto', 'Feedback e relatório.', 'fase_1_piloto', 'pendente', 'media', m.id, '2026-06-26', NULL,
  'Fase 1 — jun/2026. Coordenação: Thaís. Base para Fase 2 (jul).'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Avaliar metodologia pós-piloto')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Termo de Cooperação MPDFT', 'Cessão de espaço, apoio técnico, co-certificação.', 'fase_2_enraizamento', 'pendente', 'alta', m.id, '2026-07-08', NULL,
  'Fase 2 — jul/2026. Thaís articula.'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Termo de Cooperação MPDFT')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Convênio com UNB', 'Validação de horas pós-graduação.', 'fase_2_enraizamento', 'pendente', 'alta', m.id, '2026-07-15', NULL,
  'Fase 2 — jul/2026. Após piloto (jun).'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Convênio com UNB')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'SEMA/MPDFT doação de materiais', 'Cadeiras, impressos, equipamentos.', 'fase_2_enraizamento', 'pendente', 'media', m.id, '2026-07-22', NULL,
  'Fase 2 — jul/2026.'
FROM team_members m
WHERE m.name = 'Thaís'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%SEMA/MPDFT%')
LIMIT 1;

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, start_date, notes)
SELECT 'Expandir rodas para abrigos', 'Mapear abrigos sem rodas.', 'fase_2_enraizamento', 'pendente', 'alta', m.id, '2026-07-28', NULL,
  'Fase 2 — jul/2026. Abrigos sem rodas.'
FROM team_members m
WHERE m.name = 'Natalie'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title = 'Expandir rodas para abrigos')
LIMIT 1;

-- =============================================================================
-- 5) SEED — comentários de exemplo (DEMO_COMMENTS)
-- =============================================================================

INSERT INTO comments (task_id, user_name, content, is_system, created_at)
SELECT t.id, 'Thaís', 'Primeiro contato enviado à Prof.ª Cândida; aguardando retorno formal. Nada confirmado ainda.', false, '2026-04-04T09:00:00+00'::timestamptz
FROM tasks t
WHERE t.title = 'Falar com Cândida (UNB)'
  AND NOT EXISTS (SELECT 1 FROM comments c JOIN tasks t2 ON c.task_id = t2.id WHERE t2.title = 'Falar com Cândida (UNB)')
LIMIT 1;

INSERT INTO comments (task_id, user_name, content, is_system, created_at)
SELECT t.id, 'Thaís', 'Estrutura do curso segue; módulo de Psicologia/UNB só fecha depois da confirmação com a Cândida. Módulo violência: Márcia (psicóloga do IML) pode ajudar pontualmente — sem parceria com o IML. Giselle segue no painel e também vai participar da capacitação piloto.', false, '2026-04-04T10:00:00+00'::timestamptz
FROM tasks t
WHERE t.title = 'Organizar estrutura do curso'
  AND NOT EXISTS (SELECT 1 FROM comments c JOIN tasks t2 ON c.task_id = t2.id WHERE t2.title = 'Organizar estrutura do curso')
LIMIT 1;

INSERT INTO comments (task_id, user_name, content, is_system, created_at)
SELECT t.id, 'Thaís', 'QR Code é excelente. Cada roda terá um cartaz com QR fixo da Ouvidoria. Simples e poderoso.', false, '2026-04-04T11:00:00+00'::timestamptz
FROM tasks t
WHERE t.title ILIKE '%Ouvidora das Mulheres%'
  AND NOT EXISTS (
    SELECT 1 FROM comments c
    JOIN tasks t2 ON c.task_id = t2.id
    WHERE t2.title ILIKE '%Ouvidora das Mulheres%' AND c.content ILIKE '%QR Code%'
  )
LIMIT 1;

-- =============================================================================
-- 6) SEED — notícias públicas (página inicial via REST anon)
-- =============================================================================

INSERT INTO public_news (published_on, title, excerpt, body, is_published)
SELECT CURRENT_DATE,
  'Painel e cronograma conectados ao Supabase',
  'Tarefas, prazos e notícias passam a refletir o que está no banco.',
  'A página pública lê a tabela public_news. O cronograma usa due_date e, opcionalmente, start_date em cada tarefa.',
  true
WHERE NOT EXISTS (SELECT 1 FROM public_news LIMIT 1);

-- =============================================================================
-- 7) ROW LEVEL SECURITY + políticas (painel + fallback anon)
-- =============================================================================

ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_news ENABLE ROW LEVEL SECURITY;

-- Limpa nomes antigos se você reexecutar o script
DROP POLICY IF EXISTS "rrdf_auth_all_team" ON team_members;
DROP POLICY IF EXISTS "rrdf_anon_all_team" ON team_members;
DROP POLICY IF EXISTS "rrdf_auth_all_partners" ON partners;
DROP POLICY IF EXISTS "rrdf_anon_all_partners" ON partners;
DROP POLICY IF EXISTS "rrdf_auth_all_tasks" ON tasks;
DROP POLICY IF EXISTS "rrdf_anon_all_tasks" ON tasks;
DROP POLICY IF EXISTS "rrdf_auth_all_comments" ON comments;
DROP POLICY IF EXISTS "rrdf_anon_all_comments" ON comments;
DROP POLICY IF EXISTS "rrdf_auth_all_activity" ON activity_log;
DROP POLICY IF EXISTS "rrdf_anon_all_activity" ON activity_log;
DROP POLICY IF EXISTS "public_news_select_published" ON public_news;
DROP POLICY IF EXISTS "public_news_auth_all" ON public_news;

CREATE POLICY "rrdf_auth_all_team" ON team_members FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_team" ON team_members FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "rrdf_auth_all_partners" ON partners FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_partners" ON partners FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "rrdf_auth_all_tasks" ON tasks FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_tasks" ON tasks FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "rrdf_auth_all_comments" ON comments FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_comments" ON comments FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "rrdf_auth_all_activity" ON activity_log FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_activity" ON activity_log FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "public_news_select_published" ON public_news FOR SELECT TO anon, authenticated
  USING (is_published = true);
CREATE POLICY "public_news_auth_all" ON public_news FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Permissões para API PostgREST (Supabase)
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON team_members, partners, tasks, comments, activity_log TO anon, authenticated;
GRANT SELECT ON public_news TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public_news TO authenticated;

-- =============================================================================
-- Fim. Teste: GET /rest/v1/tasks?select=* e página pública com notícias.
-- =============================================================================

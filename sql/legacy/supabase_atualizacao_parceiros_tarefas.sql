-- ============================================================
-- Rede de Rodas do DF — atualização no Supabase
-- Rode no SQL Editor (Dashboard → SQL → New query).
-- Ajuste nomes de colunas se o seu schema for diferente.
--
-- PRÉ-REQUISITO (enum member_role): se ainda não rodou, execute ANTES,
-- numa query separada (commit obrigatório entre os dois — senão 55P04):
--   sql/00_enum_member_role_apoio_tecnico.sql
-- ============================================================

-- 1) IML não é parceiro institucional (nada fechado com o órgão). Márcia = psicóloga do IML, só referência técnica possível.
DELETE FROM partners
WHERE name ILIKE 'IML'
   OR trim(name) ILIKE 'IML';

-- 2) Garantir IMS listado (só insere se ainda não existir algo parecido)
INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes)
SELECT
  'Instituto Mãos Solidárias (IMS)',
  'ong_parceira',
  '—',
  'pendente',
  'Casas sociais com mulheres; espaço para rodas-piloto',
  'Rodas de acolhimento para beneficiárias',
  'Parceira de ONG para piloto — não confundir com IML.'
WHERE NOT EXISTS (
  SELECT 1 FROM partners p
  WHERE p.name ILIKE '%Mãos Solidárias%' OR p.name ILIKE '%(IMS)%'
);

-- 3) Cancelar encaminhamentos antigos focados em “parceria IML / Márcia”
UPDATE tasks
SET
  status = 'cancelada',
  notes = trim(both ' ' from coalesce(notes, '') || E'\n[Atualização: IML não é parceiro; parceria de piloto é com IMS.]')
WHERE (title ILIKE '%Márcia%' AND title ILIKE '%IML%')
   OR title ILIKE '%Falar com Márcia (IML)%'
   OR (description ILIKE '%IML%' AND description ILIKE '%parceria%');

-- 4) Nova tarefa para Thaís — Secretaria da Mulher (evita duplicar se já existir)
INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, notes)
SELECT
  'Apresentar projeto à Secretaria da Mulher (DF)',
  'Agendar e realizar apresentação institucional da Rede de Rodas do DF junto à Secretaria da Mulher do Distrito Federal (articulação GDF/MPDFT).',
  'fase_0_semente',
  'pendente',
  'urgente',
  tm.id,
  '2026-05-12',
  'Responsável: Thaís (articulação institucional).'
FROM team_members tm
WHERE tm.is_active IS NOT FALSE
  AND tm.name ILIKE '%Thaís%'
  AND NOT EXISTS (
    SELECT 1 FROM tasks t WHERE t.title ILIKE '%Secretaria da Mulher%'
  )
LIMIT 1;

-- 4b) Thaís — contato com Adalgiza (Núcleo de Gênero, MPDFT)
INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, notes)
SELECT
  'Falar com Adalgiza — Núcleo de Gênero (MPDFT)',
  'Articular com Adalgiza do Núcleo de Gênero do MPDFT: apresentar a Rede de Rodas do DF, alinhar capacitação, encaminhamentos e visão de gênero no projeto.',
  'fase_0_semente',
  'pendente',
  'alta',
  tm.id,
  '2026-05-11',
  'Responsável: Thaís. Fase 0 — maio/2026.'
FROM team_members tm
WHERE tm.is_active IS NOT FALSE
  AND tm.name ILIKE '%Thaís%'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%Adalgiza%')
LIMIT 1;

-- 4c) Giselle — contato Dra. Sofia (MP / caso Henry Borel)
INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, notes)
SELECT
  'Contatar Dra. Sofia — MP/PJ (Henry Borel)',
  'Ligar ou agendar contato com a Dra. Sofia na promotoria (Ministério Público) no âmbito do caso Henry Borel — alinhar possível articulação ou informações úteis à Rede de Rodas do DF.',
  'fase_0_semente',
  'pendente',
  'alta',
  tm.id,
  '2026-04-18',
  'Responsável: Giselle. Registrar retorno nas notas da tarefa.'
FROM team_members tm
WHERE tm.is_active IS NOT FALSE
  AND tm.name ILIKE '%Giselle%'
  AND NOT EXISTS (
    SELECT 1 FROM tasks t
    WHERE t.title ILIKE '%Dra. Sofia%' OR t.title ILIKE '%Henry Borel%'
  )
LIMIT 1;

-- 4d) Thaís — acordo técnico com NUAV (MPDFT), Fase 1 (piloto)
INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, notes)
SELECT
  'Acordo técnico com o NUAV (MPDFT)',
  'Formalizar ou alinhar acordo técnico com o NUAV (Núcleo de Apoio à Vítima / atenção à vítima no MPDFT-DF): fluxos de encaminhamento, linguagem de acolhimento e interface com capacitação e rodas — sem sobrepor competências.',
  'fase_1_piloto',
  'pendente',
  'alta',
  tm.id,
  '2026-06-15',
  'Fase correta: Fase 1 (piloto) — alinhar à 1ª turma e às rodas-piloto. Responsável: Thaís. (No app: start_date sugerida 2026-06-01.)'
FROM team_members tm
WHERE tm.is_active IS NOT FALSE
  AND tm.name ILIKE '%Thaís%'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%NUAV%')
LIMIT 1;

-- Opcional (se a coluna start_date existir em tasks): definir início no cronograma jun/2026.
-- UPDATE tasks SET start_date = '2026-06-01' WHERE title ILIKE '%Acordo técnico com o NUAV%' AND start_date IS NULL;

INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes)
SELECT
  'Núcleo de Gênero — MPDFT',
  'institucional',
  'Adalgiza (interlocução: Thaís)',
  'pendente',
  'Políticas de gênero, alinhamento institucional com rodas e capacitação',
  'Integração com rede de proteção e projeto',
  'Thaís articula contato com Adalgiza. Fase 0 — maio/2026.'
WHERE NOT EXISTS (SELECT 1 FROM partners p WHERE p.name ILIKE '%Núcleo de Gênero%');

UPDATE team_members
SET notes = trim(both E'\n' from coalesce(notes, '') || E'\nContato com Adalgiza (Núcleo de Gênero, MPDFT) — articulação: Thaís.')
WHERE name ILIKE '%Thaís%'
  AND (notes IS NULL OR notes NOT ILIKE '%Adalgiza%');

-- 5) Ajustar nota de tarefa de currículo (Márcia/IML só referência técnica; sem parceria com o órgão)
UPDATE tasks
SET notes = 'Módulo Psicologia/UNB: depende de confirmação com Cândida (contato: Thaís). Módulo violência: eventual apoio técnico pontual (ex.: Márcia, psicóloga do IML) — sem parceria institucional com o IML; nada fechado com o órgão. Giselle: material digital do painel e participação na capacitação (módulos acordados).'
WHERE title ILIKE '%Organizar estrutura do curso%';

UPDATE tasks
SET notes = 'Fase 1 — jun/2026. Depende do currículo (Fase 0). Logística e condução institucional: Thaís. Giselle participa da capacitação (conteúdo/presença conforme currículo) e apoio aos materiais digitais.'
WHERE title ILIKE '%turma de capacitação%' OR title ILIKE '%capacitação (piloto)%';

-- 5b) Giselle: apoio ao painel + capacitação — realoca tarefas de ponte/reunião que estavam com ela para Thaís
UPDATE team_members
SET
  role = 'apoio_tecnico',
  notes = 'Apoio tecnológico ao painel/ferramentas digitais; participação na capacitação (turma piloto e módulos acordados no currículo). Sem pontes institucionais nem reuniões de articulação.'
WHERE name ILIKE '%Giselle%';

UPDATE tasks
SET notes = replace(replace(notes, 'Alinhar pauta com Giselle antes da reunião.', 'Articulação institucional: Thaís.'),
                    'Alinhar pauta com Giselle antes da reunião', 'Articulação institucional: Thaís')
WHERE notes ILIKE '%Giselle%' AND notes ILIKE '%reunião%';

WITH g AS (SELECT id FROM team_members WHERE name ILIKE '%Giselle%' LIMIT 1),
     th AS (SELECT id FROM team_members WHERE name ILIKE '%Thaís%' LIMIT 1)
UPDATE tasks t
SET assigned_to = th.id
FROM g, th
WHERE t.assigned_to = g.id AND g.id IS NOT NULL AND th.id IS NOT NULL;

-- MPDFT: contato institucional só Thaís (ajuste manual em `notes` do parceiro se precisar)
UPDATE partners
SET contact_person = replace(replace(contact_person, 'Thaís / Giselle', 'Thaís'), 'Giselle / Thaís', 'Thaís')
WHERE name ILIKE '%MPDFT%';

UPDATE partners
SET contact_person = 'Thaís'
WHERE name ILIKE '%MPDFT%' AND contact_person ILIKE '%Giselle%';

-- 5c) UNB / Cândida: parceria não confirmada — contato e tarefas com a Thaís
UPDATE team_members
SET notes = 'Professora titular Psicologia UNB (contato via Thaís). Nada confirmado formalmente até o momento.'
WHERE name ILIKE '%Cândida%';

UPDATE partners
SET
  status = 'pendente',
  contact_person = 'Thaís (interlocução UNB; Prof.ª Cândida — sem confirmação)',
  notes = 'Parceria acadêmica em negociação. Contato e follow-up: Thaís. Retorno da UNB/Cândida ainda pendente.'
WHERE name ILIKE '%UNB%' AND (name ILIKE '%Psicologia%' OR name ILIKE '%Pós%');

UPDATE tasks
SET
  status = 'pendente',
  completed_at = NULL,
  description = 'Thaís conduz o contato com a Prof.ª Cândida (UNB) para apresentar o projeto e negociar parceria acadêmica.',
  notes = 'Aguardando resposta/confirmação da UNB. Nada fechado até o momento.',
  due_date = '2026-05-15'
WHERE title ILIKE '%Falar com Cândida%';

-- Tudo que ainda estiver com a Cândida como responsável → Thaís (até haver confirmação formal)
WITH th AS (SELECT id FROM team_members WHERE name ILIKE '%Thaís%' LIMIT 1),
     ca AS (SELECT id FROM team_members WHERE name ILIKE '%Cândida%' LIMIT 1)
UPDATE tasks t
SET assigned_to = th.id
FROM th, ca
WHERE t.assigned_to = ca.id AND ca.id IS NOT NULL AND th.id IS NOT NULL;

-- 5d) Márcia — psicóloga do IML (pessoa de referência); não implica parceria institucional com o IML
INSERT INTO team_members (name, organization, role, avatar_color, is_active, notes)
SELECT
  'Márcia',
  'IML',
  'docente',
  '#0891b2',
  true,
  'Psicóloga no IML (Instituto de Medicina Legal). Possível contribuição técnica pontual no módulo de violência. Não há parceria institucional com o IML — o projeto não tem vínculo com o órgão.'
WHERE NOT EXISTS (SELECT 1 FROM team_members WHERE name ILIKE '%Márcia%');

-- ============================================================
-- RLS — painel HTML conectado (usuário autenticado + fallback anon)
-- Só rode se souber que o app usa JWT ou anon no REST.
-- Políticas permissivas para equipe fechada; revise em produção.
-- ============================================================
/*
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Remova políticas antigas conflitantes antes, se existirem (ex.: DROP POLICY ...).

CREATE POLICY "rrdf_auth_all_team" ON team_members
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_auth_all_partners" ON partners
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_auth_all_tasks" ON tasks
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_auth_all_comments" ON comments
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "rrdf_anon_all_team" ON team_members
  FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_partners" ON partners
  FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_tasks" ON tasks
  FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_comments" ON comments
  FOR ALL TO anon USING (true) WITH CHECK (true);
*/

-- activity_log (se a tabela existir)
/*
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rrdf_auth_all_activity" ON activity_log
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rrdf_anon_all_activity" ON activity_log
  FOR ALL TO anon USING (true) WITH CHECK (true);
*/

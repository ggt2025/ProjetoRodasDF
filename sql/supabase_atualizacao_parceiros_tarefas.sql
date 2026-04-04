-- ============================================================
-- Rede de Rodas do DF — atualização no Supabase
-- Rode no SQL Editor (Dashboard → SQL → New query).
-- Ajuste nomes de colunas se o seu schema for diferente.
-- ============================================================

-- 1) IML não é parceiro institucional — apenas IMS (piloto)
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
  'Responsável: Thaís. Alinhar pauta com Giselle antes da reunião.'
FROM team_members tm
WHERE tm.is_active IS NOT FALSE
  AND tm.name ILIKE '%Thaís%'
  AND NOT EXISTS (
    SELECT 1 FROM tasks t WHERE t.title ILIKE '%Secretaria da Mulher%'
  )
LIMIT 1;

-- 5) Ajustar nota de tarefa de currículo (remover ideia de parceria formal com IML)
UPDATE tasks
SET notes = 'Detalhar com Cândida (UNB). Módulo sobre violência: convidados técnicos pontuais, sem parceria formal com IML.'
WHERE title ILIKE '%Organizar estrutura do curso%';

-- 6) (Opcional) Remover pessoa “Márcia” ligada ao IML da equipe — descomente se fizer sentido
-- DELETE FROM team_members WHERE name ILIKE '%Márcia%' AND organization ILIKE '%IML%';

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

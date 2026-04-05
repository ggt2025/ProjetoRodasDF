-- ============================================================
-- Rede de Rodas do DF — SEMA (Thaís) + COGE (Giselle): cadastro do projeto, cesta básica
-- Rode no SQL Editor em projetos que já têm team_members e tasks.
-- ============================================================

INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, notes)
SELECT
  'SEMA e COGE — cadastro do projeto, cesta básica e apoio',
  'Articulação conjunta: Thaís puxa a frente com a SEMA (Secretaria / interlocução acordada no MPDFT–GDF). Giselle trata com o COGE o cadastro formal do projeto e o que for necessário para viabilizar apoio em espécie (ex.: cesta básica), conforme regramento do órgão.',
  'fase_0_semente',
  'pendente',
  'alta',
  m.id,
  '2026-05-29',
  'Tarefa em dupla. Thaís: SEMA. Giselle: COGE (falar para destravar cadastro e possibilidade de cesta básica). Alinhar entre si antes de comprometer prazos.'
FROM team_members m
WHERE m.name ILIKE '%Thaís%'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%SEMA%' AND t.title ILIKE '%COGE%')
LIMIT 1;

UPDATE team_members
SET notes = trim(both E'\n' from coalesce(notes, '') || E'\nCom Giselle: frente SEMA na tarefa de cadastro do projeto / cesta básica (Giselle com COGE).')
WHERE name ILIKE '%Thaís%'
  AND (notes IS NULL OR notes NOT ILIKE '%frente SEMA%');

UPDATE team_members
SET notes = trim(both E'\n' from coalesce(notes, '') || E'\nCom Thaís: COGE para cadastro do projeto e cesta básica (Thaís: SEMA). Fora essa dupla, sem outras pontes de articulação institucional.')
WHERE name ILIKE '%Giselle%'
  AND (notes IS NULL OR notes NOT ILIKE '%COGE%');

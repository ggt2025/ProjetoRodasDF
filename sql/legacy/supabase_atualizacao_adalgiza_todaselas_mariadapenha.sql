-- ============================================================
-- Rede de Rodas do DF — Adalgiza (ponte Todas Elas) + Projeto Maria da Penha (Lívia Gimines)
-- Rode no SQL Editor após o schema base. Idempotente na medida do possível.
-- ============================================================

-- 1) Parceiro: Projeto Maria da Penha (Lívia Gimines); Natalie retoma quando estruturado
INSERT INTO partners (name, type, contact_person, status, contribution, receives, notes)
SELECT
  'Projeto Maria da Penha — MPDFT',
  'institucional',
  'Lívia Gimines',
  'pendente',
  'Interface com políticas e ações do projeto Maria da Penha no âmbito do MPDFT',
  'Convergência com capacitação, rodas e psicoeducação em direitos',
  'Natalie retoma contato com Lívia quando o fluxo estiver estruturado. Thaís pode apoiar alinhamento institucional.'
WHERE NOT EXISTS (
  SELECT 1 FROM partners p WHERE p.name ILIKE '%Projeto Maria da Penha%'
);

-- 2) Núcleo de Gênero: reforçar ponte Todas Elas + Adalgiza
UPDATE partners
SET
  contribution = trim(both ' ' from coalesce(contribution, '') || ' Ponte com a rede territorial Todas Elas (via Adalgiza, conforme articulação).')
WHERE name ILIKE '%Núcleo de Gênero%'
  AND contribution NOT ILIKE '%Todas Elas%';

UPDATE partners
SET notes = CASE
    WHEN notes IS NULL OR trim(notes) = '' THEN 'Thaís articula com Adalgiza. Adalgiza pode fazer ponte com o projeto Todas Elas. Fase 0 — maio/2026.'
    WHEN notes NOT ILIKE '%ponte com o projeto Todas Elas%' THEN trim(both E'\n' from notes || E'\nAdalgiza pode fazer ponte com o projeto Todas Elas (rede territorial, Parte 4).')
    ELSE notes
  END
WHERE name ILIKE '%Núcleo de Gênero%';

-- 3) Tarefa Adalgiza: enriquecer descrição e notas (se ainda não tiver o texto novo)
UPDATE tasks
SET
  description = 'Articular com Adalgiza do Núcleo de Gênero do MPDFT: apresentar a Rede de Rodas do DF, alinhar capacitação, encaminhamentos e visão de gênero no projeto. Explorar Adalgiza como ponte com o projeto Todas Elas (rede territorial). Em paralelo: Projeto Maria da Penha (Lívia Gimines) — Natalie retoma quando estiver estruturado.',
  notes = trim(both E'\n' from coalesce(notes, '') || E'\nTodas Elas: via Adalgiza/NG. Maria da Penha/Lívia: Natalie após estruturação.')
WHERE title ILIKE '%Adalgiza%' AND title ILIKE '%Núcleo de Gênero%'
  AND description NOT ILIKE '%Todas Elas%';

-- 4) Nova tarefa — Natalie / Lívia (não duplica)
INSERT INTO tasks (title, description, phase, status, priority, assigned_to, due_date, notes)
SELECT
  'Projeto Maria da Penha — retomar com Lívia Gimines',
  'Quando o arranjo institucional estiver estruturado, Natalie retoma o diálogo com Lívia Gimines (Projeto Maria da Penha / MPDFT) para alinhar convergência com capacitação, rodas e psicoeducação em direitos.',
  'fase_0_semente',
  'pendente',
  'media',
  tm.id,
  '2026-06-30',
  'Aguardar estruturação. Thaís pode apoiar contexto institucional MPDFT.'
FROM team_members tm
WHERE tm.name ILIKE '%Natalie%'
  AND NOT EXISTS (SELECT 1 FROM tasks t WHERE t.title ILIKE '%Maria da Penha%' AND t.title ILIKE '%Lívia%')
LIMIT 1;

-- 5) Notas da equipe (Thaís e Natalie) — opcional; só se coluna notes existir em team_members
UPDATE team_members
SET notes = trim(both E'\n' from coalesce(notes, '') || E'\nAdalgiza (NG): pode fazer ponte com o projeto Todas Elas (articulação: Thaís). Projeto Maria da Penha: Lívia Gimines — Natalie retoma quando estruturado.')
WHERE name ILIKE '%Thaís%'
  AND (notes IS NULL OR notes NOT ILIKE '%Todas Elas%');

UPDATE team_members
SET notes = trim(both E'\n' from coalesce(notes, '') || E'\nProjeto Maria da Penha (Lívia Gimines): retomar contato quando o arranjo institucional estiver estruturado.')
WHERE name ILIKE '%Natalie%'
  AND (notes IS NULL OR notes NOT ILIKE '%Lívia Gimines%');

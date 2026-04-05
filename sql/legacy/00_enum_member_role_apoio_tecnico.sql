-- ============================================================
-- Rode ESTE arquivo sozinho, numa query separada, e clique em Run.
-- O Postgres exige que o novo valor do enum seja commitado antes
-- de qualquer UPDATE/INSERT que use 'apoio_tecnico' (erro 55P04).
--
-- Depois rode: supabase_atualizacao_parceiros_tarefas.sql
--
-- Se team_members.role for text (não enum), não execute este arquivo.
-- ============================================================

ALTER TYPE member_role ADD VALUE IF NOT EXISTS 'apoio_tecnico';

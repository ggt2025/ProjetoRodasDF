-- ============================================================
-- Rede de Rodas do DF — apoio à entrega (peer review) nas tarefas
-- Responsável direto (assigned_to) + apoio (delivery_helper_id).
-- Rode no SQL Editor após a tabela tasks existir.
-- ============================================================

ALTER TABLE tasks ADD COLUMN IF NOT EXISTS delivery_helper_id uuid REFERENCES team_members (id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_delivery_helper ON tasks (delivery_helper_id);
COMMENT ON COLUMN tasks.delivery_helper_id IS 'Apoio à entrega / peer: acompanha prazo e apoia o responsável direto; sorteio diverso no painel.';

-- ============================================================
-- Rede de Rodas do DF — notícias públicas + coluna start_date (cronograma)
-- Rode no SQL Editor do Supabase após o schema base (tasks, team_members, …).
-- ============================================================

-- 1) Notícias na página inicial (REST anon só leitura das publicadas)
CREATE TABLE IF NOT EXISTS public_news (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  published_on date NOT NULL DEFAULT (CURRENT_DATE),
  title text NOT NULL,
  excerpt text DEFAULT '',
  body text DEFAULT '',
  image_url text DEFAULT '',
  is_published boolean NOT NULL DEFAULT true,
  sort_order int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public_news ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_news_select_published" ON public_news;
CREATE POLICY "public_news_select_published"
  ON public_news FOR SELECT
  USING (is_published = true);

DROP POLICY IF EXISTS "public_news_auth_all" ON public_news;
CREATE POLICY "public_news_auth_all"
  ON public_news FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

-- Opcional: permitir INSERT/UPDATE só para um papel (ajuste conforme sua política).

-- 2) Início previsto na tarefa (barra do cronograma no painel)
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS start_date date;

COMMENT ON COLUMN tasks.start_date IS 'Início da barra no cronograma; se NULL, o app usa ~3 semanas antes de due_date.';

-- 3) Exemplo de notícia (remova ou edite)
INSERT INTO public_news (published_on, title, excerpt, body, is_published)
SELECT CURRENT_DATE,
  'Painel e cronograma conectados ao Supabase',
  'Tarefas, prazos e notícias passam a refletir o que está no banco.',
  'A página pública lê a tabela public_news. O cronograma usa due_date e, opcionalmente, start_date em cada tarefa.',
  true
WHERE NOT EXISTS (SELECT 1 FROM public_news LIMIT 1);

-- Tabelas já criadas sem foto no card: adicione a coluna.
ALTER TABLE public_news ADD COLUMN IF NOT EXISTS image_url text DEFAULT '';

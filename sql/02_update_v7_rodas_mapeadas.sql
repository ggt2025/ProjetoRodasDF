-- =============================================================================
-- REDE DE RODAS DO DF — Migração incremental v7
-- PostgreSQL 15+ / Supabase
--
-- O QUE FAZ
--   • Cria rodas_mapeadas  — equipamentos e iniciativas permanentes no DF
--   • Cria member_rodas    — vínculo membro ↔ roda (qualquer usuário logado)
--   • Seed completo do Levantamento Rodas DF (abril/2026) — ~55 registros
--   • RLS, GRANTs e índices para as duas tabelas
--
-- COMO RODAR
--   Supabase → SQL Editor → colar este arquivo → Run
--   (Idempotente: IF NOT EXISTS / WHERE NOT EXISTS em todo lugar)
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1) TABELA rodas_mapeadas
-- ─────────────────────────────────────────────────────────────────────────────

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
  'Equipamentos e iniciativas permanentes de apoio a mulheres no DF, mapeados no levantamento Rodas DF (abril/2026). confirmado_rede=true = a rede local confirmou que os dados estão atualizados.';

CREATE INDEX IF NOT EXISTS idx_rodas_mapeadas_circ  ON rodas_mapeadas (circunscricao);
CREATE INDEX IF NOT EXISTS idx_rodas_mapeadas_tipo  ON rodas_mapeadas (tipo);
CREATE INDEX IF NOT EXISTS idx_rodas_mapeadas_vis   ON rodas_mapeadas (is_visible, circunscricao);

ALTER TABLE rodas_mapeadas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rodas_mapeadas_auth_all ON rodas_mapeadas;
DROP POLICY IF EXISTS rodas_mapeadas_anon_sel ON rodas_mapeadas;
CREATE POLICY "rodas_mapeadas_auth_all" ON rodas_mapeadas FOR ALL    TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "rodas_mapeadas_anon_sel" ON rodas_mapeadas FOR SELECT TO anon          USING (is_visible = true);

GRANT SELECT                         ON rodas_mapeadas TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON rodas_mapeadas TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2) TABELA member_rodas
-- ─────────────────────────────────────────────────────────────────────────────

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

CREATE INDEX IF NOT EXISTS idx_member_rodas_member ON member_rodas (member_id);
CREATE INDEX IF NOT EXISTS idx_member_rodas_roda   ON member_rodas (roda_id);

ALTER TABLE member_rodas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS member_rodas_auth_all ON member_rodas;
DROP POLICY IF EXISTS member_rodas_anon_sel ON member_rodas;
CREATE POLICY "member_rodas_auth_all" ON member_rodas FOR ALL    TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "member_rodas_anon_sel" ON member_rodas FOR SELECT TO anon          USING (true);

GRANT SELECT                         ON member_rodas TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON member_rodas TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3) SEED — Levantamento Rodas DF (abril/2026) — todos a confirmar pela rede
-- ─────────────────────────────────────────────────────────────────────────────
-- Convenção: confirmado_rede = false → aguarda confirmação local (bolinha amarela)
-- Cada região tem um sort_order para manter a ordenação original do levantamento.

-- ── BRASÍLIA (Plano Piloto / Asa Sul / Asa Norte / Lago Sul) ─────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Espaço Acolher — Plano Piloto','espaco_acolher','SMDF','Brasília (Plano Piloto)',
  'SMAS Tr.3, Lt.4/6, Bl.5, Térreo — Asa Sul','(61) 99323-6567','geafavd.planopiloto@mulher.df.gov.br',
  'Seg–Sex 12h–19h','permanente',
  'Acompanhamento psicossocial individual e grupal (Grupos de Mulheres e Grupos Reflexivos de Homens) para pessoas envolvidas em violência doméstica. Mais de 9,5 mil atendimentos desde a fundação. Acesso por encaminhamento judicial ou demanda espontânea.',
  'muito_alta',10
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Espaço Acolher — Plano Piloto');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Espaço Acolher — Asa Sul (10ª unidade)','espaco_acolher','SMDF','Brasília (Plano Piloto)',
  'SQS 112/312 — Asa Sul','—','—',
  'Seg–Sex 8h–18h','permanente',
  'Inaugurado em julho/2025. Capacidade para até 20 pessoas; equipe de 12 profissionais. Espaço cedido pela PCDF e reformado com R$ 250 mil.',
  'muito_alta',11
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Espaço Acolher — Asa Sul (10ª unidade)');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEAM 102 Sul','ceam','SMDF','Brasília (Plano Piloto)',
  'Estação Metrô 102 Sul — Asa Sul','(61) 3181-2245 / (61) 99183-6454','ceam.102sul@mulher.df.gov.br',
  'Seg–Sex 8h–18h (sem agendamento)','permanente',
  'Acolhimento psicossocial, pedagógico e orientação jurídica. Inclui rodas de conversa terapêuticas como parte do atendimento grupal. Demanda espontânea ou encaminhamento.',
  'muito_alta',12
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEAM 102 Sul');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEAM CIOB — Asa Norte','ceam','SMDF','Brasília (Plano Piloto)',
  'SAM, Conjunto A — Asa Norte','(61) 3341-1840','—',
  'Seg–Sex 8h–18h','permanente',
  'Acolhimento psicossocial, orientação jurídica e rodas de conversa grupais. Mesmo modelo de atendimento do CEAM 102 Sul.',
  'muito_alta',13
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEAM CIOB — Asa Norte');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Margarida (HRAN)','cepav','SES-DF','Brasília (Plano Piloto)',
  'Ambulatório HRAN, 1º Andar, Sala 04 — SMHN Q2, Asa Norte','(61) 3449-4740 / (61) 99237-0336','cepav.margarida@saude.df.gov.br',
  'Seg–Sex horário comercial (livre demanda)','permanente',
  'Atendimentos individuais e em grupos presenciais; rodas de conversa terapêuticas com mulheres em situação de violência doméstica, intrafamiliar e sexual.',
  'muito_alta',14
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Margarida (HRAN)');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Violeta (HMIB)','cepav','SES-DF','Brasília (Plano Piloto)',
  'HMIB — Av. L2 Sul, SGAS Qd.608, Módulo A, Asa Sul','(61) 3449-7759','pavvioleta.hmib@saude.df.gov.br',
  'Seg–Sex horário comercial (livre demanda)','permanente',
  'Atendimento individual (todo ciclo de vida) e grupos de mulheres, crianças e adolescentes. Grupo de pais.',
  'muito_alta',15
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Violeta (HMIB)');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Programa Elas / Rede Social de Brasília (CMVD/TJDFT)','rede_territorial','CMVD/TJDFT + MPDFT','Brasília (Plano Piloto)',
  'Fórum de Brasília — 8º andar','—','—',
  'Ações regulares ao longo do ano','permanente',
  'Seminários, cine-debates e rodas de conversa em parceria com órgãos da rede. Semana Paz em Casa (32ª edição em março/2026). Programa Elas voltado a servidoras e magistradas do TJDFT.',
  'muito_alta',16
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Programa Elas / Rede Social de Brasília (CMVD/TJDFT)');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Núcleo Direito Delas — Brasília','direito_delas','Sejus-DF','Brasília (Plano Piloto)',
  'Estação Rodoferroviária, Ala Central, Térreo','(61) 98314-0626 / (61) 2244-1282','—',
  'Seg–Sex 8h–17h','permanente',
  'Acolhimento humanizado, orientação jurídica, apoio psicológico e social, encaminhamento à rede de proteção.',
  'muito_alta',17
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Núcleo Direito Delas — Brasília');

-- ── CEILÂNDIA ─────────────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Casa da Mulher Brasileira — Ceilândia','casa_mulher','SMDF / Gov. Federal','Ceilândia',
  'CNM 1, Bl. I, Lt. 3, CEP 72215-110','(61) 98312-0284','—',
  '24 horas, todos os dias','permanente',
  'Acolhimento, atendimento psicossocial, suporte jurídico (Defensoria), capacitação profissional e alojamento de passagem (até 48h). Rodas de conversa e grupos de acolhimento. Mais de 40 mil atendimentos desde 2021.',
  'muito_alta',20
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Casa da Mulher Brasileira — Ceilândia');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Espaço Acolher — Ceilândia','espaco_acolher','SMDF','Ceilândia',
  'QNM 02, Conj. F, Lote 1/3 — Ceilândia Centro','(61) 98314-0882','geafavd.ceilandia@mulher.df.gov.br',
  'Seg–Sex 9h–18h','permanente',
  'Acompanhamento psicossocial, Grupos de Mulheres e Grupos Reflexivos de Homens.',
  'muito_alta',21
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Espaço Acolher — Ceilândia');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Núcleo Direito Delas — Ceilândia','direito_delas','Sejus-DF','Ceilândia',
  'Shopping Popular de Ceilândia — Espaço Na Hora','(61) 98314-0620 / (61) 2244-1421','—',
  'Seg–Sex 8h–17h','permanente',
  'Acolhimento, orientação jurídica, apoio psicológico e social.',
  'muito_alta',22
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Núcleo Direito Delas — Ceilândia');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Comitê de Proteção à Mulher — Ceilândia','comite_protecao','SMDF','Ceilândia',
  'Sede da Administração Regional de Ceilândia','(61) 98312-0136','—',
  'Seg–Sex 8h–18h','permanente',
  'Identificação e notificação de ameaças, acolhimento, orientação e encaminhamento de mulheres em situação de violência.',
  'muito_alta',23
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Comitê de Proteção à Mulher — Ceilândia');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Flor de Lótus (HRC)','cepav','SES-DF','Ceilândia',
  'Hospital Regional de Ceilândia — QNM 27, Área Especial 1','(61) 2017-2000 r.3155','srsoe.nupav@saude.df.gov.br',
  'Seg–Sex horário comercial','permanente',
  'Acolhimento individual e coletivo; grupos para mulheres; atendimento pediátrico e ginecológico para vítimas de violência.',
  'muito_alta',24
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Flor de Lótus (HRC)');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Rede Mulher de Ceilândia / Projeto Todas Elas (MPDFT)','rede_territorial','MPDFT — Núcleo de Gênero','Ceilândia',
  'MPDFT Ceilândia','—','—',
  'Reuniões regulares da rede local','permanente',
  'Fluxo regional de enfrentamento à violência contra a mulher consolidado. Reuniões regulares da rede multissetorial. Apresentado no 2º Fórum Todas Elas (agosto/2025).',
  'muito_alta',25
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Rede Mulher de Ceilândia / Projeto Todas Elas (MPDFT)');

-- ── GAMA ─────────────────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Rede ELAS — Gama e Santa Maria','rede_territorial','MPDFT — Núcleo de Gênero','Gama',
  'MPDFT Gama (reuniões mensais)','—','@elas_rede_de_enfrentamento (Instagram)',
  'Encontros mensais (datas definidas a cada mês)','mensal',
  'Rodas de conversa, diálogos e reflexões sobre violência contra a mulher e organização de ações comunitárias. Em funcionamento desde fevereiro de 2015 (mais de 11 anos). Cobre também Santa Maria. Fluxo regional consolidado pelo Projeto Todas Elas.',
  'alta',30
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Rede ELAS — Gama e Santa Maria');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Espaço Acolher — Gama','espaco_acolher','SMDF','Gama',
  'Promotoria de Justiça do Gama — Qd.01, Lts.860/800, Subsolo','(61) 99120-5114 / (61) 3181-2239','geafavd.gama@mulher.df.gov.br',
  'Seg–Sex 12h–19h','permanente',
  'Acompanhamento psicossocial, Grupos de Mulheres, Grupos Reflexivos de Homens.',
  'alta',31
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Espaço Acolher — Gama');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Núcleo Direito Delas — Gama','direito_delas','Sejus-DF','Gama',
  'Promotoria de Justiça do Gama — Setor Leste Industrial','—','—',
  'Seg–Sex 8h–17h','permanente',
  '11º núcleo do programa, inaugurado em dezembro de 2024. Acolhimento, orientação jurídica, apoio psicológico e social.',
  'alta',32
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Núcleo Direito Delas — Gama');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Gardênia (HRG)','cepav','SES-DF','Gama',
  'Hospital Regional do Gama — Área Especial nº 01','(61) 3449-7357 / (61) 99201-7372','nupav.srssu@saude.df.gov.br',
  'Seg–Sex horário comercial','permanente',
  'Acolhimento; atendimentos individuais e em grupo; atendimento psicossocial para crianças, adolescentes e mulheres; atendimento médico pediátrico.',
  'alta',33
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Gardênia (HRG)');

-- ── SANTA MARIA ───────────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Flor do Cerrado (HRSM)','cepav','SES-DF / IgesDF','Santa Maria',
  'Hospital Regional de Santa Maria — Qd. AC 102','(61) 3449-7356 / (61) 4042-7770 r.5525','cepavflordocerrado@gmail.com',
  'Dias úteis 7h–18h (livre demanda)','permanente',
  'Acolhimento biopsicossocial, rodas de conversa terapêuticas e grupos de mulheres. Referência da Rede Flores. Modelo de integração entre saúde, assistência social, segurança, justiça e comunidade.',
  'alta',40
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Flor do Cerrado (HRSM)');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Espaço Acolher — Santa Maria','espaco_acolher','SMDF','Santa Maria',
  'Promotoria de Justiça de Santa Maria — QR 211, Conj. A, Lote 14','(61) 3394-6863 / (61) 99516-1772','geafavd.santamaria@mulher.df.gov.br',
  'Seg–Sex 9h30–17h','permanente',
  'Acompanhamento psicossocial e Grupos de Mulheres.',
  'alta',41
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Espaço Acolher — Santa Maria');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Comitê de Proteção à Mulher — Santa Maria','comite_protecao','SMDF','Santa Maria',
  'Sede da Administração Regional de Santa Maria','—','—',
  'Seg–Sex 8h–18h','permanente',
  'Inaugurado em julho/2025. Acolhimento, orientação e encaminhamento de mulheres vítimas. A Rede ELAS (Gama/Santa Maria) também atua nesta região.',
  'alta',42
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Comitê de Proteção à Mulher — Santa Maria');

-- ── TAGUATINGA / ÁGUAS CLARAS ─────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Azaleia (HRT)','cepav','SES-DF','Taguatinga / Águas Claras',
  'Hospital Regional de Taguatinga — QNC, Área Especial nº 24','(61) 3449-6678 / (61) 99357-5529','cepav.azaleia@saude.df.gov.br',
  'Seg–Sex horário comercial','permanente',
  'Acolhimento; atendimento ginecológico para adolescentes (a partir de 12 anos) e mulheres; atendimento pediátrico.',
  'media',50
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Azaleia (HRT)');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Comitê de Proteção à Mulher — Águas Claras','comite_protecao','SMDF','Taguatinga / Águas Claras',
  'Sede da Administração Regional de Águas Claras','(61) 98312-0245','—',
  'Seg–Sex 8h–18h','permanente',
  'Um dos 7 comitês ativos no DF em 2026. Acolhimento, orientação e encaminhamento.',
  'media',51
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Comitê de Proteção à Mulher — Águas Claras');

-- ── SAMAMBAIA ─────────────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Espaço Acolher — Samambaia','espaco_acolher','SMDF','Samambaia',
  'Ed. Arena Mall — QS 406, Conj. E, Lote 3, Loja 4, Samambaia Norte','(61) 99226-2858 / (61) 3181-2237','geafavd.samambaia@mulher.df.gov.br',
  'Seg–Sex 9h–18h','permanente',
  'Acompanhamento psicossocial, Grupos de Mulheres, Grupos Reflexivos de Homens.',
  'media_alta',60
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Espaço Acolher — Samambaia');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Núcleo Direito Delas — Samambaia','direito_delas','Sejus-DF','Samambaia',
  'QS 402, Conj. G, Lote 1 — Samambaia/DF','(61) 98314-0792 / (61) 98314-0631','—',
  'Seg–Sex 8h–17h','permanente',
  'Acolhimento, orientação jurídica, apoio psicológico e social.',
  'media_alta',61
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Núcleo Direito Delas — Samambaia');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Orquídea (HRSam)','cepav','SES-DF','Samambaia',
  'Hospital Regional de Samambaia — QS 614, Conj. C, Lotes 01/02','(61) 3449-7009 / (61) 99155-2702','cepav.orquidea@saude.df.gov.br',
  'Seg–Sex horário comercial','permanente',
  'Acolhimento; atendimentos individuais e em grupo (mulheres e crianças); atendimento ginecológico e pediátrico.',
  'media_alta',62
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Orquídea (HRSam)');

-- ── SOBRADINHO / SOBRADINHO II ────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Projeto "Desabafe Aqui" — Terapia Comunitária','projeto','Sejus-DF + Instituto Bethel','Sobradinho / Sobradinho II',
  'Sobradinho II e regiões adjacentes (Vila Rabelo, Vale das Acácias)','—','—',
  'Jan–Fev/2026 (potencial de renovação)','a_confirmar',
  'Rodas de Terapia Comunitária Integrativa (TCI) para 60 mulheres codependentes em situação de vulnerabilidade. Módulo de cidadania digital, cuidado estético, apoio psicológico e jurídico. Valor: R$ 100 mil (Termo de Fomento 25/2025). Aguarda confirmação de renovação.',
  'alta',70
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Projeto "Desabafe Aqui" — Terapia Comunitária');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Espaço Acolher — Sobradinho','espaco_acolher','SMDF','Sobradinho / Sobradinho II',
  'Ed. Gran Via — Q.3, Lote Especial 05, 1º Andar, Sala 115 — Sobradinho','(61) 99501-6007 / (61) 3181-2241','geafavd.sobradinho@mulher.df.gov.br',
  'Seg–Sex 9h–18h','permanente',
  'Acompanhamento psicossocial, Grupos de Mulheres.',
  'alta',71
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Espaço Acolher — Sobradinho');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CRMB — Sobradinho II','crmb','SMDF','Sobradinho / Sobradinho II',
  'Área Especial 06, COER, Qd.01, Setor Oeste — Sobradinho II','(61) 3181-2663 / (61) 3181-2664','centrodereferenciadamulherbras@gmail.com',
  'Seg–Sex 9h–18h (sem agendamento)','permanente',
  'Acolhimento psicológico, social e jurídico; cursos gratuitos de capacitação; rodas de acolhimento e troca de experiências; alojamento de passagem (até 48h, 14 camas). Inaugurado em maio/2025.',
  'alta',72
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CRMB — Sobradinho II');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Comitê de Proteção à Mulher — Sobradinho','comite_protecao','SMDF','Sobradinho / Sobradinho II',
  'Sede da Administração Regional de Sobradinho','(61) 98279-0713','—',
  'Seg–Sex 8h–18h','permanente',
  'Acolhimento, orientação e encaminhamento. Telefone geral da coordenação dos comitês: (61) 98279-0396.',
  'alta',73
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Comitê de Proteção à Mulher — Sobradinho');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Sempre Viva (HRS)','cepav','SES-DF','Sobradinho / Sobradinho II',
  'Hospital Regional de Sobradinho — Qd. Central, Bloco B, Área Adm.','(61) 3449-5541 / WhatsApp: (61) 99253-2414','cepav.sempreviva@saude.df.gov.br',
  'Seg–Sex 8h–12h / 13h–18h','permanente',
  'Atendimento individual e em grupo para mulheres em situação de violência.',
  'alta',74
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Sempre Viva (HRS)');

-- ── PLANALTINA ────────────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Espaço Acolher — Planaltina','espaco_acolher','SMDF','Planaltina',
  'Promotoria de Justiça de Planaltina — Área Especial 10/A, Térreo','(61) 99128-9921 / (61) 3181-2242','geafavd.planaltina@mulher.df.gov.br',
  'Seg–Sex 12h–19h','permanente',
  'Acompanhamento psicossocial, Grupos de Mulheres.',
  'alta',80
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Espaço Acolher — Planaltina');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEAM Planaltina','ceam','SMDF','Planaltina',
  'A/E 1/2, Lote 3/5, Jardim Roriz — Planaltina','(61) 3388-4656 / (61) 99341-6001','ceamplanaltinadm@mulher.df.gov.br',
  'Seg–Sex 8h–18h','permanente',
  'Acolhimento psicossocial, orientação jurídica, rodas de conversa grupais.',
  'alta',81
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEAM Planaltina');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Núcleo Direito Delas — Planaltina','direito_delas','Sejus-DF','Planaltina',
  'Promotoria de Justiça de Planaltina (MPDFT)','(61) 98314-0611 / (61) 3555-2737','—',
  'Seg–Sex 8h–17h','permanente',
  'Espaço renovado inaugurado em novembro/2024. Acolhimento, orientação jurídica e apoio social.',
  'alta',82
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Núcleo Direito Delas — Planaltina');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Flor de Lis (HRP)','cepav','SES-DF','Planaltina',
  'Hospital Regional de Planaltina — Via W/L 4, Área Especial','(61) 3449-5749 / (61) 99262-0729','cepav.flordelis@saude.df.gov.br',
  'Seg–Sex 8h–12h / 13h–18h','permanente',
  'Acolhimento; atendimentos individuais e em grupo para mulheres em situação de violência.',
  'alta',83
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Flor de Lis (HRP)');

-- ── SÃO SEBASTIÃO ─────────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Núcleo Direito Delas — São Sebastião','direito_delas','Sejus-DF','São Sebastião',
  'Qd. 101, Conj. 8 — Administração Regional de São Sebastião','(61) 98314-0627 / (61) 2244-1131','—',
  'Seg–Sex 8h–17h','permanente',
  'Inaugurado em setembro/2024. Acolhimento, orientação jurídica, apoio psicológico e social.',
  'media_alta',90
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Núcleo Direito Delas — São Sebastião');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CRMB — São Sebastião','crmb','SMDF','São Sebastião',
  'Área Especial 11, Centro de Múltiplas Atividades — São Sebastião','(61) 3181-2661 / (61) 3181-2662','centrodereferenciadamulherbras@gmail.com',
  'Seg–Sex 9h–18h (sem agendamento)','permanente',
  'Acolhimento psicológico, social e jurídico; cursos gratuitos; rodas de acolhimento. Inaugurado em maio/2025.',
  'media_alta',91
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CRMB — São Sebastião');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Tulipa (São Sebastião)','cepav','SES-DF','São Sebastião',
  'Centro de Múltiplas Atividades, Conj. 10, Unidade de Saúde','(61) 99175-2409','cepav.tulipa@saude.df.gov.br',
  'Seg–Qui 8h–18h; Sex 8h–12h','permanente',
  'Acolhimento e grupos de apoio para mulheres em situação de violência.',
  'media_alta',92
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Tulipa (São Sebastião)');

-- ── RIACHO FUNDO ──────────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Projeto Todas Elas — Riacho Fundo (MPDFT)','rede_territorial','MPDFT — Núcleo de Gênero','Riacho Fundo',
  'MPDFT Riacho Fundo / Juizado de VD','—','—',
  'Ações regulares (diálogos, capacitações)','permanente',
  'Diálogos interinstitucionais regulares (3ª edição em março/2026); capacitação Provid; exibição de filmes + debate. Fluxo consolidado desde 2024. Responsável: Juíza Fabriziane Zapata.',
  'media_baixa',100
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Projeto Todas Elas — Riacho Fundo (MPDFT)');

-- ── PARANOÁ / ITAPOÃ ──────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Espaço Acolher — Paranoá','espaco_acolher','SMDF','Paranoá / Itapoã',
  'Promotoria de Justiça do Paranoá — Qd.04, Conj. B, Sala 111','(61) 3369-4784 / (61) 99206-6281','geafavd.paranoa@mulher.df.gov.br',
  'Seg–Sex 12h–19h','permanente',
  'Acompanhamento psicossocial e Grupos de Mulheres.',
  'media',110
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Espaço Acolher — Paranoá');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Núcleo Direito Delas — Paranoá','direito_delas','Sejus-DF','Paranoá / Itapoã',
  'Qd. 05, Conj. 03, Área Especial D — Parnoá','(61) 98314-0622 / (61) 2244-1417','—',
  'Seg–Sex 8h–17h','permanente',
  'Acolhimento, orientação jurídica, apoio psicológico e social.',
  'media',111
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Núcleo Direito Delas — Paranoá');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Núcleo Direito Delas — Itapoã','direito_delas','Sejus-DF','Paranoá / Itapoã',
  'Praça dos Direitos, Qd. 203, Del Lago II — Itapoã','(61) 98314-0632 / (61) 2244-1418','—',
  'Seg–Sex 8h–17h','permanente',
  'Acolhimento, orientação jurídica, apoio psicológico e social.',
  'media',112
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Núcleo Direito Delas — Itapoã');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Comitê de Proteção à Mulher — Itapoã','comite_protecao','SMDF','Paranoá / Itapoã',
  'Sede da Administração Regional do Itapoã','(61) 98312-0284','—',
  'Seg–Sex 8h–18h','permanente',
  'Acolhimento, orientação e encaminhamento.',
  'media',113
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Comitê de Proteção à Mulher — Itapoã');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Girassol (HRL — Paranoá)','cepav','SES-DF','Paranoá / Itapoã',
  'Hospital da Região Leste — Área Especial, Qd.2, Conj.K, Lt.1 (Corredor D)','(61) 2017-1550 r.1711 / (61) 99264-2694','cepav.girassol@saude.df.gov.br',
  'Seg–Qui 8h–18h; Sex 8h–12h','permanente',
  'Acolhimento e grupos de apoio para mulheres em situação de violência de todas as faixas etárias.',
  'media',114
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Girassol (HRL — Paranoá)');

-- ── GUARÁ ─────────────────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Núcleo Direito Delas — Guará','direito_delas','Sejus-DF','Guará',
  'Praça da QE 01, Lúcio Costa — Guará/DF','(61) 98314-0619 / (61) 2244-1419','—',
  'Seg–Sex 8h–17h','permanente',
  'Acolhimento, orientação jurídica, apoio psicológico e social.',
  'media',120
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Núcleo Direito Delas — Guará');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Primavera (HRGu)','cepav','SES-DF','Guará',
  'Policlínica Centro Sul / Hospital Regional do Guará — Área Especial QI 06, Lote C, Guará I','(61) 3449-5127 / WhatsApp: (61) 99451-0035','srscs.pavprimavera@saude.df.gov.br',
  'Seg–Sex horário comercial','permanente',
  'Acolhimento; atendimentos individuais e em grupo para todas as faixas etárias em situação de violência.',
  'media',121
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Primavera (HRGu)');

-- ── ESTRUTURAL (SCIA) ─────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Núcleo Direito Delas — Estrutural','direito_delas','Sejus-DF','Estrutural (SCIA)',
  'Setor Central, Área Especial 5, s/n — Estrutural/DF','(61) 98382-0189','—',
  'Seg–Sex 8h–17h','permanente',
  '9º núcleo do programa, inaugurado em fevereiro/2025. Acolhimento, orientação jurídica e apoio social.',
  'media_baixa',130
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Núcleo Direito Delas — Estrutural');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Comitê de Proteção à Mulher — Estrutural','comite_protecao','SMDF','Estrutural (SCIA)',
  'Sede da Administração Regional da Estrutural','—','—',
  'Seg–Sex 8h–18h','permanente',
  'Inaugurado em setembro/2024 (4º comitê entregue). Acolhimento, orientação e encaminhamento.',
  'media_baixa',131
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Comitê de Proteção à Mulher — Estrutural');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Roda de Conversa — UBM-DF (Estrutural)','rede_territorial','União Brasileira de Mulheres — DF','Estrutural (SCIA)',
  'Feira Permanente da Estrutural','—','@ubmdf (Instagram)',
  'Recorrente (ação mensal da sociedade civil)','a_confirmar',
  'Ação comunitária realizada em março/2026. Potencial de recorrência. UBM-DF é uma organização de sociedade civil com atuação contínua na Estrutural. Aguarda confirmação de periodicidade.',
  'media_baixa',132
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Roda de Conversa — UBM-DF (Estrutural)');

-- ── RECANTO DAS EMAS ──────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CRMB — Recanto das Emas','crmb','SMDF','Recanto das Emas',
  'Av. Buriti, Qd. 203, Lote 14 — Recanto das Emas','(61) 3181-2665 / (61) 3181-2666','centrodereferenciadamulherbras@gmail.com',
  'Seg–Sex 9h–18h (sem agendamento)','permanente',
  '1º CRMB do DF, inaugurado em maio/2025. Acolhimento psicológico, social e jurídico; cursos gratuitos; rodas de acolhimento. 312 m². Unidade móvel para corte e costura (até maio/2026).',
  'media',140
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CRMB — Recanto das Emas');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Núcleo Direito Delas — Recanto das Emas','direito_delas','Sejus-DF','Recanto das Emas',
  'Estação da Cidadania — CEU das Artes, Qd. 113, Área Especial 01','(61) 98314-0613 / (61) 2244-1424','—',
  'Seg–Sex 8h–17h','permanente',
  'Acolhimento, orientação jurídica, apoio psicológico e social.',
  'media',141
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Núcleo Direito Delas — Recanto das Emas');

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Amarílis (UBS 03 — Recanto)','cepav','SES-DF','Recanto das Emas',
  'UBS 03 — Qd. 104/105, Área Especial, Lt. 25, Área Hospitalar','(61) 99171-4300','cepav.amarilis@saude.df.gov.br',
  'Seg–Sex horário comercial (agendar antes)','permanente',
  'Equipe reduzida — recomenda-se ligar antes. Acolhimento e grupos de apoio para mulheres em situação de violência.',
  'media',142
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Amarílis (UBS 03 — Recanto)');

-- ── BRAZLÂNDIA ────────────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'Espaço Acolher — Brazlândia','espaco_acolher','SMDF','Brazlândia',
  'TJDFT — Área Especial 04, Lote 04, 1º Andar, Setor Tradicional','(61) 99103-0058 / (61) 3181-2236','agenda.nafavdbrz@gmail.com',
  'Seg–Sex 12h–19h','permanente',
  'Acompanhamento psicossocial e Grupos de Mulheres.',
  'baixa',150
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='Espaço Acolher — Brazlândia');

-- ── NÚCLEO BANDEIRANTE ────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CEPAV Alfazema (Núcleo Bandeirante)','cepav','SES-DF','Núcleo Bandeirante',
  'Policlínica Centro Sul — Unidade Núcleo Bandeirante, 3ª Av., Área Especial nº 03','(61) 2017-1145 r.8170 / WhatsApp: (61) 99451-2245','srscs.pavalfazema@saude.df.gov.br',
  'Seg–Sex horário comercial','permanente',
  'Acolhimento; atendimentos individuais e em grupo para todas as idades em situação de violência.',
  'baixa',160
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CEPAV Alfazema (Núcleo Bandeirante)');

-- ── SOL NASCENTE ──────────────────────────────────────────────────────────────

INSERT INTO rodas_mapeadas (nome,tipo,instituicao,circunscricao,endereco,telefone,email,horario,frequencia,descricao,cobertura,sort_order)
SELECT 'CRMB — Sol Nascente','crmb','SMDF','Sol Nascente / Pôr do Sol',
  'Tr. 2, Qd. 100, Conj. A, Lote EC1 — Sol Nascente','(61) 3181-2255 / (61) 3181-2660','centrodereferenciadamulherbras@gmail.com',
  'Seg–Sex 9h–18h (sem agendamento)','permanente',
  'Inaugurado em maio/2025. Atende a região mais populosa do DF (~100 mil habitantes), antes desassistida. Acolhimento psicológico, social e jurídico; cursos gratuitos; rodas de acolhimento.',
  'baixa',170
WHERE NOT EXISTS (SELECT 1 FROM rodas_mapeadas WHERE nome='CRMB — Sol Nascente');

-- ─────────────────────────────────────────────────────────────────────────────
-- FIM — Validação rápida:
--   SELECT count(*) FROM rodas_mapeadas;   → 55
--   SELECT count(*) FROM member_rodas;     → 0 (populado pelo frontend)
--   SELECT circunscricao, count(*) FROM rodas_mapeadas GROUP BY 1 ORDER BY 1;
-- ─────────────────────────────────────────────────────────────────────────────

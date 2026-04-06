/**
 * Levantamento — Rodas de conversa e serviços de apoio grupal (DF 2025–2026)
 * Arquivado em js/archive/ — não carregado pelo index atual. Ver js/archive/README.md.
 */
(function () {
  'use strict';
  window.RODAS_LEV = {
    title: 'Rodas de conversa e serviços de apoio grupal para mulheres vítimas de violência no DF (2025–2026)',
    legend:
      '🟢 Continuado (semanal/quinzenal) · 🔵 Permanente (portas abertas, seg–sex) · 🟡 Periódico (mensal/bimestral) · 🟠 Pontual · ⚪ Em articulação',
    parts: [
      {
        id: '1',
        title: 'PARTE 1 — Serviços continuados com grupos de mulheres (atendimento permanente)',
        subtitle: 'Equipamentos com grupos regulares.',
        cols: ['local', 'horario', 'frequencia', 'instituicao', 'responsavel', 'telefone'],
        colLabels: { local: 'Local / Circunscrição', horario: 'Dia / Horário', frequencia: 'Frequência', instituicao: 'Instituição', responsavel: 'Responsável / Equipe', telefone: 'Telefone' },
        rows: [
          { id: 'p1-01', local: 'CEAM 102 Sul — Estação Metrô 102 Sul, Plano Piloto', horario: 'Seg a sex, 8h–18h', frequencia: '🟢 Grupos semanais/quinzenais (rodas de conversa, oficinas, atividades pedagógicas)', instituicao: 'SMDF', responsavel: 'Equipe multidisciplinar CEAM', telefone: '(61) 3181-2245 / 99183-6454' },
          { id: 'p1-02', local: 'CEAM Planaltina — Jardim Roriz, AE entre Q.1 e Q.2', horario: 'Seg a sex, 8h–18h', frequencia: '🟢 Grupos semanais/quinzenais', instituicao: 'SMDF', responsavel: 'Equipe multidisciplinar CEAM', telefone: '(61) 3181-2249 / 99202-6376' },
          { id: 'p1-03', local: 'CEAM IV (CIOB) — SDN Conj. A, Ed. CIOB, Asa Norte', horario: 'Seg a sex, 8h–18h', frequencia: '🟢 Grupos semanais/quinzenais', instituicao: 'SMDF', responsavel: 'Equipe multidisciplinar CEAM', telefone: '(61) 3181-2251 / 98199-1198' },
          { id: 'p1-04', local: 'Casa da Mulher Brasileira — CNM 1, Bl. I, Lt. 3, Ceilândia', horario: '24h, todos os dias', frequencia: '🟢 Grupos continuados + acolhimento permanente', instituicao: 'SMDF / Gov. Federal', responsavel: 'Coordenação CMB', telefone: '(61) 3181-1474 (recepção) / 3181-2232 (NUAT)' },
          { id: 'p1-05', local: 'Espaço Acolher — Plano Piloto — Fórum SMAS Tr.3, Lt.4/6, Bl.5, Térreo', horario: 'Seg a sex, 9h–18h', frequencia: '🟢 Grupos de mulheres semanais', instituicao: 'SMDF', responsavel: 'Equipe psicossocial', telefone: '(61) 3181-2236 / 99323-6567' },
          { id: 'p1-06', local: 'Espaço Acolher — Ceilândia — QNM 02, Conj. F, Lt.1/3', horario: 'Seg a sex, 9h–18h', frequencia: '🟢 Grupos de mulheres semanais', instituicao: 'SMDF', responsavel: 'Equipe psicossocial', telefone: '(61) 3181-2240 / 98314-0882' },
          { id: 'p1-07', local: 'Espaço Acolher — Gama — Ed. Promotoria, Q.01, Lt.860/800, Subsolo', horario: 'Seg a sex, 9h–18h', frequencia: '🟢 Grupos de mulheres semanais', instituicao: 'SMDF', responsavel: 'Equipe psicossocial', telefone: '(61) 3181-2239 / 99120-5114' },
          { id: 'p1-08', local: 'Espaço Acolher — Santa Maria — Ed. Promotoria, QR 211, Conj.A, Lt.14', horario: 'Seg a sex, 9h–18h', frequencia: '🟢 Grupos de mulheres semanais', instituicao: 'SMDF', responsavel: 'Equipe psicossocial', telefone: '(61) 3181-2238 / 99516-1772' },
          { id: 'p1-09', local: 'Espaço Acolher — Samambaia — Ed. Arena Mall, QS 406, Conj.E, Lt.3, Lj.4', horario: 'Seg a sex, 9h–18h', frequencia: '🟢 Grupos de mulheres semanais', instituicao: 'SMDF', responsavel: 'Equipe psicossocial', telefone: '(61) 3181-2237 / 99530-9675' },
          { id: 'p1-10', local: 'Espaço Acolher — Planaltina — Ed. Promotoria, AE 10/A, Térreo', horario: 'Seg a sex, 9h–18h', frequencia: '🟢 Grupos de mulheres semanais', instituicao: 'SMDF', responsavel: 'Equipe psicossocial', telefone: '(61) 3181-2242 / 99128-9921' },
          { id: 'p1-11', local: 'Espaço Acolher — Sobradinho — Q.3, AE 5, Ed. Gran Via, Sl.115', horario: 'Seg a sex, 9h–18h', frequencia: '🟢 Grupos de mulheres semanais', instituicao: 'SMDF', responsavel: 'Equipe psicossocial', telefone: '(61) 3181-2241 / 99501-6007' },
          { id: 'p1-12', local: 'Espaço Acolher — Paranoá — Ed. Promotoria, Q.04, Conj.B, Sl.111', horario: 'Seg a sex, 9h–18h', frequencia: '🟢 Grupos de mulheres semanais', instituicao: 'SMDF', responsavel: 'Equipe psicossocial', telefone: '(61) 3181-2243 / 99206-6281' },
          { id: 'p1-13', local: 'Espaço Acolher — Brazlândia — Fórum de Brazlândia, AE 04, 1º andar', horario: 'Seg a sex, 9h–18h', frequencia: '🟢 Grupos de mulheres semanais', instituicao: 'SMDF', responsavel: 'Equipe psicossocial', telefone: '(61) 3181-2244 / 99103-0058' },
          { id: 'p1-14', local: 'Cepav Flor do Cerrado — Hospital Regional de Santa Maria', horario: 'Seg a sex, 7h–18h', frequencia: '🟢 Rodas de conversa terapêuticas semanais (grupo de mulheres)', instituicao: 'SES-DF / IgesDF', responsavel: 'Ronaldo Lima Coutinho (chefe Cepav)', telefone: 'Hospital: (61) 3319-3400' },
          { id: 'p1-15', local: 'CRMB Recanto das Emas — Av. Buritis Q.203 Lt.14', horario: 'Seg a sex, 9h–18h', frequencia: '🔵 Acolhimento permanente (portas abertas) + grupos', instituicao: 'SMDF / Min. Mulheres', responsavel: 'Equipe multidisciplinar', telefone: '(61) 3181-2665 / 3181-2666' },
          { id: 'p1-16', local: 'CRMB Sol Nascente — Tr.02, Q.100, Conj.A, Lt.SC1, Pôr do Sol', horario: 'Seg a sex, 9h–18h', frequencia: '🔵 Acolhimento permanente + grupos', instituicao: 'SMDF / Min. Mulheres', responsavel: 'Equipe multidisciplinar', telefone: '(61) 3181-2255 / 3181-2660' },
          { id: 'p1-17', local: 'CRMB São Sebastião — AE 11, Centro de Múltiplas Atividades', horario: 'Seg a sex, 9h–18h', frequencia: '🔵 Acolhimento permanente + grupos', instituicao: 'SMDF / Min. Mulheres', responsavel: 'Equipe multidisciplinar', telefone: '(61) informar via SMDF: 3181-1445' },
          { id: 'p1-18', local: 'CRMB Sobradinho II — AE 06 COER Q.01, Setor Oeste', horario: 'Seg a sex, 9h–18h', frequencia: '🔵 Acolhimento permanente + grupos', instituicao: 'SMDF / Min. Mulheres', responsavel: 'Equipe multidisciplinar', telefone: '(61) informar via SMDF: 3181-1445' }
        ]
      },
      {
        id: '2',
        title: 'PARTE 2 — Comitês de proteção à mulher',
        subtitle: 'Acolhimento, escuta, encaminhamento — portas abertas.',
        cols: ['local', 'horario', 'frequencia', 'instituicao', 'telefone'],
        colLabels: { local: 'Local / Circunscrição', horario: 'Dia / Horário', frequencia: 'Frequência', instituicao: 'Instituição', telefone: 'Telefone' },
        rows: [
          { id: 'p2-01', local: 'Itapoã — Q.378, AE 4, Conj.A, Admin. Regional', horario: 'Seg a sex, 8h–18h', frequencia: '🔵 Permanente', instituicao: 'SMDF', telefone: '(61) 3181-2688 / 98312-0284' },
          { id: 'p2-02', local: 'Ceilândia — QNM 13, AE, Ceilândia Sul, Admin. Regional', horario: 'Seg a sex, 8h–18h', frequencia: '🔵 Permanente', instituicao: 'SMDF', telefone: '(61) 3181-2689 / 98312-0136' },
          { id: 'p2-03', local: 'Lago Norte — Sobreloja Shopping Deck Norte', horario: 'Seg a sex, 8h–18h', frequencia: '🔵 Permanente', instituicao: 'SMDF', telefone: '(61) 3181-2685 / 98312-0245' },
          { id: 'p2-04', local: 'Estrutural — Setor Central, AE 5, Admin. Regional', horario: 'Seg a sex, 8h–18h', frequencia: '🔵 Permanente', instituicao: 'SMDF', telefone: '(61) 3181-2686 / 98312-0285' },
          { id: 'p2-05', local: 'Sobradinho — Feira Modelo de Sobradinho', horario: 'Seg a sex, 8h–18h', frequencia: '🔵 Permanente', instituicao: 'SMDF', telefone: '(61) 3181-2687 / 98279-0713' },
          { id: 'p2-06', local: 'Águas Claras — Biblioteca Pública, R. Araribá, Praça Park Sul', horario: 'Seg a sex, 8h–18h', frequencia: '🔵 Permanente', instituicao: 'SMDF', telefone: '(61) 3181-3104 / 98312-0138' },
          { id: 'p2-07', local: 'Santa Maria — Admin. Regional, Q. Central 01, Conj. H-A', horario: 'Seg a sex, 8h–18h', frequencia: '🔵 Permanente', instituicao: 'SMDF', telefone: '(61) 3181-3105 / 98312-0135' }
        ]
      },
      {
        id: '3',
        title: 'PARTE 3 — Rodas de conversa e ações comunitárias pontuais/periódicas (2025–2026)',
        subtitle: 'Eventos e ciclos identificados no levantamento.',
        cols: ['local', 'quando', 'frequencia', 'instituicao', 'pessoas', 'contato'],
        colLabels: { local: 'Local / Circunscrição', quando: 'Data / Período', frequencia: 'Frequência', instituicao: 'Instituição', pessoas: 'Pessoa(s) responsável(is)', contato: 'Contato' },
        rows: [
          { id: 'p3-01', local: 'Taguatinga — Assoc. Idosos (AIT)', quando: '09/03/2026', frequencia: '🟠 Pontual (Paz em Casa)', instituicao: 'CMVD/TJDFT', pessoas: 'Juíza Maryanne Abreu; Marcos Francisco de Souza', contato: 'CMVD: (61) 3103-7014' },
          { id: 'p3-02', local: 'Taguatinga — Taguaparque', quando: '08/03/2026, 8h–13h', frequencia: '🟠 Pontual', instituicao: 'CMVD/TJDFT', pessoas: 'Juíza Maryanne Abreu; Marcos Francisco de Souza', contato: 'CMVD: (61) 3103-7014' },
          { id: 'p3-03', local: 'São Sebastião — Sede do MP («Entre Elas: Roda de Fortalecimento»)', quando: '10/03/2026, 14h', frequencia: '🟡 Semestral (Paz em Casa)', instituicao: 'CMVD/TJDFT + MPDFT', pessoas: 'Márcia Borba; Maressa Veloso (CMVD)', contato: 'CMVD: (61) 3103-7014' },
          { id: 'p3-04', local: 'São Sebastião — CEM 01 («Falando Delas Com Eles»)', quando: '12/08/2025', frequencia: '🟠 Pontual', instituicao: 'CLDF — Procuradoria da Mulher', pessoas: 'Dep. Paula Belmonte; Fernanda Glaucia (PCDF); Del. Fabíola Chellotti; Ten. Samara Dantas; psicóloga Mariana Rego', contato: 'CLDF: (61) 3348-8000' },
          { id: 'p3-05', local: 'Santa Maria — CED 310 (roda com ~100 estudantes)', quando: '10/03/2026', frequencia: '🟠 Pontual (Paz em Casa)', instituicao: 'CMVD/TJDFT', pessoas: 'Juíza Gislaine Campos', contato: 'CMVD: (61) 3103-7014' },
          { id: 'p3-06', local: 'Santa Maria — Shopping (passeata + ação)', quando: '16/08/2025', frequencia: '🟠 Pontual', instituicao: 'CMVD/TJDFT', pessoas: 'Paulo Macedo', contato: 'CMVD: (61) 3103-7014' },
          { id: 'p3-07', local: 'Ceilândia — Bosque dos Eucaliptos', quando: '13/03/2026', frequencia: '🟠 Pontual', instituicao: 'CMVD/TJDFT + Inst. Filhos da Terra', pessoas: 'Marcos Francisco de Souza', contato: 'CMVD: (61) 3103-7014' },
          { id: 'p3-08', local: 'Ceilândia/Sol Nascente — Ciclo Palestras Conseg', quando: '09/09/2025 e nov/2025', frequencia: '🟠 Pontual (Agosto Lilás)', instituicao: 'SSP-DF + Conseg + Inst. Viva Mulher', pessoas: 'Ivone Santos (pres. Conseg Sol Nascente)', contato: 'SSP: (61) 3190-5000' },
          { id: 'p3-09', local: 'Gama — Mentes em Movimento («Vozes Femininas»)', quando: '12/03/2026, 14h', frequencia: '🟠 Pontual', instituicao: 'Sejus-DF', pessoas: 'Equipe Sejus', contato: 'Sejus: (61) 98382-0130' },
          { id: 'p3-10', local: 'Gama — Ciclo Palestras Conseg', quando: '09/10/2025', frequencia: '🟠 Pontual', instituicao: 'SSP-DF + Conseg', pessoas: 'Equipe SSP', contato: 'SSP: (61) 3190-5000' },
          { id: 'p3-11', local: 'Gama/Santa Maria — Reunião Provid', quando: '13/03/2026', frequencia: '🟡 Semestral', instituicao: 'CMVD/TJDFT + PMDF', pessoas: 'Juíza Gislaine Campos; Juiz Felipe Karsten; Ten-Cel Renata Braz', contato: 'CMVD: (61) 3103-7014' },
          { id: 'p3-12', local: 'Riacho Fundo I e II — «Diálogos Interinstitucionais» (Conselheiros Tutelares)', quando: '29/08/2025 e 13/03/2026', frequencia: '🟡 Semestral', instituicao: 'CMVD/TJDFT', pessoas: 'Juíza Fabriziane Zapata; Luana Nascimento; Lianne Oliveira', contato: 'CMVD: (61) 3103-7014' },
          { id: 'p3-13', local: 'Sobradinho II — «Desabafe Aqui» (rodas de TCI, 60 mulheres)', quando: 'Jan–fev/2026', frequencia: '🟢 Ciclo continuado (durante vigência do projeto)', instituicao: 'Sejus-DF + Instituto Bethel', pessoas: 'Instituto Bethel / Sejus', contato: 'Sejus: (61) 98382-0130' },
          { id: 'p3-14', local: 'Águas Claras — Oficinas em condomínios («Direito Delas: Empreender para Recomeçar»)', quando: 'A partir de 20/08/2025, 4 encontros', frequencia: '🟠 Série pontual (4 encontros)', instituicao: 'Sejus-DF + AMAAC + Instituto Bem IA', pessoas: 'Bia Portela (Inst. Bem IA); Sec. Marcela Passamani (Sejus)', contato: 'Sejus: (61) 98382-0130' },
          { id: 'p3-15', local: 'Águas Claras — Ciclo Palestras Conseg', quando: '26/08/2025', frequencia: '🟠 Pontual', instituicao: 'SSP-DF + Conseg + Inst. Viva Mulher', pessoas: 'Equipe SSP', contato: 'SSP: (61) 3190-5000' },
          { id: 'p3-16', local: 'Águas Claras — Roda OAB («Feminicídio e infância silenciada»)', quando: '25/08/2025', frequencia: '🟠 Pontual', instituicao: 'OAB/DF — Subseção Águas Claras', pessoas: 'Advogados OAB', contato: 'OAB/DF: (61) 3036-6100' },
          { id: 'p3-17', local: 'Brazlândia — 6º Encontro Rede Unid@s', quando: '26/03/2026', frequencia: '🟡 Anual (6ª edição)', instituicao: 'MPDFT + TJDFT + DPDF + Cras + Creas + Provid e outros', pessoas: 'Promotora Alyne de Mesquita; Pâmela Coelho (Cras)', contato: 'MPDFT: (61) 3343-9601' },
          { id: 'p3-18', local: 'Brazlândia — Roda Agosto Lilás (Assentamento Vitória, zona rural)', quando: '06/08/2025', frequencia: '🟠 Pontual', instituicao: 'MPDFT (Coord. Brazlândia) + Rede Unid@s', pessoas: 'Adv. Victoria Cavançani; Adv. Thauma Mamede; Ruan Frederick Ribas', contato: 'MPDFT Brazlândia: (61) 3391-1402' },
          { id: 'p3-19', local: 'Guará — Conversa com Eles/Papo Delas (Polo de Modas Guará II)', quando: '05/03/2026, 14h', frequencia: '🟠 Pontual', instituicao: 'Sejus-DF', pessoas: 'Equipe Sejus', contato: 'Sejus: (61) 98382-0130' },
          { id: 'p3-20', local: 'Guará — Ciclo Palestras Conseg', quando: '25/09/2025', frequencia: '🟠 Pontual', instituicao: 'SSP-DF + Conseg', pessoas: 'Equipe SSP', contato: 'SSP: (61) 3190-5000' },
          { id: 'p3-21', local: 'Samambaia — Mentes em Movimento', quando: '06/03/2026, 14h', frequencia: '🟠 Pontual', instituicao: 'Sejus-DF', pessoas: 'Equipe Sejus', contato: 'Sejus: (61) 98382-0130' },
          { id: 'p3-22', local: 'Planaltina — CMB Itinerante', quando: 'Março/2026', frequencia: '🟠 Pontual (+400 mulheres)', instituicao: 'SMDF', pessoas: 'Equipe SMDF', contato: 'SMDF: (61) 3181-1445' },
          { id: 'p3-23', local: 'Planaltina — Mentes em Movimento (saúde da mulher)', quando: '13/03/2026, 14h', frequencia: '🟠 Pontual', instituicao: 'Sejus-DF', pessoas: 'Equipe Sejus', contato: 'Sejus: (61) 98382-0130' },
          { id: 'p3-24', local: 'Recanto das Emas — Caminhada «Diga Não ao Feminicídio»', quando: '14/03/2026, 8h30', frequencia: '🟠 Pontual', instituicao: 'Sejus-DF', pessoas: 'Subsecretária Uiara Mendonça', contato: 'Sejus: (61) 98382-0130' },
          { id: 'p3-25', local: 'Núcleo Bandeirante/Park Way — Roda de conversa entre mulheres', quando: 'Mar/2026', frequencia: '🟠 Pontual', instituicao: 'Não identificada com certeza', pessoas: 'Não identificados', contato: '—' },
          { id: 'p3-26', local: 'Núcleo Bandeirante/Candangolândia — Roda Valorização Feminina (Março Mais Mulher)', quando: 'Mar/2026', frequencia: '🟠 Pontual', instituicao: 'SES-DF', pessoas: 'Equipe SES-DF', contato: 'SES: (61) 3347-1569' },
          { id: 'p3-27', local: 'Plano Piloto — Seminário Fonar (rede de proteção)', quando: '10/03/2026', frequencia: '🟠 Pontual', instituicao: 'CMVD/TJDFT + MPDFT + SES-DF', pessoas: 'Juíza Luciana Rocha; Marcela Medeiros (SES)', contato: 'CMVD: (61) 3103-7014' },
          { id: 'p3-28', local: 'Plano Piloto — Cine-Debate Programa Elas', quando: '25/08/2025', frequencia: '🟡 Semestral', instituicao: 'CMVD/TJDFT', pessoas: 'Renata Beviláqua; Letícia Custódio', contato: 'CMVD: (61) 3103-7014' },
          { id: 'p3-29', local: 'Plano Piloto — Roda na SOS Aldeias Infantis', quando: '13/08/2025 (tarde)', frequencia: '🟠 Pontual', instituicao: 'CMVD/TJDFT', pessoas: 'Renata Beviláqua (CMVD)', contato: 'CMVD: (61) 3103-7014' },
          { id: 'p3-30', local: 'Plano Piloto — Roda Hospital Aeronáutica', quando: '22/08/2025', frequencia: '🟠 Pontual', instituicao: 'CMVD/TJDFT', pessoas: 'Marcos Francisco de Souza', contato: 'CMVD: (61) 3103-7014' },
          { id: 'p3-31', local: 'VIRTUAL — Palestra «Silêncio não protege»', quando: '24/03/2026', frequencia: '🟠 Pontual', instituicao: 'CMVD/TJDFT + TRE/DF', pessoas: 'Juíza Gislaine Campos', contato: 'CMVD: (61) 3103-7014' },
          { id: 'p3-32', local: 'VIRTUAL — Práticas MPVE (Teams)', quando: '29/08/2025', frequencia: '🟠 Pontual', instituicao: 'CMVD/TJDFT', pessoas: 'Paulo Macedo', contato: 'CMVD: (61) 3103-7014' }
        ]
      },
      {
        id: '4',
        title: 'PARTE 4 — Redes locais articuladas (reuniões regulares da rede de proteção)',
        subtitle: 'Projeto Todas Elas e correlatas. Ponte institucional: Adalgiza (Núcleo de Gênero / MPDFT) com a rede Todas Elas — articulação via Thaís.',
        cols: ['local', 'frequencia', 'instituicao', 'contato'],
        colLabels: { local: 'Local / Circunscrição', frequencia: 'Frequência', instituicao: 'Instituição', contato: 'Contato' },
        rows: [
          { id: 'p4-01', local: 'Gama / Santa Maria — Rede Elas', frequencia: '🟡 Mensal', instituicao: 'MPDFT (Núcleo de Gênero) + rede multissetorial', contato: '@elas_rede_de_enfrentamento (Instagram) / MPDFT: (61) 3343-9601' },
          { id: 'p4-02', local: 'Ceilândia — Rede Mulher de Ceilândia (Todas Elas)', frequencia: '🟡 Regular', instituicao: 'MPDFT (NG) + rede local', contato: 'MPDFT NG: (61) 3343-9601' },
          { id: 'p4-03', local: 'Riacho Fundo — Todas Elas (fluxo consolidado)', frequencia: '🟡 Regular', instituicao: 'MPDFT (NG)', contato: 'MPDFT NG: (61) 3343-9601' },
          { id: 'p4-04', local: 'Brasília — Rede Social de Brasília (Todas Elas)', frequencia: '🟡 Regular', instituicao: 'MPDFT (NG) + rede', contato: 'MPDFT NG: (61) 3343-9601' },
          { id: 'p4-05', local: 'Brazlândia — Rede Unid@s', frequencia: '🟡 Regular', instituicao: 'MPDFT (Coord. Brazlândia) + rede', contato: 'MPDFT Brazlândia: (61) 3391-1402' },
          { id: 'p4-06', local: 'Planaltina / N. Bandeirante / Brazlândia — Todas Elas', frequencia: '⚪ Em implementação', instituicao: 'MPDFT (NG)', contato: 'MPDFT NG: (61) 3343-9601' }
        ]
      },
      {
        id: '5',
        title: 'PARTE 5 — Onde não há nada (lacunas confirmadas)',
        subtitle: '',
        cols: ['area', 'situacao', 'falta'],
        colLabels: { area: 'Circunscrição / RA', situacao: 'Situação', falta: 'O que falta' },
        rows: [
          { id: 'p5-01', area: 'Fercal (circ. Sobradinho)', situacao: '🔴 Deserto completo', falta: 'Nenhuma roda de conversa, nenhum equipamento, nenhuma ação identificada em 2025–2026. Região rural e isolada.' },
          { id: 'p5-02', area: 'Núcleo Bandeirante / Candangolândia / Park Way', situacao: '🔴 Sem equipamento fixo', falta: 'Nenhum CEAM, Espaço Acolher, Comitê ou CRMB. Apenas ações pontuais em março/2026. Projeto Todas Elas ainda em articulação.' },
          { id: 'p5-03', area: 'Paranoá (rodas comunitárias)', situacao: '🟠 Tem Espaço Acolher, mas sem roda comunitária aberta em 2025/2026', falta: 'Falta ação itinerante, roda de conversa aberta ou palestra na comunidade.' },
          { id: 'p5-04', area: 'Itapoã (rodas comunitárias)', situacao: '🟠 Tem Comitê e Direito Delas, mas sem roda de conversa sobre violência identificada', falta: 'Região com alto índice de feminicídio. Falta roda comunitária.' }
        ]
      }
    ],
    contatosReferencia: [
      { canal: 'Ligue 180 — Central de Atendimento à Mulher', telefone: '180' },
      { canal: 'Disque 100 — Direitos Humanos', telefone: '100' },
      { canal: 'DEAM — Delegacia da Mulher (WhatsApp 24h)', telefone: '(61) 9610-0180' },
      { canal: 'Programa Direito Delas (Sejus-DF)', telefone: '(61) 98382-0130' },
      { canal: 'Secretaria da Mulher do DF (SMDF)', telefone: '(61) 3181-1445' },
      { canal: 'CMVD/TJDFT — Coordenadoria da Mulher', telefone: '(61) 3103-7014' },
      { canal: 'MPDFT — Núcleo de Gênero', telefone: '(61) 3343-9601' },
      { canal: 'Defensoria Pública DF — Núcleo da Mulher', telefone: '(61) 3318-4800' },
      { canal: 'PROVID/PMDF — Águas Claras (17º BPM)', telefone: '(61) 99969-2791' },
      { canal: 'Comitê Proteção — Coordenação geral', telefone: '(61) 98279-0396' }
    ]
  };
})();

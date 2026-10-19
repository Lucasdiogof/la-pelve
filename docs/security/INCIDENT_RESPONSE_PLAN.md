# Plano de resposta a incidentes (RASCUNHO)

Revisão jurídica pendente. Base normativa consultada em 19/10/2026: LGPD art. 48 e Res. CD/ANPD nº 15/2024 (prazo geral de **3 dias úteis** para comunicar ANPD e titulares quando houver risco ou dano relevante, contado do conhecimento do controlador; em dobro para agentes de pequeno porte conforme Res. 2/2022; comunicação preliminar com complementação em até 20 dias úteis; registro do incidente por no mínimo 5 anos). Fontes secundárias; **confirmar no texto oficial** e o enquadramento de pequeno porte da controladora.

**Papéis:** a controladora (profissional/clínica) comunica ANPD e titulares. O fornecedor (operador) avisa a controladora. Meta operacional sugerida (interna, não é prazo legal): avisar a controladora em até 24 a 48 h do conhecimento.

## Etapas
1. **Detecção.** Fontes: alerta do Supabase/Cloudflare, relato de usuário, relatório CSP anômalo, `whatsapp_health` (falhas por código), advisor de segurança do Supabase.
2. **Classificação.** Houve acesso, perda, alteração ou divulgação indevida de dados pessoais? Envolve dados de saúde (sensíveis)? Quantas contas e pacientes? Severidade: crítica (dados clínicos expostos ou perdidos), alta, média, baixa.
3. **Evidências.** Registrar horário do conhecimento, sistemas, logs relevantes (sem copiar conteúdo clínico), versões de deploy e quem agiu.
4. **Contenção.** Revogar chaves e tokens afetados (Supabase, Cloudflare, Meta), invalidar sessões, desativar o recurso comprometido, desligar o domínio se necessário, rollback de deploy (workflow `rollback-web.yml`).
5. **Investigação.** Escopo temporal, contas e tabelas afetadas, vetor (XSS, credencial, RLS, anexo).
6. **Clínicas afetadas.** Identificar as controladoras pelo `fisioterapeuta_id`; não tratar pacientes diretamente.
7. **Avaliação de risco.** Natureza dos dados, número de titulares, probabilidade de dano, medidas que tornam os dados ininteligíveis.
8. **Comunicação à controladora.** Usar `INCIDENT_NOTIFICATION_TEMPLATES.md`, sem dados reais de pacientes no texto.
9. **ANPD e titulares.** Decisão e envio pela controladora no prazo regulatório; o fornecedor oferece as informações técnicas.
10. **Recuperação.** Restaurar serviço e dados, rotacionar segredos, validar RLS e Storage.
11. **Pós-incidente.** Revisão em até 10 dias úteis, causa raiz, ações corretivas, atualização de ROPA e deste plano.

## Contatos (A PREENCHER)
Responsável técnico, canal da controladora, advogado, canal oficial da ANPD para incidentes.

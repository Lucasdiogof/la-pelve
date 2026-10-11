# Ligar o aviso de agendamento (`appointment_confirmation`)

Ordem obrigatória (cada passo só depois do anterior):

1. Aplicar `0028_whatsapp_informative_gate.sql` (a trava grava `enabled_after = now()`).
2. Rodar de novo `01_dryrun_rollback.sql`: `legacy_after_gate` tem de ser `0`.
3. Definir o secret da Edge Function `whatsapp-dispatcher`:
   `WHATSAPP_TEMPLATE_APPOINTMENT_CONFIRMATION=appointment_confirmation`
   (template já aprovado na WABA de teste; nunca definir o de `rescheduled`).
4. `03_cron_5min.sql` (frequência de 5 minutos).
5. Teste real SOMENTE com paciente de teste autorizado e consulta futura criada
   depois do passo 1.

Reverter: remover o secret do passo 3 (o tipo volta a não ser reservado) e
`04_cron_back_to_30min.sql`.

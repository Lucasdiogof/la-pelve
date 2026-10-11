-- Rollback da 0028. ORDEM IMPORTANTE:
--   1. reaplicar a função claim_whatsapp_messages_for_dispatch da 0026
--      (bloco "3. claim_whatsapp_messages_for_dispatch" de
--      0026_whatsapp_dispatch.sql) -- ela não referencia a trava;
--   2. só então remover a trava:
drop table if exists public.whatsapp_informative_gate;

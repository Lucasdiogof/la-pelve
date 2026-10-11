-- A confirmação pelo WhatsApp altera appointments.status via webhook.
-- O Flutter precisa receber essa atualização enquanto a sessão estiver aberta.
-- RLS de appointments continua restringindo linhas a auth.uid() = fisioterapeuta_id.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'appointments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.appointments;
  END IF;
END;
$$;

-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Both "Forma de pagamento" and "Status" gain a free-text description that
-- only applies when "Outro" is selected — same pattern as other "outro"
-- fields elsewhere in the app (histórico cirúrgico, função urinária).

alter table public.financial_entries
add column forma_pagamento_outra_descricao text,
add column status_outra_descricao text;

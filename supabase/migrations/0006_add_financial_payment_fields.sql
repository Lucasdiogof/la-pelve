-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Forma de pagamento (pix/dinheiro/cartao/transferencia/outro) and status
-- (pago/pendente/parcial) — see
-- lib/features/financial/domain/entities/financial_enums.dart.

alter table public.financial_entries
add column forma_pagamento text;

alter table public.financial_entries
add column status text not null default 'pago';

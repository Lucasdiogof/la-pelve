-- Run this in the Supabase dashboard: SQL Editor > New query.
--
-- Two additions to `patients`, same JSONB-column convention as the other
-- clinical sections (anamnese, historico_*, funcao_*):
-- - plano_tratamento: diagnóstico fisioterapêutico / objetivo / conduta /
--   frequência sugerida — a simple 4-field clinical summary, not another
--   deeply nested section.
-- - encerramento: nullable — null means the treatment is still ongoing;
--   set when the fisioterapeuta closes the case (data/motivo/observação
--   final). Closes the "cycle" of the prontuário.

alter table public.patients
add column plano_tratamento jsonb not null default '{}'::jsonb,
add column encerramento jsonb;

// Gera 03_postcheck.sql a partir de um snapshot FRESCO do banco real (somente leitura).
// Rode imediatamente ANTES de aplicar a 0018:
//   node supabase/rollout-0018/make_postcheck.mjs
// e imediatamente DEPOIS:
//   npx.cmd supabase db query -f supabase/rollout-0018/03_postcheck.sql --linked --project-ref lchaboncmgcimafpupad
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const dir = path.dirname(fileURLToPath(import.meta.url));
const ref = 'lchaboncmgcimafpupad';
const snapshotFile = path.join(dir, '02_snapshot_readonly.sql');

// SNAPSHOT_JSON / POSTCHECK_OUT existem só para testar o gerador sem o banco real.
const json = process.env.SNAPSHOT_JSON
  ? JSON.parse(fs.readFileSync(process.env.SNAPSHOT_JSON, 'utf8'))
  : (() => {
      const out = execFileSync(
        'npx.cmd',
        ['supabase', 'db', 'query', '-f', snapshotFile, '--linked', '--project-ref', ref],
        { encoding: 'utf8', shell: true, maxBuffer: 10 * 1024 * 1024 },
      );
      return JSON.parse(out.slice(out.indexOf('{')));
    })();
if (!Array.isArray(json.rows) || json.rows.length === 0) throw new Error('snapshot vazio');

const q = (s) => `'${String(s).replaceAll("'", "''")}'`;
const values = json.rows.map((r) => `(${q(r.kind)}, ${q(r.k)}, ${q(r.v)})`).join(',\n    ');
const snapshotSql = fs.readFileSync(snapshotFile, 'utf8').trim().replace(/;\s*$/, '');
const stamp = new Date().toISOString();

const sql = `-- POS-CHECK da 0018 (gerado em ${stamp}). SOMENTE LEITURA.
-- Compara o banco AGORA com o snapshot tirado antes da migration.
-- Esperado: todas as linhas PASS e a ultima linha (99_geral) = PASS.

with snap as (
${snapshotSql}
), expected(kind, k, v) as (
  values
    ${values}
), cmp as (
  select coalesce(e.kind, s.kind) as kind, coalesce(e.k, s.k) as k,
         e.v as esperado, s.v as atual,
         case when e.v is not distinct from s.v then 'PASS' else 'FAIL' end as resultado
  from expected e full outer join snap s on s.kind = e.kind and s.k = e.k
), novos as (
  select '90_objetos_novos'::text as kind, x.k, x.esperado, x.atual,
         case when x.esperado = x.atual then 'PASS' else 'FAIL' end as resultado
  from (
    select 'tabelas novas existem com RLS (3)' as k, '3' as esperado,
      (select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'public' and c.relrowsecurity
          and c.relname in ('patient_consents','whatsapp_connections','whatsapp_messages'))::text as atual
    union all select 'profiles.timezone preenchido em todos os profiles',
      (select count(*) from public.profiles)::text,
      (select count(*) from public.profiles where timezone = 'America/Sao_Paulo')::text
    union all select 'patients.phone_e164 nulo em todos os pacientes',
      (select count(*) from public.patients)::text,
      (select count(*) from public.patients where phone_e164 is null)::text
    union all select 'tabelas novas vazias (consents+connections+messages)', '0',
      ((select count(*) from public.patient_consents)
     + (select count(*) from public.whatsapp_connections)
     + (select count(*) from public.whatsapp_messages))::text
    union all select 'indices owner_key criados (2)', '2',
      (select count(*) from pg_indexes where schemaname = 'public'
        and indexname in ('patients_id_owner_key','appointments_id_owner_key'))::text
  ) x
)
select kind, k, esperado, atual, resultado from cmp
union all select kind, k, esperado, atual, resultado from novos
union all select '99_geral', 'todas as verificacoes', 'PASS',
  case when exists (select 1 from cmp where resultado = 'FAIL')
         or exists (select 1 from novos where resultado = 'FAIL') then 'FAIL' else 'PASS' end,
  case when exists (select 1 from cmp where resultado = 'FAIL')
         or exists (select 1 from novos where resultado = 'FAIL') then 'FAIL' else 'PASS' end
order by 1, 2;
`;
fs.writeFileSync(process.env.POSTCHECK_OUT ?? path.join(dir, '03_postcheck.sql'), sql, 'utf8');
console.log(`03_postcheck.sql gerado (${json.rows.length} valores do snapshot, ${stamp})`);
for (const r of json.rows.filter((x) => x.kind === 'count')) console.log(`  ${r.k}: ${r.v}`);

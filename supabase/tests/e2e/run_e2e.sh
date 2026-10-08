#!/usr/bin/env bash
# E2E do WhatsApp (outbound + inbound) com os adapters REAIS do Supabase:
# supabase-js -> PostgREST -> Postgres local com as migrations e o Supabase
# Vault. A Meta é substituída por um provider falso (nenhuma rede externa,
# nenhuma credencial real).
#
# Requisitos locais: Postgres 16 com supabase_vault instalada
# (shared_preload_libraries + vault.getkey_script), PostgREST e Deno.
#
# Uso:
#   PGHOST=/socket PGPORT=5432 PGUSER=postgres POSTGREST_BIN=/caminho/postgrest \
#   DENO_BIN=/caminho/deno supabase/tests/e2e/run_e2e.sh
set -euo pipefail

cd "$(dirname "$0")/../../.."

case "${PGHOST:-localhost}" in
  /*|localhost|127.0.0.1) ;;
  *) echo "PGHOST precisa ser local" >&2; exit 2 ;;
esac

DB="la_pelve_e2e_$$"
PORT="${E2E_POSTGREST_PORT:-54400}"
PSQL=(psql -X -q -v ON_ERROR_STOP=1 -d "$DB")
JWT_SECRET="$(head -c 48 /dev/urandom | base64 | tr -d '\n/+=' | head -c 48)"

createdb "$DB"
cleanup() {
  [[ -n "${PGRST_PID:-}" ]] && kill "$PGRST_PID" 2>/dev/null || true
  dropdb --if-exists "$DB" >/dev/null 2>&1 || true
}
trap cleanup EXIT

"${PSQL[@]}" -f supabase/tests/supabase_stubs.sql >/dev/null
for f in $(ls supabase/migrations/*.sql | grep -v '/0013_' \
  | sed '/0011_rename_domain_to_english/i supabase/migrations/0013_financial_entries_outro_fields.sql'); do
  PGOPTIONS="-c client_min_messages=warning" "${PSQL[@]}" -f "$f" >/dev/null
done

# Papel que o PostgREST usa para trocar para anon/authenticated/service_role
# (mesmo esquema do Supabase).
"${PSQL[@]}" <<'SQL' >/dev/null
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'authenticator') then
    create role authenticator login noinherit;
  end if;
end $$;
grant anon, authenticated, service_role to authenticator;
SQL

# JWT HS256 do service_role, assinado com um segredo aleatório desta execução.
SERVICE_ROLE_KEY="$(JWT_SECRET="$JWT_SECRET" node -e '
const c = require("node:crypto");
const b = (o) => Buffer.from(JSON.stringify(o)).toString("base64url");
const h = b({ alg: "HS256", typ: "JWT" });
const p = b({ role: "service_role", iss: "la-pelve-e2e", exp: Math.floor(Date.now() / 1000) + 3600 });
const s = c.createHmac("sha256", process.env.JWT_SECRET).update(h + "." + p).digest("base64url");
process.stdout.write(h + "." + p + "." + s);
')"

PGRST_DB_URI="postgres://authenticator@/${DB}?host=${PGHOST}&port=${PGPORT:-5432}" \
PGRST_DB_SCHEMAS=public \
PGRST_DB_ANON_ROLE=anon \
PGRST_JWT_SECRET="$JWT_SECRET" \
PGRST_SERVER_PORT="$PORT" \
PGRST_LOG_LEVEL=crit \
  "${POSTGREST_BIN:-postgrest}" >/dev/null 2>&1 &
PGRST_PID=$!

for _ in $(seq 1 50); do
  curl -sf "http://127.0.0.1:${PORT}/" >/dev/null 2>&1 && break
  sleep 0.2
done

E2E_DB="$DB" \
E2E_REST_URL="http://127.0.0.1:${PORT}" \
E2E_SERVICE_ROLE_KEY="$SERVICE_ROLE_KEY" \
  "${DENO_BIN:-deno}" test --no-config --allow-env --allow-net=127.0.0.1 --allow-run=psql --allow-read \
  supabase/tests/e2e/

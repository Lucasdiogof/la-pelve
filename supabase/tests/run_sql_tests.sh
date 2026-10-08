#!/usr/bin/env bash
# Roda os testes SQL de supabase/tests/*.test.sql num banco DESCARTÁVEL:
# cria um database novo num Postgres LOCAL, aplica os stubs do Supabase e
# todas as migrations, roda os testes e apaga o database.
#
# Nunca aponte para o projeto Supabase real: o script recusa hosts que não
# sejam locais.
#
# Uso: PGHOST=/caminho/do/socket PGPORT=5432 PGUSER=postgres \
#        supabase/tests/run_sql_tests.sh
set -euo pipefail

cd "$(dirname "$0")/../.."

case "${PGHOST:-localhost}" in
  /*|localhost|127.0.0.1) ;;
  *) echo "PGHOST precisa ser local (socket, localhost ou 127.0.0.1)" >&2; exit 2 ;;
esac

DB="la_pelve_sql_tests_$$"
PSQL=(psql -X -q -v ON_ERROR_STOP=1 -d "$DB")

createdb "$DB"
trap 'dropdb --if-exists "$DB" >/dev/null 2>&1 || true' EXIT

"${PSQL[@]}" -f supabase/tests/supabase_stubs.sql >/dev/null

# Ordem real de aplicação: 0013 rodou em produção ANTES de
# 0011_rename_domain_to_english (que renomeia as colunas criadas por ela).
for f in $(ls supabase/migrations/*.sql | grep -v '/0013_' \
  | sed '/0011_rename_domain_to_english/i supabase/migrations/0013_financial_entries_outro_fields.sql'); do
  PGOPTIONS="-c client_min_messages=warning" "${PSQL[@]}" -f "$f" >/dev/null
done

passed=0
for t in supabase/tests/*.test.sql; do
  out=$("${PSQL[@]}" -f "$t" 2>&1) || { echo "$out"; echo "FALHOU: $t" >&2; exit 1; }
  n=$(grep -c 'PASS:' <<<"$out" || true)
  echo "$t: $n passaram"
  passed=$((passed + n))
done
echo "Total: $passed testes SQL passaram"

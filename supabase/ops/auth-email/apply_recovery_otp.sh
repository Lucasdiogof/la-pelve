#!/usr/bin/env bash
# Aplica o e-mail de recuperação por código (6 dígitos, sem link) no projeto
# La Pelve e lê de volta. Só altera os campos abaixo: SMTP não é tocado.
# Uso: SUPABASE_ACCESS_TOKEN=sbp_... bash supabase/ops/auth-email/apply_recovery_otp.sh
set -euo pipefail
REF=lchaboncmgcimafpupad
DIR="$(cd "$(dirname "$0")" && pwd)"
: "${SUPABASE_ACCESS_TOKEN:?defina SUPABASE_ACCESS_TOKEN}"
URL="https://api.supabase.com/v1/projects/$REF/config/auth"

body=$(python -c '
import json,sys
html=open(sys.argv[1],encoding="utf-8").read()
print(json.dumps({
 "mailer_subjects_recovery":"Seu código La Pelve",
 "mailer_templates_recovery_content":html,
 "mailer_otp_length":6,
 "mailer_otp_exp":900,
}))' "$DIR/recovery.html")

curl -sS -w "
HTTP %{http_code}
" -X PATCH "$URL" -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" -d "$body"

curl -sS -f "$URL" -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" | python -c '
import json,sys
c=json.load(sys.stdin)
print("otp_length:",c.get("mailer_otp_length"),"| otp_exp(s):",c.get("mailer_otp_exp"))
print("subject:",c.get("mailer_subjects_recovery"))
t=c.get("mailer_templates_recovery_content","")
print("has Token:", "{{ .Token }}" in t, "| has ConfirmationURL:", "ConfirmationURL" in t)
print("smtp_host:",c.get("smtp_host"),"(preservado)")'

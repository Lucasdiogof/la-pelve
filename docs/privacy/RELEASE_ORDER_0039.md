# Ordem de liberação: trava de custódia (migration 0039)

Status: **PREPARADO, NADA APLICADO.** O PR #14 está em rascunho e nada foi mergeado, publicado ou aplicado em produção. Cada passo marcado com **[AUTORIZAÇÃO]** só roda com o seu "pode".

## Por que a ordem importa
A migration 0039 muda `delete_own_account()`: com registros clínicos, ele passa a exigir `confirm_clinical_data_custody()` nas últimas 24 h. O **app novo** chama essa função antes de excluir. O **app antigo não chama**: depois da migration, um app antigo que tentar excluir a conta com dados recebe o erro `custody_not_confirmed` (falha segura: nada é apagado, a pessoa vê uma mensagem genérica de erro). Aplicar a migration antes do app novo, portanto, só bloqueia exclusões, nunca apaga dados; mas o app novo antes da migration é o caminho sem surpresa. Não existe mecanismo de atualização forçada no app (verificado: nenhuma referência a versão mínima).

## Passos
**0. Revisão e merge do PR #14** **[AUTORIZAÇÃO]**
- Conferir o diff: `supabase/migrations/0039_*.sql`, `lib/features/auth/data/auth_repository_impl.dart`, textos em `profile_strings.dart`, `web/_headers`, `.github/workflows/deploy.yml` (`--no-web-resources-cdn`), docs. CI já está verde (Flutter, Edge Functions e 282 testes SQL, incluindo 15 da 0039).
- O merge não faz deploy (`AUTO_DEPLOY` não está definido).

**1. Pré-flight (somente leitura)** — pode rodar a qualquer momento
```
npx.cmd supabase db query -f supabase/rollout-0039/01_preflight_readonly.sql --linked --project-ref lchaboncmgcimafpupad
```
Esperado: todas PASS (a linha 06 é só informativa).

**2. App mobile novo primeiro** **[AUTORIZAÇÃO]**
- Subir a versão em `pubspec.yaml` (hoje `1.0.2+5`; sugestão `1.0.3+6`).
- Gerar o AAB do Android (`--dart-define-from-file=env.json`) e o build iOS no Mac (`scripts/build_ios.sh`); enviar às lojas.
- Esperar a aprovação e a adoção. Como não há atualização forçada, parte dos usuários continuará no app antigo por um tempo.

**3. Web nova** **[AUTORIZAÇÃO]**
- `gh workflow run deploy.yml --ref main` (build com recursos locais, smoke test no `lapelve.lucksrei.com`). A Web atualiza para todos imediatamente (`Cache-Control: no-cache`).
- Validar logado com uma conta de teste: o app continua funcionando e o `console` não mostra violações novas de CSP.

**4. Go/no-go para a migration** — critérios
- App novo aprovado nas duas lojas e Web publicada.
- Decisão consciente sobre os usuários que ainda estão no app antigo (a exclusão de conta deles falhará até atualizarem). Como hoje há poucos usuários e a exclusão de conta é rara, o impacto é pequeno.
- Aprovação do dono.

**5. Dry-run em produção (transação revertida)** **[AUTORIZAÇÃO]**
```
npx.cmd supabase db query -f supabase/rollout-0039/02_dry_run_in_rollback.sql --linked --project-ref lchaboncmgcimafpupad
```
Aplica a migration dentro de uma transação e **reverte** no final. Esperado: todas PASS. Confirmar depois, com o pré-flight, que nada persistiu.

**6. Aplicar a migration** **[AUTORIZAÇÃO]**
```
npx.cmd supabase db query -f supabase/migrations/0039_account_deletion_custody_guard.sql --linked --project-ref lchaboncmgcimafpupad
```
É idempotente e aditiva: não altera nem apaga nenhum dado existente.

**7. Pós-check (somente leitura)**
```
npx.cmd supabase db query -f supabase/rollout-0039/04_postcheck_readonly.sql --linked --project-ref lchaboncmgcimafpupad
```
Esperado: todas PASS.

**8. Teste ponta a ponta com conta descartável** (opcional, **[AUTORIZAÇÃO]**)
Criar uma conta de teste com dados fictícios, tentar excluir em um app antigo (deve falhar sem apagar) e no app novo (deve confirmar a custódia e excluir). Nunca usar dados reais de pacientes.

## Rollback
Se a trava bloquear algo legítimo: `supabase/rollout-0039/03_rollback.sql` restaura o `delete_own_account()` anterior e remove as duas funções novas. As colunas `profiles.custody_confirmed_*` ficam (aditivas, inofensivas). Reverter reabre o risco de exclusão em cascata sem trava. O rollback do front é o workflow `rollback-web.yml`.

## O que continua pendente (não faz parte desta liberação)
Exportação de dados no app, fluxo de "encerrar conta" separado de "excluir dados", decisões jurídicas de retenção, CSP bloqueante e coletor de relatórios. Ver `LEGAL_DECISIONS.md`, `ACCOUNT_DELETION_AUDIT.md` e `docs/security/CSP_PLAN.md`.

# Atualização 16/11/2026 — pós-aprovação da Meta

## Estado real
- Meta (confirmado pelo dono no painel): empresa verificada, App Review aprovado (messaging, management, public_profile), app publicado. NÃO confirmado por mim: Access Verification / Tech Provider (exige o painel do dono).
- Doc oficial (Embedded Signup): Tech Provider usa token de negócio obtido no servidor; o cliente cadastra a PRÓPRIA forma de pagamento na conta dele (o custo não cai na Lucksrei). Limite de 10 novos clientes / 7 dias, sobe para 200 com Business Verification + Access Verification. Coexistence (WhatsApp Business app) é suportado, sem registro do número.
- Preços: cobrança por mensagem entregue, por categoria e país; desde 01/10/2026 mensagens utility dentro da janela de 24 h deixam de ser gratuitas. Valores do Brasil: consultar a tabela oficial (BRL).
- Produção: connect v21 (com piloto), dispatcher v20 (SEM a correção abaixo, ver pendências), webhook v35, cron `*/30`. Migration 0042 aplicada.

## Feito hoje (main)
- 9de75ce: tipo de mensagem sem template ativo não é materializado e não entra na regra dos 2 h (corrige o lembrete de 12 h descartado).
- ff50200: liberação por banco `whatsapp_rollout` (off | pilot | all). Piloto: `update whatsapp_rollout set mode='pilot', pilot_user_ids=array['<uuid>']::uuid[]`. Rollback: `set mode='off'` (fecha também states já emitidos). Conexões existentes não são afetadas.

## Atualização (sprint 2, 16/11)
- Migration 0043 aplicada: preferências por profissional (`profiles.whatsapp_notify_on_booking`, `whatsapp_reminder_12h`, padrão ligado). Desligar cancela as mensagens ainda `scheduled` do tipo (trigger); religar não reenvia o passado (cancelled é definitivo).
- Dispatcher v21 publicado (a576ce2): materializa só tipos com template ativo E preferência ligada; `appointment_confirmation` agora tem nome padrão no dispatcher (`appointment_confirmation`); `appointment_rescheduled` segue sem template (não enviado).
- Trava contra mensagens antigas: `whatsapp_informative_gate` (enabled_after 11/10, max_lateness 30 min) impede aviso informativo atrasado; o envio só sai com conexão `connected` e consentimento ativo.
- App: Perfil → WhatsApp (conectada) tem os dois interruptores de avisos; tela sem conexão tem o aviso de coexistência (sem prometer: a Meta decide na hora). Conectar, Reconectar, Atualizar status, validade e Desconectar já existiam.
- Mobile: o app abre a página de conexão no navegador do sistema (`LaunchMode.externalApplication`), sem WebView; ao voltar, a tela relê o estado no servidor (a fonte da verdade). Não testado em aparelho/emulador.
- RLS conferida em produção: todas as tabelas `whatsapp_*` com RLS; só `whatsapp_connections` e `whatsapp_messages` têm política (SELECT da própria dona); nenhuma escrita para `authenticated`/`anon`; credenciais só no Vault.
- Piloto: `whatsapp_rollout.mode='off'`. Nada liberado.

## Piloto ativo (16/11, 11:2x UTC)
- `whatsapp_rollout`: mode `pilot`, só o UUID do dono (e-mail conferido). `whatsapp_self_connect_allowed` = true só para ele; as outras 7 contas (incluindo a da Samara) = false. Rollback: `update whatsapp_rollout set mode='off'`.
- A conexão de teste segue `connected`; para conectar um número real o dono precisa antes desconectar a de teste (o banco recusa 2ª conexão ativa, WA007).
- Cron 11:30 com o dispatcher v21: sucesso, 0 erros (leitura das novas colunas de `profiles` OK).
- App: status individual dos modelos (aprovado / em análise / recusado ou pausado) na tela conectada; nota de cobrança da Meta atualizada.
- Reconexão: o botão Reconectar refaz o fluxo oficial; token com aviso 7 dias antes de vencer. Preferências exigem internet (gravação direta); falha reverte o interruptor e avisa.

## Pendências (dono)
1. Confirmar Access Verification no painel da Meta (não consegui: login necessário).
2. Autorizar o piloto para uma conta (candidata: a única com conexão de teste e 6 pacientes).
3. Conectar um WhatsApp Business real (escolha do fluxo na tela da Meta) e homologar com paciente fictício e destinatário autorizado.
4. Cobrança: cada profissional cadastra a própria forma de pagamento no WhatsApp Manager (Tech Provider).

# Roadmap WhatsApp — La Pelve (estado em 30/10/2026)

## Onde estamos
- Código, banco e Edge Functions em produção (main `2092bc0`). Migrations até 0036 aplicadas.
- Web oficial: https://lapelve.lucksrei.com (o workers.dev foi desativado).
- Meta (app 2811023262627717, portfólio Lucksrei verificado):
  - Domínios, OAuth, SDK JS, política de privacidade e exclusão de dados: OK.
  - Configuração do Embedded Signup `4693096200923752` (token de 60 dias, a única opção do painel): OK e igual ao Supabase.
  - Webhook assinado em `messages`, `account_update` e `message_template_status_update`; testes do painel OK.
  - Testes de API das permissões: concluídos.
  - App **Não publicado** → a Meta bloqueia o Embedded Signup ("Lucksrei não pode integrar clientes no momento").
- Conexão de TESTE religada manualmente (WABA 1118307474103479, número +1 555 637 7568, token de usuário do sistema `lapelve_whatsapp` sem expiração no Vault). Templates `appointment_12h` e `appointment_confirmation` aprovados.
- `WHATSAPP_SELF_CONNECT_ENABLED` **desligado** (ninguém vê o botão Conectar).
- Paciente de teste com consentimento ativo e uma consulta; lembrete sai às 07:00 (regra de silêncio 22:00–06:59).

## Próximos passos

### 1. Gravar os vídeos (dono)
- **Vídeo 1 — whatsapp_business_messaging:** tela WhatsApp do app "Conectado" → consulta criada → lembrete chega no WhatsApp → tocar em Confirmar → consulta vira "Confirmado" → bloco "Lembretes pelo WhatsApp" com Entregue/Lido.
- **Vídeo 2 — whatsapp_business_management:** tela WhatsApp do app (número, status, Atualizar status) → WhatsApp Manager com os dois modelos aprovados.
- Lembrete só sai 12 h antes da consulta e nunca entre 22:00 e 06:59. Para o vídeo: criar a consulta de dia, para 14 h 30 depois da criação (ex.: criada 08:00 → consulta 22:30 → lembrete 10:30).

### 2. Conferir e preparar o envio (Claude)
- Conferir no banco: mensagem `sent → delivered → read` e consulta `confirmed`.
- Escrever em inglês a descrição de uso de cada permissão e as instruções para o analista.

### 3. Enviar o App Review (dono)
- Painel → Analisar → Análise do app → Uso permitido: subir os dois vídeos, colar os textos, marcar a conformidade, enviar.

### 4. Após a aprovação
- Publicar o app (Publicar → Live).
- Claude religa `WHATSAPP_SELF_CONNECT_ENABLED=true` e testa o botão Conectar com a conta do dono. Na tela "Você vinculou La Pelve anteriormente", escolher **Editar configurações**.
- Decidir se a conexão de teste continua ou é substituída por um número real da clínica.

### 5. Depois do go-live (melhorias)
- **BUG:** o lembrete de 12 h é descartado ("too_close_to_immediate_message") quando o aviso imediato cai a menos de 2 h dele, mesmo se o template do aviso imediato não estiver configurado (então nada sai). Ex.: consulta criada às 00:11 → aviso e lembrete adiados para 07:00 → lembrete descartado. Corrigir: só aplicar a regra dos 2 h se o tipo imediato tiver template ativo; e não materializar tipos sem template.
- Reconexão a cada 60 dias (token do Embedded Signup); o app já mostra validade e "Reconectar".
- Avaliar o template de aviso de agendamento imediato (`appointment_confirmation`), hoje não configurado no envio.
- Revisar a página `/terms` se a Meta exigir Termos de Serviço próprios (hoje aponta para `/privacy`).

## Regras para quem continuar
- Commits direto na main, mensagens curtas em inglês, sem menção a IA.
- Deploy de função: `npx.cmd supabase functions deploy <fn> --project-ref lchaboncmgcimafpupad --use-api --no-verify-jwt` com `SUPABASE_ACCESS_TOKEN` definido.
- Deploy web: workflow `deploy.yml` é manual (`gh workflow run deploy.yml --ref main`).
- Nunca reativar consentimentos revogados nem enviar mensagem real sem autorização do paciente.
- Não expor tokens, App Secret nem PIN.

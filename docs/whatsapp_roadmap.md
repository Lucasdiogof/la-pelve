# Atualização 16/11/2026 (noite, 3) — Chamado escalado
- Caso 29569203806031459: o 1º retorno foi de agente de IA (confirmou a inconsistência Access Verification, sem solução). O chat informa que o caso foi **encaminhado a um especialista**, que responderá **por e-mail** (marketing@lucksrei.com), e pede para **não enviar mais detalhes até ser contatado**. Aguardar.

# Atualização 16/11/2026 (noite, 2) — Teste com outra conta do Facebook

- Embedded Signup v5 (config 4693096200923752) chamado direto pelo SDK em página estática do domínio, com uma conta do Facebook que **não** administra a Lucksrei (login feito pelo dono). Resultado: **"Lucksrei não pode integrar clientes no momento"**, igual à conta do dono. Session ID: `01a1e492-ca80-73de-9c0c-b32929baec65`. Nada gravado; "compartilhar contato" não clicado.
- Conclusão: a hipótese de autointegração (admin do próprio Tech Provider) está **refutada**. O bloqueio é do lado da Meta para a Lucksrei/app, coerente com a Access Verification ainda "Em análise" na página dedicada. Aguardando o chamado 29569203806031459.

# Atualização 16/11/2026 (noite) — Investigação do bloqueio do Embedded Signup

## Achado principal
- A página dedicada https://developers.facebook.com/4371966796448884/access-verification/ mostra **"Em análise"** (enviada em 04/10/2026 13:19; texto "entraremos em contato em 5 dias"), com o aviso de que **2 apps (La Pelve e Beard System, `whatsapp_business_management`) precisam concluí-la até 15/01/2027**. Isso **contradiz** a linha "Verificado — Provedor de Tecnologia" de Business Suite → Informações da empresa. O status "Verificado" registrado acima não é confiável: tratar Access Verification como NÃO CONFIRMADA até a Meta esclarecer.
- Hipótese de trabalho (não comprovada): a Meta ainda não tem a Lucksrei como Tech Provider efetivo → "não pode integrar clientes", aba "Integração de Provedor de Tecnologia" em branco (1007) e o aviso "WhatsApp needs more information" podem ter a mesma origem.
- Sem pista de autointegração na documentação oficial; relatos da comunidade são inconclusivos (nenhuma resposta da Meta).

## Verificado no painel (leitura)
- Business Support Home: sem restrições; WABA de teste sem problemas; Parceiros: nenhum.
- Central de Segurança: verificação da empresa "Verificada"; só 1 administrador (Lucas); o aviso "WhatsApp needs more information" não tem detalhe clicável (o "Ver detalhes" leva à Central de Segurança, sem texto sobre WhatsApp).
- App: publicado há poucas horas; alertas sem pendência; Login do Facebook para Empresas: OAuth, domínio e redirect corretos.

## Chamado na Meta (aberto com autorização do dono)
- Suporte direto, tópico "Dev: Onboarding", tipo "Troubleshoot Meta Business Verification". **Protocolo/caso 29569203806031459** (16/11/2026 10:33).
- URL: https://business.facebook.com/direct-support/case-detail/29569203806031459/?business_id=4371966796448884
- Sem anexos, sem credenciais, sem dados clínicos.

## Pendências
1. Responder ao chamado / chat do agente quando a Meta responder.
2. Teste com outra conta do Facebook que não administre a Lucksrei (precisa de login do dono nessa conta; só liberar UUID temporário no piloto e remover depois; não concluir vinculação).
3. Depois do desbloqueio: homologação v5/coexistence com número real (autorização específica).

# Atualização 16/11/2026 (tarde) — Coexistence

- Embedded Signup **v5** na página (`extras: { setup: {}, version: 'v5' }`): a Meta mostra as duas opções (número novo ou WhatsApp Business existente). A página aceita `messaging_account_ids` (v5) e `waba_id` (v4).
- Coexistência: a Meta devolve só a WABA → o servidor descobre o número; só segue com **exatamente um** número na WABA (vários = 409 `phone_ambiguous`, sem efeito).
- Regra da Meta: pedir UMA vez, em até 24 h, `POST /{phone}/smb_app_data` (`smb_app_state_sync` e `history`). Feito no `complete`; falha é repetida no "Atualizar status" (pendente/erro). Estado em `setup_state.smb_sync`.
- Privacidade: `history`, `smb_app_state_sync` e `smb_message_echoes` são aceitos (200) e **descartados**: nada gravado, nenhum contato vira paciente, nenhuma mídia baixada, nada de conteúdo em log. "Sim" vindo do histórico nunca confirma consulta. Mensagens comuns em `messages` só agem se forem confirmação de um lembrete nosso (nada é armazenado além do resultado).
- A página orienta a profissional a **não compartilhar o histórico** (a escolha é feita no app WhatsApp Business; recusar gera o evento 2593109 no webhook e não impede o FINISH).
- BSUID: 0044 aplicada e webhook publicado (respostas sem telefone só valem citando um lembrete nosso).

## Homologação (16/11, noite)
- Webhooks `history`, `smb_app_state_sync` e `smb_message_echoes` assinados (v27.0). Teste do painel chegou em produção: 200, log só com contagens.
- Piloto conferido: modo `pilot`, só o dono; uma conexão (a de teste, `connected`).
- App (Perfil → WhatsApp) com a conta do dono: conectado, modelos aprovados, interruptores, Atualizar status e Desconectar OK.
- **Tech Provider / Access Verification: VERIFICADO.** Business Suite → Configurações → Informações da empresa (portfólio 4371966796448884): "Access verification status: Verificado — Sua empresa foi verificada como Provedor de Tecnologia." (lido em 16/11). Alerta do app de 04/10: verificação de acesso enviada.
- Business Verification: Verificada (04/10/2026), com aviso **"WhatsApp needs more information"** sem detalhe clicável no painel. Causa desconhecida; não bloqueou App Review nem Access Verification.
- Aba "Integração de Provedor de Tecnologia" em branco (também no Chrome do dono): o servidor da Meta responde **erro 1007** em `DeveloperAppDashboardContentPagelet` (view `onboard`). Falha da Meta, não do navegador; o status foi lido pela rota acima.
- App: Ações necessárias = nenhuma; publicado; 0% do limite de volume.
- "Contact book for WhatsApp" do portfólio está **ligado** (a Meta guarda telefone/BSUID dos contatos do portfólio Lucksrei). Não alterado; decisão do dono.

- Permissões (Casos de uso → Permissões e recursos): `whatsapp_business_management` e `whatsapp_business_messaging` com acesso avançado (menu oferece "Reduzir o acesso").
- **Embedded Signup v5 testado com a conta do dono (16/11):** "Você vinculou La Pelve anteriormente" → Editar configurações → **"Lucksrei não pode integrar clientes no momento"** (oferece compartilhar contato; não compartilhado; fechado). A escolha número novo × existente **não apareceu**. Nada gravado no banco (1 conexão, a de teste).
- Hipótese principal (relato da comunidade, sem confirmação da Meta): a conta do Facebook do dono é admin do próprio portfólio do parceiro (Lucksrei); a Meta não deixa o parceiro integrar a si mesmo. Outras causas possíveis: passos da aba "Integração de Provedor de Tecnologia" (que dá erro 1007) incompletos, ou o aviso "WhatsApp needs more information".

## Pendências
1. Testar o Embedded Signup com uma conta do Facebook que **não** seja admin do portfólio Lucksrei (uma profissional piloto com portfólio próprio). Não usar a conta da Samara sem autorização.
1b. Se também falhar: chamado no Suporte ao Desenvolvedor da Meta (WhatsApp Business Platform) citando o erro 1007 da aba onboard, o bloqueio "não pode integrar clientes" e o Session ID da tela.
2. Dono: abrir chamado na Meta só se o aviso "WhatsApp needs more information" passar a bloquear algo.
3. Dono: autorizar explicitamente a conexão de um número real (exige desconectar antes a de teste: WA007).
4. Com número real: sync de 24 h, templates na WABA da profissional, cobrança dela, envio autorizado, confirmação, reconexão, isolamento.

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

## Verificação no painel da Meta (16/11)
- Business Verification da Lucksrei (4371966796448884): Verificada (04/10/2026). No app, Analisar → Verificação mostra "Verificado".
- Access Verification: não aparece em nenhuma tela do app nem do Centro de Segurança; não é pré-requisito do piloto (só eleva o limite de onboarding).
- Permissões aprovadas (envio de 15/11): whatsapp_business_management, whatsapp_business_messaging, public_profile. Ações necessárias: nenhuma. App publicado, 0% do limite de volume.
- Aba "Integração de Provedor de Tecnologia" do caso de uso não renderizou no painel embutido; status de Tech Provider ainda sem leitura direta.
- WhatsApp Manager: só a conta de teste (Test Number +1 555-637-7568, 0 enviadas, 1/5 destinatários). Nenhum número real. Cobrança: cada clínica paga pela própria conta; nada configurado.
- Risco a tratar: a Meta anuncia nomes de usuário do WhatsApp com BSUID; respostas de pacientes poderão chegar sem telefone. O casamento de respostas por telefone (_shared/inbound) precisará de fallback.

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

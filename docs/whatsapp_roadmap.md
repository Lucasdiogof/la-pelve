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
- Lembrete só sai 12 h antes da consulta e nunca entre 22:00 e 06:59.

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
- Reconexão a cada 60 dias (token do Embedded Signup); o app já mostra validade e "Reconectar".
- Avaliar o template de aviso de agendamento imediato (`appointment_confirmation`), hoje não configurado no envio.
- Revisar a página `/terms` se a Meta exigir Termos de Serviço próprios (hoje aponta para `/privacy`).

## Regras para quem continuar
- Commits direto na main, mensagens curtas em inglês, sem menção a IA.
- Deploy de função: `npx.cmd supabase functions deploy <fn> --project-ref lchaboncmgcimafpupad --use-api --no-verify-jwt` com `SUPABASE_ACCESS_TOKEN` definido.
- Deploy web: workflow `deploy.yml` é manual (`gh workflow run deploy.yml --ref main`).
- Nunca reativar consentimentos revogados nem enviar mensagem real sem autorização do paciente.
- Não expor tokens, App Secret nem PIN.

# Diagnóstico do Embedded Signup — nosso código × bloqueio da Meta

Somente leitura. Nada de cookies, tokens, telefones ou dados de pacientes nos registros.

## Revisão do código (17/11/2026)
Comparado com a documentação oficial (implementação v4/v5, coexistence):

| Item | Nosso `web/whatsapp-connect.html` | Doc oficial | Resultado |
|---|---|---|---|
| SDK | `connect.facebook.net/en_US/sdk.js`, async defer, crossorigin | igual | OK |
| `FB.init` | appId do servidor, `xfbml:false`, `version` = `WHATSAPP_GRAPH_API_VERSION` | `version` = Graph mais recente (doc cita v27.0) | Valor em produção não lido (secret). Não explica o bloqueio |
| `FB.login` | `config_id`, `response_type:'code'`, `override_default_response_type:true`, `extras:{setup:{},version:'v5'}` | igual, sem `version` em `extras` na doc pública | `version:'v5'` não consta na doc pública; é a única diferença |
| Disparo | no `click` do botão | exige gesto do usuário | OK |
| Listener | checa origem `facebook.com`, `JSON.parse`, `type==='WA_EMBEDDED_SIGNUP'` | igual | OK |
| Eventos | trata FINISH, FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING, CANCEL; resto = falha genérica | também há FINISH_ONLY_WABA, FINISH_GRANT_ONLY_API_ACCESS, ERROR | Lacuna só de diagnóstico: ERROR/CANCEL não registram `session_id`, `error_code`, `current_step` |
| Code | enviado ao servidor na hora (TTL 30 s) | igual | OK |
| Domínio/OAuth | domínio `https://lapelve.lucksrei.com/` e redirect `.../whatsapp-connect` conferidos no painel (16/11) | exigidos | OK |
| Flutter nativo | abre a mesma página no navegador do sistema (`LaunchMode.externalApplication`), sem WebView | — | Os 3 ambientes executam o MESMO HTML |

## Por que isto aponta para a Meta (e o que ainda não prova)
- A tela "Lucksrei não pode integrar clientes no momento" é desenhada pela Meta dentro da janela, ANTES de qualquer callback nosso.
- Reproduzida (17/11) com uma página estática do domínio, só `FB.init` + `FB.login`, sem nosso script, sem state, sem servidor, com a conta do dono e com uma conta externa. Sessions: `01a1e474-aa97-70b4-aef2-fde3ebb24b7b`, `01a1e492-ca80-73de-9c0c-b32929baec65`.
- NÃO descartado ainda: `extras.version:'v5'` e o `config_id` são comuns a todos os testes. Teste A abaixo isola o primeiro; o segundo só a Meta confirma (a configuração aparece como válida no painel).

## Matriz de testes (parar sempre na primeira tela da Meta)
Registrar por ambiente: ambiente, navegador/versão, última etapa alcançada, texto da tela, Session ID (canto inferior da tela da Meta), hora.

| Ambiente | Como |
|---|---|
| E1 Chromium automatizado | feito: bloqueio |
| E2 Chrome desktop | Teste B, no PC |
| E3 Chrome Android | Teste C no celular |
| E4 Safari iOS | Teste C no iPhone (se houver) |
| E5 App Flutter nativo | Teste D no celular |

### Teste B — Chrome desktop (conta do dono)
1. Abrir o La Pelve na web, Perfil → WhatsApp → Conectar (abre `lapelve.lucksrei.com/whatsapp-connect`).
2. (Opcional) F12 → Console, colar antes de clicar:
`addEventListener('message',e=>{try{const d=typeof e.data==='string'?JSON.parse(e.data):e.data;if(d&&d.type==='WA_EMBEDDED_SIGNUP')console.log('WA',d.event,d.data&&{step:d.data.current_step,code:d.data.error_code,sid:d.data.session_id})}catch(_){}})`
3. Clicar "Continuar com a Meta". Se aparecer "Você vinculou La Pelve anteriormente", clicar "Editar configurações".
4. PARAR na primeira tela posterior. NÃO escolher número, NÃO compartilhar contato, NÃO concluir. Anotar texto e Session ID. Fechar a janela.

### Teste C — Chrome Android / Safari iOS (conta do dono)
Mesmos passos 1, 3 e 4, abrindo `https://lapelve.lucksrei.com` no navegador do celular, entrando no La Pelve web e indo a Perfil → WhatsApp → Conectar. Se o navegador bloquear a janela, anotar "popup bloqueado" e permitir pop-ups para o site.

### Teste D — App Flutter nativo
Abrir o app, Perfil → WhatsApp → Conectar. O app abre o navegador do sistema; seguir 3 e 4. Voltar ao app e anotar o que a tela do La Pelve mostra (deve reler o estado: continua "conectado" com a conexão de teste).

### Teste A — sem `version:'v5'` (opcional, eu faço no PC)
Página estática do domínio com `extras:{setup:{}}` apenas. Se o bloqueio persistir, `version:'v5'` está descartado como causa.

## O que NÃO fazer em nenhum teste
Não desconectar a conexão de teste, não escolher/registrar número, não enviar mensagem, não clicar em "Sim, compartilhar minhas informações de contato", não usar a conta da Samara.

## Como ler os resultados
- Mesmo bloqueio em todos os ambientes → causa fora do cliente (Meta). Enviar relatório de bug com a matriz.
- Bloqueio só em um ambiente → investigar esse ambiente (popup/cookies de terceiros/versão do navegador).
- Tela de escolha (número novo × existente) em algum ambiente → o bloqueio depende do ambiente/conta; rever hipóteses.

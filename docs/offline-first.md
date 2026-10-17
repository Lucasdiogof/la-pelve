# La Pelve — funcionamento offline-first

Estado: implementado para **Android/iOS** (pacientes, agenda, evoluções e
financeiro). **Web/PWA continua 100% online** por decisão de segurança (ver
abaixo). O Supabase segue como backend oficial e fonte definitiva.

## Arquitetura (reaproveita a existente)

```
Telas / Cubits (inalterados)  ──►  Repository (interface existente)
                                      │
                      PatientRepositoryOffline / AgendaRepositoryOffline /
                      FinancialRepositoryOffline   (lib/features/*/data)
                                      │ lê/grava só no espelho local
                              LocalStore (SQLite cifrado)  ◄── LocalWriter
                                      ▲  outbox persistente
                                      │
                    SyncEngine ◄── ConnectivityMonitor
                       │  push (fila em ordem) → pull (foto do servidor)
                       ▼
                RemoteGateway (SupabaseRemoteGateway) ──► Supabase (RLS)
```

- `lib/core/offline/local/` — `LocalStore` (abstração), `SqliteLocalStore`,
  `KeyVault` (Keychain/Keystore), fábrica por plataforma.
- `lib/core/offline/sync/` — `SyncEngine`, `ConflictResolver`,
  `EntityConfig`, `RemoteGateway`, `SyncStatusCubit`.
- `lib/core/offline/offline_session.dart` — abre/fecha o banco do usuário
  logado (ligado ao `SessionDataController`).
- `lib/core/offline/ui/` — faixa de estado, central de sincronização,
  resolução de conflitos, textos pt/en/es.
- Sem contexto offline (Web, falha de Keystore) os repositórios caem no
  repositório Supabase de antes — nada quebra.

## Fluxo

- **Leitura**: sempre do espelho local (instantânea). Só a primeira carga em
  um aparelho precisa do servidor; sem rede nesse caso aparece "Sem conexão"
  com nova tentativa automática (nunca loading infinito: limite de 20 s).
- **Gravação**: transação única grava o registro local **e** a operação na
  fila. Só depois a UI diz que salvou — e diz "Salvo neste dispositivo" quando
  o servidor ainda não confirmou. Nunca afirma gravação no servidor sem prova.
- **Sincronização** dispara: após login, quando a conexão volta, ao voltar
  ao primeiro plano, após cada gravação local, a cada 60 s com o app ativo e
  pelo botão "Sincronizar agora". Não depende de execução em segundo plano
  (iOS/navegadores não garantem).
- **Fila** (`outbox`): id da operação, usuário, entidade, tipo, payload,
  `depends_on`, status (`pending/syncing/conflict/failed`), tentativas, último
  erro (só código, sem dado clínico), chave de idempotência. Sobrevive ao app
  fechado; operação interrompida volta a `pending` na próxima rodada. Backoff
  exponencial 5 s → 15 min. Edições seguidas do mesmo registro viram uma
  operação só. Pai (paciente) sempre antes de filho (consulta/evolução/
  lançamento), mantendo o vínculo mesmo criados offline.
- **Idempotência**: ids são gerados no cliente e iguais no servidor. Reenvio
  de `create` após resposta perdida (`23505`) só é tratado como sucesso se a
  linha existente tem o mesmo conteúdo; senão vira falha `id_collision`.
  Reenvio de `update` cujo efeito já está no servidor não é conflito.
- **Exclusões**: paciente = exclusão lógica (`deleted_at`, como já era);
  consulta/evolução = exclusão definitiva, ausente no pull = removida
  localmente. Consulta/evolução criada e apagada offline nunca chega ao
  servidor.

## Conflitos (nunca "última gravação vence")

Merge de 3 vias por coluna: `base` (último estado do servidor conhecido) ×
servidor agora × alteração local.

| Entidade | Regra |
|---|---|
| Paciente, consulta, financeiro | conflito só se a **mesma coluna** mudou nos dois lados para valores diferentes; colunas diferentes se combinam (UPDATE parcial preserva o resto do servidor) |
| **Evolução (texto clínico)** | **estrita**: qualquer mudança no servidor desde a base, diferente do pretendido, é conflito |
| Apagado no servidor / editado offline | conflito |

Em conflito nada é gravado: o registro fica bloqueado para nova edição e
aparece na central de sincronização com as duas versões lado a lado. A
profissional escolhe: **manter a minha**, **manter a do servidor** ou, em
evoluções, **manter as duas** (a local vira um novo registro). Colunas
controladas por trigger (`schedule_revision`, `schedule_revision_at`) são
ignoradas na comparação.

Janela residual: sem a migração `0037` a checagem é "ler e depois gravar".
Com ela (aplicada em produção em 17/10) a gravação passa a ser condicional a
`updated_at` e a janela fecha — o código já usa `updated_at` quando existe.

## Segurança e LGPD

- **Cifrado em repouso** (mobile): SQLite3 Multiple Ciphers (ChaCha20) via
  hook do pacote `sqlite3`; chave aleatória de 256 bits por usuário no
  Keychain (`first_unlock_this_device`, fora de backup) / Keystore. Testado:
  o arquivo não contém texto claro nem o cabeçalho "SQLite format 3".
- Nenhum token, segredo ou credencial no banco local; a sessão do Supabase
  segue onde já estava. Logs só têm códigos (sem dado clínico). Notificações
  não carregam dado clínico.
- **Isolamento**: um arquivo e uma chave por usuário (nome em hash). Cada
  operação carrega o `user_id`; o motor **não envia** se o usuário autenticado
  agora difere do dono do banco. Toda chamada ao servidor passa pela RLS.
- **Logout explícito / exclusão de conta**: apaga arquivo e chave. Se houver
  alterações não sincronizadas, o aviso diz que sair as apaga.
  **Sessão expirada/revogada** (saída involuntária): o arquivo fica, ilegível
  sem a chave e sem tela de acesso, para não perder pendências; é apagado
  quando **outra** conta entra no aparelho (troca de conta nunca mistura
  dados) ou no próximo logout explícito.
- O cache local **não é autorização**: sem sessão válida nenhuma tela lê o
  banco; a RLS decide o que o servidor entrega a cada sincronização.
- **Minimização**: só tabelas necessárias ao uso offline; anexos (arquivos),
  perfil, WhatsApp e consentimentos **não** são espelhados.
- **Web/PWA**: IndexedDB não equivale a banco cifrado com chave em hardware.
  Por isso **nenhum dado clínico é guardado offline na Web** (a fábrica de
  armazenamento da Web é um stub que não persiste nada).
- Cifrar o aparelho **não** equivale a conformidade integral com a LGPD:
  continuam necessários base legal, retenção, controles de acesso e processos
  da clínica. Este documento descreve controles técnicos, não certificação.

## O que funciona offline

Pacientes (listar, buscar, ver ficha, cadastrar, editar, alta/reabertura,
excluir), agenda (ver, criar, reagendar, status, cancelar), evoluções (ver
histórico já sincronizado, criar, editar, excluir), lançamentos financeiros.

## Online-only (declarado)

- **Consentimento de WhatsApp** (registro legal): editar paciente offline
  mantém o consentimento como está (interruptor desabilitado com aviso).
  Paciente novo salvo offline: consentimento e anexos ficam para quando
  houver internet; a UI avisa.
- **Anexos/arquivos** (Storage), **perfil**/foto, **conexão WhatsApp**,
  **login/cadastro/recuperação**, alteração de senha, exclusão de conta.
- Nenhum envio de WhatsApp parte do app: o agendador roda no servidor sobre
  os dados já sincronizados; reenviar operações não dispara efeitos externos
  (criar consulta repetida é bloqueado pelo id único).

## Plataformas

| Plataforma | Estado |
|---|---|
| Android | compila (debug APK); validação em aparelho real **pendente** |
| iOS | **pendente de validação real** (sem build possível no Windows; Keychain e hook do SQLite3MC no iOS não testados) |
| Windows (testes) | testes automatizados com SQLite3MC real |
| Web/PWA | compila; **sem armazenamento offline** (só online) |

## Limitações conhecidas

- Sincronização completa por tabela a cada rodada (sem incremental): bom para
  centenas/milhares de linhas; incremental exige `updated_at` do servidor
  (migração `0037`, aplicada em 17/10).
- Exclusão remota de consulta/evolução é detectada por ausência no pull.
- `generateId()` (microssegundos) pode colidir entre dois aparelhos criando
  no mesmo instante; a colisão é detectada (`id_collision`) e vira "alteração
  com erro", nunca sobrescreve.
- Primeira abertura num aparelho novo sem internet não tem o que mostrar.
- iOS/navegadores não executam sincronização em segundo plano: pendências
  seguem quando o app volta ao primeiro plano.

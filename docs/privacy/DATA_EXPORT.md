# Exportação de dados (Perfil > Exportar meus dados)

Rascunho técnico. A exportação **não comprova custódia legal**: ela entrega à profissional uma cópia conferível; a guarda continua dependendo de decisão jurídica e de ela guardar o arquivo.

## Formato (aberto e documentado)
ZIP com `LEIA-ME.txt`, `manifest.json` (versão 1) e:
- `data/*.json`: `profiles`, `patients` (inclui anamnese e histórico, e pacientes já "excluídos" por soft delete), `evolution_entries`, `appointments`, `financial_entries`, `attachments` (metadados), `patient_consents`, `whatsapp_messages` (só metadados de envio). Uma linha por registro, campos com o nome do banco; as relações são as chaves (`patient_id`, etc.).
- `attachments/<patient_id>/<id>_<nome>`: arquivos originais, byte a byte.
- `attachments/_sem_registro/`: arquivos do Storage sem linha correspondente (órfãos).
O manifesto lista cada arquivo com tamanho e SHA-256 e as contagens por categoria.

## Garantias
1. Leitura paginada (o servidor limita respostas) com conferência: linhas lidas = contagem exata do servidor e ids únicos, por tabela.
2. Recontagem no fim: se algo mudou durante a exportação, ela falha.
3. Anexos: listagem paginada do Storage, 3 tentativas por arquivo, SHA-256 gravado; qualquer falha aborta **sem entregar pacote parcial**. Nada é apagado em nenhum ponto.
4. O ZIP gerado é relido e cada arquivo é conferido contra o manifesto antes de ser oferecido.
5. Alterações offline ainda não sincronizadas bloqueiam a exportação (o servidor ainda não tem tudo).
6. Recibo: o app envia hash do manifesto e contagens a `record_data_export()`; o servidor compara com as contagens reais (inclusive objetos no Storage). Se não bater, o app não oferece o arquivo.
7. Mensagens de erro e logs só têm código/tabela/contagem, nunca dado de paciente nem nome de arquivo.

## Limites (honestos)
- Entrega ao sistema de arquivos: o app só sabe que pediu para salvar; **não prova que a profissional recebeu ou guardou** o arquivo (na Web o download não é verificável).
- O ZIP é montado em memória: contas com muitos anexos grandes podem esgotar a memória em aparelhos modestos. Divisão em volumes é uma melhoria futura.
- Não há assinatura digital nem carimbo de tempo: os checksums provam consistência interna, não autoria nem momento.
- Os dados saem em claro; o arquivo é dado sensível de saúde e fica sob a responsabilidade de quem o salva.
- Backups do Supabase fora do escopo (não verificados).

# Menu inicial e salvamento único

Versão **0.21.2-godot.49**, Android **21249**, GDD **3.3**. Decisão de Dener
em 17/11/2026: apenas **Novo jogo** e **Carregar jogo** na entrada; uma partida
salva. A escolha entre três partidas fica para o futuro.

## Comportamento

- **Novo jogo** inicia diretamente a campanha mobiliada do refúgio, sem
  funcionário, mantendo a progressão da versão .48. As antigas opções de início
  vazio, taverna livre e tutorial não aparecem nessa tela.
- **Carregar jogo** restaura a partida e fecha o menu. Sem salvamento, o botão
  permanece visível e desabilitado. Arquivo inválido informa o erro no próprio
  menu, sem descartar o progresso atual nem abrir outra campanha silenciosamente.
- Se já houver progresso, Novo jogo abre uma confirmação com **Começar novo
  jogo** e **Voltar**. Cancelar não altera o save. Confirmar cria o dia 1 e sua
  própria preparação de horda; a preparação antiga não acompanha a nova campanha.
- **Opções → Salvar e carregar** apresenta somente a partida salva, Dormir e
  salvar, Salvar jogo, Carregar jogo e importação de arquivo. Não há escolha de
  slot nem criação de segunda partida. Dormir e os salvamentos automáticos do
  ciclo continuam gravando a mesma partida.

## Migração e segurança

A chave ativa é `entre-partida-unica`; a preparação interna usa
`entre-refugio-preparo-unico`. O formato externo dos saves continua 12.

Na primeira inicialização sem a chave nova, procurar um save válido no slot
anteriormente ativo, depois nos slots 1, 2 e 3, depois nos formatos antigos sem
slots (12 até 04). Importar a primeira partida válida e seu backup correspondente.
O pacote de persistência grava a migração antes de jogar. **Todos os arquivos e
chaves anteriores permanecem intactos**, mas não aparecem como opções de partidas.
Se nenhum legado for válido, conservar a presença do arquivo e informar falha
na tentativa de carregar; não substituí-lo automaticamente por uma campanha nova.
Se a chave única já existe, não repetir a migração nem recuperar silenciosamente
outro slot sobre ela.

Novo jogo confirmado conserva o save anterior e sua preparação em chaves internas
de segurança, antes de substituir a partida. Importar JSON também conserva o
anterior e limpa a preparação da outra campanha. Essas cópias não são slots
jogáveis adicionais. A persistência atômica e o backup `.bak` do arquivo continuam
ativos. Falhas de gravação preservam o arquivo anterior e informam o erro.

## Verificação

As **52 suítes padrão passaram**; a validação específica também passou após
o tratamento de cabeçalhos inválidos no resumo do save.

`MenuInicialUI` usa os botões Godot reais e verifica início direto sem funcionário,
apenas duas opções, carregamento ausente, confirmação/cancelamento, gravação no
disco e retomada em outra sessão, opções sem slots, migração do slot ativo,
backup correto, preservação dos legados, migração única e arquivos inválidos.
`SalvamentoDiscoNativoUI` cobre importação válida/inválida e recuperação de backup;
`RefugioUI` cobre retomada da preparação após duas derrotas seguidas.

Capturas pelo renderizador Compatibility: [PC](arte/menu-unico-inicio.png),
[tela larga compacta](arte/menu-unico-telefone.png),
[confirmação](arte/menu-unico-confirmacao.png) e
[salvamento](arte/menu-unico-salvamento.png). Não houve teste em aparelho Android
físico. Nenhuma sprite do jogo foi substituída.

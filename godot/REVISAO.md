# Revisão da migração Godot 0.21.2

O projeto Godot está nesta pasta; a versão HTML continua no diretório pai.
A migração é híbrida: a apresentação usa Godot 4.6.3 Standard e a simulação
JavaScript usa a extensão QuickJS fornecida no pacote original. Esta revisão
não converte as regras para GDScript e não altera as bibliotecas nativas.

## Correções

- Interface e mensagens de erro ficam acima dos sprites do mundo. Antes,
  os índices de profundidade dos móveis os desenhavam sobre os menus.
- Título da HUD mantém largura legível, com estado compacto. O cabeçalho
  da construção ocupa linhas separadas para evitar palavras cortadas.
- Avisos possuem fundo e ficam afastados da placa de abertura.
- Quadros lentos preservam o tempo transcorrido; o motor de regras já o
  subdivide em passos de até 80 ms.
- Perda de foco pausa a simulação, limpa entradas pendentes e pausa sprites.
  Retomar não adiciona o tempo passado em segundo plano.
- Digitar em campos numéricos não aciona os atalhos do mundo.
- Sprites fora da sala param de animar; segmentos gráficos vazios não
  criam nós; alertas reutilizam as amostras de áudio.

## Verificação reproduzível

Execute na pasta deste projeto, com Godot 4.6.3 disponível no PATH:

```sh
XDG_DATA_HOME="$(mktemp -d)" XDG_CACHE_HOME="$(mktemp -d)" godot --headless --editor --import
XDG_DATA_HOME="$(mktemp -d)" XDG_CACHE_HOME="$(mktemp -d)" godot --headless --script res://qa/Verificar.gd
```

`-- --rapido` ao final omite as sete suítes extensas de regras, mas executa
os percursos integrados e as novas regressões. Os testes gravam saves e por
isso precisam de diretório de dados separado. A execução QuickJS destas
suítes pode levar vários minutos.

`qa/Visual.gd` captura início, salão e construção em `/tmp/esquinas-*.png`.
Execute com uma sessão gráfica Linux e `--audio-driver Dummy` se não houver
saída de áudio. O teste usa uma partida de teste; também isole XDG_DATA_HOME.

A validação feita aqui é em Linux x86-64. A DLL Windows é a fornecida no ZIP;
Windows, exportação final, áudio real e jogabilidade prolongada precisam de
teste na plataforma alvo. Não há garantia de ausência de todos os bugs.

Para repetir somente as sete suítes de regras com Node.js (opcional):
`node qa/Regras.cjs`. O modo `-- --regressoes` no verificador Godot executa
apenas o smoke inicial e os testes das correções, sem os percursos extensos.

## Resultados desta revisão

- Importação e execução em Godot 4.6.3 Linux x86-64.
- Sete suítes de regras executadas com sucesso em Node.js e na extensão QuickJS da Godot.
- Percursos integrados executados pela extensão QuickJS na Godot: sem falhas.
- Regressões de foco, tempo, edição de campos, camadas e cache de áudio: sem falhas.
- Capturas renderizadas por OpenGL/Mesa e inspecionadas: início, salão e construção.
  Exemplos em `qa/capturas/`.

O ZIP final foi extraído em outra pasta, reimportado sem cache prévio e
validado com `--regressoes`: FALHAS: 0, sem erros ou avisos no log.

## Revisão funcional de novembro de 2026

- Corrigido bloqueio de mouse por contêineres invisíveis da HUD. Todos os
  descendentes decorativos deixam passar os cliques; o status não aumenta
  a área da barra superior ao quebrar linhas.
- Ações principais da bancada em duas colunas e painel com rolagem delimitada.
  Avisos ficam acima do painel para não cobrir os botões.
- Tela cheia removida da barra inferior e disponível em Opções → Câmera.
- Mantidas as regras e os controles de movimento da versão HTML. As rotas
  e a velocidade permanecem iguais ao HTML; a validação de construção recebeu
  a otimização descrita abaixo. Nenhum arquivo HTML foi alterado.
- Gravar após recuperar um arquivo corrompido preserva o último backup válido.
  JSON inválido é recusado sem lançar exceção na extensão nativa.
- Dimensões dos painéis são reaplicadas após a atualização dos controles,
  quando os tamanhos mínimos dos filhos já podem ser recalculados.

Testes nativos adicionais e instruções estão em `qa/LEIA-ME.md`.

Na auditoria ampliada, passaram 63 verificações de interface nativa: 21 na
cozinha/movimentação/câmera, 28 nos menus e salvamentos e 14 na construção.
Também passaram as sete suítes de regras no Node.js. A importação de JSON
corrompido e duas corrupções sucessivas do arquivo principal foram exercitadas
com diretórios de dados descartáveis. Os testes gráficos usaram Godot 4.6.3,
Linux x86-64 e Mesa; um aviso de V-Sync indisponível pertence ao driver virtual.
Windows, exportação e saída de áudio física não foram validados nesta auditoria.
As sete suítes de regras também passaram dentro da extensão nativa QuickJS
na Godot, além da execução em Node.js. Os fluxos de interface foram acionados
por eventos de mouse/teclado enviados ao viewport, incluindo rolagem dos painéis.

## Desempenho: início mobiliado e posicionamento

O validador anterior chamava o cálculo de menor rota para cada móvel. Cada uma
das 22 instalações do cenário de teste repetia esse trabalho; a prévia também
validava ao atualizar o cursor e novamente ao desenhar. Na extensão QuickJS,
isso custava cerca de 4 segundos para começar e mais de 1 segundo por prévia.

A validação agora preenche uma grade de ocupação e calcula conectividade uma
única vez. Isso verifica as mesmas passagens sem calcular caminhos individuais.
A otimização preservou o método de busca de rotas; o controle livre foi acrescentado na revisão descrita abaixo. Como diagonais
só são permitidas entre células ortogonais livres, os dois métodos encontram
exatamente o mesmo conjunto de células acessíveis.

A prévia reutiliza apenas a última validação, com chave que inclui posição,
rotação, móvel em edição, geometria instalada e células reservadas pelos atores.
A confirmação usa a validação real novamente: o cache não autoriza compras.

Medições na mesma máquina Linux/Godot 4.6.3 (tempos de processamento):

| Operação | Antes | Depois |
| --- | ---: | ---: |
| Gerar cenário mobiliado nas regras | 4.049 ms | 38 ms |
| Começar mobiliado e atualizar interface | 3.992 ms | 61 ms |
| Atualizar prévia do cursor, mediana de 12 quadros | 1.103 ms | 6 ms |
| Dez consultas à mesma prévia | 5.828 ms | 4,5 ms |

Com OpenGL/Mesa por software, as atualizações incluindo renderização ficaram
em 14–20 ms após o primeiro quadro (56 ms de aquecimento). São medições locais,
não uma garantia de FPS em outros computadores. Não foi necessário alterar
as bibliotecas nativas para aplicar a otimização.

Validação: 1.173 comparações com o algoritmo anterior, cache e invalidação,
sete suítes de regras em Node.js e QuickJS, teste integrado e construção com
cliques reais na janela Godot; todos passaram. Fontes HTML preservados.

## Movimento livre do jogador

WASD/setas agora controlam uma velocidade contínua, normalizada nas diagonais,
com parada e inversão imediatas. O jogador deixa de precisar concluir uma célula
antes de responder à próxima direção. A posição subcélula é mantida no campo
`settled`, já existente no formato de save 9; as teclas pressionadas são transitórias.

O corpo do jogador usa raio de 0,20 célula. O deslocamento é varrido em passos
curtos e resolvido em eixos separados: ao encostar na parede, o eixo livre
continua avançando. Contato não impede recuar; quadros lentos não atravessam
obstáculos. As células ocupadas pelo corpo são reservadas para impedir que
móveis e NPCs entrem nelas. NPCs e construção continuam usando a grade.

O clique para caminhar e se aproximar dos objetos permanece disponível. Uma
transição interpolada recoloca a posição no caminho de navegação quando o
jogador troca do teclado para o clique, sem teletransportar para a grade.
Animação acompanha o movimento real e para quando o corpo fica bloqueado.

O mundo é atualizado em cada quadro renderizado, com limite de 60 FPS, sem o
temporizador que podia descartar quadros alternados perto de 60 Hz. Menus e
perda de foco continuam pausando a simulação e liberando as teclas.

Validação: 13 cenários de física, eventos de teclado na janela Godot, animação,
colisões, salvamento e perda de foco; suítes de regras, cozinha, construção,
menus e teste integrado passaram. Arquivos da versão HTML preservados.

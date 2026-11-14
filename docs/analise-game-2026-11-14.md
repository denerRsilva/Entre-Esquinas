# Análise do jogo — 14/11/2026

Revisão do projeto local na branch `migration/gdscript`, incluindo as mesas
modulares ainda não publicadas no GitHub. Avaliação de código, regras, testes
automatizados e arte disponível na conversa. Não houve sessão visual manual
nem teste de toque, desempenho gráfico ou instalação em aparelho Android.

## Bugs reproduzidos e corrigidos

1. **Entrega duplicada entre jogador e garçom.** Com o pedido em transporte,
   o jogador podia entregar outro prato da mesma receita. O cliente começava
   a comer e o garçom continuava carregando um prato vinculado ao pedido já
   atendido. A interação agora respeita a entrega reservada, preserva o prato
   nas mãos do jogador e permite ao garçom concluir normalmente.
2. **Remover cadeira limpa invalidava o salvamento.** Após recolher louça,
   `dirtyTables` mantinha uma entrada com quantidade zero. Remover a cadeira
   deixava essa referência sem objeto correspondente; o validador recusava o
   save. A remoção agora também limpa a entrada. Cadeiras ainda sujas continuam
   protegidas contra remoção.
3. **Save corrompido causava erros de script antes da validação.** A migração
   acessava itens de recuperação e contêineres de estoque sem conferir sua
   estrutura. Entradas como `recovery: [42]`, `[null]`, `[{}]` e estoque nulo
   reproduziram erros. Esses dados agora são rejeitados antes da migração.
   A compatibilidade com a normalização de saves antigos foi preservada.

Os casos foram executados antes das correções e falharam. Estão em
`godot/qa/AuditoriaRegressoes.gd`, incluído no comando padrão de testes.
Também foram atualizados comentários obsoletos que ainda descreviam o mapa
como dependente de JavaScript e a interface de receitas como temporária.

## Testes

- Executadas as 23 suítes existentes: movimento, construção, cozinha,
  atendimento, administração, conservação de itens, interface e salvamentos.
- Acrescentada a suíte de regressão acima, totalizando 24 suítes no comando
  padrão. Os testes dos sistemas afetados foram repetidos após as correções.
- Os testes de interface usam Godot em modo headless: verificam controles e
  estado do jogo, mas não comprovam qualidade visual, FPS ou ergonomia de toque.
- Comando: `scripts/testar-migracao.sh`.

## Avaliação e melhorias propostas

O ciclo pegar → cortar → cozinhar → empratar → servir já tem uma estrutura
clara. A mesa com ferramentas intercambiáveis reforça a conexão entre o que
o jogador vê e o que pode fazer. A prioridade deveria ser tornar esse ciclo
mais expressivo e variado antes de ampliar muito o mapa ou o catálogo.

### Visual e clareza — prioridade alta

- **Estado visível dos objetos:** tábua com ingrediente durante o corte,
  vapor no cozimento, brilho breve quando o prato fica pronto e fumaça crescente
  ao passar do ponto. Associar som e forma às cores dos avisos.
- **Construção:** destacar mesas compatíveis ao selecionar um kit; mostrar
  o encaixe e a frente útil do móvel. Conferir todas as rotações, porque o
  renderizador atual altera a proporção do sprite conforme a ocupação, em vez
  de usar artes direcionais para cada móvel. Isso merece inspeção visual.
- **Coesão:** finalizar o atlas das bancadas, alinhar bases e sombras, e revisar
  a escala dos pixels dos assets gerados. A prancha de bancada ainda é estudo.
- **Receitas:** manter comida pronta em destaque, sequência de ícones e
  quantidades curtas. Introduzir o primeiro preparo com uma demonstração visual.

### Mecânicas — prioridade alta/média

- Mostrar visualmente quando um pedido já está com o garçom, evitando que
  o jogador prepare uma segunda porção por falta de informação.
- Dar uma escolha útil ao layout: proximidade reduz deslocamentos, mas deve
  existir passagem clara para cozinheira e garçom.
- Introduzir receitas gradualmente e permitir escolher um cardápio pequeno
  antes de abrir. Isso transforma preparação em uma decisão do jogador.
- Calibrar o ritmo por testes com pessoas: o código dá somente 8 segundos de
  comida no ponto antes da perda de qualidade e 25 até queimar. Não alterei
  esses valores sem observar o custo real de deslocamento e interação.

### Diversão e progressão — prioridade média

- Um objetivo curto por turno, como servir três pratos no ponto, com recompensa
  visual e pequena melhoria para a taverna.
- Clientes recorrentes com preferências mostradas por ícones e reações. Isso
  dá motivo para reconhecer personagens, além de apenas atender cronômetros.
- Alternar períodos tranquilos e picos curtos de movimento; evitar pressão
  constante para preservar o clima acolhedor.
- Fazer a renda financiar escolhas visíveis: outra estação, uma decoração ou
  uma receita nova. As primeiras recompensas devem chegar cedo.

## Pendências técnicas encontradas na leitura

- **Campanhas longas (resolvido na atualização seguinte; ver `bancadas-salvamento-efeitos.md`):** os pedidos concluídos ficavam no histórico e o validador
  rejeita mais de 5.000 pedidos. É preciso definir arquivamento que preserve
  pedidos ainda referenciados por clientes ou pratos em transporte. Não basta
  apagar a lista nem aumentar o limite indefinidamente.
- **Custo do histórico:** a validação de reputação percorre visitas e eventos
  repetidamente. Medir saves de campanhas extensas antes de decidir índices
  e compactação; não foi feito benchmark de desempenho gráfico nesta revisão.
- **Legibilidade:** vários métodos comprimem diferentes operações na mesma
  linha. Expandir os trechos ao modificá-los e manter o tratamento de estados
  inválidos próximo à entrada dos dados. Evitar uma reescrita ampla junto com
  alterações de comportamento.

Próxima prioridade recomendada: inspeção visual das rotações e encaixes,
proteção de campanhas longas e um teste de primeiro turno com um jogador novo.

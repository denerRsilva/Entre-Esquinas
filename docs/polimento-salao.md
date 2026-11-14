# Direção dos clientes, kits e passeio do garçom

Clientes que estão na cadeira, esperando atendimento, aguardando o prato ou
comendo, usam a direção da cadeira ligada à mesa. Caminhada e saída continuam
usando a direção real do movimento. Clientes aguardando comida também ficam
protegidos contra o deslocamento para liberar passagem.

Os dois kits ficam no centro do tampo da mesa. Nas bancadas, o centro considera
a forma e rotação: o retângulo inteiro do kit fica sobre madeira, mesmo na
quina. O cálculo é compartilhado pelo palco e guardado em cache por forma.

O garçom livre escolhe destinos aleatórios acessíveis no salão. Não entra na
cozinha durante o passeio nem usa a saída; depois de uma tarefa na cozinha,
pode atravessá-la para retornar ao salão. Pedidos e pratos prontos têm prioridade
sobre o passeio, que não empurra personagens. Durante o atendimento, a velocidade permanece igual à dos clientes.
Ocioso, cada passo leva 0,7 segundo (antes, 0,4), com trajetos próximos de
2 a 4 células e pausas aleatórias de 3 a 7 segundos. A primeira pausa começa
assim que fica livre; ao voltar da cozinha, retorna ao salão antes de pausar.
Pedidos interrompem pausas e aceleram o passo atual sem mudar a posição. O objetivo de passeio é compatível com o salvamento atual.

`PolimentoSalaoUI` verifica as quatro orientações de cadeiras, as três fases
sentadas, os dois kits em todas as rotações de bancada, a posição real no palco,
a retomada do passeio depois de anotar e servir, a volta da cozinha e save/load.
Os snapshots históricos de migração desativam apenas o passeio novo para manter
a comparação com o comportamento antigo; o teste novo cobre o comportamento
atual habilitado, que é o padrão do jogo. A fonte de sorteio do passeio é
independente dos sorteios de perfis e avaliações de clientes.

`OciosidadeGarcomUI` cobre a duração e persistência das pausas, trajetos curtos,
ritmo lento, retomada do passeio e prioridade imediata de tarefas.

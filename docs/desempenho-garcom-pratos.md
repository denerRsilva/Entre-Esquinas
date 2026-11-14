# Busca de caminho do garçom e posição dos pratos

A reprodução usa a taverna mobiliada, um cliente sentado esperando atendimento
e o garçom na cozinha. Bancadas bloqueiam a ligação com o salão. Em 300 passos
de 50 ms, o garçom tenta atender e eventualmente procura destinos ociosos.

Antes, a cada célula explorada, o A* ordenava toda a fila de candidatos, repetia
verificações de todos os móveis e consultava listas de obstáculos. Os passeios
podiam tentar separadamente muitos destinos inacessíveis no salão.

Agora, o A* usa uma fila binária de prioridade com o mesmo desempate anterior;
cada busca indexa os móveis uma vez e consulta obstáculos por posição. Somente
paredes imutáveis ficam em cache, separadas por sala e configuração do mapa.
A ocupação por móveis e atores é reconstruída, permitindo mudanças imediatas.
O passeio consulta a região acessível uma vez e ignora destinos desconectados
antes de planejar rotas individuais.

Medição headless na mesma máquina, com o mesmo cenário e sorteio fixo:

| Medida | Antes | Depois |
| --- | ---: | ---: |
| Planejamento de acesso ao cliente, média de 30 chamadas | 14,17 ms | 0,47 ms |
| Passo de simulação, mediana | 12,57 ms | 0,46 ms |
| Passo de simulação, percentil 95 | 14,24 ms | 0,57 ms |
| Pior passo | 476,20 ms | 2,17 ms |
| Total dos 300 passos | 5.180 ms | 148 ms |

São tempos de CPU desta reprodução, não medições de FPS no celular. A hipótese
de vazamento foi descartada: o alerta vinha de um callback do script inicial
de medição, corrigido antes da comparação final.

Os pratos servidos e sujos passam a usar a cadeira vinculada, a orientação da
mesa e a projeção de seu tampo. Clientes acima da mesa recebem o prato junto à
borda de cima; os de baixo e dos lados usam suas próprias posições.

`DesempenhoGarcomUI` verifica os cenários com e sem passagem, ausência de picos
acima de 100 ms nesta máquina de testes, posição dos dois pratos na mesma mesa,
louça suja, mesa girada e atualização de obstáculos após construir ou mover.
Os testes de migração de movimento, construção e atendimento preservam os
resultados anteriores de rotas e regras.

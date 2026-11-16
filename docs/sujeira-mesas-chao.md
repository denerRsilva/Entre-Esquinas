# Sujeira nas mesas e no chão

Ao terminar uma refeição, o cliente deixa uma mancha no lugar da mesa onde
estava sentado, além do prato sujo existente. Em aproximadamente 35% das
visitas, também deixa migalhas/derramamento numa célula livre ao lado da cadeira.
As marcas têm até três intensidades e não bloqueiam a caminhada. A entrada e
a saída ficam fora dos pontos de surgimento. A variação é estável por visita,
sem consumir sorteios de perfis/avaliações nem rerrolar ao carregar uma partida.

`tableStains` guarda manchas por cadeira e `floorDirt` guarda as coordenadas do
piso do restaurante. Esses dados não representam pratos ou ingredientes.
Recolher louça não limpa a mancha; limpar manchas não consome, cria ou apaga
pratos. Os tamanhos, texturas e folhas de sprites existentes são preservados.
As marcas usam retângulos de pixels inteiros e as cores já usadas na sujeira
dos pratos, dentro de uma célula artística 32 × 32.

## Limpeza

O jogador clica numa mesa livre e sem pratos sujos para passar pano; também
há o ícone contextual e a tecla de interação. Clicar na sujeira do chão faz o
personagem se aproximar e limpar. As mãos precisam estar livres e os trabalhos
manuais concluídos. Mesas com clientes ativos aguardam o fim do atendimento.
Não são adicionados avisos, nomes ou texto flutuante no cenário.

O garçom mantém pedidos/entregas como prioridade. Depois recolhe a louça e a
leva à pia, e limpa superfícies/chão quando está livre. Pode limpar o chão
mesmo sem pia acessível, mas não apaga manchas sob pratos ainda na mesa.
Alvos inalcançáveis conservam as marcas. A busca usa uma passagem de alcance
para escolher entre os pontos candidatos, em vez de A* para cada mancha.

Manchas também contam na higiene dos assentos e mesas: quando todas as mesas
estão sujas, continua valendo a saída insatisfeita dos novos clientes.
Guardar/mover mesas e cadeiras manchadas é bloqueado; construção sobre um
ponto de chão sujo exige limpá-lo antes, sem cobrar pela tentativa inválida.

## Salvamentos e verificação

Os dois campos são opcionais para manter saves antigos aceitos. A validação
confere chaves, coordenadas, referência da cadeira/mesa e intensidade de 1 a 3.
Limpar o cenário de testes remove essas referências. Não há alteração do
número de partidas, da grade lógica ou da contabilidade de comida/louça.

As 47 suítes do conjunto padrão passaram. HigieneUI cobre refeição/geração,
ausência de duplicação, save/load, coleta separada, limpeza por clique e
prioridade contextual, conservação, limpeza automática, higiene dos assentos,
construção e dados inválidos. A rotina mede ticks e exige menos de 100 ms.
Capturas reais do renderizador Compatibility: `docs/arte/higiene-sujo.png`,
`higiene-manchas.png` (prato recolhido, mancha restante) e `higiene-limpo.png`.
O enquadramento das capturas foi testado no PC; não é teste em aparelho físico.

# Serviço e empratamento

O garçom leva 1,2 segundo para anotar um pedido quando chega ao cliente. A barra
aparece acima dele e o pedido é criado uma única vez ao final. Se o cliente sai,
o garçom muda de função ou se afasta, a anotação é cancelada. O progresso fica
no salvamento; o passeio ocioso continua depois do atendimento.

A sessão abre o restaurante automaticamente dentro dos horários configurados na
Gestão, assim que o jogo avança. Almoço e jantar usam o mesmo comportamento.
O HUD da porta foi retirado. O relógio e o estado do serviço continuam no HUD
superior. Ao terminar o horário, novas entradas param e os clientes presentes
podem concluir o atendimento. Menus e construção continuam pausando o tempo.

Clicar na estação de empratamento com comida pronta nas mãos inicia a barra sem
apoiar a panela. Ao concluir, os pratos ficam disponíveis na superfície e a
panela vazia permanece nas mãos. Em lotes antigos com várias porções, todas são
empratadas juntas; é preciso haver pratos limpos e espaço suficientes. Cancelar
ou se afastar preserva a comida. Panelas já apoiadas em saves anteriores ainda
funcionam pelo fluxo antigo, uma porção de cada vez.

`FluxoImersaoUI` cobre o fluxo real de cozinhar/empratar, cancelamento, falta de
pratos, lotes antigos, conservação, barra de anotação, criação única do pedido,
retomada dos dois trabalhos após save/load, saída do cliente, retirada do HUD
e abertura automática dos dois turnos com horários personalizados.
Os snapshots antigos de migração mantêm anotação instantânea somente nos testes
comparativos; o jogo usa a anotação com progresso por padrão.

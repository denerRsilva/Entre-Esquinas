# Cadeiras e reação à louça suja

Cada chegada sorteia uma cadeira com mesa, orientação e caminho válidos. A
reserva é individual e começa ao entrar: vários clientes podem usar a mesma
mesa, mas nunca a mesma cadeira. Lugares ocupados por personagens ou reservados
por clientes em trânsito ficam fora do sorteio.

Um lugar sujo continua participando da escolha inicial. Se o cliente o escolher,
há 50% de chance de procurar outra cadeira limpa e livre **da mesma mesa**, e
50% de ir embora. Sem alternativa nessa mesa, ele sai. Quem troca de cadeira
começa com 20% da paciência de atendimento; essa primeira impressão também
reduz a parcela de atendimento na avaliação final. Escolher diretamente um
lugar limpo não gera essa penalidade.

Quando **todas as mesas utilizáveis têm pelo menos um prato sujo**, o cliente
entra e volta imediatamente à saída, com satisfação zero. A regra vale mesmo
havendo outras cadeiras limpas nessas mesas. O salão inteiro sujo não interrompe
as chegadas: cada visitante rejeitado tem uma visita perdida e seu abandono
contabilizados uma única vez, com impacto na reputação. Nenhum pedido é criado.
Limpar uma mesa remove essa rejeição obrigatória.

Não são adicionados nomes, avisos ou janelas. A barra de paciência existente
reflete o atendimento reduzido ao sentar. Saves antigos continuam aceitos;
o motivo opcional `arrivalIssue` e a paciência são preservados em save/load.

Validação: AssentosClientesUI cobre sorteio de todas as 12 cadeiras iniciais,
lotação compartilhando mesas, reserva em trânsito, entrada bloqueada, as duas
reações, falta de alternativa, saída com satisfação zero, reputação,
conservação, salvamento e liberação após recolher louça pela interação real.
ComandasUI identifica a mesa escolhida aleatoriamente. AtendimentoNativo
verifica vendas, abandonos, receita e conservação; seus 240 snapshots de ações
continuam exatos. SimulacaoNativa mantém 178 snapshots de relógio/logística e
substitui os 24 contratos antigos de chegada por esses testes comportamentais.
Os snapshots antigos pressupunham sempre a primeira cadeira e reserva da mesa
inteira, comportamentos removidos nesta atualização.

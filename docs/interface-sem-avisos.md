# Cenário sem janelas de feedback

O jogo não exibe mais notificações flutuantes de sucesso/erro após ações,
nem os painéis automáticos de tarefas e pedidos. Os avisos de corte, cozimento,
empratamento, pratos prontos, passagem bloqueada e confirmação sobre móveis
não geram caixas de texto. Nomes e instruções sobre personagens, objetos e
portais também não são desenhados no cenário.

Continuam visíveis as barras animadas nas tarefas e na paciência dos clientes,
os ícones dos pratos pedidos, o ingrediente na panela, a comida servida e as
animações de corte, vapor e calor. Foram retiradas as molduras escuras dos
indicadores sobre clientes e o balão adicional do prato levado pelo garçom;
o próprio item carregado continua visível.

Os controles de interação por ícones, inventários, menus abertos pelo jogador,
o livro de receitas e a confirmação da construção permanecem disponíveis.
A prioridade do pedido agora é escolhida na interação com o cliente, porque
o painel automático que continha esse botão foi retirado. Erros dentro de
menus abertos continuam no próprio menu, sem abrir uma janela adicional.
O catálogo de construção deixou de repetir a última mensagem de ação.

As regras de simulação e os dados dos salvamentos não mudam. As mensagens
internas continuam disponíveis para diagnóstico e validação, mas não são
transformadas em notificações na tela durante o jogo.

Teste específico: `scripts/testar-migracao.sh InterfaceLimpaUI`. Cobre início,
sucesso/erro, corte real até devolver o ingrediente, ausência dos painéis e
rótulos, inventário, opções, confirmação de construção, ícone do pedido e
priorização por interação. A captura visual usa Godot Compatibility:
`InterfaceLimpaUI.gd -- --capture`.

Validação: 36 suítes de regressão aprovadas e conferência visual com
Compatibility. Captura em `docs/arte/interface-sem-avisos.png`.

Android 0.21.2-godot.29 (21229) exportado do commit b5ee888. ZIP e assinatura
v2/v3 verificados; sem teste em aparelho Android físico nesta execução.

## Nomes em aproximação e seleção

A composição do cenário agora adota a visualização sem rótulos também quando
o chamador não informa opções de limpeza. Os ícones de interação com NPCs,
móveis e saídas não apresentam texto nem tooltip, incluindo “Sair para a cidade”.
As descrições continuam nas propriedades de acessibilidade para leitores de
tela. Nomes dos produtos nos menus de compra e inventário permanecem nesses
menus. A referência histórica de migração habilita os rótulos antigos apenas
no teste, enquanto `InterfaceLimpaUI` valida a apresentação atual por padrão,
a seleção de cada móvel e o ícone da saída próximo à porta.

A nova verificação visual mantém o cursor sobre o ícone da porta por mais de
0,5 segundo e confirma que o texto não reaparece. Captura em
`docs/arte/saida-sem-rotulo.png`. As 36 suítes de regressão passaram novamente.

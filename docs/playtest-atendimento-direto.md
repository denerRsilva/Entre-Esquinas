# Playtest do zero e atendimento direto

Versão **0.21.2-godot.52**, Android **21252**, GDD **3.5**.

## Problemas e correções

- O jogador anotava instantaneamente, enquanto só o garçom tinha barra. Agora
  um clique no cliente agenda a aproximação e inicia **1,2s de anotação**. A
  comanda nasce apenas no final. O mesmo cliente não ganha tarefas concorrentes
  de jogador/garçom. Movimento cancela; repetir clique não reinicia a barra.
- Clientes ainda abriam ações de servir/priorizar e recebiam uma imagem flutuante
  do pedido. Esses controles e a imagem duplicada foram retirados da visão de
  jogo. A comida permanece na **comanda** e no **prato sobre a mesa**.
- Contextos sem ações ainda geravam uma área de interface vazia sobre o mapa.
  Agora são filtrados e o painel fica oculto, evitando interceptar cliques.
- Clique antecipado no cliente que está chegando passa a aguardar seu assento
  e só então aproxima o jogador e anota, sem exigir novo clique ou bloquear o
  único acesso à cadeira. Clicar em cliente comendo não atende outro cliente.
- Selecionar mesa suja oferece **recolher pratos** e **limpar mesa**, conforme
  os estados reais. Passar pano fica indisponível enquanto houver pratos,
  clientes usando a mesa ou mãos ocupadas. Não há coleta automática ao abrir
  as escolhas. Atender cliente diretamente não abre essas opções da mesa.

A entrega usa um clique no cliente com o prato pronto. Os demais fluxos de
cozinha, lavagem, coleta em pilha e garçom permanecem. A tecla E continua
funcionando sem depender dos botões retirados. Nenhuma sprite foi alterada.

## Playtest nativo desde Novo jogo

`godot/qa/PlaytestDoZeroUI.gd` injeta movimentos e cliques no Viewport da Godot,
percorrendo o roteamento real de controles e mapa. Não dispara sinais de botões
manualmente. O percurso principal não cria clientes nem salta o relógio por
comandos: o tempo da simulação avança em passos e as chegadas são naturais.
Apenas a aleatoriedade recebe uma semente fixa para reproduzir o cenário.

1. Novo jogo: caixa 200, duas mesas e oito cadeiras, sem funcionário.
2. Gestão → Cardápio: escolhe servir caldo de batata no almoço.
3. Geladeira → corte → fogão → empratamento; panela vazia retorna à mão.
4. Clique único no rosto: aproxima, mostra barra no jogador e termina uma comanda,
   sem ícones intermediários. Cliente correto recebe o prato e paga.
5. Mesa → recolher → pia com lavagem por prato → devolver prato limpo → limpar.
6. Completa as três chegadas do almoço, fecha o turno e vai ao mercador.
7. Compra cinco batatas por 10 com dinheiro do atendimento; estoque cai para sete.
8. Salva e carrega pela interface, preservando dinheiro e vendas.

**Resultado observado:** duas vendas, receita 20, oito pratos e duas panelas
conservados. Uma das três chegadas recusou uma cadeira que ainda tinha prato
sujo durante o recolhimento, com `arrivalIssue=dirtySeat`. É a regra já aprovada,
não um travamento de anotação; não foi alterado o balanceamento para mascarar
essa consequência. Ao terminar o almoço e comprar reposição, caixa 210.

Em cópias separadas do estado durante a anotação, o teste verifica persistência
da barra, conclusão única ao carregar, cancelamento por movimento e recusa de
save apontando para cliente inexistente. O save externo continua versão 12;
partidas anteriores carregam sem reset. Não é necessário começar de novo.

## Evidências e limites

As **55 suítes padrão passaram**, incluindo repetições específicas após as
novas regras de interação e limpeza. O percurso visual terminou com zero
falhas de verificação.

`AnotarPedidosUI` cobre oito cadeiras, cliente em chegada, três clientes próximos,
cliques repetidos e zooms de 0,7 a 2 em tela compacta. `HigieneUI` e
`LoucaEmpilhadaUI` exercitam as novas escolhas sem criar/apagar louça.

Capturas Compatibility: [novo jogo](arte/inicio-salao.png),
[anotando](arte/playtest-zero-anotando.png), [pedido concluído](arte/playtest-zero-pedido.png),
[escolhas de limpeza](arte/playtest-zero-limpeza.png),
[almoço concluído](arte/playtest-zero-almoco.png) e [mercador](arte/playtest-zero-mercador.png).

O Cloud Desktop não iniciou sua sessão de controle por erro da ferramenta
(`the gaas-browser node_repl sandbox cannot be disabled`). O teste visual foi
realizado pela janela nativa da Godot em Xorg/Compatibility, com eventos reais
de mouse no Viewport e capturas verificadas. É um playtest automatizado no Linux,
complementado por suítes de regressão, não um teste manual ou em Android físico.

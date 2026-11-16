# Pia com pilhas e lavagem por prato

Cada pia guarda até **10 pratos sujos à esquerda** e **10 limpos à direita**.
Cada prato real tem sua própria camada na pilha, usando a arte e o tamanho já
adotados para pratos na mão e nas mesas, inclusive com a pia rotacionada.
Os arquivos de arte originais não foram alterados.

## Uso

Clicar na pia levando louça suja deposita até a capacidade disponível. A sobra
continua na mão. Com as mãos livres, o jogador inicia a lavagem dos pratos
sujos: cada prato leva **2 segundos**, com a mesma barra azul animada das outras
tarefas. Ao completar um ciclo, um prato sai da esquerda e entra na direita,
e a barra reinicia para o próximo. A fila para quando acaba a louça suja ou
quando a pilha limpa chega a dez. Não há conversão instantânea em pratos na mão.

Clicar na metade direita da pia ou no ícone de retirada pega até cinco limpos,
respeitando a pilha já carregada. Também é possível retirar os limpos quando
não há sujos ou a pilha limpa está cheia. Retirar interrompe a lavagem antes
de ocupar as mãos; os pratos podem abastecer a estação de empratamento.

Afastar-se pausa o trabalho; voltar permite continuar. O ícone de cancelamento
encerra a tarefa sem consumir o prato que estava sendo lavado. Outras tarefas
manuais exigem concluir ou cancelar a lavagem. Não foram adicionados nomes,
caixas de feedback ou textos flutuantes ao cenário.

**O garçom continua apenas recolhendo e levando pratos à pia. Não lava.**
O limite de transporte permanece cinco; ao entregar numa pia quase cheia,
ele conserva a sobra nas mãos. Com todas as pias cheias, aguarda espaço.

## Salvamentos

`dirtyPlates` e `cleanPlates` representam os estoques de cada pia; o campo
opcional `washing` guarda pia, tempo restante e ciclo atual. Salvar/carregar
preserva tanto os pratos quanto o progresso, sem duplicações. Pia com conteúdo
não pode ser reembolsada, e uma pia em uso não pode ser movida.

Saves anteriores podiam ter vinte sujos numa pia: o carregamento mantém dez,
redistribui o excedente para outras pias disponíveis e preserva o restante em
itens recuperáveis. Os três slots de salvamento permanecem como antes.

## Validação

As **48 suítes** do conjunto padrão passaram. `PiaTarefasUI` cobre interação por clique, barras por ciclo, pilhas e rotações,
capacidade, pausa/cancelamento, retirada, reabastecimento, save/load durante
lavagem, migração de excedentes, depósito parcial de jogador/NPC, conservação
e recusa de dados inválidos. Os fluxos anteriores foram atualizados para
aguardar a tarefa e retirar os pratos limpos. Capturas reais do renderizador
Compatibility: [lavagem](arte/pia-lavagem.png) e
[pilha limpa completa](arte/pia-pratos-limpos.png).

Versão Android: **0.21.2-godot.45**, código **21245**. A compilação e a assinatura
são verificadas; não houve teste em aparelho Android físico.

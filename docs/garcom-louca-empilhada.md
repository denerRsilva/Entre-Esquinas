# Garçom ativo e louça em pilhas

Registro da versão .43. A capacidade da pia, o desenho das pilhas e a lavagem
instantânea descritos abaixo foram substituídos pela
[lavagem por prato da versão .45](lavagem-pratos.md). O garçom continua só recolhendo.

**Atualização .48:** novas campanhas de refúgio começam sem funcionário; a
[contratação](contratacao-primeiro-garcom.md) substitui o garçom gratuito. O
contratado começa ativo; modos livres antigos mantêm os padrões abaixo.

O garçom começa trabalhando nas partidas novas, vazias ou mobiliadas. Ao abrir
uma partida antiga sem a marca `waiterDefaultApplied`, o funcionário parado
também é habilitado uma vez. A marca fica no salvamento; pausar pela gestão e
salvar mantém essa escolha nos próximos carregamentos. Não há reativação
forçada a cada quadro. A opção da equipe agora descreve atendimento e coleta.

## Coleta e lavagem

Jogador e funcionários usam `Louca.gd` para retirar pratos reais das cadeiras.
Um clique recolhe até cinco pratos disponíveis na mesa. Se já houver uma pilha
suja na mão, novas coletas, inclusive em outras mesas, completam até cinco;
o restante continua na origem. Ferramentas, comida e pratos limpos nas mãos
impedem a mistura com louça suja. Trabalhos manuais em curso também impedem a
coleta do jogador. Cada prato carregado é desenhado como uma camada da mesma
arte existente, sem alterar seu tamanho e sem criar outra sprite.

A lavagem continua manual e instantânea, como antes, mas conserva a quantidade
da pilha: cinco sujos viram cinco limpos. Instalar na estação respeita seu limite
de vinte e deixa a sobra na mão. Guardar no armazenamento também conserva a
pilha, inclusive se houver espaço apenas para uma parte.

## Rotina do funcionário

Entrega de comida e anotação de pedidos têm prioridade. Na ociosidade, o garçom
recolhe até cinco pratos, podendo visitar outra mesa para completar a pilha, e
leva à pia. Com louça nas mãos, precisa descarregar antes de voltar ao
atendimento; se surgir prioridade, ele deixa de procurar pratos adicionais.
Se for pausado durante o transporte, termina a entrega do que já pegou.

Cada pia tem capacidade técnica atual de vinte pratos sujos, mostrados em
quatro pilhas de até cinco. O jogador clica na pia com as mãos vazias para lavar
até cinco dos pratos entregues. Não há lavagem automática pelo garçom. Sem pia
acessível ou com todas cheias, ele não começa a recolher louça. Se uma pia for
removida ou bloqueada durante o trajeto, a carga continua com o funcionário.

## Integridade e validação

O save inclui a pilha do jogador, a carga `dirtyPlates` do funcionário e o
campo opcional `dirtyPlates` da pia. A conservação conta todos esses locais.
Validação rejeita mãos/NPC acima de cinco e pia acima de vinte. Retirar uma pia
com conteúdo pelo reembolso é bloqueado; mover mantém seu conteúdo. Os campos
novos são opcionais em saves antigos, sem alterar o número de slots.

A busca de limpeza usa uma única busca de alcance para os alvos candidatos;
o funcionário não recalcula essa busca enquanto atravessa uma célula. O teste
de trajeto real mede o tempo por quadro e exige menos de 100 ms por tick.

As 46 suítes do conjunto padrão passaram, incluindo a nova LoucaEmpilhadaUI.
Ela cobre padrão ativo, pausa salva, partida antiga, coleta entre mesas,
limite cinco, lavagem, instalação parcial, armazenamento, save/load durante
transporte, pia sem acesso, prioridades e conservação. Testes de interface
manuais pausam explicitamente a automação para isolar suas ações; o teste novo
entra com o padrão real ativo. Capturas do renderizador Compatibility estão em
`docs/arte/louca-jogador.png`, `louca-garcom.png` e `louca-pia.png`.

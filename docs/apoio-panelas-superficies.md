# Apoio de panelas em superfícies livres

Panelas vazias ou cheias podem ser colocadas num fogão livre, numa mesa de
trabalho sem kit ou num módulo livre de bancada horizontal, vertical ou de
quina. Cada mesa/módulo aceita uma panela. Os mesmos cliques retiram a panela
para as mãos quando elas estão livres.

O apoio é recusado se a superfície já possui panela, kit de corte/empratamento,
pratos, utensílios, ingredientes ou outros itens. A recusa preserva os itens
nas mãos e no móvel. Não é possível instalar um kit sobre uma panela, nem
vender o móvel enquanto ela estiver apoiada. Mover/girar o móvel leva a panela
junto. As regras são verificadas novamente ao concluir uma interação enfileirada.

O empratamento continua sendo feito com a panela nas mãos: ao terminar, ela
fica vazia nas mãos. Isso não usa um espaço de apoio nem coloca a panela sobre
o kit de empratamento. A mesa equipada que aparece na referência do usuário
não aceita apoiar panelas.

A colocação de panela cheia num fogão livre preserva receita, porções,
qualidade atual e condição queimada. A panela volta ao estado de aquecimento
do fogão; panelas apoiadas em mesas/bancadas ficam fora do fogo. A representação
usa o centro do tampo, incluindo as formas da bancada e a rotação da mesa.

O armazenamento lógico inclui a panela apoiada nas verificações de conservação
de utensílios e comida. Salvar/carregar mantém esse conteúdo e sua posição.
Saves antigos com panelas já apoiadas na estação de empratamento são aceitos
sem apagar itens: o jogador continua podendo retirar a panela antiga. Novos
apoios nessa estação são recusados.

`ApoioPanelasUI.gd` cobre as quatro bases, panelas vazias/cheias, ocupação com
ferramentas/pratos/outros itens, tentativa de duas panelas, fogão ocupado,
panela queimada, conservação, save/load, movimentação do móvel e o fluxo real
de cozinhar → apoiar → retirar → recolocar no fogão → empratar nas mãos.
Também cobre bloqueio de kit/venda e conteúdo malformado em saves.

As referências históricas de migração mantêm os demais casos comparáveis.
Dez contratos antigos de cozinha que permitiam sobreposição ou rejeitavam
panelas cheias foram substituídos pelos testes específicos da nova regra;
a suíte de interações também registra os contratos substituídos de retorno
ao fogão. A regressão padrão contém 37 suítes, todas aprovadas, além da
verificação adicional de apoio/salvamento e da captura Compatibility
`ApoioPanelasUI.gd -- --capture`. Não houve teste em aparelho Android físico.

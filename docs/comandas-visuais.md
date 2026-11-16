# Comandas visuais

A arte de papel amarelo aprovada é usada por recorte de atlas, sem modificar o
PNG original (`godot/arte/ui/comanda-aprovada.png`). A amostra preenchida fica
apenas como referência no atlas: os elementos no jogo são dinâmicos.

Cada pedido anotado gera uma comanda no canto superior direito, contendo apenas
o número da mesa, a imagem real da receita e a barra de paciência existente
(`BarraAnimada.gd`, com o pacote Modern UI já usado no jogo). A barra diminui
conforme a espera, com as mesmas cores verde, amarelo e vermelho dos clientes.
Os números em pixel art identificam mesas, não o ID interno de cada pedido.
São derivados da ordem dos móveis no salvamento; remover mesas pode renumerá-los.

Clientes que ainda aguardam anotação não geram comandas. O pedido continua na
tela durante o preparo e a entrega, até ser servido ou cancelado. Menus,
construção e cidade ocultam a faixa. Muitos pedidos podem ser acessados por
rolagem horizontal, inclusive por toque, respeitando a área segura do celular.

Os controles são reaproveitados por ID de pedido; atualizar a paciência não
recria papéis, imagens ou barras. Não há textos explicativos ou tooltips novos.
Os dados são derivados do estado existente, sem alterar o formato dos saves.

Validação: `scripts/testar-migracao.sh ComandasUI BarrasAnimadasUI InterfaceLimpaUI
TelaExpandidaUI DesempenhoGarcomUI`. A suíte ComandasUI cobre criação, receita,
mesa, espera, save/load, reutilização dos controles, rolagem, áreas seguras,
menus, cidade, entrega e cancelamento. Capturas com o renderizador real em PC
1280×720 e celular 1170×540 estão em `docs/arte/comandas-pc.png` e
`docs/arte/comandas-celular.png`. Os formatos de celular foram simulados no PC;
não representam teste físico em aparelho Android.

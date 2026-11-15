# Tela expandida e interiores

A janela inicia em tela cheia. No PC, F11 ou Opções → Alternar tela cheia
permitem voltar ao modo janela. O Android mantém orientação paisagem e modo
imersivo. A base visual é 960×540 com `canvas_items` e aspecto `expand`:
a área visível acompanha a proporção do dispositivo, sem esticar sprites.

O mapa cobre a janela toda; a HUD é sobreposta e se reposiciona nas bordas.
O controlador recebe a largura/altura do viewport e usa o mesmo retângulo para
câmera, cliques, interação e arrasto de construção. O redimensionamento também
atualiza menus abertos, quando a simulação está pausada.

Fora da geometria de cada interior, o fundo é preto. A câmera enquadra o
interior com espaço para a interface; em zoom maior acompanha o personagem e
permite ver até 40 unidades do mundo além das paredes. Telas largas mostram
mais espaço ao redor, com a interface usando a largura disponível. As dimensões
do restaurante, colisões e disposição dos móveis permanecem no mapa original.

Menus, catálogo, mensagens, botões inferiores e confirmação de construção
acompanham o tamanho do viewport. No Android, a HUD considera a área segura
informada pelo sistema para recortes da tela e navegação por gestos; o mundo
continua ocupando a tela toda.

`TelaExpandidaUI.gd` verifica 1280×720, 1920×1080, 2340×1080, 2560×1080,
1024×768 e 960×540, incluindo proporção, limites de controles, cliques reais
na geladeira, conversão tela/mundo e construção. Também verifica a margem de
câmera nas paredes e a conversão da área segura. As capturas são geradas pelo
renderizador Compatibility com `-- --capture`.

Validação concluída: 35 suítes de regressão aprovadas; conferência visual com
Godot Compatibility em 1920×1080 e 2340×1080. Capturas em
`docs/arte/tela-expandida-pc.png` e `docs/arte/tela-expandida-celular.png`.
As resoluções de celular foram simuladas no computador; não houve teste em
aparelho Android físico nesta execução.

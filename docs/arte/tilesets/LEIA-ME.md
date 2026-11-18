# Entre Esquinas — folhas visuais para tilesets

Base: conceito aprovado em `../direcao-aprovada.png`. Unidade artística pretendida: 32 × 32; objetos maiores em múltiplos dessa unidade.

## Arquitetura

Pisos de madeira horizontal e vertical, terracota, cerâmica de cozinha, pedra e terra. Paredes com reboco e lambril, paredes de azulejo, vigas, terminações e cantos. Fundações e fachadas gastas, porta fechada e vão aberto, janelas acesa e apagada. Telhas, chapas metálicas, cumeeiras e bordas. Calçamento, musgo, hera, vegetação, entulho, degrau e grelha.

## Móveis e cozinha — seis colunas por cinco linhas

1. Fogão aceso; fogão apagado; geladeira fechada; geladeira aberta; bancada de corte; bancada de empratamento.
2. Mesa vazia; mesa com toalha e vela; quatro vistas de cadeira (as laterais exigem correção de orientação).
3. Armário vazio; armário com louça; estante vazia; estante com três panelas; pia; lixeira.
4. Pilha de pratos; prato limpo; prato sujo; panela vazia; tampa; panela queimada.
5. Prateleira de potes; suporte de utensílios; balcão; banco; chaleira; frigideira.

## Decoração e vila — seis colunas por cinco linhas

1. Lanterna acesa; lanterna apagada; vela; vaso de folhagem; planta pendente; flores.
2. Tapete; capacho; toalha dobrada; bandeira da taverna; placa de perigo; quadro de avisos.
3. Barraca com produtos; barraca vazia; bancada do ferro-velho; toldo remendado; engrenagem; tubos.
4. Caixa vazia; caixa de legumes; barril; saco de arroz; caixa de ferramentas; peças de geladeira.
5. Floreira de pedra; ruína com vegetação; banco externo; balde; vassoura; lenha.

## Estado de produção

Estas são folhas de referência ampliadas geradas por imagem, não um recurso TileSet `.tres` pronto. A aparência segue o conceito, mas dimensões, perspectiva dos cantos, orientações, transparência e junções precisam de preparação antes de uso. As texturas de piso ainda não foram validadas como repetíveis sem emenda. Algumas peças têm halos semitransparentes.

Próxima preparação técnica: normalizar pixels, recortar e alinhar peças a 32 × 32; corrigir cadeiras laterais e cantos que ficaram diagonais; testar pisos repetidos; separar decoração de colisão; criar atlas e terrenos na Godot; validar uma sala montada e circulação. Não substituir a geometria do jogo com esta folha sem essas verificações.

Objetos com conteúdo têm versões vazias quando presentes. Na integração, panelas, pratos e ingredientes reais devem ser camadas ligadas ao estado do jogo; uma imagem de prateleira cheia não deve gerar itens nem exibir conteúdo inexistente. Bancas, peças e objetos novos não implementam comércio ou crafting por si só.

## Arquivos únicos após a limpeza

As cópias desta pasta eram byte a byte iguais às texturas do jogo. Use [arquitetura](../../../godot/arte/taverna/arquitetura.png), [móveis](../../../godot/arte/taverna/moveis.png) e [decoração](../../../godot/arte/taverna/decoracao.png).

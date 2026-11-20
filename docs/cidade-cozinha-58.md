# Cidade integrada e cozinha — 0.21.2-godot.58

O mapa aprovado agora é o exterior jogável da campanha. Sair pela porta da
taverna abre a cidade de 80 × 64 tiles de 32px; tocar a fachada/entrada da taverna
ou selecionar esse destino no mapa traz o jogador de volta ao salão. Teclado,
clique, joystick por toque e zoom funcionam no exterior. O botão Mapa e a tecla M
abrem uma lista rolável de destinos. E permite interagir junto às entradas dos
serviços ativos. O mapa pausa o relógio enquanto é consultado.

Beto atende no mercado e mantém o estoque diário limitado, os preços e a entrega
na geladeira. Nina atende no acolhimento nos dias de caravana já definidos pela
campanha. As outras construções, a horta e as oficinas compõem o cenário e a
navegação; esta entrega não cria sistemas novos de agricultura ou fabricação.
Há 17 moradores de ambientação, além dos vendedores. Eles não substituem nem
alteram a população coletiva de 50 moradores das novas campanhas.

A iluminação acompanha o relógio da partida. Os interiores continuam mostrando
fundo preto além das paredes. O HUD existente permanece acessível na cidade;
a consulta do mapa ocupa a tela e devolve o HUD ao fechar.

## Cozinha

Fogão, pia e geladeira usam recortes do **Modern Interiors completo**, adquirido
pelo proprietário. A pia combina cuba e móvel; a geladeira usa três células
empilhadas de 32px. Piso e revestimento vêm do Room Builder do mesmo pacote.
As cenas dos aparelhos são compartilhadas com as miniaturas da construção.
Mesas de trabalho, utensílios, panelas, pratos e decoração anteriores continuam
nesta etapa, para manter as interações e permitir avaliação visual por lotes.

A disposição inicial .57 e a passagem sem divisória permanecem. O visual novo
se aplica também às partidas existentes, sem reposicionar seus móveis.
Corte, cozimento, empratamento, louça e recursos da campanha conservam as regras.

- [Cozinha](cidade-cozinha-58/cozinha.png)
- [Saída da taverna](cidade-cozinha-58/taverna.png)
- [Cidade em janela de celular](cidade-cozinha-58/cidade-celular.png)

## Arte e peso

A pasta Descompactado do Drive permitiu baixar os PNGs individuais dos pacotes
pagos. Nenhuma versão gratuita de teste foi incorporada. Os arquivos originais
continuam preservados no acervo externo e no estudo da cidade.

A versão jogável inclui só as partes usadas. Quadros dos moradores foram
recortados sem reamostragem para 768 × 128; o botão da cidade usa só seu bloco
64 × 64; os recortes da cozinha e da arquitetura foram empacotados em dois atlas
160 × 96 e 160 × 128. Não houve redução de resolução, interpolação ou alteração
de paleta. `godot/mundo/cidade/assets.json` e
`godot/arte/interiores/fontes.json` registram origem, retângulos e SHA-256.

A soma teórica dos pixels RGBA das texturas da cidade cai de 101,07 MiB no estudo
original para 10,70 MiB, antes de outras despesas do renderizador. Não é uma
medição de RAM total do jogo. A cidade desliga processamento e renderização
quando o jogador está no interior. Créditos de LimeZu integram o jogo.

## Edição e compatibilidade

Abra `godot/mundo/cidade/Cidade.tscn` na Godot para pintar `Piso32`, mover objetos
em `Objetos` e editar pontos em `Destinos`. As bases físicas ficam junto aos
objetos. A navegação lê a geometria salva da cena; não é preciso editar um
algoritmo para mover um banco ou prédio. A cidade tem câmera e física próprias
em SubViewport, abaixo do HUD, sem interferir nas coordenadas internas da taverna.

O save ganha apenas `cityVisit` opcional, com posição e zoom do exterior.
Partidas antigas continuam válidas. O jogador conserva o item carregado ao
atravessar a porta. A economia mantém suas âncoras internas de compatibilidade;
o comércio é aberto depois da caminhada física até o vendedor no mapa novo.
Ao sair novamente da taverna, o personagem reaparece diante da porta.

## Validação

`CidadeIntegradaUI` percorre a porta, cidade, mercado, horta e retorno usando
física real; compra pelo menu, verifica estoque e conservação, salva e carrega
no exterior e cozinha depois da viagem. Exercita entrada real por mouse,
tecla M, toque, lista de destinos e janelas 1280×720, 2340×1080 e 960×432.
Capturas foram renderizadas pela Godot em Linux. O conjunto existente também
verifica cozinha, atendimento, construção, contratação, campanha e disco.

Quatro fixtures antigas foram atualizadas: célula bloqueada da antiga divisória,
linhas da grade de depuração no mesmo local, barreira do teste de desempenho e
posição da câmera no teste de rosto. Essas incompatibilidades foram reproduzidas
na .57 antes de atualizar os testes. O playtest do zero passou a visitar o
mercado pelo novo mapa, em vez de clicar coordenadas da rua antiga.

As 61 suítes passaram em lotes, incluindo o novo playtest integrado. O primeiro
toque após fechar o mapa foi corrigido: o joystick é reativado imediatamente,
sem aguardar o próximo quadro. A área do joystick não intercepta cliques do PC
nem cobre os botões inferiores do HUD.

A auditoria de arte confere os canvases registrados e a de migração mantém zero
JavaScript. APKs universal e ARM64 têm a mesma identidade e assinatura anteriores.
Instalação e desempenho em aparelho Android físico ainda precisam ser avaliados.

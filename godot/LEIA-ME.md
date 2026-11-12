# Fluxo atual: somente as mãos

O jogador não tem inventário nem barra de slots. No início mobiliado, ingredientes ficam na geladeira, uma panela no fogão e pratos na mesa de cozinha. Frango e legumes podem ser cortados. Consulte [COZINHA-FISICA.md](COZINHA-FISICA.md) para controles, migração e testes. Os registros abaixo descrevem entregas anteriores.

# Compatibilidade verificada na Godot 4.7.2

Importação e testes nativos em Linux/4.7.2: [relatório](qa/VALIDACAO_4_7_2.md).
Os registros abaixo de validação apenas na 4.6.3 são históricos.

# Atualização: cozinha física

Veja [COZINHA-FISICA.md](COZINHA-FISICA.md) para o fluxo atual, migração de saves e testes.
Uma porção por cozimento, mesa de corte separada da mesa de cozinha, panela nas
mãos e empratamento sem talher. O proprietário usa Godot 4.7.2; testes locais desta
alteração foram executados em 4.6.3 Linux. As instruções abaixo sobre abertura e
arquitetura permanecem como referência histórica.

# Entre Esquinas — Restaurante & Vida na Cidade

**Projeto editável para Godot 4.6.3 Standard • PC x86-64 • 0.21.2-godot.1**

Regras e decisões de design: [GDD consolidado](../GDD.md).

## Abrir e jogar

1. Extraia o ZIP por completo. Mantenha a pasta `nativo` junto ao projeto.
2. No gerenciador da Godot, escolha **Importar**, selecione `project.godot` e abra o projeto. Aguarde a primeira importação das texturas.
3. Pressione **F5**. **Começar na taverna** abre o restaurante equipado. **Começar vazio** inicia a montagem do zero. O botão **Tutorial** exibe os primeiros passos.

Use WASD/setas para movimento livre e contínuo, com parada imediata ao soltar e deslizamento nas paredes. O clique no chão também continua disponível para caminhar até um destino. Clique em móveis e clientes para se aproximar. Use **Gestão → Modo construção** para reposicionar, girar ou guardar móveis. **Opções → Salvar e carregar** controla o progresso.

## Editar a cozinheira

Abra **personagens/Cozinheira.tscn** e selecione o nó **Cozinheira**. Clique no recurso **Sprite Frames** no Inspetor. O painel inferior permite escolher **baixo**, **esquerda**, **direita** ou **cima**, reproduzir o ciclo, trocar quadros e alterar os FPS. O enquadramento e a escala são propriedades do nó. Use F5 para ver a alteração durante uma partida.

O projeto inicia com a arte da versão publicada. Para experimentar a alternativa de 12 poses, abra **mundo/Restaurante.tscn**, selecione **Mapa → Palco** e arraste **personagens/Cozinheira12Poses.tscn** para a propriedade **Cozinheira** no Inspetor. Salve a cena e pressione F5.

A alternativa usa **arte/cozinheira-12-poses-64.png**, com 3 colunas, 4 linhas e células de 64 × 64. A sequência usa primeiro passo, neutra, segundo passo, neutra. Cada figura tem um ponto de apoio comum. As cores e os detalhes resultam da arte fornecida; um retoque pixel a pixel continua possível. Para pintar novos pixels, edite o PNG em seu editor de imagens e salve no mesmo caminho. A Godot reimporta a imagem e preserva as animações. Se mudar o número de quadros, ajuste o recurso SpriteFrames.

## Onde mexer

| O que editar | Arquivo ou pasta |
|---|---|
| Atendente, logística e moradores | Cenas e recursos em `personagens/` |
| Fogão, mesa, geladeira e demais móveis | Cenas individuais em `moveis/`. O nó Arte define imagem, escala e posição em relação ao chão |
| Piso e paredes visuais do salão | `mundo/Salao.tscn`, com TileSet de 40 px. A unidade original do projeto foi preservada |
| Fachada e rua | `mundo/Rua.tscn` |
| Moldura, cores e botões | `interface/Restaurante.tres`; controles da interface em `interface/` |
| Receitas, preços, capacidade, colisões, ocupação e passagem entre cômodos | `simulacao/restaurant-core.js` |
| Mapeamento de compras, ações, menus e atalhos | `simulacao/acoes.js` |
| Direções, ordenação no cenário e vínculo com as cenas de arte | `mundo/Palco.gd` |

Ao mudar a planta, atualize também as regras de circulação e a disposição do cenário mobiliado. Pintar uma parede visual na camada de tiles, por si só, só altera sua aparência.

## Como o jogo roda

A Godot cuida da janela, dos eventos, do mapa, dos sprites animados, dos controles, do áudio e da gravação local. A simulação da versão publicada 0.21.2 executa dentro do próprio processo da Godot, por meio da extensão **RestauranteVM**, com QuickJS compilado para Windows e Linux x86-64. O projeto abre no editor padrão, sem instalar Node.js ou iniciar servidor. As fontes para recompilar a extensão estão em `nativo/fonte/`.

A origem usada na migração foi o commit `f8781d25ee5747ad57b39db8f947ee1328892f53` do projeto publicado. A rua e as conversas mantêm o alcance da demonstração 0.21.2. O protótipo histórico da mercearia está arquivado em `historico/` e pode ser aberto pelo menu de salvamento.

## Progresso e exportação

A versão Godot grava em `user://restaurante.json` e preserva uma cópia da gravação anterior. Para trazer um progresso do navegador, o botão **Importar salvamento (.json)** recebe o JSON do estado do restaurante. Em seguida use **Carregar restaurante**. O progresso do site e o do PC são independentes.

Os perfis de exportação **Windows PC** e **Linux PC** estão configurados. Para gerar um executável no seu computador, instale os modelos de exportação correspondentes à Godot 4.6.3. Esta entrega contém o projeto de edição e as bibliotecas nativas para essas duas plataformas.

## Validação

Na Godot 4.6.3 para Linux x86-64 foi feita a importação do projeto e a execução sem janela. Passaram as sete suítes de regras de chegada de clientes, calendário e reputação, cozinha, paciência, qualidade, turnos e garçom. O teste de integração cobre controles Godot, tutorial, início mobiliado, construção, inventário, compra no computador, preparo e retirada de pratos, troca entre rua e salão e salvamento/carregamento no disco.

O teste está em `qa/Verificar.gd`. Execute com dados de usuário de teste, pois a verificação grava uma partida. Em Linux, na raiz do projeto:

```sh
XDG_DATA_HOME="$(mktemp -d)" godot --headless --editor --import
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://qa/Verificar.gd
```

A validação visual em movimento e o playtest de um turno inteiro no Windows ficam para a abertura deste projeto no PC. O pacote inclui a DLL Windows x86-64, compilada por cross-compilação. A execução local verificada foi em Linux. Web, Android e macOS exigem trabalho específico na extensão antes de exportar.

## Rua e teste de clientes

Atravesse a porta do restaurante com WASD/setas ou clique nela para sair. Na rua,
a fachada mostra o estado do serviço e o botão **Abrir restaurante** (ou
**Encerrar restaurante** quando aberto). O serviço respeita os horários dos turnos.
A porta da fachada permite retornar ao salão.

Para testar clientes sem esperar o relógio chegar ao almoço:

1. Entre em **Opções → Testes**.
2. Escolha **11:00** no seletor de horário e clique em **Avançar horário**.
3. Volte ao jogo e abra o restaurante pela placa, dentro ou fora do salão.
4. Os clientes começam a chegar após alguns segundos de jogo ativo.

O seletor avança em blocos de dez minutos, somente para a frente no dia atual.
Não simula o intervalo pulado: preserva a paciência, preparos e entregas. Passar
do fim do turno encerra novas entradas; às 02:00, a virada de dia segue as regras
normais e aguarda as pendências. O avanço fica na partida ao usar Salvar.

# Restaurante jogável — Godot .10

Escolha **Começar na taverna** para usar a nova planta de **20 × 10 células**, incluindo paredes: 200 células, cerca de 29% menos que a versão .8 e 48% menos que a planta original.

- Salão com três mesas, 12 cadeiras e um garçom; cozinha equipada. Sem cômodo de estoque e sem NPC de logística.
- Computador, caixas de recebimento e prateleira são comprados e posicionados pelo catálogo de construção. Não vêm instalados. Geladeira do estoque removida do catálogo da nova planta.
- Computador e recebimento funcionam nas posições instaladas. Compras exigem caixas; guardar caixas é bloqueado quando ainda há ingredientes ou entregas pendentes. Mover as caixas conserva o conteúdo.
- Saves anteriores continuam usando sua planta e funcionários, sem conversão destrutiva. A nova partida recebe a planta menor.

A arte usa as pranchas aprovadas, ainda ampliadas e não finalizadas como atlas nativo 32 × 32. A grade lógica permanece em 40 pixels. Rua e NPCs ainda usam arte anterior. A remoção do estoque não implementa comércio com NPCs nem fabricação por artesãos.

Validação: Regras.cjs (incluindo taverna-unica.test.cjs), MaosUI, TavernaUnicaUI, MovimentoUI e Verificar, Godot 4.6.3 Linux. Verificados cozinha completa, colisão e acesso, catálogo, computador instalado, compra/entrega/retirada, conservação e saves. Captura em restaurante-jogavel.png. APK .10 com assinatura e alinhamento conferidos; ainda não testado em aparelho Android físico.

Polimento .10: removido o retângulo marrom sobre a mesa de empratamento; preparo aproximado uma célula; fogão perto da geladeira e estante de panelas em sua antiga posição; segundo vaso transferido ao canto superior esquerdo. A mesa de empratamento e o vaso inferior esquerdo permanecem no lugar.

Interações .11: botões contextuais sem legendas visíveis; prato, panela e ingredientes com símbolos de inserir, retirar, preparar ou descartar. Armazenamento mostra arte, quantidade e seta de retirada. Descrições permanecem nos tooltips. Fluxo MaosUI validado e captura em interacoes-visuais.png.

Versão .13: clientes caminham a 2,5 células/s (0,4 s por célula; antes 0,18 s). Velocidade da cozinheira preservada. Início mobiliado segue a imagem enviada: três mesas com quatro cadeiras, equipamentos alinhados na parede superior e garçom fora dos assentos. Testados movimento em curso/salvamento, assentos, circulação e cozinha completa.

Versão .14: todos os NPCs (clientes, garçom, moradores e logística de saves antigos) usam 0,4 s por célula, equivalentes a 2,5 células/s. A velocidade do jogador permanece inalterada.

Versão .15: personagem principal a 3,3 células/s tanto no teclado quanto por clique (antes 4,5 e aproximadamente 5,56, respectivamente). NPCs continuam a 2,5 células/s.

Versão .16: spritesheets do garçom e dos três clientes integradas como AnimatedSprite2D, quatro direções, quatro quadros por direção e 5 FPS de animação. Escala compatível com a cozinheira; filtro nearest e recorte de transparência. NPCs mantêm 2,5 células/s. Teste SpritesNPCs.gd confirma os quatro modelos e seus frames, além de saves válidos. Captura em npcs-integrados.png. Os atlas ainda são estudos ampliados, não sprites nativos finais de 32 × 32.

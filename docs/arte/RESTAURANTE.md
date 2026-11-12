# Restaurante jogável — Godot .10

Escolha **Começar na taverna** para usar a nova planta de **20 × 10 células**, incluindo paredes: 200 células, cerca de 29% menos que a versão .8 e 48% menos que a planta original.

- Salão com três mesas, 12 cadeiras e um garçom; cozinha equipada. Sem cômodo de estoque e sem NPC de logística.
- Computador, caixas de recebimento e prateleira são comprados e posicionados pelo catálogo de construção. Não vêm instalados. Geladeira do estoque removida do catálogo da nova planta.
- Computador e recebimento funcionam nas posições instaladas. Compras exigem caixas; guardar caixas é bloqueado quando ainda há ingredientes ou entregas pendentes. Mover as caixas conserva o conteúdo.
- Saves anteriores continuam usando sua planta e funcionários, sem conversão destrutiva. A nova partida recebe a planta menor.

A arte usa as pranchas aprovadas, ainda ampliadas e não finalizadas como atlas nativo 32 × 32. A grade lógica permanece em 40 pixels. Rua e NPCs ainda usam arte anterior. A remoção do estoque não implementa comércio com NPCs nem fabricação por artesãos.

Validação: Regras.cjs (incluindo taverna-unica.test.cjs), MaosUI, TavernaUnicaUI, MovimentoUI e Verificar, Godot 4.6.3 Linux. Verificados cozinha completa, colisão e acesso, catálogo, computador instalado, compra/entrega/retirada, conservação e saves. Captura em restaurante-jogavel.png. APK .10 com assinatura e alinhamento conferidos; ainda não testado em aparelho Android físico.

Polimento .10: removido o retângulo marrom sobre a mesa de empratamento; preparo aproximado uma célula; fogão perto da geladeira e estante de panelas em sua antiga posição; segundo vaso transferido ao canto superior esquerdo. A mesa de empratamento e o vaso inferior esquerdo permanecem no lugar.

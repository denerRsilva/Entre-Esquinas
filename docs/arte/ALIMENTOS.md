# Estudo visual dos alimentos

Referência: direção de arte aprovada em `direcao-aprovada.png`.
Folha: [alimentos.png](../../godot/arte/taverna/alimentos.png), organizada em três linhas, da esquerda para a direita.

1. Arroz no saco; legumes inteiros (cenoura e repolho); frango cru.
2. Arroz solto (alternativa visual, não um estado cortado); legumes cortados; frango cru cortado.
3. Arroz com legumes; sopa de legumes; frango com arroz.

A cenoura e o repolho representam juntos o item atual “legumes”, não ingredientes novos independentes.
O arroz não exige corte. Frango cortado permanece cru até o cozimento.

Imagem gerada ampliada em 1536 × 1024, RGBA. É um estudo visual, não um atlas nativo validado de 32 × 32.
A transparência e os contornos ainda exigem limpeza e conferência em fundos claros e escuros;
há pixels semitransparentes e halo na imagem gerada. Ainda falta normalizar células, escala e paleta antes da integração.
Não altera receitas, regras ou sprites do APK atual.

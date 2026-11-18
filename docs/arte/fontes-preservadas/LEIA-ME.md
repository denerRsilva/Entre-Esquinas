# Fontes preservadas fora do projeto Godot

Estas dez pranchas não são carregadas pelo jogo. Antes estavam em `godot/arte`,
apesar de já excluídas das exportações desde a .55. Foram movidas para cá sem
alterar um único byte, preservando os originais e evitando sua importação e
cache pela Godot.

O mapeamento de caminhos, tamanhos e SHA-256 está em
[limpeza-arquivos.json](../../limpeza-arquivos.json), seção `archived_sources`.
Os caminhos antigos continuam bloqueados nos presets como proteção contra uma
reintrodução acidental. Estes arquivos não devem voltar a `res://` sem uso real.

`ui/modern-ui-32.png` é o original comprado e enviado pelo proprietário. Somente
seus recortes de barras são usados pelo jogo, em `barras-compactas-32.png`.
O teste `AtlasCompacto.gd` e `scripts/compactar-ui.gd` leem o original daqui em
operações de desenvolvimento; ele não é necessário no APK.

As demais imagens são estudos e fontes históricas. As texturas realmente
utilizadas continuam em `godot/arte`; o kit nativo 32px permanece separado.

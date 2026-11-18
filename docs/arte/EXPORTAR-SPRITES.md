# Exportar sprites para edição

O ZIP completo ocupava 51,5 MiB e duplicava fontes já presentes no repositório,
além de recortes e renderizações gerados. Foi retirado da revisão atual na
limpeza. Nenhuma fonte única foi apagada. A versão anteriormente entregue pode
ser [baixada pelo histórico](https://github.com/denerRsilva/Entre-Esquinas/blob/090eac49287a956a189323fc700c08dacccd488d/docs/arte/sprites-completas-para-aseprite.zip),
usando **Download raw file** no GitHub.

Para gerar um pacote atualizado, execute na raiz do repositório com Godot 4.6.3,
Python 3 e um display gráfico disponível:

```sh
godot --headless --path godot --editor --import --quit
godot --path godot --rendering-method gl_compatibility --script "$PWD/scripts/exportar-sprites.gd" -- /tmp/entre-esquinas-sprites
python3 scripts/empacotar-sprites.py /tmp/entre-esquinas-sprites /tmp/sprites-completas-para-aseprite.zip
```

Use uma pasta de saída vazia para não misturar exportações antigas. O segundo
comando precisa do renderizador para capturar as cenas reais; não usar
`--headless` nele. No Windows, substitua `/tmp` e `$PWD` por caminhos locais.

O pacote inclui fontes atuais, originais preservados, referências, recortes,
renderizações, manifestos e checksums. As ferramentas não reduzem nem redesenham
os pixels. Os caminhos de fontes arquivadas foram atualizados após a limpeza.
O ZIP é um produto gerado sob demanda, não uma dependência do jogo.

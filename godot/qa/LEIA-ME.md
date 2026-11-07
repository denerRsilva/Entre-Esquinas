# Testes da versão Godot

Execute na pasta `godot/` com Godot 4.6.3. Use um diretório de dados de teste:
os testes gravam e, em MenusUI, corrompem arquivos de propósito para verificar
recuperação. Não execute com o diretório da sua partida pessoal.

```sh
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://qa/Verificar.gd
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://qa/CozinhaUI.gd
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://qa/MenusUI.gd
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://qa/ConstrucaoUI.gd
```

Importe antes com `godot --headless --editor --import` se estiver extraindo o
projeto pela primeira vez. No Linux, configure também `XDG_CACHE_HOME` para uma
pasta gravável se o cache padrão não estiver disponível.

- `Verificar.gd`: sete suítes de regras no QuickJS, percursos de compra,
  preparo, troca de cômodos e reforma; regressões de foco, relógio e teclado.
- `CozinhaUI.gd`: cliques de mouse e teclas enviados ao viewport nativo;
  caminhada, fogão, receita, panela, bancada, retirada e câmera. Detecta
  sobreposições da HUD que os testes JavaScript não detectam.
- `MenusUI.gd`: tutorial, todas as abas de Gestão/Opções, inventário,
  salvar/carregar, importação e recuperação de arquivo corrompido. O teste
  rola os painéis como o jogador para alcançar controles fora da área visível.
- `ConstrucaoUI.gd`: início vazio, pausa da construção, seleção por clique,
  rotação, confirmação de mudança, conservação do caixa e retorno ao jogo.
- `Regras.cjs`: as mesmas sete suítes de regras no Node.js, opcional.

Em sessão gráfica, omita `--headless` de CozinhaUI para testar entrada e saída
reais de tela cheia. `-- --capturas` gera `/tmp/esquinas-ui-*.png`. Sem placa de
som, use `--audio-driver Dummy`; isso não valida a saída sonora real.

Um código de saída zero deve vir acompanhado de `FALHAS: 0`. Verifique também
se há `SCRIPT ERROR` no log: falhas de compilação de GDScript podem acontecer
antes do executor de testes e precisam ser tratadas como falha.

## Desempenho de entrada e construção

```sh
node qa/layout.test.cjs
node qa/preview-cache.test.cjs
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://qa/Desempenho.gd
```

`layout.test.cjs` compara 1.173 disposições com o validador anterior, incluindo
233 aceitas, portas, obstáculos, acesso aos móveis e reservas dos personagens.
`preview-cache.test.cjs` verifica reutilização durante o desenho, invalidação
quando a geometria/posição/rotação muda e revalidação obrigatória ao confirmar.
O benchmark imprime tempos reais, sem limites absolutos dependentes da máquina.
Para incluir renderização, rode em sessão gráfica, sem `--headless`, e acrescente
`-- --render`. O primeiro quadro pode incluir compilação e aquecimento do driver.

## Movimento livre

```sh
node qa/movimento.test.cjs
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://qa/MovimentoUI.gd
```

A suíte de física cobre 13 cenários: posição subcélula, parada e inversão
imediatas, velocidade independente da frequência dos quadros, diagonais,
paredes, cantos, móveis, passagem estreita, quadro lento, reservas dos atores,
salvamento e retomada da navegação por clique. O teste Godot envia teclas ao
viewport e verifica também animação, foco e atualização em cada quadro.
Pode ser executado em sessão gráfica sem `--headless`, como CozinhaUI.

## Rua, serviço externo e seletor de horário

```sh
node qa/rua-horario.test.cjs
XDG_DATA_HOME="$(mktemp -d)" godot --headless --script res://qa/RuaHorarioUI.gd
```

São dez cenários de regras (horários, retrocesso inválido, paciência/preparo
preservados, clientes na rua, virada de dia e porta livre/ocupada). O teste
Godot percorre o fluxo pela interface nativa, incluindo o OptionButton,
11:00, saída com WASD, abertura externa, chegada de clientes e retorno ao salão.
Em sessão gráfica, `-- --capturas` salva a rua e o painel do relógio em `/tmp/`.

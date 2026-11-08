# Validação na Godot 4.7.2

Ambiente: Linux x86-64, `4.7.2.stable.official.ed1daf0bf`, extensão RestauranteVM/QuickJS incluída no projeto. Executável oficial com SHA-512 conferido com o arquivo de somas da distribuição.

## Correções

- `CozinhaUI.gd`: restauradas as funções auxiliares compartilhadas de layout, clique nativo, busca de botão, captura opcional e caminhada. A troca anterior pelo novo teste físico havia retirado funções herdadas por MenusUI, ConstrucaoUI, MovimentoUI e RuaHorarioUI, causando erros de compilação nesses scripts.
- `MenusUI.gd`: expectativas de importação atualizadas da chave antiga `entre-restaurante-09` para `entre-restaurante-10`. O jogo já gravava e importava no formato novo; os dois erros eram expectativas desatualizadas do teste.

Todas as seis suítes abaixo terminaram com código de saída zero e `FALHAS: 0`, sem erros de script nos logs finais.

## Verificações

- Importação pelo editor sem janela, incluindo scripts e GDExtension.
- `FluxoCozinhaUI.gd`: corte, receita contextual, panela nas mãos, mesa de cozinha, empratamento individual, salvamento, inventário com tempo ativo e construção pausada.
- `MenusUI.gd`: menus, importação válida/inválida, gravação, carregamento e recuperação de backup.
- `ConstrucaoUI.gd`: posicionamento, rotação, movimentação, caixa, conservação e retorno ao jogo.
- `MovimentoUI.gd`: controles, colisões, animação, posição fracionária e foco.
- `RuaHorarioUI.gd`: relógio, entrada/saída, abertura externa e clientes na rua.
- `Verificar.gd`: integração geral, regras de atendimento/paciência/reputação/turnos/garçom e regressões de foco e tempo.

Comando de exemplo, usando dados isolados da partida pessoal:

```sh
XDG_CONFIG_HOME=/tmp/esquinas47-config XDG_DATA_HOME=/tmp/esquinas47-teste XDG_CACHE_HOME=/tmp/esquinas47-cache godot --headless --audio-driver Dummy --script res://qa/FluxoCozinhaUI.gd
```

A validação foi em modo sem janela. Não comprova apresentação gráfica em uma sessão de desktop, saída sonora física, Windows ou exportação. Não foram necessárias mudanças no código de gameplay ou recompilação da extensão para os cenários executados.

# Otimização de interface e cenário

Medição de 240 quadros a 1/60 de segundo, com cozimento ativo, na mesma máquina
headless. `PerfilInterface.gd` mede separadamente a sessão (simulação e modelos),
o palco e a aplicação do HUD. O parâmetro `--bancadas` adiciona oito bancadas.

| Cenário / etapa | Antes (ms/quadro) | Depois (ms/quadro) |
| --- | ---: | ---: |
| Taverna: sessão | 0,998 | 1,004 |
| Taverna: palco | 0,251 | 0,257 |
| Taverna: HUD | 0,553 | 0,138 |
| Oito bancadas: sessão | 2,289 | 1,621 |
| Oito bancadas: palco | 1,178 | 0,306 |
| Oito bancadas: HUD | 0,745 | 0,123 |

Os controles de progresso são reaproveitados enquanto somente seus valores
mudam. Alterações de texto, estrutura, duração ou tarefa ainda atualizam o painel.
Isso evita reconstruir a árvore de controles e recalcular o layout a cada quadro.
O ajuste do painel de construção só é agendado quando ele está visível.

As 12 combinações de forma/rotação das bancadas são calculadas uma vez e guardadas.
Cada consumidor recebe uma cópia para evitar que a junção de peças altere o
perfil original. O controlador de simulação pertence à sessão, em vez de ser
instanciado novamente em cada passo; estado, entrada e sorteios continuam atuais.

`OtimizacaoInterfaceUI` verifica identidade e atualização dos controles, tarefas
simultâneas, ocultação/reabertura do painel, mudança de duração, alerta sem barra,
isolamento dos perfis em cache e reaproveitamento do controlador.
Os tempos medem CPU do teste, não FPS ou GPU de um telefone físico.

Reprodução:

```sh
godot --headless --path godot --script res://qa/PerfilInterface.gd
godot --headless --path godot --script res://qa/PerfilInterface.gd -- --bancadas
```

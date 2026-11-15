# Barras animadas da HUD

O atlas `godot/arte/ui/modern-ui-32.png` é o PNG original do pacote
Modern UI Style 1 32x32 enviado pelo proprietário do projeto, que informou
ter adquirido o direito de uso. Não foi redesenhado nem reamostrado.

- Azul: corte, cozimento, empratamento e anotação do pedido.
- Verde, amarelo e vermelho: paciência dos clientes, no cenário e no painel.
  Os limites são 50% e 25% de paciência restante.
- Verde, amarelo e vermelho: ponto ideal e alertas do fogão.

`ArteBarras.gd` compartilha o atlas, mantém as pontas da moldura e recorta o
preenchimento. `BarraAnimada.gd` conserva o valor real da tarefa no Range e
interpola apenas o desenho. O cenário usa a mesma arte e interpola por
identidade da tarefa/cliente. Tarefas concluídas ou canceladas removem a barra
imediatamente; os tempos da simulação e os salvamentos continuam iguais.
O filtro nearest mantém os pixels nítidos. Não há porcentagem escrita nas barras.

As barras do painel de cozinha e pedidos são reaproveitadas quando só o valor
muda. O cache do cenário descarta identidades ausentes, sem acumular clientes.
A animação dos controles cessa ao alcançar o valor solicitado.

Validação: `scripts/testar-migracao.sh BarrasAnimadasUI OtimizacaoInterfaceUI
FluxoImersaoUI DesempenhoGarcomUI FluxoCompletoNativoUI SalvamentoDiscoNativoUI`.
O teste específico cobre valores fracionários, crescimento e redução suave,
faixas de cor, troca de tarefas e reaproveitamento dos controles. Captura visual
com o renderizador Compatibility: executar `BarrasAnimadasUI.gd -- --capture`.
A galeria usa os controles reais: `docs/arte/hud-barras.png`.

As 34 suítes do conjunto padrão de regressão passaram, além da conferência
visual com Godot Compatibility. Android 0.21.2-godot.27 (21227) exportado do
commit 6fa6f88; ZIP, presença do atlas/scripts, exclusão de QA e assinatura
v2/v3 verificados. Sem teste em aparelho físico nesta execução.

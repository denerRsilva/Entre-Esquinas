# 0.20.2 — Reorganização no modo construção

05/11/2026. Base 0.20.1: 344ae7590aad5d6b0d785985e0e430954226999c.

- Clique/toque em móvel instalado no modo construção inicia reposicionamento sem aproximação do personagem. Confirmação preserva identidade e conteúdo, sem cobrar novamente. Cancelar conserva o objeto original.
- Mover e Guardar removidos de todas as ações operacionais, inclusive Mais opções da bancada. Guardar/reembolsar aparece no controle de edição apenas ao selecionar um móvel existente. Guardas de modo impedem chamadas de edição pela UI durante o jogo.
- Áreas autorizadas e bloqueios de colisão, móveis com conteúdo, preparo ativo e serviço pendente preservados. Computador/recebimento são infraestrutura fixa. Não foi alterado o núcleo da simulação ou o save.
- node ui.test.cjs: passou. Todos os nove tipos selecionados por coordenadas da câmera sem aproximação, cancelamento, movimentação válida, conservação de conteúdo/identidade/caixa, validade do estado, bloqueio de guardar bancada com itens, reembolso único e bloqueio fora do modo. Regressões anteriores também passaram.
- node --check UI, build HTML e git diff --check: passaram.
- Chrome na prévia: restaurante mobiliado, Gestão → Modo construção, seleção da geladeira distante, indicação de posição válida e confirmação voltando ao modo pausado. Inspeção visual dos controles realizada.
- Sem playtest humano ou teste em celular físico.

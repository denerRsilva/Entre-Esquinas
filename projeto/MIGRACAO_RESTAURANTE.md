# Transferência — 0.10.2
Engenharia de Software. Pedido aprovado: cabe ao jogador decidir abrir, sem exigências mínimas de estrutura ou insumos. Removida validação de abertura e bloqueio de cardápio vazio. HUD deixa de cobrar montagem mínima. Preservados requisitos reais das tarefas, os ciclos almoço/jantar e a conclusão dos clientes no fechamento. Save compatível com 0.10.0/0.10.1.
Verificação: testes da simulação e da interface passaram, inclusive restaurante vazio e cardápio vazio, sem criar receita inválida. Próximo: usuário/QA avaliar liberdade de abertura e suas consequências durante a operação.

--- Histórico ---

# Transferência — 0.10.1
Engenharia de Software. Implementado pedido do usuário: mostrar ícones somente para o objeto clicado. Seleção exclusiva com requisito de proximidade preservado; chão cancela, outro alvo substitui. Computador, recebimento e atendimento mantêm ações isoladas pelo alvo selecionado. Sem alterações de receitas ou economia. Save da 0.10.0 preservado.
Testes: UI cobre proximidade sem seleção, clique, cancelamento e alvos fixos; suíte do restaurante permanece passando.
Próximo: usuário/QA testar o comportamento no dispositivo real.

--- Histórico ---

# Transferência — 0.10.0

Responsável: Engenharia de Software.
Objetivo aprovado: ícones de interação acima dos objetos; preparo exige ingredientes/panela/utensílio no fogão; panela cheia não pode ser reutilizada; quatro pratos por receita; mesa de preparo exige panela de comida/pratos/colher; pia lava pratos; pia e lixo esvaziam panelas.
Implementação: ciclo físico completo com estados de panela e pratos; inventários específicos por objeto; botões agrupados sobre cada objeto; receitas selecionáveis com requisitos visíveis; garçom integrado à bancada; coleta de louça suja; descarte e conservação. O preparo antigo que consumia ingredientes de qualquer equipamento da cozinha foi substituído.
Escolhas operacionais para tornar o pedido testável: lote usa ingredientes de quatro porções; colher não consumida; duas colheres são convenientes para as duas estações; louça suja fica na mesa após consumo; lavagem/empratamento imediatos; uma panela em preparo de cada vez; custos de móveis e pratos provisórios. Quantidade por transferência permite dividir pilhas.
Verificações: README.md lista testes e limites. Save em formato/chave novos preserva versões anteriores.
Pendências: QA humano/Android real, balanceamento e ritmo do ciclo. Panelas vazias não exigem lavagem nesta etapa. Narrativa/cidade não expandidas.
Documentos a atualizar: GDD/Registro Mestre (receitas em lotes, utensílios no equipamento, ciclo de pratos e interação contextual); plano de QA e guia de interface.
Próxima especialidade: QA/Game Design avaliar clareza e diversão do trabalho no restaurante.

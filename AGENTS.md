# Diretrizes do projeto

- A direção de arte obrigatória é pixel art com unidade de **32 × 32 pixels**.
  Sprites individuais e quadros de personagem usam canvas 32 × 32. Elementos
  maiores são compostos por tiles 32 × 32, com a mesma densidade de pixels.
- Leia [docs/DIRETRIZES-ARTE.md](docs/DIRETRIZES-ARTE.md) antes de criar,
  substituir, recortar ou integrar arte. Pranchas ampliadas existentes são
  materiais provisórios; filtro nearest ou redução na Godot não os torna arte
  nativa 32 × 32.
- Preserve os originais. O pedido de 18/11/2026 autoriza redesenhar usando-os
  como referência, sem reduzir os PNGs antigos; o novo acervo está separado em
  `docs/arte/redesenho32`. Alterar dimensões na integração exige
  atualizar recortes, frames e pivôs, sem alterar automaticamente os saves.

- A premissa vigente é o **refúgio no apocalipse zumbi**, conforme o GDD 3.6;
  a origem nuclear anterior foi substituída. `docs/primeiro-ciclo-refugio.md`
  registra o protótipo .46 e não prevalece sobre as regras aprovadas no GDD.
- Alimentação, energia e moral são **três barras coletivas da cidade**, de 0 a 100.
  Hordas substituem o jantar a cada 3 a 5 dias sem penalidade pela refeição suspensa. Não há combate
  controlável; a defesa tem apresentação animada. **Duas derrotas consecutivas**
  levam ao game over. **Uma vitória zera a sequência de derrotas e restaura o
  estado normal**. A retomada deve permitir refazer a preparação pelo salvamento.
- A versão .47 implementa valores coletivos e derrotas consecutivas, com
  migração dos saves .46. As barras ficam somente em **Gestão → Cidade**,
  sem painel permanente no cenário. Ver `docs/cidade-menu-coletivo.md`.
- Desenvolver em trechos jogáveis para avaliação de Dener antes de ampliar a
  campanha. Parâmetros do primeiro ciclo são provisórios; preservar partidas
  antigas. A direção .49 usa um único slot de salvamento; três slots ficam
  para o futuro. Preservar arquivos legados e backups internos sem expô-los como
  partidas extras. Ver `docs/menu-inicial-save-unico.md`.

- Na campanha de refúgio, começar **sem funcionário**. Contratação é conquistada
  pelo crescimento da cidade; garçom é a primeira função. A .48 implementa busca
  em Gestão → Equipe, população 4 e custo 100 como parâmetros de teste. Preservar
  equipe antiga, pausa e carga ao migrar. Ver `docs/contratacao-primeiro-garcom.md`.
- Direção atual: **sem computador**, ingredientes pelo mercador de estoque
  limitado e viajantes; peças essenciais também vêm de viajantes. Carpinteiro,
  artesão e vendedor de decoração fornecem melhorias. O GDD distingue essa
  direção aprovada das compras antigas ainda presentes no protótipo.
- A .50 implementa o kit de 200 para **novas campanhas**: duas mesas/oito
  cadeiras, duas panelas/oito pratos, arroz 12/batata 8/cenoura 8 e duas receitas
  iniciais. Não aplicar esse kit ao carregar saves anteriores.
- Reposição presencial com Beto, estoque diário limitado e entrega direta na
  geladeira, sem computador/recebimento. Nina intermedeia a caravana a partir
  do dia 4; frango e aprendizado de canja são o primeiro teste desse comércio.
- Nutrição de 1–10 coxas afeta a barra coletiva; mini relógios representam
  aproximadamente 2s cada de corte + cozimento + empratamento. Novas células
  em `arte/inicio-32.png` são nativas 32px; preservar os atlas antigos.
  Ver `docs/inicio-mercador.md` para parâmetros, compatibilidade e limites.

- Atendimento direto (.52): um clique no cliente agenda aproximação e anotação
  de 1,2s com barra no jogador, sem ícones contextuais de anotar/servir/priorizar.
  Cliques repetidos não reiniciam a tarefa; movimento cancela. Cliente chegando
  é atendido após sentar, sem ocupar antecipadamente seu acesso.
- Comida do pedido permanece na comanda e no prato real, sem ícone flutuante
  duplicado sobre o cliente. Mesas sujas apresentam recolher pratos e limpar;
  passar pano exige retirar a louça, liberar a mesa e as mãos. Não renderizar
  contextos vazios que possam interceptar cliques no mapa.

- A .54 implementa as melhorias aprovadas em `docs/melhorias-equilibrio-54.md`:
  multiplicador alimentar 2; moral pela satisfação; faixa de preços ±20%,
  orçamento e preferências; descanso pelo término do jantar; chegadas distribuídas.
- Funcionário vinculado a morador consome uma porção excedente real por turno,
  remunerada pela cidade ao preço de referência, sem tomar pratos reservados.
  `mealBreak` integra conservação, validação e save; nunca pagar antes da conclusão
  nem duplicar a refeição ao carregar. Funcionário continua sem lavar pratos.
- Primeira vitória libera lote de duas porções com o dobro dos ingredientes,
  além do corte 20% mais rápido. Não conceder comida/utensílios gratuitamente.
- Avanço ao próximo turno usa a simulação e exige ausência de pendências e
  comida no fogão; nunca sobrescrever o checkpoint de preparação da horda.

- Reformulação visual .55: usar grade de 32px e múltiplos para objetos maiores,
  conforme `docs/DIRETRIZES-ARTE.md` e `docs/arte/escala32/kit`. O pack Village
  Interiors é referência estrutural, não arte autorizada a copiar para o jogo.
- Rodar `python3 scripts/verificar-arte.py` ao adicionar arte. Não registrar
  estudos ampliados como nativos só porque suas dimensões são múltiplas de 32.
- Dez pranchas antigas/completas ficam preservadas em `docs/arte/fontes-preservadas`, fora de `res://`; os caminhos antigos continuam bloqueados nas exportações.
  Reintroduzir uma dependência exige rever `excluidos-exportacao.json` e presets.
- Android universal permanece disponível. `Android ARM64` é uma opção menor;
  não remover silenciosamente suporte a ARM32/x86_64 do preset universal.

- Limpeza: não duplicar APKs com nomes diferentes no Git. Manter universal e ARM64; gerar o ZIP completo de sprites sob demanda, conforme `docs/arte/EXPORTAR-SPRITES.md`. Não recolocar cópias de atlas em docs; apontar para a fonte única.

- Feedback visual de 18/11: o primeiro redesenho foi rejeitado por aparência genérica e perspectiva inconsistente. Não tratá-lo como direção aprovada. A revisão 2 de fogão/pia/geladeira está em `docs/arte/redesenho32/REVISAO-COZINHA.md`: tampos profundos vistos de cima, frentes curtas, volumes/bevels e desgaste em clusters. Verificação de canvas não substitui avaliação artística.

- Refinamento atual: trabalhar poucas sprites por vez. O pedido seguinte focou somente um fogão em canvas 64×64 (2×2 blocos de 32), permitindo áreas vazias. O estudo 3 está em `docs/arte/fogao-64-r3`; não expandir automaticamente a revisão aos outros móveis.

- Experimento .56 autorizado: novos jogos começam com 50 moradores; não recalibrar intervalos, estoques, receitas, preços, horários, status ou contratação. Saves anteriores conservam sua população. `initialPopulation` distingue a base antiga3 da nova50; crescimento continua +1 nas primeiras três vitórias. A arte está pausada neste trabalho.

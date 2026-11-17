# Entre Esquinas

## GDD 3.1 — Refúgio no apocalipse zumbi

**Revisão documental:** 17 de novembro de 2026. **Responsável pelas decisões:** Dener Silva.

Esta versão consolida a proposta aprovada pelo proprietário em 17/11/2026 e suas
retificações: **três barras coletivas** e **derrotas consecutivas, reiniciadas
por uma vitória**. O histórico Git preserva o GDD 3.0 e as versões anteriores.

> **A taverna é onde a cidade recupera as forças para sobreviver à próxima horda.**

### Direção vigente e alcance desta revisão

A cidade é um refúgio em reconstrução no apocalipse zumbi, inicialmente precário,
que representa segurança e o último ponto de esperança para os sobreviventes.
Sua recuperação atrai mais pessoas; elas trazem habilidades e histórias, além
de maior necessidade de refeições e estrutura. A origem nuclear foi substituída;
a origem dos zumbis permanece em aberto.

- **Alimentação, energia e moral são três barras coletivas da cidade, de 0 a 100.**
  O jogador procura mantê-las altas. Diversão é uma das formas de recuperar moral.
- Dias comuns têm almoço e jantar. Hordas a cada **3 a 5 dias** substituem o
  jantar daquela noite, sem penalidade pela refeição suspensa.
- Não há combate controlável. A preparação e as condições das defesas determinam
  um resultado apresentado numa animação curta e pulável, com moradores reconhecíveis.
- A primeira derrota inicia um estado de recuo. **Uma vitória seguinte zera a
  sequência e devolve a cidade ao estado normal. Duas derrotas seguidas causam
  game over**, com possibilidade de retomar a preparação por um salvamento.
- Reconstrução e novos moradores recompensam visualmente o progresso. Melhorias
  também precisam ser sentidas no trabalho da taverna, com tempo para aproveitá-las.
- O desenvolvimento acontece em trechos jogáveis; Dener avalia o ritmo antes de
  ampliarmos a campanha.

**Estado do executável, separado do design:** a versão `0.21.2-godot.46`,
publicada no [commit 9f7fd4a](https://github.com/denerRsilva/Entre-Esquinas/commit/9f7fd4a48464fa8750699e2ef99a0200fe158bd1),
ainda usa status individuais com médias e derrotas acumuladas. Esses dois
comportamentos são **substituídos como direção de design nesta revisão**, mas
sua adaptação no código e nos salvamentos é uma tarefa posterior. Esta entrega
atualiza documentação; não altera o jogo nem gera um APK novo.

O [registro do primeiro protótipo](docs/primeiro-ciclo-refugio.md) documenta o que
foi implementado na versão .46. Números de moradores, tempos, ganhos, perdas,
pesos do cálculo e recompensas numéricas são **parâmetros provisórios**, não
regras finais. Hospedagem, cerveja, NPCs pilares definitivos e cidade completa
continuam em desenvolvimento futuro. A produção artística mantém 32 × 32.

As seções 1 a 3 e 12 a 14 registram a direção atual e suas pendências. As
seções técnicas 4 a 11 preservam o registro herdado da base anterior; o termo
“implementado” nessas passagens refere-se à inspeção histórica, não certifica
que todos os valores ainda correspondam ao executável .46. Descrições antigas
não prevalecem sobre as decisões aprovadas nesta versão.

### Estados usados no documento

| Estado | Como interpretar |
| --- | --- |
| Implementado | Comportamento encontrado no código da base inspecionada. Não significa aprovação definitiva de balanceamento nem ausência de bugs. |
| Direção aprovada | Escolha expressa do proprietário para o projeto, ainda que sua implementação não exista. |
| Parâmetro de teste | Valor atual que pode ser ajustado após avaliação. |
| Proposta não aprovada | Ideia ou solução que depende de aprovação antes da implementação. |
| Em aberto | Questão sem regra final definida. |
| Arquivado ou substituído | Conteúdo histórico isolado na seção 13; não orienta o gameplay atual. |

### Organização

- Seções 1 e 2: visão, universo e princípios aprovados.
- Seção 3: ciclo, defesa, crescimento e recompensas aprovados.
- Seções 4 a 11: registro técnico histórico da operação; valores sujeitos à revisão.
- Seção 12: direções futuras aprovadas e propostas não aprovadas, identificadas separadamente.
- Seção 13: ideias substituídas e histórico fora do escopo vigente.
- Seção 14: pendências, critérios de qualidade e rastreabilidade.

O termo **taverna** descreve o destino de design. O código e a interface atuais ainda usam **restaurante**; hospedagem e comércio presencial não são funcionalidades já entregues.

<!-- page -->

## 1 Visão, três pilares e sistemas

### Descrição do jogo

Administre uma taverna numa cidade que se reconstrói durante um apocalipse zumbi. Alimente e acolha os sobreviventes que defendem esse ponto de esperança. A expansão da comunidade aumenta a demanda e as possibilidades de operação, enquanto hordas periódicas põem o preparo à prova.

**Direção aprovada.** A taverna será um ponto de encontro e poderá oferecer descanso a viajantes. Comida, convivência e relações com o entorno sustentam a experiência. A hospedagem ainda não possui regras finais e não faz parte do funcionamento atual.

### Três barras coletivas da cidade

**Direção aprovada em 17/11/2026.** Há uma barra de alimentação, uma de energia e
uma de moral, cada uma de **0 a 100**. Representam as condições da comunidade.
Os três valores coletivos orientam preparação, feedback e resolução da defesa.
A população altera a demanda necessária para sustentá-los; a relação numérica
entre pessoas, refeições, descanso e ganhos ainda será balanceada.

| Pilar coletivo | Representa | Contribuições da taverna e da cidade |
| --- | --- | --- |
| Alimentação | Comunidade nutrida e fisicamente preparada. | Refeições suficientes e nutritivas. |
| Energia | Descanso e resistência para sustentar a defesa. | Recuperação e organização do descanso; hospedagem poderá contribuir quando especificada. |
| Moral | Esperança, confiança e disposição para cooperar. | Convívio, diversão, amizade, acolhimento e acontecimentos da comunidade. |

As barras são **status mantidos ao longo do tempo**. A unidade de design é a
cidade; os moradores continuam reconhecíveis nas histórias e na defesa, sem
exigir três barras independentes por personagem. As médias de status pessoais
presentes na versão .46 são uma solução provisória a substituir.

Moral pode influenciar cooperação, disposição para defender e atratividade
para novos moradores. Intensidades, limites e formas de recuperar cada barra
permanecem parâmetros de balanceamento. Receitas, bebidas e descanso devem ter
funções compreensíveis; uma refeição não substitui automaticamente o descanso.

### Sistemas que sustentam os pilares

Operação, gestão, vila e progressão são sistemas do jogo, separados dos três
pilares de status:

| Sistema | Papel na experiência |
| --- | --- |
| Operação | Preparar, cozinhar, servir e coordenar prioridades no espaço físico. |
| Gestão | Escolher cardápio, preços, compras, ajuda e disposição dos equipamentos. |
| Vila e relações | Conhecer moradores, obter recursos e reconhecer os efeitos do cuidado. |
| Progressão | Reconstruir a cidade, ampliar a taverna e abrir novas possibilidades. |

### Princípios de design

**Direção aprovada em 12/11/2026:** priorizar contexto visual e leitura imediata. Usar arte, ícones, quantidades e sequências visuais para ensinar ações; texto deve ser curto e complementar. No livro de receitas, destacar a arte da comida pronta e explicar o preparo da forma mais simples possível, sem blocos de instruções.

- Priorizar diversão, decisões compreensíveis e retorno claro das ações.
- Fazer a organização da cozinha e do salão influenciar o trabalho.
- Reduzir cliques sem decisão; avaliar o custo do transporte de uma unidade por vez em playtests.
- Permitir que automação libere o jogador para novas escolhas.
- Informar acontecimentos antes de aplicar consequências que exijam planejamento.
- Desenvolver a vila de forma conectada à taverna, sem transformar a rua em decoração sem função.
- Conectar desafios a recompensas perceptíveis no cenário e na operação.
- Dar tempo para aproveitar uma melhoria antes do próximo aumento de responsabilidade.
- Manter informação suficiente para compreender a preparação e as consequências das hordas.
- Usar playtests do proprietário para ajustar espera, repetição, ritmo e dificuldade.

### Referências por função

Stardew Valley orienta movimento, cotidiano, fantasia e variedade de pratos conhecidos. Travellers Rest inspira operação de taverna e melhorias. Chef RPG permanece referência de gastronomia e conexão com o entorno. PlateUp! foi acrescentado como referência para ações diretas, cozinha física e organização. Essas referências não aprovam automaticamente todos os sistemas desses jogos.

O foco imediato de produção continua sendo um serviço completo compreensível e interessante. O projeto não possui diversão, retenção ou viabilidade comercial comprovadas por testes automatizados.

<!-- page -->

## 2 Universo e direção artística

**Direção aprovada em 17/11/2026.** O jogo se passa durante um apocalipse zumbi. A cidade é um refúgio em reconstrução, com estrutura inicialmente precária, que atrai sobreviventes por sua promessa de segurança. O crescimento traz esperança, novos moradores e maior responsabilidade de alimentar a comunidade. A origem do apocalipse permanece em aberto.

O perigo exterior convive com acolhimento, reconstrução e esperança. A cidade deve ganhar vida visivelmente e oferecer melhorias concretas na taverna. Não há combate controlável, sistema de radiação ou magia aprovado por esta premissa.

### Pessoas e alimentação

Exploradores de ruínas, agricultores, mecânicos, comerciantes de passagem e moradores antigos são tipos de habitantes aprovados para o universo. Suas regras comerciais, rotinas e diferenças de atendimento ainda precisam de especificação. Os perfis atuais de paciência não equivalem a essas ocupações.

O cardápio futuro deve reunir pratos conhecidos de diferentes partes do mundo, adaptados ao universo. A culinária exclusivamente brasileira deixa de orientar o projeto. As três receitas atualmente implementadas permanecem até uma tarefa específica de mudança.

### Materiais e leitura visual

Pixel art continua sendo a linguagem aprovada. Fachadas reparadas, móveis restaurados, equipamentos antigos, roupas adaptadas e vegetação retomando partes da vila compõem a direção aceita. Madeira e terracota permanecem materiais possíveis dentro do tom novo.

A versão 0.21.2-godot.7 integra uma primeira montagem jogável do interior baseada na direção aprovada abaixo. Rua, moradores e algumas interfaces ainda usam a arte anterior; a nova ambientação não está concluída.

**Direção aprovada em 17/11/2026.** A reconstrução deve produzir acolhimento e esperança visíveis: casas reparadas, ruas iluminadas, oficinas funcionando e moradores ocupando espaços antes abandonados. O perigo exterior convive com uma taverna que recupera a comunidade. Paleta e perspectiva seguem a direção visual aprovada; novas peças e o acabamento do cenário serão avaliados em arte real.

### Direção visual aprovada — vida entre ruínas

A prancha [direção aprovada](docs/arte/direcao-aprovada.png) é a referência visual aceita por Dener. A vila combina ruínas e reparos com exteriores frios e pouco saturados; a taverna usa madeira, terracota e luz âmbar. Ingredientes e itens carregados precisam se distinguir do cenário. Personagens usam silhuetas simples e roupas adaptadas; a cozinheira de referência tem coque castanho, blusa clara, avental verde-petróleo e botas.

A unidade artística aprovada é **32 × 32 pixels**, com móveis maiores em múltiplos dessa unidade. A perspectiva é superior com frente dos objetos visível. A produção deve preservar pixels nítidos e validar animações, escala, colisões e leitura no celular. A montagem jogável mantém a grade lógica de 40 pixels e escala os recortes dos estudos ampliados; ainda não entrega um atlas nativo final de 32 × 32.

**Diretriz reafirmada pelo proprietário em 16/11/2026:** produzir sprites individuais e cada quadro de personagem em **32 × 32 pixels reais**; pisos, paredes e objetos maiores são compostos na mesma unidade. Pranchas ampliadas e o redimensionamento em tempo de execução não substituem esse acabamento. A preparação manual dos arquivos atuais será feita pelo proprietário no Aseprite antes de sua reintegração. Ver [diretrizes de produção da arte](docs/DIRETRIZES-ARTE.md). A exportação para edição não altera o gameplay ou a grade lógica atual.

O cenário inicial deve buscar a composição e as proporções da taverna da prancha aprovada. A prancha não fornece uma planta medida nem peças prontas: dimensões em tiles, circulação e encaixes devem ser conferidos durante a montagem. A produção foi dividida pelo proprietário nesta ordem: **cozinheira → alimentos → tilesets do cenário e objetos**. A sprite sheet inicial da cozinheira é um estudo gerado em resolução ampliada; foi integrada à personagem jogável com quatro direções e quatro poses por direção, mas ainda não é um atlas nativo final de 32 × 32. A opção principal “Começar na taverna” abre três mesas, 12 cadeiras e cozinha equipada. Piso em TileMapLayer, paredes, móveis, alimentos e decoração usam as pranchas aprovadas. Na versão .9, novas partidas usam uma planta de 20 × 10 células (200 células com paredes), aproximadamente 29% menor que a planta .8 de 20 × 14 e 48% menor que a original de 24 × 16. O cômodo inferior de estoque foi removido. Permanecem três mesas, 12 cadeiras e a cozinha; o único funcionário inicial é o garçom, no salão. Prateleira, computador e caixas de recebimento são opcionais no catálogo de construção. A geladeira do estoque e o NPC de logística não fazem parte da nova partida. Computador e recebimento podem ser posicionados e movidos; ingredientes só podem ser comprados depois de instalar o recebimento, e caixas com conteúdo ou entregas pendentes não podem ser guardadas. Saves anteriores conservam a planta e os equipamentos existentes para evitar perda de progresso. A câmera enquadra o espaço menor. A composição aproxima as proporções do concept, sem prometer equivalência exata.

### Regras de legibilidade

Ingredientes, pratos, recipientes, mãos e estações precisam ser reconhecíveis no tamanho de jogo. Estados de corte, cozimento e queima devem ter leitura distinta. Estrelas de qualidade pertencem aos ingredientes e refeições; não devem decorar fogões, personagens ou utensílios.

A resolução-base artística foi aprovada em 32 × 32; escala de exibição e padrão final de animação exigem validação em sprites reais. A grade lógica atual de 40 pixels não define, por si só, a resolução artística definitiva. Uma imagem conceitual não equivale a um atlas pronto para produção.

<!-- page -->

## 3 Ciclo, defesa, crescimento e recompensas

### Dia comum

**Direção aprovada.** Preparação pela manhã → almoço → atividades da tarde →
jantar → descanso. Cozinhar, servir, comprar, organizar e limpar participam do
ciclo. O jogador desenvolve a taverna para sustentar os três status coletivos.

### Noite de horda

Hordas acontecem a cada **três a cinco dias**. No dia do ataque, o alarme mobiliza
os moradores e a defesa substitui o jantar. **Não há penalidade pela refeição
suspensa**. A preparação nos dias anteriores participa do resultado.

O intervalo e o horário exatos, a forma de anunciar o risco e a antecedência
dos sinais serão testados. A primeira horda no terceiro dia e a sequência
fixa 4/5/3 do protótipo são parâmetros, não uma agenda final obrigatória.

### Resultado e apresentação da defesa

Não há combate controlável. O resultado considera alimentação, energia e
moral **coletivas**, junto das condições das estruturas de defesa. Fórmulas e
pesos ainda serão balanceados. A animação apresenta o resultado calculado;
pular sua apresentação não altera consequências ou recompensas.

Uma sequência curta mostra moradores nos postos, com variações de vitória
tranquila, defesa sofrida, recuo/invasão parcial e queda da cidade. NPCs
importantes da história devem ser reconhecíveis. Seus nomes, funções e enredos
finais serão definidos pelo proprietário.

Os sinais visuais acompanham preparação, ataque e pós-horda. Devem permitir
perceber a condição da cidade e compreender o efeito do trabalho da taverna.
O jogador pode reconhecer na defesa a pessoa que alimentou durante o dia.

### Derrotas consecutivas e retomada

**Regra aprovada:** o limite é de **duas derrotas consecutivas**. Uma vitória
interrompe a sequência, zera o contador de derrotas seguidas e devolve a cidade
ao estado normal de defesa. Uma derrota antiga não continua consumindo uma chance
após essa vitória.

| Estado antes do ataque | Resultado | Estado depois |
| --- | --- | --- |
| Normal, 0 derrotas seguidas | Vitória | Normal, 0 derrotas seguidas. |
| Normal, 0 derrotas seguidas | Derrota | Recuo, 1 derrota seguida; há outra chance. |
| Recuo, 1 derrota seguida | Vitória | Normal, contador reiniciado em 0. |
| Recuo, 1 derrota seguida | Derrota | Queda da cidade e game over. |

Exemplos: **derrota → vitória → derrota** deixa a cidade em recuo com uma derrota
na sequência atual. **Derrota → derrota** encerra a campanha. Vitórias tranquilas
e defesas sofridas que tenham sido vencidas reiniciam a sequência igualmente.

O reset refere-se ao estado de risco e à sequência de derrotas. A recuperação
numérica das barras e estruturas será balanceada separadamente. Danos às
barricadas, ferimentos e perdas limitadas de suprimentos são possibilidades
para a primeira derrota; valores e efeitos exatos permanecem em aberto.
As consequências devem permitir uma recuperação viável antes do próximo ataque.

No game over, é possível carregar um salvamento anterior com tempo suficiente
para refazer a preparação. A retomada precisa evitar uma derrota inevitável
salva segundos antes do resultado. Preservar os **três slots** de partidas e
seus dados existentes.

### Cidade em reconstrução e novos moradores

A cidade começa precária e representa segurança e esperança. Conforme resiste
e se reconstrói, atrai sobreviventes: mais pessoas trazem necessidades de comida
e estrutura, além de trabalho, habilidades, histórias e possibilidades de defesa.

O aumento da demanda acompanha o desenvolvimento da taverna. As hordas também
crescem ao longo da progressão; sua curva e a relação exata com população,
atividade da cidade ou passagem do tempo ainda serão definidas nos playtests.
O crescimento deve oferecer tempo de adaptação e não anular imediatamente o
benefício de uma melhoria recém-conquistada.

### Desafios e recompensas

O trabalho cotidiano participa de objetivos maiores da comunidade. Preparar
refeições, cuidar das condições da cidade e concluir desafios deve aproximar
o jogador de melhorias desejadas. A progressão combina retorno imediato do
atendimento com conquistas ao longo de turnos e etapas de reconstrução.

| Conquista ou progresso | Recompensa visual | Efeito possível na operação |
| --- | --- | --- |
| Recuperar a oficina | Artesão trabalhando e espaço iluminado. | Equipamentos e ferramentas melhores. |
| Melhorar o abastecimento | Entregas e depósitos organizados. | Mais possibilidades de planejar ingredientes. |
| Acolher trabalhadores | Casas ocupadas e ruas movimentadas. | Ajuda e divisão de tarefas. |
| Ampliar a taverna | Salão reconstruído e equipado. | Mais capacidade e opções de organização. |

Esses pares orientam o design aprovado; missões, custos, ordem de desbloqueio
e números específicos ainda precisam de detalhamento. Uma melhoria deve ser
sentida também em capacidade, tempo, conservação ou novas escolhas de trabalho.
O jogador precisa experimentar o benefício antes da próxima ampliação da demanda.

### Base operacional histórica

O registro abaixo e as seções 4 a 11 preservam a descrição de uma inspeção
anterior. A versão .46 tem alterações posteriores documentadas nos guias; não
interpretar valores antigos como regras aprovadas de balanceamento desta revisão.
A operação física existente deve ser preservada ao adaptar os status e as hordas.

### Sequência da base histórica

1. Organizar móveis e obter ingredientes e utensílios.
2. Preparar a cozinha e abrir pela placa da entrada.
3. Anotar pedidos e administrar a paciência dos clientes.
4. Buscar ingredientes nas mãos, cortar quando necessário e abastecer a panela.
5. Cozinhar, retirar a panela, apoiar, empratar e servir.
6. Recolher a louça, lavar e repor os pratos.
7. Suspender novas entradas, concluir pendências e acompanhar o fechamento diário.

### Ambientes da base histórica

O restaurante reúne salão, cozinha e estoque no mesmo cenário. O estoque tem acesso pela cozinha; equipá-lo é opcional para abrir. Geladeiras e prateleiras ampliam armazenamento. O computador e o recebimento ainda estão presentes na área administrativa. Estabelecimentos vizinhos não são lojas jogáveis.

A rua possui fachada, toldo, calçada, jardins, bancos e faixa de pedestres. A porta permite entrar e sair por clique ou teclado. A transição aguarda um destino livre e não deve colocar personagens sobrepostos ou provocar retorno em loop. A fachada permite abrir e encerrar o serviço; clientes e funcionários continuam simulados no interior enquanto o jogador está fora.

### Movimento e câmera da base histórica

WASD ou setas controlam deslocamento contínuo, com parada e inversão imediatas. O jogador pode parar entre células. Diagonais são normalizadas; contato com uma parede permite deslizar pelo eixo livre. Quadros lentos não devem atravessar colisões. O corpo tem raio atual de 0,20 célula e velocidade de 4,5 células por segundo, ambos parâmetros de teste.

O clique no chão mantém navegação por destino. Clicar em objetos aproxima o personagem e inicia a ação válida; trocar entre teclado e clique não deve teletransportar o jogador. NPCs e colocação de móveis continuam apoiados na grade lógica.

Animações acompanham o deslocamento real. Nas diagonais, a direção visual prioriza cima ou baixo enquanto existe movimento vertical; se esse eixo estiver bloqueado, acompanha o deslizamento lateral. Pressionar uma parede sem deslocamento não mantém a caminhada.

O zoom atual vai de 70% a 200%, em passos de 10%. Tela cheia fica em Opções e Câmera. Alertas de cozimento não deslocam a câmera.

<!-- page -->

## 4 Construção e organização do espaço

**Registro técnico histórico.** Descrição da base anterior; consultar a direção vigente nas seções 1 a 3 e o registro do protótipo .46 para diferenças.

**Implementado.** Gestão e Modo construção dão acesso à edição dos móveis. A simulação congela, a HUD operacional desaparece e o catálogo lateral pode ser recolhido. Alterações exigem serviço concluído, sem clientes ou pedidos ativos. Não há reposicionamento pelo menu operacional normal dos objetos.

Selecionar um móvel instalado permite mover, girar ou guardar. O painel de posicionamento usa Girar, Confirmar posição, Guardar e reembolsar e Cancelar. Guardar fica oculto ao comprar um móvel novo. Foram retirados desse painel nome do móvel e textos auxiliares de posição e exploração.

### Catálogo atual

Todos os preços abaixo são parâmetros de teste em dinheiro genérico. Dimensões são células na orientação inicial.

| Móvel | Dimensão | Área permitida | Preço |
| --- | --- | --- | --- |
| Mesa | 2 por 1 | Salão | $45 |
| Cadeira | 1 por 1 | Salão | $15 |
| Fogão | 2 por 1 | Cozinha | $150 |
| Mesa de preparo para corte | 2 por 1 | Cozinha | $90 |
| Mesa de cozinha para empratar | 2 por 1 | Cozinha | $90 |
| Pia | 2 por 1 | Cozinha | $70 |
| Geladeira da cozinha | 1 por 2 | Cozinha | $120 |
| Geladeira do estoque | 1 por 2 | Estoque | $140 |
| Prateleira seca | 2 por 1 | Cozinha ou estoque | $65 |
| Estante de panelas | 2 por 1 | Cozinha | $65 |
| Lixeira | 1 por 1 | Cozinha ou estoque | $25 |

### Validação e conservação

A prévia e a confirmação verificam área permitida, ocupação, personagens, portas e acesso aos móveis. Compra inválida não cobra. Mover preserva identidade e conteúdo, sem nova compra. Guardar exige retirar conteúdo e respeitar tarefas e louça pendentes; o comportamento atual reembolsa integralmente o móvel.

O validador de conectividade e o cache de prévia foram otimizados. A confirmação continua verificando o estado real; um resultado de cache não autoriza uma compra inválida.

### Assentos

Mesas de dois tiles aceitam cadeiras apenas nos lados compridos e voltadas para a mesa. Na horizontal, cabem duas acima e duas abaixo; a regra acompanha a rotação. As pontas são recusadas na construção. Não é necessário completar quatro lugares para atender.

Cadeiras isoladas podem ser móveis, mas não recebem clientes. Saves antigos preservam cadeiras incompatíveis; elas deixam de contar como assentos válidos sem eliminar louça ou atendimento em andamento. Uma reforma não relacionada não exige corrigir todo o layout antigo.

<!-- page -->

## 5 Transporte, armazenamento e cenário de teste

**Registro técnico histórico.** Descrição da base anterior; consultar a direção vigente nas seções 1 a 3 e o registro do protótipo .46 para diferenças.

**Implementado.** O jogador não tem mochila, barra de inventário ou seleção por slots. Transporta uma unidade de ingrediente, panela, prato ou louça por vez nas mãos. O desenho acompanha a carga real. Não pode receber outro item enquanto as mãos estiverem ocupadas.

### Armazenamentos

Geladeira da cozinha, geladeira do estoque e prateleira seca têm dez espaços cada. As pilhas comuns podem alcançar 99 unidades quando o tipo e a qualidade forem compatíveis. A prateleira mantém restrição a armazenamento seco; geladeiras aceitam ingredientes e itens transportáveis conforme as regras atuais. Essas permissões de protótipo não definem validade ou refrigeração realista.

Um clique aproxima o jogador e abre o inventário do objeto. Selecionar um item retira uma unidade para as mãos e fecha o painel. Guardar item das mãos devolve a unidade a um armazenamento compatível. Espaço insuficiente preserva o item. O tempo continua avançando com o inventário do objeto aberto; não existe transferência automática ao fogão.

A estante de panelas tem três espaços unitários e aceita somente panelas vazias. Não aceita alimentos, pratos ou panelas com comida. Sua imagem acompanha a quantidade real; comprar, mover ou carregar o móvel não gera panelas gratuitas. Guardar e reembolsar exige esvaziá-la.

### Formas de liberar as mãos

- Guardar o item em armazenamento compatível.
- Colocar ingrediente na panela antes de cozinhar, quando a combinação permitir.
- Instalar panela vazia no fogão ou apoiar uma panela na mesa de cozinha.
- Instalar prato limpo ou apoiar refeição pronta na mesa de cozinha.
- Servir o pedido compatível, lavar louça ou descartar comida conforme a ação disponível.

Não existe inventário oculto de transporte. Os registros internos de recuperação de migração servem somente a itens antigos que não couberam nos armazenamentos.

### Começar mobiliado

| Recurso inicial de teste | Quantidade ou condição |
| --- | --- |
| Jogador | Mãos vazias e nenhum inventário pessoal. |
| Ingredientes | 30 arroz, 30 legumes e 30 frango cru na geladeira da cozinha. |
| Panelas | Uma instalada no fogão e três vazias na estante; quatro no total. |
| Pratos | 12 limpos instalados na mesa de cozinha; nenhum talher exigido. |
| Salão | Três mesas com quatro cadeiras cada nos lados compridos. |
| Caixa | $1.500; montagem de teste não é cobrada como campanha. |

Começar vazio permite montar do zero. O cenário mobiliado e a ferramenta de limpar tudo são recursos de teste, não condições finais de campanha. Saves existentes não recebem automaticamente móveis sobre um layout personalizado.

<!-- page -->

## 6 Cozinha física e receitas atuais

**Registro técnico histórico.** Descrição da base anterior; consultar a direção vigente nas seções 1 a 3 e o registro do protótipo .46 para diferenças.

**Implementado.** A mesa de preparo corta; a mesa de cozinha recebe a panela e emprata. Fogão, bancadas, pia e lixo não abrem janelas genéricas de trabalho. Um clique inicia a ação principal válida após a aproximação; ações alternativas ainda podem aparecer junto ao objeto.

### Fluxo de uma refeição

1. Retirar uma unidade de ingrediente do armazenamento para as mãos.
2. Levar frango cru ou legumes inteiros à mesa de preparo e cortar por dois segundos ativos. O resultado permanece nas mãos e conserva a qualidade. Arroz não é cortado.
3. Clicar no fogão para adicionar o ingrediente à panela vazia instalada. Buscar os demais ingredientes, uma unidade por vez.
4. A combinação exata identifica a receita e exibe seu ícone sobre a panela. Ingredientes incompatíveis ou excedentes são recusados sem consumo. Antes do cozimento, é possível retirar o último ingrediente com as mãos livres.
5. Com receita completa e mãos livres, iniciar Cozinhar. O preparo continua enquanto o jogador executa outras tarefas.
6. Retirar a panela pronta antes da queima. Ela sai do fogão e ocupa as mãos; não pode ser retirada enquanto ainda cozinha. A retirada encerra sua exposição ao calor.
7. Apoiar a panela na mesa de cozinha e liberar as mãos. Com prato limpo disponível, empratar por dois segundos junto à mesa.
8. Pegar o prato pronto e servir. Retirar a panela vazia da mesa para reinstalar no fogão.

Cada novo cozimento rende uma porção. Cada empratamento produz um prato. O sistema aceita panelas antigas com mais porções apenas para conservar partidas migradas.

| Receita | Ingredientes preparados por cozimento | Cozinhar | Preço inicial |
| --- | --- | --- | --- |
| Arroz com legumes | 1 arroz e 1 legumes cortados | 6 s | $14 |
| Sopa de legumes | 2 legumes cortados | 5 s | $12 |
| Frango com arroz | 1 arroz e 1 frango cortado | 8 s | $20 |

### Limites e cancelamento

O código atual controla um cozimento ativo por vez, mesmo com mais fogões instalados. A mesa tem apoio de uma panela, capacidade de 12 refeições prontas e até 99 pratos limpos. Esses limites e tempos são parâmetros de teste; não há frigideira, caldeirão ou óleo implementados.

Corte pode ser cancelado sem consumir o ingrediente. Afastar-se pausa corte e empratamento. Durante trabalho manual, transferências conflitantes são bloqueadas. Cancelar empratamento conserva o recipiente e o prato. Receita flexível por família de ingredientes ainda é direção futura, não o reconhecimento atual.

<!-- page -->

## 7 Qualidade, calor e limpeza

**Registro técnico histórico.** Descrição da base anterior; consultar a direção vigente nas seções 1 a 3 e o registro do protótipo .46 para diferenças.

**Implementado.** Ingredientes e refeições usam quatro níveis de qualidade. O preparo calcula a média dos níveis dos ingredientes efetivamente consumidos, ponderada pelas quantidades e arredondada para baixo. Cortar, transportar e salvar preservam a qualidade; deixar comida pronta no fogo pode reduzi-la.

| Nível | Apresentação | Multiplicador de compra |
| --- | --- | --- |
| Comum | Sem estrela | 1 |
| Prata | Estrela cinza ou prateada | 1,25 |
| Ouro | Estrela amarela | 1,5 |
| Roxa | Estrela roxa | 2 |

Estrelas aparecem somente nos ingredientes e pratos correspondentes. Não usar estrelas em personagem, fogão, mesa ou panela vazia. O feedback de preparo inclui progresso, ícone da receita, estados de calor e sinais sonoros; a câmera não salta para o fogão.

### Comida pronta no fogão

| Tempo ativo após terminar | Estado atual |
| --- | --- |
| Antes de 8 segundos | No ponto; janela segura. |
| A partir de 8 segundos | Passando do ponto; qualidade começa a cair. |
| A partir de 20 segundos | Perigo próximo de queima. |
| A partir de 25 segundos | Queimado; não pode ser empratado como comida utilizável. |

São parâmetros de teste. De 8 a 20 segundos, a qualidade inicial decai até o nível comum; o estado de queima é separado. Retirar a panela conserva a qualidade no instante da retirada e encerra a degradação pelo fogo. Falta de espaço ou mãos ocupadas não pausa automaticamente o calor.

### Louça e descarte

Depois do consumo, a louça fica na mesa e interfere em sua liberação. Recolher entrega um prato sujo por vez às mãos. A pia converte a unidade carregada em prato limpo; o jogador a leva à mesa de cozinha. Não há lavagem obrigatória de panelas acrescentada a este fluxo.

Pia e lixeira permitem descartar comida transportada. Descartar uma panela com refeição conserva a panela vazia; descartar uma refeição empratada conserva o prato sujo. Quantidades desperdiçadas entram na conservação de refeições. Uma panela queimada precisa ser descartada antes de reutilizada.

Validade de ingredientes, contaminação, refrigeração por temperatura e desgaste de óleo não estão implementados nem são requisitos finais desta revisão.

<!-- page -->

## 8 Clientes, atendimento e equipe

**Registro técnico histórico.** Descrição da base anterior; consultar a direção vigente nas seções 1 a 3 e o registro do protótipo .46 para diferenças.

**Implementado.** Clientes chegam individualmente. Reservam uma mesa inteira até terminar a visita e retirar a louça; grupos e compartilhamento entre desconhecidos não estão implementados. A primeira chegada ocorre após oito segundos ativos e as seguintes são espaçadas por 25 segundos, quando houver condições, como parâmetros de teste.

O prato desejado permanece oculto até o pedido ser anotado pelo jogador ou garçom. Antes disso, personagem, ação e fila de pedidos indicam espera sem antecipar o prato. Depois da anotação, a receita aparece e pode ser priorizada no painel de pedidos.

### Paciência e resultado da visita

A espera por atendimento e pela comida tem contadores separados. Anotar encerra a primeira fase e inicia a segunda. No limite exato, abandono tem prioridade sobre entrega. Não há pagamento por pedido perdido; os ingredientes já consumidos não retornam. Pratos e recipientes não podem desaparecer em trânsito.

| Perfil técnico atual | Espera para anotar | Espera pela comida |
| --- | --- | --- |
| Impaciente | 40 a 60 s | 60 a 90 s |
| Normal | 60 a 90 s | 90 a 150 s |
| Paciente | 90 a 120 s | 150 a 210 s |

Os perfis têm pesos iguais de sorteio no protótipo. Acima de 50% do tempo restante, o indicador é paciente; entre 50% e 20%, perde paciência; no trecho final, fica estressado; ao abandonar, sinaliza saída. Feliz aparece após serviço satisfatório. Estes perfis não definem as futuras profissões dos clientes.

A satisfação combina atendimento, espera pela comida e qualidade com pesos atuais de 35%, 35% e 30%. Classes: muito satisfeito a partir de 85, satisfeito a partir de 65, neutro a partir de 40 e insatisfeito abaixo de 40. Probabilidades de avaliação são parâmetros: elogio de 60% e 20% nas duas classes superiores; reclamação de 5%, 35% e 75% para neutro, insatisfeito e abandono. Não confundir chance de avaliação com pagamento garantido.

### Funcionários de teste

Existem dois funcionários gratuitos com atribuição contínua de Parado, Logística ou Garçom. Logística transporta entre recebimento e armazenamentos compatíveis. Garçom anota pedidos e busca refeições prontas na mesa de cozinha para servir; não corta nem cozinha.

Mudanças de tarefa respeitam cargas em trânsito. Salários, contratação comercial, níveis de funcionários e cozinha ou lavagem automáticas não estão implementados. A autonomia futura deve preservar decisões do jogador, sem tratar o estabelecimento totalmente automático como meta aprovada.

<!-- page -->

## 9 Relógio, calendário e reputação

**Registro técnico histórico.** Descrição da base anterior; consultar a direção vigente nas seções 1 a 3 e o registro do protótipo .46 para diferenças.

**Implementado.** O dia começa às 06:00 e termina às 02:00 da madrugada seguinte. Meia-noite não avança a data jogável. Cada dez minutos do relógio correspondem atualmente a sete segundos de simulação ativa.

| Serviço padrão | Início | Fim |
| --- | --- | --- |
| Almoço | 11:00 | 15:00 |
| Jantar | 18:00 | 22:00 |

Horários são configuráveis em Gestão e Turnos, em blocos de dez minutos, sem sobreposição. Alterar exige serviço concluído. Abrir antes do início ou depois do fim é recusado. Fechar cedo mantém o mesmo período; não adianta o calendário.

Ao fim do horário, novas entradas param. Clientes presentes e preparos continuam. Às 02:00, a virada aguarda pendências do serviço; não apaga clientes, pedidos ou comida para forçar um novo dia. Fechamento financeiro e despesa diária ocorrem uma vez na transição para o dia seguinte.

O calendário possui sete dias da semana e quatro estações de 28 dias cada. Seus nomes atuais são Primavera, Verão, Outono e Inverno. Essa estrutura não comprova safra sazonal, clima ou eventos associados já implementados.

### Reputação

A reputação começa em zero, fica entre 0 e 100 e registra avaliações por visita. Elogio acrescenta um ponto; reclamação ou abandono retiram um ponto por visita, sem duplicar os dois efeitos. A mesma visita não pode ser processada duas vezes.

| Pontuação mínima | Faixa atual |
| --- | --- |
| 0 | Desconhecido |
| 20 | Pouco conhecido |
| 40 | Reconhecido |
| 60 | Bem avaliado |
| 80 | Referência local |

No código atual, reputação não multiplica demanda nem modifica preços automaticamente. O histórico de visitas e avaliações aparece na Gestão. Faixas, pesos e variações são parâmetros de teste.

### Pausas e continuidade

Construção, livro de receitas, menus administrativos e perda de foco suspendem a simulação. Inventários de geladeiras, prateleiras e estante de panelas mantêm o tempo ativo. Abrir armazenamento interrompe o controle de movimento, mas não congela os clientes ou o fogo. Retomar não deve somar o tempo passado em segundo plano.

<!-- page -->

## 10 Economia, compras e interface

**Registro técnico histórico.** Descrição da base anterior; consultar a direção vigente nas seções 1 a 3 e o registro do protótipo .46 para diferenças.

**Implementado.** A economia atual usa dinheiro genérico representado por $. Caixa inicial de $1.500 e despesa diária de $12 são parâmetros do protótipo. Elos e escambo não substituíram esse dinheiro no código.

### Compras atuais no computador

O computador oferece Fornecedor, Utensílios, Cardápio e preços e Entregas. Ingredientes podem ser encomendados em quantidades de 1 a 100, com qualidade selecionável. A compra debita o caixa e gera uma entrega; não põe todo o lote nas mãos. A entrega leva cinco segundos ativos e o recebimento tem capacidade atual de 60 unidades.

| Item comum | Preço por unidade | Destino da compra |
| --- | --- | --- |
| Arroz | $2 | Entrega ao recebimento. |
| Legumes | $2 | Entrega ao recebimento. |
| Frango cru | $4 | Entrega ao recebimento. |
| Panela vazia | $25 | Uma unidade nas mãos livres. |
| Prato limpo | $5 | Uma unidade nas mãos livres. |

Talher não é vendido nem exigido. O jogador recolhe ingredientes do recebimento um por vez; logística pode auxiliar. Cardápio permite ativar receitas e ajustar preço de $1 a $100. Pedidos anotados mantêm o preço combinado.

Compras diminuem o caixa; ingredientes entram no custo quando efetivamente usados no preparo. O relatório mostra receita, ingredientes consumidos, compras, investimentos, clientes pagos e perdidos, além de resultado e caixa no fechamento. Aluguel, salários completos e financiamento não fazem parte da economia implementada.

### Destino aprovado das compras e da administração

**Direção aprovada, ainda não implementada.** O computador permanece na taverna exclusivamente para funções administrativas, sem compras de ingredientes, peças ou equipamentos. Cardápio e preços são funções administrativas existentes; a composição final dos demais acessos e sua relação com Gestão ainda será detalhada.

A compra de ingredientes passa para um NPC comerciante na cidade, próximo da taverna. Peças para equipamentos como geladeiras são compradas no ferro-velho. Um artesão fabrica os equipamentos, que são entregues após a conclusão da fabricação. Essa entrega refere-se aos equipamentos; não define entrega automática de ingredientes nem de peças. A seção 12 descreve a direção futura e a seção 14 registra os detalhes pendentes. As compras no computador descritas acima continuam sendo o comportamento do código até a implementação da migração.

### Organização da interface

| Acesso | Conteúdo atual |
| --- | --- |
| Gestão | Turnos, Modo construção, Equipe, Fechamento, Clientes, Calendário e Reputação. |
| Opções | Câmera e tela cheia, Salvar e carregar, Testes e Primeiros passos. |
| Livro de receitas | Botão ao lado de Opções; três receitas com quantidades, corte, tempo e sequência de preparo. A consulta pausa. |
| Tela inicial | Começar vazio, Começar mobiliado e Tutorial recolhível. Sem leitura longa obrigatória. |

A interface usa o tema visual anterior com molduras, ícones e artes de itens. O livro já existe; não deve ser tratado como sugestão futura. Não há botão de mochila ou barra de cinco slots. Avisos de ações e erros continuam, mas instruções repetitivas de trazer ingrediente e atalhos redundantes de corte e retirada foram removidos.

<!-- page -->

## 11 Salvamentos, ferramentas de teste e plataformas

**Registro técnico histórico.** Descrição da base anterior; consultar a direção vigente nas seções 1 a 3 e o registro do protótipo .46 para diferenças.

**Implementado.** O formato atual de salvamento é 12, com chave `entre-restaurante-12` e arquivo Godot `user://restaurante.json`. Inclui mãos, conteúdo dos móveis, corte, cozimento, panela apoiada, refeições, compras, posição fracionária, relógio, calendário, reputação e horários. Teclas pressionadas não persistem.

### Migração e segurança

O carregamento valida uma cópia antes de substituir a partida. Há backup e importação de JSON compatível. Itens das mochilas antigas são transferidos para armazenamentos, preservando quantidade e qualidade. Excedentes ficam em recuperação acessível pelo painel do armazenamento, uma unidade por vez; não formam uma mochila de gameplay.

Panelas antigas preservam suas porções. Bancadas anteriores são convertidas para mesa de cozinha sem reorganizar a planta; a mesa de corte pode ser comprada depois. Cadeiras incompatíveis e talheres antigos são conservados por compatibilidade. Nenhum recurso deve ser apagado para adequar uma partida ao novo fluxo. Saves do HTML e da Godot são independentes; importar JSON não é sincronização automática.

### Ferramentas de teste

Opções e Testes permitem avançar o relógio, em blocos de dez minutos, somente para a frente entre 06:00 e 02:00 do dia atual. O salto não simula o intervalo de paciência, preparo ou entrega; aplica as regras de encerramento e virada sem abrir o serviço automaticamente. Limpar tudo apaga móveis e itens de teste, não reembolsa e só afeta o arquivo salvo após gravar.

### Estado técnico

A Godot controla janela, entrada, interface, apresentação, áudio e disco. Regras JavaScript executam dentro do processo pela GDExtension RestauranteVM com QuickJS. Não é uma conversão integral para GDScript e não exige Node.js para jogar.

| Base ou plataforma | Estado registrado |
| --- | --- |
| Editor | Proprietário usa Godot 4.7.2; há validação Linux sem janela documentada nessa versão. Histórico de migração em 4.6.3 preservado. |
| Windows e Linux PC | Bibliotecas x86-64 e perfis de exportação. Validação documentada predominantemente em Linux. |
| Android | APK de teste 0.21.2-godot.4, código 21204, Android 7 ou superior, assinatura de depuração. Instalação e desempenho físico ainda precisam de teste. |
| HTML | Removido da árvore ativa, incluindo o atalho e o HTML histórico embutido. Recuperável pelo histórico Git. Desenvolvimento exclusivo na Godot; sua simulação JavaScript/QuickJS permanece necessária. |
| macOS e web Godot | Sem exportação pronta comprovada por esta revisão. |

O projeto ainda declara 0.21.2-godot.1 em sua configuração, enquanto o APK declara .4; são metadados distintos existentes. Esta revisão não altera versões de executável. A grade lógica continua em 40 pixels e o viewport Godot em 960 por 700.

<!-- page -->

## 12 Desenvolvimento futuro e propostas

### Direção vigente a adaptar no protótipo

O próximo ajuste do ciclo existente deve substituir os status individuais por
três valores coletivos e o total de derrotas pela sequência consecutiva. É
necessário preservar moradores, histórias, crescimento, recursos e os três
salvamentos. Regras de conversão dos saves e valores iniciais coletivos ainda
precisam ser definidos na tarefa de implementação. Uma vitória deve reiniciar
a sequência sem apagar conquistas da cidade.

### Direções aprovadas ainda não implementadas

A direção vigente é a taverna do refúgio no apocalipse zumbi. A ambientação nuclear anterior foi substituída. A operação existente deve ser preservada enquanto o universo é incorporado. A aprovação abaixo é de conceito. Detalhes e parâmetros são desenvolvidos em trechos jogáveis com avaliação de Dener; esta revisão documental não implementa novas regras no executável.

- Manter o computador exclusivamente para funções administrativas da taverna; retirar dele as funções de compra.
- Oferecer frango, legumes e arroz por meio de um NPC comerciante na cidade, próximo à taverna, com deslocamento do jogador até ele.
- Comprar peças no ferro-velho para fabricar equipamentos como geladeiras. A fabricação é realizada por um artesão; o equipamento é entregue após ele concluir o trabalho. Não há fabricação desses equipamentos pelo jogador nesta direção aprovada.
- Ampliar obtenção por produtores locais, feiras de caravanas, trocas com clientes, coleta em áreas recuperadas e expedições encomendadas.
- Usar tipos de clientes ligados às ocupações do mundo, além dos perfis técnicos de paciência.
- Exigir frigideira e óleo para frituras e caldeirão para sopas.
- Permitir substituições controladas de ingredientes em receitas como sopas.
- Encomendar móveis de madeira ao marceneiro e equipamentos a especialistas; filtro de água habilita bebidas e recuperação de ruas abre oportunidades.
- Incorporar indisponibilidade temporária de ingredientes, mais movimento previsto no jantar, abundância de um vegetal e encomendas de refeições, com informação antes da consequência.
- Testar fornecedor local, comerciante itinerante, dois perfis de cliente e um acontecimento anunciado que afete o cardápio.
- Desenvolver dinheiro com identidade própria e escambo com determinados comerciantes. O objeto e nome não foram escolhidos.

### Propostas não aprovadas para detalhamento

| Código | Proposta preservada para avaliação |
| --- | --- |
| P01 | Elos metálicos marcados como dinheiro local, distintos de sucata e de materiais de fabricação. |
| P02 | Escambo opcional por ofertas fixas, com quantidades claras, confirmação única e limites contra ciclos infinitos de lucro. |
| P03 | Catálogo de comércio presencial como exceção às janelas operacionais, mantendo o tempo ativo. |
| P04 | Morador local e explorador como os dois perfis do primeiro teste. |
| P05 | Colheita abundante de legumes como primeiro evento, com aviso, preço temporário e fim anunciado. |
| P06 | Detalhes ainda não aprovados: apresentar custo e prazo conhecidos na encomenda e instalar o equipamento entregue pelo modo construção. Fabricação pelo artesão e entrega após conclusão já são direção aprovada; não fazem parte da pendência. |
| P07 | Óleo consumido uma vez por preparo e água potável como base de determinadas receitas; sem tarefas repetitivas de despejo. |
| P08 | Vendedor provisório de utensílios (panelas e pratos). A parte antiga sobre retirar o computador e migrar a administração para Gestão ou livro físico foi substituída pela manutenção do computador administrativo. |
| P09 | Famílias de ingredientes e prioridade de receitas específicas sobre genéricas, evitando resultados ambíguos. |

Os detalhes remanescentes dessas propostas continuam não aprovados; os conceitos já aprovados estão identificados separadamente acima. Detalhes de receitas, hospedagem, água e fornecedores continuam pendentes. Energia é uma das três barras coletivas aprovadas em 17/11/2026; o descanso automático e os valores individuais da versão .46 são um registro de protótipo, a adaptar.

<!-- page -->

## 13 Ideias substituídas e histórico isolado

Esta seção guarda decisões antigas para rastreabilidade. Não define o jogo atual. Ela não deve ser usada para reintroduzir automaticamente mecânicas antigas ou eliminar itens de saves compatíveis.

| Ideia ou regra anterior | Estado e substituição |
| --- | --- |
| Status individuais com médias no painel | Substituídos como direção em 17/11/2026 por três barras coletivas de alimentação, energia e moral. O código .46 ainda precisa da adaptação. |
| Duas derrotas acumuladas ao longo da campanha | Substituídas por duas derrotas consecutivas; uma vitória reinicia a sequência e o estado normal. O código .46 ainda precisa da adaptação. |
| Retirar o computador e migrar suas funções administrativas para Gestão ou livro físico | Substituído em 12/11/2026: manter o computador exclusivamente administrativo, com compras fora dele. |
| Mercearia como atividade principal | Projeto anterior arquivado. A existência de um HTML histórico não cria uma loja integrada à vila. |
| Ambientação brasileira e origem nuclear | Substituídas pelo refúgio no apocalipse zumbi; pratos de diferentes tradições permanecem possíveis. |
| Tom exclusivamente sombrio e melancólico | Perigo exterior combinado com acolhimento, reconstrução e esperança; recompensa visual aprovada em 17/11/2026. |
| Estabelecimento definido apenas como restaurante | Substituído pela direção de taverna. Hospedagem ainda requer desenho e implementação. |
| Mochila com dez espaços | Substituída pelo transporte de uma unidade nas mãos. |
| Barra permanente de cinco slots e teclas de seleção | Etapa intermediária removida; não deixar interface substituta nessa área. |
| Ingrediente cortado retorna ao inventário pessoal | Substituído por ingrediente cortado nas mãos. |
| Receita escolhida em janela e ingredientes consumidos à distância | Substituídos por adição física e reconhecimento da combinação na panela. |
| Fogão e bancada como inventários genéricos | Substituídos por estados e encaixes específicos, sem janelas operacionais. |
| Mesa de preparo como estação de empratamento | Separada em mesa de corte e mesa de cozinha. |
| Quatro porções por novo cozimento ou empratamento em lote | Substituídas por uma porção por cozimento e um prato por ação. Porções antigas só são compatibilidade de save. |
| Colher ou talher obrigatório e compra de talher | Removidos da operação e da loja; itens antigos são preservados. |
| Panela cheia enviada automaticamente à mochila | Substituída por retirada nas mãos e apoio na mesa de cozinha. |
| Movimento do jogador preso a passos de uma célula | Substituído por deslocamento contínuo; a grade continua na construção e navegação. |
| Cadeiras aceitas nas pontas das mesas de dois tiles | Substituídas pela política dos lados compridos. |

### Ideias antigas que nunca receberam aprovação

IP01: tocar em alerta para deslocar a câmera ao fogão permanece não aprovado. A regra vigente é avisar sem mover a câmera. Big Ambitions foi retirado das referências. Carrinhos, pallets e logística da antiga mercearia não são automaticamente requisitos da taverna. Uma segunda unidade e sistemas amplos de romance ou concorrência não integram o escopo atual de implementação.

O computador permanece como direção aprovada, agora exclusivamente administrativa. O código ainda inclui compras; a seção 10 preserva esse registro até a migração das compras para os serviços presenciais. A retirada do computador deixou de orientar o projeto. Frigideira, caldeirão e comércio presencial são futuros; não são ideias descartadas.

<!-- page -->

## 14 Pendências, validação e rastreabilidade

### Questões em aberto

Nome da cidade, origem do protagonista, origem dos zumbis e tempo desde o
apocalipse. Identidade, funções e histórias dos NPCs pilares. Fórmulas de
alimentação, descanso e moral coletivas; curva de crescimento da população e
das hordas; antecedência dos avisos; penalidades exatas do recuo. Valores do
primeiro protótipo permanecem ajustáveis. As escolhas entre barras individuais
ou coletivas e entre derrotas acumuladas ou consecutivas estão **resolvidas**:
valem as coletivas e as consecutivas com reset por vitória.

Hospedagem, cerveja, refrigeração, água, novas receitas e preços ainda precisam
de detalhamento. A cerveja é a direção inicial para bebidas; servir, abastecer
e lavar canecas serão desenvolvidos em etapa própria. Não há ordem definitiva
que obrigue desbloquear cerveja como primeira grande conquista.

Lista e quantidade de peças por equipamento, preços do ferro-velho, remuneração
e tempo de fabricação do artesão, transporte de peças, recebimento e instalação
ainda serão especificados. Fabricação pelo artesão e entrega após conclusão
permanecem aprovadas. Transporte de compras deve respeitar a operação física
existente; mochila, caixas ou carrinhos não são respostas automáticas.

### Método aprovado de desenvolvimento

1. Delimitar e entregar um trecho jogável do começo do jogo.
2. Dener joga e relata espera, repetição, clareza dos status, decisões, desafio e satisfação.
3. Ajustar os parâmetros a partir dessa experiência, mantendo os ganhos das melhorias perceptíveis.
4. Ampliar o próximo trecho com base no retorno, preservando recursos e salvamentos.

O início já está prototipado na versão .46; o próximo trabalho no executável
precisa contemplar as duas retificações desta revisão antes de considerar seu
balanceamento representativo da direção aprovada. Comércio presencial, artesão,
hospedagem e novas bebidas entram conforme o escopo de cada trecho for definido.

### Critérios de qualidade

- Manter três barras coletivas finitas entre 0 e 100, com feedback compreensível.
- Zerar a sequência de derrotas após qualquer defesa vencida; derrota/vitória/derrota não causa game over.
- Aplicar game over após derrota/derrota e permitir refazer a preparação.
- Suspender jantar de horda sem penalizar a refeição indisponível.
- Preservar vínculos com moradores, recompensas de reconstrução e melhorias perceptíveis na operação.

- Conservar ingredientes, panelas, pratos, refeições e dinheiro nas ações, falhas e migrações.
- Impedir pagamento duplicado e revelar pedido somente após anotação.
- Preservar diferença entre cozimento autônomo e corte ou empratamento dependentes de presença.
- Manter construção pausada, armazenamento ativo e retomada sem salto de tempo.
- Validar posições, acesso e assentos sem cobrar por colocação recusada.
- Recusar save inválido e manter backup utilizável após recuperação.
- Conferir interface e exportação nas plataformas reais; teste Linux não comprova funcionamento físico Android ou Windows.

### Evidência histórica da inspeção e limites

Na inspeção que antecedeu esta revisão, passaram o executor atual `godot/qa/Regras.cjs` e verificações adicionais de movimento, prévia de fogão, cache e layouts em Node.js. Uma consulta simulada confirmou livro com três receitas, pausa na consulta e tempo ativo no armazenamento. Não houve novo playtest gráfico nem execução do APK nessa inspeção.

O teste avulso `qa/rua-horario.test.cjs` falhou ao preparar ingredientes buscando a mochila removida. A falha foi identificada no arranjo antigo do teste e não comprova defeito no fluxo novo. Registros antigos de sete suítes não equivalem ao conjunto atual; testes históricos devem ser interpretados por versão. Testes automáticos não comprovam diversão.

### Fontes de manutenção

- [Registro do protótipo .46 e seus parâmetros](docs/primeiro-ciclo-refugio.md).
- Código atual: [Refugio.gd](godot/simulacao/nativa/Refugio.gd),
  [Simulacao.gd](godot/simulacao/nativa/Simulacao.gd),
  [Cozinha.gd](godot/simulacao/nativa/Cozinha.gd) e
  [Salvamentos.gd](godot/simulacao/nativa/Salvamentos.gd).
- [Diretriz de produção da arte](docs/DIRETRIZES-ARTE.md),
  [compilação Android](godot/ANDROID.md) e [QA](godot/qa/LEIA-ME.md).

O executável atual usa GDScript. Referências a JavaScript/Node na inspeção
histórica acima não descrevem o runtime presente. Os testes do protótipo .46
foram registrados na entrega correspondente; esta revisão documental não
executa nem comprova as novas regras no jogo. Testes automatizados também não
comprovam diversão ou balanceamento final.

### Histórico de revisões

| Revisão | Conteúdo |
| --- | --- |
| 2.1 — 12/11/2026 | Comércio presencial, ferro-velho, fabricação por artesão, entrega e computador administrativo. |
| 3.0 — 17/11/2026 | Nova premissa zumbi e primeiro protótipo jogável, com parâmetros provisórios. |
| **3.1 — 17/11/2026** | Proposta consolidada aprovada: cidade de esperança, três barras coletivas, hordas de 3 a 5 dias, defesa animada, derrotas consecutivas com reset por vitória, retomada, crescimento, recompensas visuais e funcionais e desenvolvimento por playtests. |

A aprovação de Dener desta revisão resolve as duas definições pendentes.
O Git preserva as versões anteriores. Alterações no GDD devem atualizar a seção
correspondente, mantendo separadas direção aprovada, comportamento existente,
parâmetro de teste e implementação ainda pendente.

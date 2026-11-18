# Melhorias aprovadas — versão .54

18/11/2026 · GDD 3.6 · Godot 4.6.3 · Android 21254.

Implementação das oito propostas aprovadas: alimentação, moral, preços,
refeição da equipe, descanso, ritmo, preferências/recompensa e leitura visual.
Parâmetros para o primeiro trecho jogável, sujeitos a avaliação do proprietário.
Não é uma declaração de balanceamento final de uma campanha longa.

## Regras jogáveis

### Alimentação e moral

- Alimentação por prato consumido: **nutrição × 2 / população**. O multiplicador
  anterior era 5,2. Os dois turnos continuam consumindo 8 pontos cada.
- Caldo mantém a alimentação se todos comerem nos dois turnos. Arroz com cenoura
  recupera aproximadamente 8 pontos/dia e canja 16, antes do teto de 100.
- Moral por refeição: `clamp((satisfação − 60) / 10, −4, 4) / população`.
  Com satisfação 85, atender todos nos dois turnos recupera aproximadamente um
  ponto líquido por dia, em vez de cerca de dez. Atendimento ruim pode reduzir.
- As barras continuam coletivas de 0–100, somente em **Gestão → Cidade**.
- A horda continua substituindo o jantar **sem consumo ou penalidade pela
  refeição cancelada**. Duas derrotas consecutivas e vitória que zera a sequência
  permanecem. Nenhum combate controlável foi acrescentado.

### Preços com consequência

Referências preservadas: caldo 10, arroz com cenoura 14, canja 20. A campanha do
refúgio permite ±20%, arredondando os extremos para dentro em quartos de moeda:

| Receita | Mínimo | Referência | Máximo |
|---|---:|---:|---:|
| Caldo | 8 | 10 | 12 |
| Arroz com cenoura | 11,25 | 14 | 16,75 |
| Canja | 16 | 20 | 24 |

Cada perfil tem orçamento relativo à referência: impaciente 100%, normal 110%,
paciente 120%. O morador prefere uma opção acessível no cardápio; se nenhuma
couber, vai embora insatisfeito, registrando motivo `price`.

O preço ajusta a satisfação em até oito pontos: desconto favorece a moral,
preço alto a prejudica. Assim, desconto troca margem por satisfação; preço alto
pode reduzir público e alimentação. Pedidos já anotados conservam o valor e o
ajuste combinados. Preços legados fora da faixa são normalizados ao carregar
apenas para pedidos futuros; dinheiro, estoque e pedidos existentes são mantidos.
Restaurantes antigos sem a campanha de refúgio mantêm o comportamento legado.

### Funcionário alimentado e remunerado

A contratação continua conquistada com população quatro, custo 100, sem
funcionário gratuito no início. Um funcionário vinculado a morador faz **uma
refeição por turno**, em intervalo de quatro segundos junto à estação.

- Retira uma porção física excedente do cardápio. Clientes e pratos reservados
  têm prioridade; nenhuma comida é criada gratuitamente.
- O mesmo NPC segura o prato e mostra barra durante o intervalo. Não há cópia
  do personagem como cliente adicional. Ele volta ao trabalho ao terminar.
- Ao consumir, alimenta a cidade e recebe o pagamento do preço de referência,
  custeado pela cidade. Não usa o preço elevado do cardápio para esse pagamento.
- O prato vira louça suja real nas mãos do funcionário e segue para a pia.
  **O garçom continua sem lavar pratos**, conforme a preferência do proprietário.
- Gestão → Equipe explica a porção extra e mostra o estado da refeição.
  Fechamento informa a receita da equipe, já incluída na receita total.
- Sem excedente, ele continua trabalhando; o jogador precisa preparar sua porção.
  Funcionários legados sem vínculo de morador não recebem identidade inventada.

O início, o prato em trânsito/consumo e a conclusão pertencem ao salvamento.
Carregar durante o intervalo não duplica comida, louça ou pagamento.

### Energia ligada ao término do jantar

O último término de atendimento do jantar determina a recuperação ao amanhecer:

| Término | Energia recuperada |
|---|---:|
| Até 22h | 16 |
| Até 23h | 12 |
| Depois de 23h | 8 |

Saída tardia sem conseguir comer também conta. Alimentação abaixo de 40 limita
recuperação a oito, como antes. A Cidade mostra previsão e último descanso.
Organizar o atendimento ou ajustar os horários passa a influenciar o descanso;
a velocidade dos NPCs não foi reduzida. Não há punição pelo jantar suspenso na
horda. Hospedagem e acomodações continuam futuras, não simuladas por um botão.

### Ritmo e avanço de tempo

Primeira chegada aproximadamente oito segundos após a abertura. As demais ficam
espaçadas conforme duração do turno e população não empregada, entre 28 e 50s,
em vez dos 25s fixos. A exceção de sujeira continua: o cliente pode desistir de
um lugar sujo, e salão inteiramente sujo causa desistência.

**Gestão → Cidade ou Turnos → Avançar até o próximo turno** fica disponível
quando não há clientes, pedidos/tarefas/cargas pendentes nem comida no fogão.
Se o restaurante estiver aberto, todos os moradores daquele turno precisam já
ter tido sua oportunidade de visita. A simulação avança até abertura seguinte,
amanhecer ou horda; não muda o relógio sem processar consumo, despesas e dias.
Abertura continua automática. O checkpoint anterior à preparação da horda é
preservado, para permitir refazer as decisões após derrota.

O avanço usa passos de no máximo um segundo e respeita as fronteiras do relógio,
sem reconstruir milhares de quadros de interface durante a espera. Não é um
atalho para interromper comida no fogo ou escapar de clientes esperando.

### Preferências e recompensa da primeira vitória

Lia/Nina preferem caldo; Beto/Rui, arroz com cenoura; Íris/Cora, canja. As imagens
ficam na Cidade. A escolha considera orçamento e cardápio; se a receita favorita
não estiver disponível, outra pode ser pedida. Não é obrigatório aprender canja
antes do seu desbloqueio. Favorita servida acrescenta quatro pontos à satisfação.

A primeira vitória continua reduzindo corte de 2 para 1,6s e agora libera
**até duas porções na mesma panela**. Adicionar o dobro de todos os ingredientes,
cozinhar o lote e empratar consome dois pratos limpos. Não duplica ingredientes.
O fogo mantém o tempo da receita; o ganho é evitar repetir fogo e manuseio.
O livro e a recompensa da oficina informam a capacidade. Quantidades dos
alimentos no livro continuam sendo por porção.

### Leitura visual

- Enquadramento de jogo 25% mais próximo em telas horizontais de proporção ≥2,
  mantendo preto além dos interiores. Construção mantém seu enquadramento próprio.
- Livro usa colunas conforme quantidade/largura, com margens que deixam o rodapé
  legível. Cardápio aproveita duas colunas. Arte, coxas e relógios permanecem.
- Ação de retirar prato pronto mostra comida; retirar pratos limpos mostra pilha,
  mantendo a seta de retirada. Entrada e saída continuam com setas opostas.
- Ao recusar um lugar, o cliente olha para a cadeira e faz um movimento breve
  de reação, sem nome, ícone flutuante ou janela de feedback nova.
- Nenhum PNG original foi redesenhado ou substituído. A arte definitiva em 32×32
  segue aguardando os arquivos editados pelo proprietário.

[Cardápio](arte/equilibrio54-cardapio.png) ·
[Intervalo do funcionário](arte/equilibrio54-intervalo.png) ·
[Cidade](arte/equilibrio54-cidade.png) ·
[Livro compacto](arte/equilibrio54-livro-telefone.png) ·
[Reação](arte/equilibrio54-reacao.png) ·
[Almoço](arte/equilibrio54-almoco.png) ·
[Ingrediente na janela compacta](arte/equilibrio54-batata-telefone.png).

## Validação e resultados

**58 suítes padrão aprovadas**, com repetições específicas depois dos ajustes.
Novas suítes `EquilibrioNativo` e `EquilibrioUI` verificam regras e fluxo físico:

- Manutenção/recuperação, moral, orçamento, desconto e preservação de orçamento
  já combinado; rejeição de preço 100 sem alterar o cardápio.
- Lote real de duas batatas cortadas, cozimento, empratamento e conservação.
- Intervalo do garçom, porção retirada, prato restante, louça e pagamento únicos;
  salvar/carregar durante o consumo; proteção de porção reservada a cliente.
- Migração sem reset, rejeição de estado inválido, descanso por horário e saída
  tardia, avanço pelo botão real e proteção do checkpoint ao iniciar horda.
- Livro/menus em janela compacta, inclusive espaço do rodapé antes da moldura.

Percursos gráficos em Xorg/Compatibility/Mesa no Linux, com eventos nativos de
mouse no Viewport. No almoço desde Novo jogo, RNG fixo 0,5, **três vendas e zero
perdas**, contra duas vendas/uma recusa por sujeira na .53. A regra de sujeira
não foi removida: houve tempo para recolher antes da próxima chegada. Última
limpeza terminou em 194,25s, antes do fim do almoço em 210s: aproximadamente
16s restantes, contra 66s no percurso anterior. Caixa após cinco batatas: 220.
Não extrapolar uma semente para taxa média de perdas de jogadores reais.

A conferência gráfica dos alimentos passou novamente em janela compacta, agora
com zoom 1,3125. Batata cortada: 113 pixels visíveis na mão e 102 no fogão; prato
pronto: largura capturada de 20px tanto na estação quanto na mão. Pequenas
variações do raster não representam mudança de tamanho físico do item.

### Projeções de balanceamento

[Dados completos](equilibrio54/projecoes.json): fórmulas até 60 dias, atendimento
perfeito de todos os moradores, satisfação 85%, estoque e execução assumidos.
**Não são campanhas inteiras jogadas**, nem validam desempenho humano:

| Estratégia | Primeira horda | Segunda horda | Alimentação no dia 7 |
|---|---|---|---:|
| Sem refeições | Recuo | Queda | 0 |
| Caldo só no almoço | Defesa sofrida | Recuo | 25 |
| Caldo nos dois turnos | Defesa sofrida | Vitória tranquila | 65 |
| Arroz com cenoura nos dois turnos | Vitória tranquila | Vitória tranquila | 92 |

Caldo só no almoço chega à queda na terceira horda, dia 12, em vez de sustentar
60 dias. No modelo ideal, contratar e alimentar o funcionário preserva as
refeições/renda de referência, descontando o custo único de contratação.
Preços 8/10 produzem satisfação diferente com espera igual; 12 excede orçamento
do cliente normal sem outra opção, e 100 é recusado pelo comando.

A capacidade máxima atual de seis moradores e força de horda limitada a 72
permanece um limite do protótipo. Campanha longa, hospedagem, crafting/comércio
expandido e novas sprites precisam de próximas etapas. Não foi testado em
Android físico; toque real, bateria, temperatura e uma partida humana de vários
dias continuam necessários para calibrar estes parâmetros.

## Compatibilidade

Save externo continua versão 12. `refuge.balance.version=1` registra descanso
e refeições de equipe do dia; o prato durante intervalo integra conservação.
Dados legados válidos são atualizados sem reaplicar kit inicial ou zerar barras,
dinheiro, utensílios e pedidos. Os registros da auditoria .53 são históricos e
não foram sobrescritos pelas novas projeções.

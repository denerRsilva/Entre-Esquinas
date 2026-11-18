# Auditoria do jogo — .53

17/11/2026 · Godot 4.6.3 · Android 21253 · campanha nova do GDD 3.5.

**O bug relatado foi reproduzido e corrigido.** Batata e cenoura, inteiras e
cortadas, não eram desenhadas no cenário. Os pratos das receitas novas também
caíam no desenho de prato vazio. O jogo alterava corretamente o inventário,
mas a apresentação escondia essa alteração. Não era erro do jogador.

O ciclo básico está funcional, mas o balanceamento ainda permite estratégias
que enfraquecem os três pilares e a progressão. A prioridade recomendada é
consolidar esse primeiro ciclo antes de acrescentar receitas ou sistemas.

## Método e limites

- **Percurso nativo automatizado, começando em Novo jogo:** eventos de mouse
  no Viewport, roteamento real de interface/mapa, chegadas naturais e relógio
  avançado em passos de simulação. Caixa 200, sem funcionário. Não foram
  criados clientes nem saltado o relógio no almoço principal. RNG fixo 0,5
  para reproduzir o percurso; não representa uma amostra estatística de partidas.
- **Inspeção renderizada:** Xorg/Compatibility/Mesa no Linux, 1280×720 e
  960×432. Capturas verificadas visualmente; comparação de pixels com e sem
  cada alimento para provar que há desenho na tela, além do estado correto.
- **Regressões:** 55 suítes existentes e a nova `AuditoriaVisualAlimentosUI`.
  Incluem receitas, contratação, horda, derrota consecutiva, louça, construção,
  movimentos, interface, persistência e partidas antigas. Casos controlados de
  horda/canja usam estados de teste; não são partidas completas pelo mouse.
- **Balanceamento:** seis projeções das fórmulas, até 60 dias cada, com
  atendimento ideal de todos os moradores elegíveis, satisfação fixa de 85% e
  sem deslocamento, sujeira, deterioração, estoque ou erro operacional. Não são
  seis campanhas jogadas. Uma prova separada usa os comandos reais de preço,
  geração de cliente, anotação e cálculo de satisfação.
- Não houve teste em telefone Android físico, medição térmica/bateria, controle
  por toque real, audição humana dos efeitos ou campanha longa jogada por pessoa.
  Janela compacta não substitui esses testes. Não é possível garantir ausência
  de todos os bugs com essas verificações.

## Bugs corrigidos

| Achado | Causa | Correção e evidência |
|---|---|---|
| Batata/cenoura invisíveis na mão e no fogão | `Cena.food` aceitava apenas as oito entradas antigas, embora `Alimentos` já suportasse o atlas novo | Cenário consulta o catálogo de texturas compartilhado. Antes: 36 verificações visuais falhavam; depois: zero |
| Caldo, arroz com cenoura e canja aparentavam prato vazio no mundo | Mesmo filtro recusava as receitas novas; `plate` usava o prato vazio como alternativa | Receitas novas e aliases `dish_` chegam ao renderizador; catálogo inteiro produz pixels opacos |
| Prato novo menor que a louça vazia | Canvas 32×32 com margens transparentes era comprimido numa área de 20×14 | Recorte de exibição da silhueta de 28×15, largura física 20. Livro mantém canvas 32×32. PNGs preservados |
| Testes anteriores não percebiam invisibilidade | Conferiam alimento/tarefa e existência da textura, sem percorrer o compositor até o desenho | Nova regressão cruza ingredientes, cortes e receitas cadastrados com o compositor; modo gráfico confere pixels realmente visíveis |

Não foi necessário migrar ou reiniciar salvamentos. Regras econômicas,
nutrição, horários, arte original e kit inicial permanecem. O formato externo
de save continua versão 12.

### Evidência visual

[Batata cortada antes](arte/auditoria53-batata-antes.png) ·
[Batata cortada depois](arte/auditoria53-batata-depois.png) ·
[Batata na panela](arte/auditoria53-panela.png) ·
[Caldo na estação](arte/auditoria53-empratado.png) ·
[Caldo servido](arte/auditoria53-servido.png) ·
[Janela compacta](arte/auditoria53-telefone.png) ·
[Catálogo renderizado](arte/auditoria53-catalogo.png) ·
[Livro compacto](arte/inicio-receitas-telefone.png) ·
[Mercador compacto](arte/inicio-mercador-telefone.png).

Foram percorridas 12 etapas de alimento por resolução: retirar, cortar,
adicionar ao fogão, terminar cozimento, empratar e retirar prato, tanto para
batata/caldo quanto para cenoura/arroz. Na tela PC a batata cortada passou de
nenhum comando de desenho para **167 pixels visíveis na mão e 190 no fogão**;
na compacta, 65 em ambos. O prato pronto usa largura física igual à louça
vazia; pequenas diferenças de um pixel na captura vêm do arredondamento e zoom.
As cores/silhuetas de receitas são conferidas no catálogo; canja também tem
regressão de preparo, aprendizado e save em `InicioUI`.

## Atendimento e ritmo observados

O percurso escolheu caldo no cardápio, preparou antes da abertura, anotou com
barra de 1,2s, serviu, recolheu, lavou, devolveu pratos e limpou a mesa. Ao fim
visitou Beto, comprou cinco batatas por 10 e salvou/carregou pela interface.

| Marco | Tempo de simulação desde o início às 10h |
|---|---:|
| Primeiro pagamento | 68,20s |
| Primeiro ciclo de limpeza/lavagem/devolução terminado | 81,45s |
| Segundo pagamento | 131,05s |
| Segundo ciclo de limpeza terminado | 144,30s |
| Fim do almoço, 15h | 210s |

Resultado: **duas vendas, uma recusa por cadeira suja, receita 20 e caixa 210
após reposição**. Oito pratos e duas panelas conservados; save válido.
A recusa ocorreu entre pagamento e recolhimento. É a regra aprovada de sujeira,
que permite desistência mesmo com outros lugares disponíveis, não um bug de
anotação. Não extrapolar esse 1/3 para a taxa média de desistências: a mesma
semente força uma escolha específica de cadeira.

O almoço dura 168s (11h–15h). Após o último ciclo ficaram aproximadamente
**66s sem novas visitas nesse turno**, 39% da duração do almoço; ainda é
possível organizar/cozinhar, mas a demanda daquele turno já acabou. O intervalo
15h–18h soma mais 126s. No começo há três moradores e oito cadeiras: capacidade
de salão não é o gargalo. Deslocamento e manuseio ocupam uma parcela importante
do trabalho; os relógios das receitas não medem esse percurso completo.

**Proposta:** objetivos curtos de preparação/abastecimento à tarde e uma forma
clara de encerrar a preparação quando não há pendências. Manter espaço para
respirar entre serviços; evitar transformar todo minuto em pressão. Avaliar
cadência de chegadas com jogadores reais antes de aumentar o volume.

## Economia e balanceamento

### 1. Preço sem consequência — prioridade alta

É possível colocar caldo a 100 em vez de 10. Na prova com as mesmas decisões,
ambos os preços geraram cliente normal, paciência 75s/120s, pedido aceito e
satisfação **87,15%**. Preço não participa da escolha de receita nem da satisfação.

Com seis vendas de caldo, reposição a custo e despesa diária 12: preço 10 dá
margem diária **36**; preço 100 dá **576**, 16 vezes mais, com a mesma demanda.
É uma estratégia dominante, não uma escolha interessante. Essas margens são
estimativas de reposição, não o caixa real do dia 1, que recebe estoque inicial.

**Proposta:** primeiro definir preços de referência e capacidade de pagamento;
depois testar uma faixa curta de preço com consequência visual e previsível
na procura/satisfação. Evitar uma punição escondida ou economia que exija
planilha. Não alterado nesta entrega.

### 2. Alimentação e moral saturam; jantar perde importância — prioridade alta

Por refeição: alimentação += nutrição × 5,2 / população. Cada turno comum retira
8 de alimentação, 6 de energia e 2 de moral. Com todos alimentados nos dois
turnos, caldo acrescenta 41,6 de alimentação/dia contra consumo 16; arroz com
cenoura acrescenta 62,4. O excesso é perdido no teto 100.

| Política idealizada | Primeira horda, dia 3 | Resultado nas projeções |
|---|---|---|
| Nenhuma refeição | Preparo 48,2 contra força 50; recuo | Queda na segunda horda, dia 7 |
| Só caldo no almoço; nenhum jantar | Preparo 77,4 contra 50; vitória tranquila | Sobrevive aos 60 dias projetados |
| Caldo no almoço e jantar | Preparo 82,6 contra 50; vitória tranquila | Sobrevive aos 60 dias projetados |
| Arroz com cenoura nos dois turnos | Preparo 82,6 contra 50; vitória tranquila | Mesma primeira defesa do caldo por causa do teto |

O cenário sem refeições não simula as perdas adicionais por clientes
abandonando; ele isola consumo e defesa. As políticas com comida pressupõem
serviço perfeito e abastecimento, portanto não provam que jogar seja fácil
para qualquer pessoa. Mostram que **as fórmulas oferecem pouca razão para
manter o jantar ou investir em maior nutrição** quando o jogador domina o fluxo.

**Proposta:** calibrar o consumo dos moradores e a contribuição das porções em
conjunto, testando caldo como manutenção básica e refeições nutritivas como
uma forma de recuperar déficits. Preservar as barras como status, não bônus,
e preservar a ausência de penalidade pelo jantar cancelado na horda.

### 3. Energia se recupera quase sozinha — prioridade alta

Dois turnos custam 12 e o amanhecer recupera 16 quando alimentação ≥40: saldo
de +4 em dia comum. No ataque há só almoço, defesa custa outros 12 e o amanhecer
recupera 16: saldo de −2, antes de considerar limites. Não há ainda uma decisão
de descanso/hospedagem que sustente esse pilar.

**Proposta:** introduzir a menor decisão jogável de descanso quando esse
sistema for implementado, e então calibrar energia. Somente reduzir o valor
agora criaria uma obrigação sem ferramenta para resolvê-la.

### 4. Contratar reduz a demanda pagante — prioridade alta

O novo morador contratado deixa a lista de visitantes, mas continua na
população usada no cálculo coletivo. Com quatro moradores, contratar o primeiro
garçom reduz de quatro para três potenciais vendas por turno, além do custo 100.
Com arroz, um dia comum ideal cai de margem 68 para 48 antes do custo da
contratação. A automação ajuda operacionalmente, mas parte de sua recompensa
econômica desaparece. Não há salário recorrente neste cálculo.

**Proposta:** definir refeição de funcionário e demanda dos viajantes, ou
outra renda coerente que mantenha o ganho da contratação. O funcionário não
deve existir simultaneamente como cliente duplicado. Medir tempo livre ganho,
vendas perdidas e lucro antes/depois, em vez de julgar apenas pela animação.

### 5. Receita desbloqueada tem utilidade fraca — prioridade média

| Receita | Custo dos ingredientes | Preço | Margem por visitante | Nutrição | Corte + fogo + empratamento inicial |
|---|---:|---:|---:|---:|---:|
| Caldo de batata | 2 | 10 | 8 | 4 | 9s |
| Arroz com cenoura | 4 | 14 | 10 | 6 | 10s |
| Canja | 8 | 20 | 12 | 8 | 14s |

Tempos excluem caminhada/retirada/serviço e incluem cozimento automático, que
pode se sobrepor a outras ações. Não são taxas de produção reais. A canja vem
da caravana no dia 4, depois da primeira horda, com aprendizado 30 e frango
limitado a seis a cada quatro dias. Nutrição alta perde valor se a barra já está
no teto. Há pouca motivação mecânica para variar o cardápio.

**Proposta:** pequenos gostos dos moradores, recuperação nutritiva perceptível
e ocasiões para a canja. Primeiro corrigir os tetos/consumo; evitar receitas
extras que só troquem o desenho. A falta de estoque não deveria exigir adivinhar
o pedido futuro: revisar como o cardápio informa disponibilidade.

### 6. Crescimento e derrota — prioridade média

A população para em seis após três vitórias. Força da horda para em 72; defesa
pode alcançar 100. Nas políticas ideais testadas a pressão deixa de crescer.
Isso é aceitável para um trecho de protótipo, mas ainda não sustenta campanha
longa. A recompensa inicial reduz corte de 2 para 1,6s: ganho real de 0,4s por
corte, pequeno diante da caminhada. Melhorias deveriam liberar uma decisão,
capacidade ou tarefa perceptível, além de alterar percentuais.

Também não encontrei recuperação econômica para caixa esgotado e geladeira
vazia: compra exige saldo e a despesa diária continua sendo cobrada. O jogo
avança até a derrota; não é travamento de execução, mas risco de espiral sem
ação útil. Propor ajuda comunitária ou trabalho limitado de emergência.
Preservar duas derrotas **seguidas**, vitória que zera a sequência e retomada
da preparação; os testes dessas regras passaram.

## Leitura visual, interface e diversão

**O que está ajudando:** cenário compacto e acolhedor, separação clara de
salão/cozinha, clique direto no cliente, comanda visual, tarefas com barra,
panela vazia devolvida à mão e louça com quantidade real. São boas bases para
o ciclo de cuidar das pessoas. A ligação entre moradores alimentados e defesa
é o diferencial mais forte; merece ocupar o centro da progressão.

**O que precisa de atenção, sem redesenho nesta revisão:**

1. **Escala no celular.** A visão geral deixa o alimento cortado com cerca de
   12px de largura na captura compacta. Está visível, mas requer atenção. Testar
   zoom inicial mais próximo do personagem e seguimento suave, mantendo exterior
   preto dos interiores. Não confundir canvas nativo 32px com tamanho na tela.
2. **Coesão artística.** Atlas antigos são estudos ampliados, enquanto os novos
   alimentos são nativos 32px. A mistura de densidades/perspectivas continua
   perceptível. Pratos novos têm silhueta quadrada e pouco relevo. A edição
   definitiva no Aseprite pelo proprietário continua sendo a referência; não
   foram substituídos os originais para tentar esconder a diferença.
3. **Prato na borda da estação.** No lugar inferior direito aprovado, seleção
   branca, prato claro e borda da mesa podem se confundir. Diferenciar seleção
   do tampo/prato com contorno discreto; não mudar os quatro lugares aprovados
   nem reduzir a louça para caber.
4. **Ícones de ação.** As duas opções da estação ainda usam símbolos muito
   semelhantes. Entrada/retirada deveriam combinar desenho da louça com seta
   inequívoca. Evitar reintroduzir textos flutuantes ou popups de feedback.
5. **Saída por sujeira pouco explicada.** A informação existe no estado, mas
   a visão limpa oculta a antiga reação. Animar olhar para o prato, recuo e
   expressão breve explicaria a saída sem nome ou janela. Não remover a regra
   aprovada de desistência.
6. **Hierarquia do HUD.** Cabeçalho compacto tem data, reputação, fase, dinheiro
   e nome; textos ficam menores que botões inferiores. Priorizar horário,
   dinheiro e comandas; detalhes podem continuar nos menus. Barras coletivas
   permanecem em Gestão → Cidade, conforme aprovado.
7. **Livro e comércio.** Revistos em captura compacta: os botões do mercador
   ficam acessíveis com rolagem, mas o livro deixa uma terceira coluna vazia
   com apenas duas receitas e o rodapé encosta na moldura. Aproveitar a largura
   disponível e dar respiro aos símbolos de etapas; aumentar legibilidade das
   mini coxas/relógios sem acrescentar explicações extensas.
8. **Ambientação e recompensa.** O trabalho da cozinha funciona, mas a cidade
   ainda comunica pouco a reconstrução durante o serviço. Priorizar pequenas
   mudanças de fachada, rotina/expressão dos mesmos moradores e melhorias
   operacionais após a primeira defesa. Cerveja, hóspedes e raridades podem
   ampliar esse ciclo depois que a economia básica estiver consistente.

## Desempenho e estabilidade

As regressões do garçom não reproduziram a lentidão extrema anteriormente
relatada. No microteste desta máquina, 300 passos por cenário: mediana 0,034ms
e p95 0,609ms com rota normal; mediana 1,029ms e p95 2,177ms com rota bloqueada;
picos aproximadamente 33ms durante a bateria concorrente. São tempos do núcleo
de simulação no Linux, não FPS do jogo completo ou garantia de desempenho no
Android. Medir renderização, alocação e temperatura num aparelho continua pendente.
Não houve motivo para uma reescrita geral ou otimização especulativa nesta entrega.

## Entrega e compilação

Código da correção: `b2712db`. Android **0.21.2-godot.53 / 21253**, assinatura
verificada e igual à .52. Integridade ZIP conferida; os dois scripts corrigidos
estão recompilados. **Todas as 35 texturas importadas têm exatamente os mesmos
bytes da .52**, sem substituição dos atlas. APK sem JavaScript ou QA, tamanho
99,507MiB; os dois nomes de APK apontam para conteúdo idêntico. Resultado das
**56 suítes padrão: aprovado**, além dos percursos gráficos PC/compacto e menus.
[Metadados e hash do Android](auditoria53/android.json). Não testado em aparelho.

## Próximas etapas recomendadas

1. **Primeiro ciclo balanceado:** preços, contribuição/consumo coletivo,
   jantar e valor da contratação. Medir um iniciante e um jogador experiente
   pelos dias 1–7: vendas, perdas, tempo ocioso, caixa, status antes da horda e
   custo da contratação. A primeira horda deve ensinar, sem tornar o jantar
   irrelevante. Não usar estas projeções perfeitas como única meta.
2. **Clareza sem poluição:** zoom compacto, entrada/retirada de louça, reação
   à sujeira e um pequeno objetivo vespertino. Avaliar compreensão sem explicar
   verbalmente onde clicar; manter um clique para anotar.
3. **Recompensa e expansão:** melhoria perceptível após defesa, funcionário
   que libere tempo para nova função e comércio/crafting conforme o GDD.
   Depois ampliar bebidas e hospedagem. Não aumentar apenas a quantidade de
   cliques para simular dificuldade.

São propostas para avaliação; os parâmetros e a direção do GDD não foram
reescritos automaticamente por esta auditoria.

## Reprodução e dados

```sh
scripts/testar-migracao.sh
godot --headless --path godot --script res://qa/AuditoriaBalanceamento.gd
DISPLAY=:88 XDG_DATA_HOME=/tmp/auditoria-visual-nova godot --path godot \
  --rendering-method gl_compatibility --audio-driver Dummy \
  --script res://qa/AuditoriaVisualAlimentosUI.gd -- --pixels
# Acrescentar --phone para 960×432; requer servidor gráfico ativo.
```

`AuditoriaBalanceamento` é uma ferramenta de análise, fora da bateria de
regressão: estratégias ruins não devem virar expectativas obrigatórias dos
testes. [Projeções completas](auditoria53/projecoes.json),
[pixels PC](auditoria53/pixels-pc.json), [pixels compactos](auditoria53/pixels-telefone.json).
As projeções precisam ser refeitas quando economia, população ou nutrição mudar.

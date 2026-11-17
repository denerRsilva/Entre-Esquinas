# Registro do primeiro protótipo: o refúgio (.46)

**Registro histórico de implementação; não define as regras finais.** A revisão
[GDD 3.1](../GDD.md), aprovada por Dener em 17/11/2026, determina **três barras
coletivas** e **duas derrotas consecutivas, com reset da sequência por vitória**.
A versão .46 descrita abaixo ainda usa status individuais/médias e derrotas
acumuladas. Esses comportamentos estão substituídos como direção e precisam
ser adaptados no código e nos salvamentos em outra tarefa. Os parâmetros abaixo
continuam documentando o executável .46; não foram alterados nesta revisão.

A premissa do refúgio foi aprovada por Dener em 17/11/2026. A cidade é um ponto
de esperança em reconstrução no apocalipse zumbi. A taverna alimenta as pessoas que a defendem.
O desenvolvimento avança em trechos jogáveis, com o proprietário avaliando o
ritmo antes de ampliar a campanha. A origem nuclear anterior foi substituída;
a origem dos zumbis e os NPCs pilares da história permanecem em aberto.

## O que experimentar agora

No início, escolher **Começar no refúgio**. A campanha usa o primeiro dos três
slots que estiver vazio. Se todos estiverem ocupados, o jogo pede qual partida
substituir antes de gravar. Restaurantes antigos continuam carregáveis; não
são convertidos automaticamente. A opção anterior de taverna mantém o modo livre.

O trecho começa com a taverna equipada e três moradores recorrentes. As artes
e nomes Lia, Beto e Nina são provisórios e reaproveitam o elenco existente; não
definem os futuros NPCs pilares. Cada morador visita uma vez por turno, pode
pedir as receitas existentes e mantém sua aparência no ataque. Os mais famintos
chegam primeiro. A população inicial é pequena para testar os fluxos atuais.

O painel compacto mostra as médias da cidade para **alimentação, energia e
moral**, todas de 0 a 100. Tocar no painel abre os status individuais com
retratos, pausando o tempo. Não há nomes flutuantes ou avisos automáticos novos.

Uma refeição realmente concluída melhora alimentação e moral de quem a comeu;
anotar um pedido ou entregar um prato ainda não finalizado não concede isso.
Energia se recupera no descanso noturno. As perdas regulares são aplicadas
uma vez ao fechar cada turno. Hospedagem, escalas de trabalho e diversão como
atividade separada ficam para os próximos trechos; neste início, descanso é
automático e atendimento afeta moral.

## Primeira horda e consequências

A primeira horda chega no terceiro dia, no começo do horário do jantar. O
jantar é suspenso, sem perda de alimentação, energia ou moral por esse turno.
Serviços de almoço ainda pendentes podem terminar antes da defesa. Dormir ou
avançar o relógio não permite saltar o ataque.

O resultado é calculado deterministicamente a partir dos status e da defesa.
Uma animação curta apresenta os moradores em seus postos e a horda, usando
sprites existentes com tons e movimentos provisórios. Não há combate
controlável. O evento dura oito segundos e pode ser pulado sem mudar o resultado.
O relógio, refeições e lavagens ficam suspensos durante a sequência.

- Vitória tranquila ou defesa sofrida: a primeira etapa de oficina é recuperada,
  o corte passa de 2 para **1,6 segundo**, e chega um novo sobrevivente.
- Primeira derrota: recuo, barricada danificada e queda de moral. Há outra chance.
- Segunda derrota: game over, com retorno à preparação anterior ao ataque.

Neste trecho, as duas derrotas são contadas na campanha, sem reset automático
por vitória. A penalidade inicial é defesa −20 (piso 25), moral −8; não há morte
permanente de NPC principal ou perda de ingredientes. São parâmetros de teste.
A reconstrução tem três níveis iniciais com luzes progressivas no exterior e
nas casas da sequência; a melhoria de corte é concedida só na primeira etapa.
A população cresce até seis neste trecho; não representa o tamanho final da cidade.

Depois da primeira horda, os intervalos são 4, 5 e 3 dias, repetindo essa ordem.
O painel informa a próxima chegada. Datas secretas, alarmes antecipados,
variedade de inimigos e uma cidade ampliada ficam para futuras partidas de teste.

## Parâmetros iniciais

| Regra | Valor de teste |
| --- | --- |
| Status iniciais | Alimentação 65, energia 70, moral 65 por morador |
| Refeição concluída | Alimentação +26; moral +2 a +8 conforme satisfação |
| Visita abandonada | Moral −3 |
| Fim de turno normal | Alimentação −8, energia −6, moral −2 |
| Descanso noturno | Energia +16; +8 se alimentação estiver abaixo de 40 |
| Desgaste da horda | Energia −12 após o resultado |
| Preparo da defesa | Alimentação ×0,35 + energia ×0,25 + moral ×0,25 + defesa ×0,15 |
| Força da horda | 50 inicialmente; +4 por ataque, limitada a 72 neste trecho |
| Vitória tranquila | Preparo pelo menos 18 acima da força |
| Vitória | Preparo igual ou maior que a força |
| Defesa inicial | 65; vitória recupera 8 até 100 |

As barras representam condições, não bônus acumuláveis. Ganhos e perdas param
em 0/100. Não há sorteio oculto decidindo vitória nem reajuste de dificuldade
que cancele imediatamente uma melhoria conquistada. As três receitas e a
cozinha física permanecem como estão, incluindo as regras da pia da versão .45.

## Salvamentos e retomada

Há três partidas visíveis. Cada slot pode guardar um backup interno da
preparação da horda, no mesmo arquivo de persistência. Esse backup não é um
quarto slot nem substitui o save normal. A manhã do dia de horda é preservada;
salvar durante a animação ou no game over não apaga essa oportunidade de
replanejar. A sequência salva guarda o resultado, o progresso e a marca de
consequências aplicadas, impedindo repetir recompensas ao carregar ou pular.

## Playtest com o proprietário

Jogar até a primeira horda e sentir a manhã seguinte. Para dormir depois do
serviço: **Opções → Salvar e carregar → Dormir e salvar**. O avanço de horário
já existente em Opções/Testes pode abreviar uma revisão, mas não substitui o
teste do ritmo normal e não permite evitar a horda.

Observar: quanto tempo sobra entre pedidos; se percebe qual morador precisa
comer; se entende o resultado da defesa; se a melhora no corte é perceptível;
e se o aumento para quatro moradores parece uma responsabilidade agradável.
Essas observações orientam o próximo trecho. Cerveja, hospedagem, comércio
presencial e a campanha extensa continuam como direção futura, sem expansão
automática nesta entrega.

## Verificação

`RefugioUI` exercita partida nova, serviço real com alimentação individual,
jantar normal, ausência de penalidade na horda, transição e pausa da sequência,
save/load, pulo idempotente, recompensa e corte melhorado, duas derrotas,
retomada da manhã, dados inválidos e compatibilidade com partidas antigas.
As **49 suítes** do conjunto padrão passaram. Capturas do renderizador:
[início](arte/refugio-inicio.png), [horda](arte/refugio-horda.png),
[vitória](arte/refugio-vitoria.png) e [tela larga](arte/refugio-horda-telefone.png). A versão Android é 0.21.2-godot.46 (21246).
As capturas e a compilação não equivalem a teste em aparelho Android físico.

# Gestão → Cidade e status coletivos

Implementação da sugestão aprovada por Dener em 17/11/2026, alinhada ao GDD 3.1.
Versão Android **0.21.2-godot.47**, código **21247**.

## Consulta

Na campanha de refúgio, abrir **Gestão → Cidade**. A consulta pausa o jogo e
reúne alimentação, energia e moral coletivas (0 a 100), população, condições
das defesas, próxima horda e situação da cidade. As três barras usam os assets
já existentes. Não há barra, botão de moradores ou painel permanente no cenário.
Fechar o menu devolve o jogador à tela de jogo limpa. A navegação mantém palavras
inteiras e se reorganiza quando faltar largura; o conteúdo permite rolagem.

A situação é **Normal**, **Preparação para a horda** quando falta até um dia,
ou **Recuo** após uma derrota. Defesas são informadas por condição e valor;
não são um quarto pilar. O modo livre antigo continua sem status de refúgio.
A sequência noturna segue curta e pulável; cansaço na apresentação considera
a energia coletiva registrada no início da batalha. Arte de personagens,
objetos e cenário permanece preservada. Feedback ambiental mais elaborado
continua sendo desenvolvido junto das próximas etapas de arte e gameplay.

## Estado coletivo e ritmo de teste

O refúgio guarda **três valores próprios**, não uma média recalculada de barras
individuais. Os moradores mantêm identidades e visitas recorrentes. Uma refeição
concluída contribui para a cidade; a demanda aumenta com a população.

Os parâmetros iniciais continuam provisórios:

- Alimentação 65, energia 70 e moral 65 ao começar.
- Refeição concluída: alimentação +26/população; moral +(2 a 8)/população,
  conforme satisfação. Visita abandonada: moral −3/população.
- Fim de turno comum: alimentação −8, energia −6 e moral −2, uma vez por turno.
- Descanso: energia +16, ou +8 se a alimentação coletiva estiver abaixo de 40.
- Horda: energia −12 depois do resultado. Vitória recupera moral +8 e defesa +8;
  derrota reduz moral em 8 e defesa em 20, com piso de 25 para defesa.

Ganhos e perdas respeitam 0/100. Jantar suspenso pela horda não aplica perda
nesses status. Primeira horda no terceiro dia, intervalos 4/5/3, recompensa do
corte e limite provisório de seis moradores permanecem como no primeiro trecho.
A chegada de alguém não recalcula nem reduz as barras; a maior população muda
as contribuições por refeição e a demanda dos próximos turnos.

## Derrotas consecutivas

Uma vitória zera `defeats`, a sequência de derrotas seguidas. Duas derrotas
consecutivas causam game over. Os totais históricos `victories` e `losses`
são separados, mantendo reconstrução, população e melhorias independentes
do reset da sequência. Derrota/vitória/derrota mantém uma chance; derrota/derrota
encerra a campanha. Os três slots e seus backups internos de preparação permanecem.

## Compatibilidade com a versão .46

O estado opcional do refúgio passa do schema 1 para o 2, preservando a versão
externa 12 dos saves existentes. Ao carregar um save .46 válido, convertemos
uma única vez as médias anteriormente exibidas em três valores coletivos
persistidos. As barras pessoais são removidas; nomes, aparências, recursos,
dinheiro, móveis, população e progresso permanecem. Sem refúgio, não há conversão.

Os saves .46 só guardavam o total de derrotas e a última batalha, sem um histórico
completo de resultados. Se a última batalha concluída foi uma vitória, a sequência
é zerada. Resultados antigos já concluídos, inclusive game over, são preservados;
a retomada pode usar o backup de preparação, também migrado ao carregar.

Em uma batalha antiga ainda pendente, perdas acumuladas não são carregadas como
uma segunda chance já consumida quando existem vitórias anteriores: a sequência
é reiniciada, e o resultado pendente é recalculado com o mesmo preparo/força.
Sem vitória anterior, a derrota conhecida é mantida. Essa conversão é deliberada
para evitar um game over novo baseado em um histórico que o arquivo não registrou.
Não são reaplicadas recompensas ou consequências de batalhas já encerradas.

## Verificação

`CidadeUI` cobre navegação real, ausência de painel na partida, três barras no
menu, pausa, persistência coletiva, limite 100, contribuição de refeições,
derrota/vitória/derrota, duas derrotas seguidas, reconstrução preservada e
migração de cinco saves .46 exportados e validados antes da mudança. Também
verifica arquivos inválidos, recarga idempotente e compatibilidade com modo livre.
`RefugioUI` mantém o teste de cozinha/serviço real e retomada da preparação.
As **50 suítes** do conjunto padrão passaram. Capturas do renderizador Compatibility:
[partida sem painel](arte/cidade-jogo.png), [menu](arte/cidade-menu.png), [tela larga](arte/cidade-menu-telefone.png) e
[recuo](arte/cidade-recuo.png). Não houve teste em aparelho Android físico.

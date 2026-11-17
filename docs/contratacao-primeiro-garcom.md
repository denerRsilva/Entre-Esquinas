# Primeira contratação da taverna

Versão **0.21.2-godot.48**, Android **21248**. Direção aprovada por Dener:
funcionários são conquistados com o crescimento da cidade; garçom é a primeira
função. O [GDD 3.2](../GDD.md) registra também o kit e abastecimento aprovados
para as próximas etapas.

## Trecho jogável entregue

- **Nova campanha de refúgio começa sem funcionário.** O jogador faz o primeiro
  atendimento, cozinha e limpeza; não há garçom gratuito no salão.
- **Gestão → Equipe** mostra o marco de quatro moradores. Na progressão atual,
  a primeira defesa vencida traz o quarto habitante e libera a busca.
- **Procurar contratação** mostra pessoas disponíveis, retrato, função e custo.
  A primeira opção é Íris; novas chegadas acrescentam Rui e Cora enquanto houver
  vaga. Os três fundadores preservam seus papéis atuais na cidade. O limite de
  seis moradores ainda pertence ao primeiro protótipo, não à campanha final.
- Uma vaga de garçom, contratação única de **$100**. População quatro e preço
  são **parâmetros provisórios de teste**, não regras finais de balanceamento.
  O pagamento é lançado como investimento. Não foi acrescentado salário nem
  outra despesa nesta etapa; a despesa diária genérica existente permanece.
- O contratado começa ativo: anota com progresso, serve, recolhe até cinco
  pratos sujos e limpa mesas/chão conforme o sistema existente. **Não lava
  pratos**, mantendo a decisão do proprietário. Pode ser pausado na gestão.
- A pessoa mantém aparência e vínculo de morador. Não aparece simultaneamente
  como cliente; se estiver visitando, é necessário terminar a visita antes de
  contratar. Falta de saldo, vaga ocupada ou salão inacessível não cobra.
- Outras profissões e múltiplas vagas continuam futuras; os dados separam
  pessoa, função e tarefa para permitir sua evolução.

## Salvamentos e compatibilidade

Registro da .48: havia três slots e formato externo 12. A
[versão .49](menu-inicial-save-unico.md) passa a um slot, preservando os arquivos
legados. O formato externo 12 permanece. O estado do refúgio recebe
`hiring.version = 1`, com vínculos entre trabalhador, morador e profissão.
Novas campanhas têm lista vazia. Saves anteriores conservam seus funcionários
como vínculos legados, sem cobrança, remoção ou troca de carga/tarefa. Pausar e
salvar não reativa a pessoa ao carregar. Modos livres antigos preservam seu
comportamento de teste. O comando de limpar cenário conserva contratações,
sem criar garçom gratuito nem perder a identidade contratada.

## O que permanece para o próximo trecho

O início aprovado de caixa 200, duas mesas/oito cadeiras, duas panelas/oito
pratos, arroz/batata/cenoura e duas receitas iniciais está no GDD. **Ainda não
foi aplicado ao executável .48**, que conserva caixa 1500, três mesas, receitas
e estoque anteriores. A redução deve acompanhar abastecimento utilizável para
não bloquear a continuidade da partida.

Mercador limitado, viajantes, carpinteiro, ferro-velho, artesão, decoração,
retirada do computador e indicadores de nutrição/tempo são a direção aprovada
para as próximas adaptações. Não foram apresentados como funcionalidades desta
entrega. Arte existente preservada para a edição 32 × 32 do proprietário.

## Verificação

As **51 suítes padrão passaram**. `ContratacaoUI` cobre o menu nativo, bloqueio
antes da chegada, crescimento das opções, contratação de pessoas diferentes,
pagamento único, visita em andamento, função bloqueada, atendimento real com
barra de anotação, persistência, pausa, reset do cenário e migração de funcionário
antigo carregando louça. Rejeita vínculos inválidos e estado inconsistente.

Capturas do renderizador Compatibility: [antes do desbloqueio](arte/contratacao-bloqueada.png),
[candidatos](arte/contratacao-candidatos.png), [equipe contratada](arte/contratacao-equipe.png)
e [formato largo de telefone](arte/contratacao-telefone.png). Não houve teste
em aparelho Android físico. Testes não comprovam diversão ou equilíbrio final.

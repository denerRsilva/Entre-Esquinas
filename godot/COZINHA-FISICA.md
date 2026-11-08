# Cozinha física

Fluxo implementado somente na Godot. HTML preservado.

1. Selecione o ingrediente na mochila e feche o menu.
2. Clique na **Mesa de preparo • corte**: uma unidade de frango ou legumes vira ingrediente cortado em dois segundos ativos. Arroz não precisa de corte. O resultado volta à mochila; falta de espaço não elimina o ingrediente.
3. Instale uma panela vazia no fogão. Selecione e adicione uma unidade de ingrediente por clique. Arroz com legumes: 1 arroz + 1 legumes cortados; sopa: 2 legumes cortados; frango com arroz: 1 arroz + 1 frango cortado. As receitas são reconhecidas por correspondência exata. Remova o último ingrediente para corrigir uma combinação.
4. Use o ícone **Cozinhar**. Cada cozimento novo rende uma porção. O personagem fica livre; pronto, passando do ponto e queimado mantêm as regras anteriores. Estrelas não aparecem no preparo.
5. Retire a panela: ela ocupa as mãos, deixa o fogão livre e para de perder qualidade pelo calor.
6. Apoie na **Mesa de cozinha**, reponha pratos limpos e use **Empratar uma porção**. Não é necessário talher. A ação leva dois segundos junto à mesa. Comida queimada não pode ser empratada.
7. Pegue o prato nas mãos e clique na mesa ou cliente com pedido compatível. O garçom procura pratos prontos na nova mesa de cozinha e mantém as funções anteriores. Uma retirada remove imediatamente o prato da mesa, impedindo disputa pelo mesmo item.
8. Retire a panela vazia apoiada e instale novamente no fogão, ou guarde a panela vazia na mochila. Pia e lixo permitem descartar comida carregada preservando seu recipiente. A lavagem de pratos continua disponível.

Um clique agenda a aproximação e a ação. Ações alternativas ficam junto ao objeto. Computador mantém catálogo; geladeiras e prateleiras abrem inventário dividido após aproximação, **sem pausar o tempo**. Outros menus, perda de foco e construção continuam pausando. Ações de corte/empratamento aguardam proximidade e podem ser canceladas sem consumo.

## Salvamentos

Formato 10, chave `entre-restaurante-10`, com leitura das chaves anteriores. Arquivo local Godot continua `user://restaurante.json`, com backup. A migração copia e valida o estado antes de substituir a partida.

- Bancadas antigas viram mesas de cozinha na mesma posição, com pratos, talheres e refeições preservados. Compre uma mesa de corte no modo construção; a migração não instala um móvel sobre corredores ou outros objetos.
- Panelas antigas conservam suas porções: cada empratamento retira somente uma. Panelas cheias antigas da mochila podem ser erguidas pelas ações da mesa de cozinha e apoiadas nela.
- Preparo no fogão conserva progresso e rendimento antigo. Empratamento antigo é cancelado sem consumo, mantendo panela e pratos na origem.
- Qualidade, queima, ingredientes adicionados, panela apoiada, mãos e tarefas manuais integram o estado salvo.
- Talheres antigos continuam preservados e podem ser retirados da mesa; não são exigidos nas partidas novas.

## Validação

Executar da pasta `godot`:

```sh
node qa/Regras.cjs
node qa/rua-horario.test.cjs
node qa/movimento.test.cjs
node qa/layout.test.cjs
node qa/preview-cache.test.cjs
XDG_CONFIG_HOME=/tmp/esquinas-config XDG_DATA_HOME=/tmp/esquinas-teste XDG_CACHE_HOME=/tmp/esquinas-cache godot --headless --audio-driver Dummy --script res://qa/FluxoCozinhaUI.gd
```

`fluxo-cozinha.test.cjs` cobre transações, mãos ocupadas, reconhecimento, cancelamento, migração, conservação e porção individual. A fixture v9 foi gerada com o código anterior e é independente da versão atual. `FluxoCozinhaUI.gd` percorre os controles Godot e verifica inventário ativo e construção pausada. `CozinhaUI.gd` aponta para esse novo teste.

As antigas suítes `qa/regras/kitchen.test.cjs` e `quality.test.cjs` descrevem a cozinha anterior; não fazem parte do executor atual. Casos aplicáveis de qualidade e queima são cobertos pela suíte física. Os cenários de paciência, reputação e garçom usam fixtures de refeições para isolar esses sistemas da duração de produção. O percurso antigo `qa/percursos.js` só roda com `Verificar.gd -- --percursos-antigos`.

Testado neste ambiente com Godot **4.6.3 Linux**, Node.js e extensão QuickJS incluída. A versão **4.7.2** informada pelo proprietário, Windows e avaliação visual/humana de um dia completo ainda exigem teste no ambiente correspondente.

# Cozinha: transporte somente nas mãos

Atualização somente na Godot. Não há mochila, slots do jogador, barra de inventário ou atalhos de seleção. O jogador transporta **uma unidade por vez**, em suas mãos. O desenho representa o item realmente carregado.

## Início mobiliado

- Mãos vazias e nenhum inventário do jogador.
- Geladeira da cozinha com 30 arroz, 30 legumes e 30 frango cru.
- Uma panela instalada no fogão, sem panelas extras na mochila ou nas mãos.
- Doze pratos limpos na mesa de cozinha, destinada ao empratamento.
- Mesas, cadeiras e disposição da cozinha preservados.

## Preparar e servir

1. Clique na geladeira: o personagem se aproxima e abre seu inventário de dez espaços. Clique num ingrediente para retirar uma unidade; o painel fecha e o item aparece nas mãos. O tempo continua passando enquanto o armazenamento estiver aberto.
2. Frango cru e legumes inteiros podem ser cortados na mesa de preparo. Um clique aproxima e inicia dois segundos de corte. A versão cortada fica nas mãos, com a qualidade preservada. Arroz dispensa corte.
3. Clique no fogão para adicionar o ingrediente carregado à panela. Volte à geladeira para o próximo ingrediente. Não há consumo de um inventário oculto nem abastecimento automático.
4. A combinação exata identifica a receita: arroz + legumes cortados; dois legumes cortados; arroz + frango cortado. Com as mãos vazias, use Cozinhar. Cada preparo novo rende uma porção.
5. Retire a panela pronta antes de queimar. Ela ocupa as mãos e para de perder qualidade pelo calor. Apoie na mesa de cozinha.
6. Emprate uma porção usando os pratos limpos instalados, sem talher. Pegue o prato nas mãos e clique na mesa/cliente compatível para servir. O garçom continua buscando pratos prontos na mesa de cozinha.
7. Retire a panela vazia da mesa para reinstalar no fogão. Recolha um prato sujo por vez nas mãos, lave na pia e reponha na mesa de cozinha.

Mãos ocupadas impedem retirar outro item. Para liberar as mãos, use Guardar item das mãos no painel da geladeira/armazenamento compatível ou apoie panela/prato na mesa de cozinha. Geladeiras aceitam os ingredientes e itens transportáveis; a prateleira mantém o armazenamento seco. Compras de utensílios no computador vão às mãos e exigem que estejam livres. O recebimento também entrega uma unidade por vez às mãos.

Corte pode ser cancelado sem consumo; afastar-se pausa o trabalho manual. Corte e empratamento impedem transferir o item durante a tarefa. Construção, outros menus e perda de foco mantêm suas pausas anteriores. Inventários de armazenamento continuam sem pausar a simulação.

## Persistência

Formato 12, chave `entre-restaurante-12`, com leitura das chaves anteriores. O arquivo Godot continua `user://restaurante.json`, com backup.

A migração valida uma cópia do estado e transfere os itens dos antigos slots para os armazenamentos, preservando quantidade, qualidade, utensílios e porções. Se todos os armazenamentos estiverem cheios ou ausentes, os excedentes permanecem em registros de recuperação de migração: são acessíveis pelo painel da geladeira e saem uma unidade por vez para as mãos. Não há inventário de transporte adicional nem uso desses registros pelo gameplay normal. Saves inválidos não substituem a partida atual.

Uma tarefa antiga de corte baseada em slots é cancelada sem consumir os ingredientes preservados. Preparos no fogão, panela apoiada e comida transportada são conservados. Pratos antigos em trânsito são convertidos para as mãos do jogador; cargas dos funcionários mantêm sua lógica.

## Verificação

Na pasta `godot`, usando Godot 4.7.2 e dados de teste:

```sh
node qa/Regras.cjs
XDG_CONFIG_HOME=/tmp/maos-config XDG_CACHE_HOME=/tmp/maos-cache XDG_DATA_HOME=/tmp/maos-teste godot --headless --audio-driver Dummy --script res://qa/MaosUI.gd
```

`maos.test.cjs` cobre três receitas, frango/legumes cortados, conservação, cancelamento, mãos ocupadas, serviço manual, garçom, pagamento, abandono, limpeza, compras, entregas e limites de queima. `maos-migracao.test.cjs` cobre estados antigos v9/v11, armazenamento cheio, recuperação, estados inválidos e panelas com porções/qualidade.

`MaosUI.gd` percorre os cliques reais na geladeira, mesa de corte, fogão e empratamento, incluindo o retorno à geladeira após adicionar o primeiro ingrediente. `CozinhaUI.gd`, `FluxoCozinhaUI.gd`, `InventarioUI.gd` e `ItemNaMaoUI.gd` são entradas para esse fluxo atual. A infraestrutura compartilhada está em `UIBase.gd`.

Menus, construção do fogão, cadeiras, movimento e integração geral também foram verificados em modo sem janela na Godot 4.7.2 Linux. Testes antigos que pressupõem cinco slots ou ingredientes na mochila não fazem parte do executor atual; satisfação, atendimento e garçom são cobertos no ciclo novo.

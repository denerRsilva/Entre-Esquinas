# Testes nativos

Na raiz do repositório:

```sh
python scripts/verificar-migracao.py
scripts/testar-migracao.sh
```

Requer Godot 4.6.3 e `rg`. O runner usa diretórios temporários isolados para os salvamentos e reprova erros GDScript, falhas de asserção ou término anormal. Os logs ficam no caminho informado ao terminar. `GODOT_BIN` permite selecionar o executável e `QA_TIMEOUT_SECONDS` altera o limite por suíte.

As 56 suítes padrão cobrem criação de partidas; mapa e inventários; qualidade, receitas e conservação; salvamentos dos formatos 4–12; movimento e portais; construção; clientes/garçom; administração e dias completos; cozinha; simulação; câmera; interações; composição visual; ícones; controlador; menus; fluxo geladeira → corte → panela → empratamento → cliente → louça → pia; compras/equipe/horários; edição da planta; conversas; e recuperação de salvamentos em disco.

As fixtures em `referencia-migracao/*.json` registram os resultados do motor anterior e são comparadas com os módulos GDScript. As referências e geradores JavaScript foram removidos após a validação; podem ser consultados no histórico Git, incluindo o commit `0205aa0`. Os testes antigos que dirigiam a VM foram substituídos, sem depender de Node.js ou QuickJS.

Exemplo de suíte isolada:

```sh
scripts/testar-migracao.sh FluxoCompletoNativoUI SalvamentoDiscoNativoUI
```

`ContratacaoUI` testa contratação real pelo menu, crescimento, serviço,
conservação do pagamento, pausa, persistência, migração da equipe antiga e
rejeição de vínculos inválidos. `--capture` gera capturas para revisão visual.

`MenuInicialUI` verifica os dois botões iniciais, confirmação de novo jogo,
slot único, retomada em nova sessão, migração do slot legado ativo e respectivos
backups, fallback de saves antigos inválidos e erro de carregamento sem perda.

`InicioUI` testa kit, novas receitas pelo fluxo físico, atendimento/pagamento,
comércio presencial, estoque limitado/persistido, bloqueio sem saldo/espaço,
reposições, aprendizado da canja, nutrição, arte nativa 32px e saves anteriores.

`AnotarPedidosUI` clica no rosto dos clientes nas oito cadeiras, verifica
comandas individuais, ausência de duplicação, três clientes próximos,
persistência e seleção com diferentes zooms em tela compacta.

`PlaytestDoZeroUI` inicia Novo jogo e usa eventos de mouse pelo Viewport, sem
acionar callbacks de botões diretamente. Percorre cardápio, cozinha, chegadas
naturais, anotação com barra, entrega, pagamento, higiene, pia, mercador e
salvamento. A semente fixa torna reproduzível a recusa de uma cadeira suja.
Cópias separadas verificam anotação salva, cancelamento e ausência de duplicação.


`AuditoriaVisualAlimentosUI` percorre as duas receitas iniciais com mouse nativo,
cruza o cadastro inteiro de alimentos com o compositor e confere a largura dos
pratos. Com `--pixels`, exige renderizador gráfico e compara capturas com/sem o
alimento para verificar pixels visíveis, em mão/fogão/estação. `--phone` usa
960 × 432. A bateria headless verifica o fluxo e catálogo; não mede pixels.

`AuditoriaBalanceamento` roda separadamente e exporta projeções de fórmulas em
`/tmp/auditoria-balanceamento.json`. Não simula trabalho físico, estoque ou erro
humano; não faz parte das regressões. Método e limites estão em
[docs/auditoria-playtest-53.md](../../docs/auditoria-playtest-53.md).

# Cozinha inicial — .57

Novo jogo usa a disposição enviada em 18/11/2026. Coordenadas da grade:

| Objeto | X | Y |
|---|---:|---:|
| Fogão | 15 | 8 |
| Preparo/corte | 17 | 8 |
| Geladeira | 19 | 7 |
| Pia | 20 | 8 |
| Lixo | 22 | 8 |
| Empratamento | 15 | 11 |
| Estante de panelas | 19 | 11 |

O salão mantém as duas mesas inferiores da referência (6,11 e 11,12),
cada uma com quatro cadeiras. A parede ao lado do fogão foi retirada da
renderização, colisão, navegação e reserva da construção na planta de cômodo
único. Paredes externas e plantas históricas de vários cômodos permanecem.

Só a criação de campanha reposiciona móveis. Carregar mantém a organização
que o jogador salvou; o espaço da divisória também fica aberto nessas partidas
de cômodo único. Nenhum reset de estoque, dinheiro ou progressão ao carregar.
Os 50 moradores e os demais parâmetros da .56 permanecem. Arte não alterada.

Validação em Linux/Godot: Novo jogo, as duas receitas iniciais e canja, servir,
comércio e salvar/carregar pelo fluxo InicioUI; captura renderizada do salão;
navegação e construção na área liberada. APKs universal e ARM64 em build/Android.

Também passaram Populacao50UI, TelaExpandidaUI, AuditoriaRegressoes,
RegrasNativas, MovimentoNativo, ConstrucaoNativa, SalvamentoDiscoNativoUI e
PlaytestDoZeroUI, além das auditorias de migração e de arte.
Os APKs .57/21257 têm a mesma assinatura anterior, integridade ZIP e
arquiteturas conferidas. Os arquivos de execução extraídos do APK universal
passaram InicioUI com zero falhas; só o harness de QA foi acrescentado.
Isso valida o conteúdo exportado em Linux, sem teste físico em Android.
Hashes e detalhes em [cozinha-inicial-57-apks.json](cozinha-inicial-57-apks.json).

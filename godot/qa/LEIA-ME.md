# Testes nativos

Na raiz do repositório:

```sh
python scripts/verificar-migracao.py
scripts/testar-migracao.sh
```

Requer Godot 4.6.3 e `rg`. O runner usa diretórios temporários isolados para os salvamentos e reprova erros GDScript, falhas de asserção ou término anormal. Os logs ficam no caminho informado ao terminar. `GODOT_BIN` permite selecionar o executável e `QA_TIMEOUT_SECONDS` altera o limite por suíte.

As 52 suítes padrão cobrem criação de partidas; mapa e inventários; qualidade, receitas e conservação; salvamentos dos formatos 4–12; movimento e portais; construção; clientes/garçom; administração e dias completos; cozinha; simulação; câmera; interações; composição visual; ícones; controlador; menus; fluxo geladeira → corte → panela → empratamento → cliente → louça → pia; compras/equipe/horários; edição da planta; conversas; e recuperação de salvamentos em disco.

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

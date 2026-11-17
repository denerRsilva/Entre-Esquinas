#!/bin/sh
# Headless migration checks must fail on GDScript errors, even when a QA scene
# accidentally reports FALHAS: 0 after a failed method call.
set -eu
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
qa_run=$(mktemp -d /tmp/esquinas-migracao.XXXXXX)
if [ "$#" -eq 0 ]; then
  set -- PartidaNativa RegrasNativas ArmazenamentoNativo ConservacaoNativa MigracaoSaveNativa MovimentoNativo ConstrucaoNativa AtendimentoNativo AdministracaoNativa CozinhaNativa SimulacaoNativa CameraNativa InteracoesNativas CenaNativa ComidaInterfaceNativa SessaoCompletaNativa AplicacaoNativaUI FluxoCompletoNativoUI AdministracaoCompletaUI ConstrucaoCompletaUI EnquadramentoConstrucaoUI ArteBancadasUI BancadasPiskelUI CatalogoSecoesUI PolimentoSalaoUI OciosidadeGarcomUI FluxoImersaoUI DesempenhoGarcomUI OtimizacaoInterfaceUI BarrasAnimadasUI ComandasUI LoucaEmpilhadaUI PiaTarefasUI RefugioUI CidadeUI ContratacaoUI MenuInicialUI InicioUI AnotarPedidosUI HigieneUI AssentosClientesUI TelaExpandidaUI InterfaceLimpaUI PratosEstoqueUI TamanhoItensUI BancadasEmpratamentoUI SlotsEmpratamentoUI ApoioPanelasUI MesasModularesUI AuditoriaRegressoes NovidadesTavernaUI FluxoBancadasUI SocialNativo SalvamentoDiscoNativoUI
fi
for qa_case in "$@"; do
  qa_name=${qa_case%.gd}
  qa_log="$qa_run/$qa_name.log"
  qa_status=0
  XDG_DATA_HOME="$qa_run/data-$qa_name" XDG_CACHE_HOME="$qa_run/cache" \
    timeout "${QA_TIMEOUT_SECONDS:-300}" "${GODOT_BIN:-godot}" --headless --path "$project_root/godot" \
    --script "res://qa/$qa_name.gd" > "$qa_log" 2>&1 || qa_status=$?
  if [ "$qa_status" -ne 0 ] || rg -q 'SCRIPT ERROR|^ERROR:|FALHOU|FALHAS: [1-9]' "$qa_log"; then
    cat "$qa_log"
    printf 'FALHOU %s (log: %s)\n' "$qa_name" "$qa_log"
    exit 1
  fi
  printf 'PASSOU %s\n' "$qa_name"
done
printf 'Logs: %s\n' "$qa_run"

# Validação final da migração

Atualização da limpeza: o APK atual é [EntreEsquinas.apk](../build/Android/EntreEsquinas.apk). A cópia idêntica `-gdscript` e seu checksum foram removidos; nomes nas validações abaixo são históricos.

Godot 4.6.3 Standard, Linux, 14/11/2026. Executado em três lotes com diretórios de dados isolados; 22 suítes aprovadas, sem erros GDScript nos logs.

- PartidaNativa
- RegrasNativas
- ArmazenamentoNativo
- ConservacaoNativa
- MigracaoSaveNativa
- MovimentoNativo
- ConstrucaoNativa
- AtendimentoNativo
- AdministracaoNativa
- CozinhaNativa
- SimulacaoNativa
- CameraNativa
- InteracoesNativas
- CenaNativa
- ComidaInterfaceNativa
- SessaoCompletaNativa
- AplicacaoNativaUI
- FluxoCompletoNativoUI
- AdministracaoCompletaUI
- ConstrucaoCompletaUI
- SocialNativo
- SalvamentoDiscoNativoUI

A auditoria encontrou zero fontes JavaScript, consumidores da ponte e GDExtensions legadas. O projeto iniciou pela cena principal sem a extensão. O APK separado foi exportado, alinhado, assinado e verificado; sua chave corresponde à do APK anterior. A inspeção ZIP não encontrou código JavaScript, biblioteca RestauranteVM ou arquivos de QA.

APK: `build/Android/EntreEsquinas-gdscript.apk`. SHA-256: `build/Android/SHA256SUMS-gdscript`. O APK anterior permaneceu inalterado. Não houve teste em aparelho Android.

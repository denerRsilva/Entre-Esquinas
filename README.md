# Entre Esquinas — Godot

O projeto ativo está em [godot/project.godot](godot/project.godot). Abra com Godot 4.6.3 Standard e siga [as instruções](godot/LEIA-ME.md).

- [Cozinha inicial .57: disposição da referência e sem divisória](docs/cozinha-inicial-57.md).
- [Mapa explorável do refúgio — projeto separado para avaliação](estudos/cidade-refugio32/LEIA-ME.txt).
- [Teste .56: novo jogo com 50 moradores, sem recalibração](docs/teste-50-moradores.md).
- [APK Android universal](build/Android/EntreEsquinas.apk): no GitHub, use **Download raw file**.
- [APK Android ARM64 — menor, para aparelhos compatíveis](build/Android/EntreEsquinas-arm64.apk).
- [Compilação Android](godot/ANDROID.md), [testes nativos](godot/qa/LEIA-ME.md) e [conclusão da migração](docs/MIGRACAO-GDSCRIPT.md).
- [GDD — direção aprovada](GDD.md) e [direção de arte](docs/arte/RESTAURANTE.md).
- [Diretriz de pixel art 32 × 32](docs/DIRETRIZES-ARTE.md) e [exportação de sprites para editar no Aseprite](docs/arte/EXPORTAR-SPRITES.md).
- [Estudos de redesenho em 32px — revisão visual em andamento](docs/arte/redesenho32/LEIA-ME.md).
- [Escala 32px: análise do pacote, redução de peso e primeiro kit nativo](docs/arte/escala32/RELATORIO.md).
- [Novos alimentos: PNGs individuais 32 × 32 para edição](docs/arte/novos-alimentos-32x32.zip).
- [Melhorias .54: balanceamento, refeição da equipe, descanso e clareza visual](docs/melhorias-equilibrio-54.md).
- [Auditoria .53: playtest, alimentos invisíveis, leitura visual e balanceamento](docs/auditoria-playtest-53.md).

O jogo, incluindo regras, interface, controles e composição visual, executa em GDScript. JavaScript, DOM simulado e a extensão QuickJS foram removidos do projeto. As fixtures JSON preservam os resultados anteriores; os testes atuais também são GDScript.

Na raiz do repositório:

```sh
python scripts/verificar-migracao.py
scripts/testar-migracao.sh
```

[Limpeza do projeto](docs/limpeza-arquivos.md): duplicações removidas e originais preservados fora da pasta importada pela Godot.

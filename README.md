# Entre Esquinas — Godot

O projeto ativo está em [godot/project.godot](godot/project.godot). Abra com Godot 4.6.3 Standard e siga [as instruções](godot/LEIA-ME.md).

- [APK Android em GDScript](build/Android/EntreEsquinas-gdscript.apk): no GitHub, use **Download raw file**.
- [APK Android — nome alternativo do mesmo arquivo](build/Android/EntreEsquinas.apk).
- [Compilação Android](godot/ANDROID.md), [testes nativos](godot/qa/LEIA-ME.md) e [conclusão da migração](docs/MIGRACAO-GDSCRIPT.md).
- [GDD — direção aprovada](GDD.md) e [direção de arte](docs/arte/RESTAURANTE.md).
- [Diretriz de pixel art 32 × 32](docs/DIRETRIZES-ARTE.md) e [sprites completas para editar no Aseprite](docs/arte/sprites-completas-para-aseprite.zip).
- [Melhorias .54: balanceamento, refeição da equipe, descanso e clareza visual](docs/melhorias-equilibrio-54.md).
- [Auditoria .53: playtest, alimentos invisíveis, leitura visual e balanceamento](docs/auditoria-playtest-53.md).

O jogo, incluindo regras, interface, controles e composição visual, executa em GDScript. JavaScript, DOM simulado e a extensão QuickJS foram removidos do projeto. As fixtures JSON preservam os resultados anteriores; os testes atuais também são GDScript.

Na raiz do repositório:

```sh
python scripts/verificar-migracao.py
scripts/testar-migracao.sh
```

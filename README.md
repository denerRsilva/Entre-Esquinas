# Entre Esquinas — Godot

O projeto ativo está em [godot/project.godot](godot/project.godot). Abra com Godot 4.6.3 Standard e siga [as instruções](godot/LEIA-ME.md).

- [APK Android em GDScript](build/Android/EntreEsquinas-gdscript.apk): no GitHub, use **Download raw file**.
- [APK anterior preservado](build/Android/EntreEsquinas.apk).
- [Compilação Android](godot/ANDROID.md), [testes nativos](godot/qa/LEIA-ME.md) e [conclusão da migração](docs/MIGRACAO-GDSCRIPT.md).
- [GDD](GDD.md) e [direção de arte](docs/arte/RESTAURANTE.md).

O jogo, incluindo regras, interface, controles e composição visual, executa em GDScript. JavaScript, DOM simulado e a extensão QuickJS foram removidos do projeto. As fixtures JSON preservam os resultados anteriores; os testes atuais também são GDScript.

Na raiz do repositório:

```sh
python scripts/verificar-migracao.py
scripts/testar-migracao.sh
```

# Entre Esquinas — Godot

O projeto ativo está em [godot/project.godot](godot/project.godot). Abra com Godot 4.6.3 Standard e siga [as instruções](godot/LEIA-ME.md).

- [APK Android](build/Android/EntreEsquinas.apk): no GitHub, use **Download raw file**.
- [Compilação e validação Android](godot/ANDROID.md).
- [GDD](GDD.md) e [direção de arte](docs/arte/RESTAURANTE.md).
- Testes: `cd godot` e `node qa/Regras.cjs`; testes nativos descritos em [QA](godot/qa/LEIA-ME.md).

O jogo de navegador e o HTML histórico foram removidos. O JavaScript em `godot/simulacao` permanece necessário: a extensão RestauranteVM executa essas regras com QuickJS dentro da Godot, sem navegador ou servidor. Os arquivos antigos continuam recuperáveis no histórico Git.

# APK Android

O APK de teste fica em `../build/Android/EntreEsquinas.apk`. Baixe o arquivo
completo pelo botão **Download raw file** no GitHub e permita a instalação
de aplicativos dessa origem no Android. O pacote é
`com.entreesquinas.restaurante`, versão `0.21.2-godot.4` (21204).
Requer Android 7.0 ou superior. Tamanho aproximado: 89 MiB.
O SHA-256 está em `../build/Android/SHA256SUMS`.

Esta compilação usa assinatura de depuração, para testes por instalação
direta. Publicação na Play Store exige uma chave de produção própria e AAB.
A chave privada usada nesta compilação não é incluída no repositório.
Uma recompilação com outra chave pode exigir desinstalar a versão anterior;
exporte seu salvamento antes para preservar o progresso.

## Compilar novamente no Linux

Requisitos: Godot 4.6.3 Standard e seus modelos de exportação Android,
JDK 17 ou superior, Android SDK (platform-tools, plataforma 36 e build-tools 36.0.0)
e NDK r28b (`28.1.13356709`). Nas configurações do editor Godot, preencha
os caminhos do Java SDK, Android SDK e da chave de depuração.

Na pasta `godot/`:

```sh
export ANDROID_NDK_ROOT=/caminho/do/android-sdk/ndk/28.1.13356709
sh nativo/fonte/compilar.sh android arm64-v8a
sh nativo/fonte/compilar.sh android armeabi-v7a
sh nativo/fonte/compilar.sh android x86_64
godot --headless --editor --import
mkdir -p ../build/Android
godot --headless --export-debug Android ../build/Android/EntreEsquinas.apk
```

A extensão QuickJS é empacotada nas três arquiteturas, com alinhamento
de 16 KB. O perfil mantém orientação horizontal, modo imersivo e toque
emulando o mouse para os controles existentes. O código vem do commit
`357cf215d00bd9e1d1ef895d4cd23caa5755d601`, com as adaptações Android.

## Validação

As suítes `node qa/Regras.cjs`, `qa/Verificar.gd` e
`qa/EstantePanelasUI.gd` passaram na Godot 4.6.3 Linux.
A assinatura, o manifesto, as três bibliotecas nativas e o alinhamento
do APK foram conferidos com as ferramentas Android.
Ainda é necessário testar instalação, desempenho, áudio e toques num
celular Android; os testes de jogo executados neste ambiente foram em Linux.

## Polimento das interações

Sem item compatível, selecionar um móvel apenas aproxima o personagem, sem
avisos “Traga…” nem ícones de ingredientes nesses avisos. Foram removidos os
atalhos de adicionar ingrediente e retirar panela do fogão e de cortar na
mesa de preparo. As ações continuam pelo clique direto: geladeira → mãos →
mesa de preparo → ingrediente cortado nas mãos → panela. Clique no fogão
para retirar a panela pronta ou a panela vazia sem ingredientes.

## Livro de receitas

O botão **Livro de receitas** fica ao lado de **Opções**. Mostra as três
receitas atuais com quantidades por panela, necessidade de corte, tempo
de cozimento e sequência de empratamento. A consulta pausa o jogo.

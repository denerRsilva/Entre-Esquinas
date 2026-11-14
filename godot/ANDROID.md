# APK Android em GDScript

A compilação nativa fica em `../build/Android/EntreEsquinas-gdscript.apk`; a anterior permanece em `EntreEsquinas.apk`. O SHA-256 está em `SHA256SUMS-gdscript`. No GitHub, baixe o arquivo completo pelo botão **Download raw file**.

Pacote, versão e configurações anteriores foram mantidos: `com.entreesquinas.restaurante`, `0.21.2-godot.18` (21218), Android 7.0+, orientação horizontal e toque emulando mouse. A assinatura de depuração é a mesma do APK anterior. Não é necessário recompilar extensões C/C++ ou QuickJS.

## Exportar

Use Godot 4.6.3 Standard, modelos de exportação Android correspondentes, Java SDK e Android SDK configurados nas preferências do editor. O SDK usado nesta validação tem plataforma 36 e build-tools 36.0.0; Java 21.

```sh
mkdir -p build/Android
godot --headless --path godot --export-debug Android build/Android/EntreEsquinas-gdscript.apk
```

Se executar dentro da pasta `godot/`, use `../build/Android/EntreEsquinas-gdscript.apk` como destino. A exportação usa assinatura de depuração. Publicação em loja requer configuração de assinatura de produção; a chave privada não integra o repositório.

## Validação desta migração

- Auditoria sem JavaScript, consumidores da ponte ou GDExtensions legadas.
- Testes GDScript de regras, paridade com fixtures e fluxos reais dos controles, incluindo cozinha, atendimento, construção, administração e disco.
- APK exportado, assinatura verificada e chave comparada com a versão anterior.
- Conteúdo do APK conferido: nenhum JavaScript, QuickJS ou arquivo de QA.

A execução dos testes ocorreu em Linux/Godot 4.6.3. Instalação, áudio, toque e desempenho do APK ainda precisam de validação em um aparelho Android.

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

## Polimento 0.21.2-godot.5

- Botões com altura mínima de 44 px lógicos e ações dos móveis com legenda visível e alvo mínimo de 144 × 48.
- Livro em coluna única, com nomes e ingredientes por escrito, etapas numeradas e mais espaço entre receitas.
- Avisos posicionados fora da faixa das ações do móvel selecionado.
- Indicadores de calor sem contagem fictícia de 0/1 segundo; corte informa quando está pausado por distância.
- Versão declarada no projeto sincronizada com o APK.

Validação: Regras.cjs, MaosUI, MovimentoUI e Verificar passaram em Linux.
Inspeção de capturas renderizadas em 960 × 700: salão, livro e ações da mesa.
As suítes cobrem cozinha, atendimento, pagamento, lavagem e regras de fechamento;
isso não substitui um playtest contínuo de um dia inteiro nem teste físico Android.

## Livro visual 0.21.2-godot.6

Substitui o livro textual da versão .5: três cartões com arte ampliada do prato,
ícones e quantidades de ingredientes, indicação curta de corte ou uso direto
e ícones de panela, fogo com tempo e prato. Sem parágrafos de instrução.
Conferido em captura renderizada na Godot; fluxo MaosUI passou sem falhas.
A diretriz de priorizar contexto visual está registrada no GDD.

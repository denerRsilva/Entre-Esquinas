# Validação da cozinha 0.13.0

Base: ZIP 0.12.0 indicado pelo proprietário. Implementação autorizada: retirar inventários genéricos de fogão e bancada, instalar equipamentos e louça por ações rápidas, consumir ingredientes da mochila, transportar panela cheia, empratar e disponibilizar pratos à equipe, com feedback visual.

## Testes executados

- `node restaurant.test.cjs` / `node kitchen.test.cjs`: 13 cenários aprovados, cobrindo instalação, fonte de ingredientes, repetição de ações, preparo longe do fogão, mochila cheia, utensílios, empratamento com duração, pausa por distância, porções parciais, área de retirada cheia, cancelamento, saves em andamento, migração real da 0.12.0 e recuperação de excedentes. Inclui garçom, pagamento, coleta e lavagem da louça.
- `node patience.test.cjs`: 15 cenários aprovados. Preservadas etapas, perfis, abandonos, cancelamento e conservação do prato na mão, probabilidades de manifestações e migração de experiência. Os fixtures usam o novo fluxo; a bancada cheia é exercitada com 12 pratos na área física de retirada. A avaliação ao término da refeição usa margem de 0,01 segundo para não depender de arredondamento de ponto flutuante.
- `node calendar-reputation.test.cjs`: 12 cenários aprovados. Preservados calendário, reputação, fechamento e migração. Atualizado o caso de preparo na madrugada para o cozimento híbrido, que agora continua longe do fogão.
- `node ui.test.cjs`: aprovado com DOM/Canvas simulados. Exercita botões reais de instalação, receita, barras acessíveis, retirada de panela, empratamento, retirada de prato sem pedido, armazenamento dividido e pausa dentro de menus.
- Sintaxe dos dois scripts e compilação dos dois scripts embutidos no HTML único: aprovadas.

## Conferência no navegador

Executado no navegador de prévia: início mobiliado, deslocamento ao fogão, receita usando mochila, cozimento com indicador e barra, retirada da panela cheia, deslocamento à bancada, empratamento rápido e confirmação de quatro pratos prontos. Não foi preciso abrir inventário do fogão nem da bancada. As ações de cozinha possuem rótulos visíveis, além dos ícones.

## Persistência e limites

Formato 7 e chave nova; fallback 06/05/04. Migração em cópia preserva os saves originais. Excedentes dos antigos equipamentos ficam em reserva recuperável pelo menu Inventário, sem descarte. Calendário/reputação da 0.12.0 não são reiniciados.

Parâmetros provisórios: 2 segundos para empratar, 12 pratos na área de retirada e 99 pratos limpos instalados. Cozimento conserva 4 porções por lote e os tempos existentes. Empratamento é manual e pausa quando o jogador se afasta; cozinha continua sem presença. Menus e aba oculta pausam a simulação inteira.

Não houve teste em aparelho Android físico nem playtest humano desta versão. O teste no navegador não comprova que a nova experiência seja intuitiva para jogadores novos; esse é o próximo teste recomendado. Não foram alterados preços, receitas, paciência, probabilidades de avaliação ou efeitos de reputação.

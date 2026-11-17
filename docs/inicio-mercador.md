# Começo jogável com mercador

Versão **0.21.2-godot.50**, Android **21250**, GDD **3.4**. Implementa o início
aprovado por Dener com reposição presencial, respeitando o mundo sem computador.

## Nova campanha

Caixa **200**, duas mesas/oito cadeiras, fogão, geladeira, corte/preparo,
empratamento, pia, estante de panelas e lixeira. Duas panelas (fogão e estante),
oito pratos limpos na estação. Ingredientes na geladeira: arroz 12, batata 8,
cenoura 8. Sem funcionário; contratação continua conquistada com a população.
Menu inicial permanece Novo jogo/Carregar jogo e um único slot.

| Receita | Ingredientes por porção | Preço | Cozinhar | Nutrição |
| --- | --- | --- | --- | --- |
| Caldo de batata | 1 batata cortada | 10 | 5s | 4/10 |
| Arroz com cenoura | 1 arroz + 1 cenoura cortada | 14 | 6s | 6/10 |
| Canja, aprendida depois | 1 arroz + 1 cenoura cortada + 1 frango cortado | 20 | 8s | 8/10 |

Corte e empratamento mantêm as tarefas existentes. A panela vazia retorna à mão
ao empratar. Pratos e ingredientes mantêm tamanho entre mão e superfícies.
Livro e **Gestão → Cardápio** mostram a comida pronta, coxas de nutrição (1–10)
e relógios. Cada relógio representa aproximadamente 2s do total de corte +
cozimento + empratamento, arredondado para cima; deslocamentos não entram na
estimativa. Corte melhorado considera seu tempo real. Alimentação coletiva
recebe **nutrição × 5,2 / população** por refeição concluída. Receitas antigas
conservam a contribuição anterior equivalente a nutrição 5.

## Reposição na cidade

Sair pela porta e clicar em **Beto**, no lado direito da rua. O personagem
se aproxima e abre o mercador. A compra só funciona perto dele. Cada amanhecer
repõe **12 arroz, 12 batatas e 12 cenouras**, a 2 por unidade; sobras não acumulam.
É possível comprar uma ou cinco unidades por ação. O menu pausa o tempo.

A entrega na geladeira da taverna está incluída. A compra confere espaço total
antes de cobrar; pode repartir entre geladeiras existentes. Sem saldo, estoque
ou espaço, nenhuma quantidade/dinheiro muda. Não há recebimento, entrega pendente
ou mochila necessária nesse fluxo. Computador e recebimento não são vendidos
no catálogo do refúgio; computadores legados ficam preservados e inativos.
Cardápio e preços são administrados pelo menu, sem equipamento obrigatório.

A primeira caravana ocorre no **dia 4**, depois a cada quatro dias. Neste trecho,
**Nina intermedeia** as mercadorias de viajantes usando a personagem já existente;
não é uma população nova nem uma arte de viajante definitiva. Vende até seis
frangos a 4 cada e ensina canja por **30**, uma única vez. Aprendizado e estoque
persistem. Gestão → Cidade informa o próximo dia de caravana. Comprar a receita
a inclui no livro e no cardápio; é possível ajustar sua oferta depois.

Agenda, preços, limites, custo da receita e nutrição são **parâmetros de teste**.
Não há balanceamento final comprovado. Carpinteiro, ferro-velho, artesão, vendedor
de decoração e peças especiais de viajantes permanecem para próximos trechos;
o modo construção ainda mantém a compra provisória de móveis.

## Compatibilidade e arte

O kit é aplicado exclusivamente ao criar a campanha. Carregar uma partida antiga
não reduz caixa, mesas, cadeiras, estoque ou utensílios e não troca receitas.
O mercador legado oferece arroz 12/legumes 12/frango 6 para manter seu cardápio
operante. Entregas antigas são preservadas; a nova compra não cria outras.

O formato externo de save continua 12. `startKit.version=1` identifica o início
novo e suas receitas aprendidas; `market.version=1` guarda dia, estoque local e
estoque de caravana. Salvar/carregar no mesmo dia não reabastece a loja. O
amanhecer repõe o limite; backup de preparação restaura o estoque daquele
momento, sem duplicar compras. Dinheiro, ingredientes, refeições, pratos e panelas
continuam sujeitos às verificações de conservação.

[Arte nova](../godot/arte/inicio-32.png): nove células nativas **32 × 32** para
batata, batata cortada, cenoura, cenoura cortada, três pratos e dois indicadores.
Fonte reproduzível: `godot/qa/GerarArteInicio.gd`. Nenhum atlas anterior foi
editado ou reduzido. Personagens e o restante dos estudos continuam aguardando
a edição do proprietário conforme a diretriz artística.

## Validação

As **53 suítes padrão passaram**. Após o ajuste visual dos indicadores e do
mercador, as suítes específicas de início/interface/salvamento foram repetidas.
`InicioUI` cozinha as receitas, serve um morador com pagamento, visita o mercador
pelo mapa e compra pelo botão Godot. Confere falta de estoque/saldo/espaço sem
cobrança, reposição ao amanhecer, persistência, canja, contribuição nutritiva,
conservação e compatibilidade. Rejeita corrupção de estoque, alimentos,
refeições e aprendizado. Capturas em Compatibility; sem teste Android físico.

[Salão](arte/inicio-salao.png) · [Livro](arte/inicio-receitas.png) ·
[Mercador](arte/inicio-mercador.png) · [Livro em tela compacta](arte/inicio-receitas-telefone.png) ·
[Mercador em tela compacta](arte/inicio-mercador-telefone.png).

# Bancadas, partidas e sinais da cozinha

## Construção e bancadas

As bancadas usam recortes da prancha de madeira aprovada, com câmera fixa,
acabamento frontal e contornos externos. Peças vizinhas informam suas conexões
nas quatro direções; as bordas internas são retiradas. A rotação preserva a
perspectiva da madeira e não gira a fachada como uma imagem plana.

Selecionar um kit destaca em verde as mesas e bancadas vazias compatíveis,
mesmo antes de apontar uma posição. Uma bancada aceita um kit de corte ou de
empratamento. Instalar ferramentas preserva ID, posição, rotação e ocupação
original. Retirar o kit devolve a bancada original. Os preparos e a conservação
de pratos/ingredientes seguem as mesmas regras das mesas.

## Três partidas

Em Opções → Salvar e carregar há três espaços independentes. Cada um permite
continuar uma partida existente ou começar uma nova quando vazio. A tela
inicial também oferece continuar os espaços já gravados. O salvamento antigo
é lido como a primeira partida.

“Dormir e salvar” fecha o dia, aplica o fechamento financeiro existente e grava
o início do dia seguinte. É necessário concluir o serviço e os preparos antes
de dormir. A virada natural às 02:00 também grava automaticamente quando o
jogo consegue concluir o dia. O salvamento manual continua disponível.
A importação de arquivo grava no espaço selecionado; a gravação física mantém
a proteção existente de arquivo temporário e backup.

Pedidos concluídos sem referências ativas são compactados quando o histórico
chega a 4.500 registros. São mantidos os 200 recentes e todos os pedidos ativos
ou referenciados por clientes, fila de pratos e personagens que os transportam.
Vendas, relatórios, refeições e reputação permanecem nos seus próprios totais.
A compactação ocorre no fechamento e na leitura/escrita do save.

## Sinais durante o jogo

- Garçom com prato e seta acima do personagem; pedido “A caminho da mesa”.
- Ingrediente e movimento de faca durante o corte.
- Vapor durante o cozimento e sinal sonoro periódico discreto.
- Brilho oscilante no ponto ideal.
- Alerta pulsante, fumaça e sons de aviso conforme a comida passa do ponto.

Os sons desta etapa são sinais sintetizados; não são gravações de utensílios.

## Verificação

`NovidadesTavernaUI` cobre destaque sem hover, instalação/retirada, conexões,
ocupação, persistência, três partidas, sono, sons, brilho, alerta e histórico
com mais de 5.000 pedidos, incluindo prato cancelado ainda em transporte.
`FluxoBancadasUI` executa o ciclo real de retirar ingrediente, cortar, cozinhar,
empratar, atender, receber pagamento e lavar louça usando bancadas equipadas.

As demais suítes de regressão verificam compatibilidade com os sistemas
anteriores. Os testes de interface são headless; a avaliação visual e auditiva
em um aparelho Android continua sendo uma etapa de aceitação.

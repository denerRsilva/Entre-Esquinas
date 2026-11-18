# Mesa de trabalho e ferramentas

Uma mesa de trabalho ocupa 2 × 1 células e usa uma única base visual de
76 × 58 pixels. A referência é a antiga mesa de preparo/corte, sem os objetos
do tampo. Mesa vazia, corte e empratamento compartilham `MesaTrabalho.gd`;
somente a camada de ferramentas muda. Catálogo e cenário usam essas mesmas cenas.

No modo construção:

- Mesa vazia: $55.
- Kit de corte e preparo: $35; instalar sobre qualquer célula da mesa vazia.
- Kit de empratamento: $35; instalar da mesma forma.
- Um kit por mesa. Retirar o kit permite escolher outra função.
- Mover a mesa transporta seu kit e seu conteúdo. Retirar o kit exige concluir
  o trabalho e recolher os itens apoiados. O reembolso separa mesa e ferramentas.

Os tipos internos `prep` e `kitchen` continuam identificando as funções para
as regras de cozinha e para compatibilidade com os saves existentes. A compra
expõe apenas `worktable` e os dois kits. Instalar ferramentas muda a função do
mesmo objeto, mantendo ID, posição e ocupação; não cria um móvel sobreposto.
Saves antigos já representam mesas equipadas e mantêm ingredientes, pratos,
panelas e trabalhos em andamento. Saves novos também registram `tableKit`.

As bancadas em L/U de [estudo preservado](arte/fontes-preservadas/modular/mesas-bancadas-base-comum-concept.png)
são um estudo atualizado para alinhar madeira, perspectiva e altura da base
à mesa compartilhada. Ainda não substituem o atlas das bancadas do cenário:
essa prancha não é um atlas com encaixes de 32 × 32 validados.

Validação: `scripts/testar-migracao.sh MesasModularesUI` testa compra pela
interface, encaixe, erros sem cobrança, movimento, corte real, troca de kit,
reembolso e salvamento, incluindo corte em andamento e mesas antigas.

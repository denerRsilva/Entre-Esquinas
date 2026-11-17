# Diretrizes do projeto

- A direção de arte obrigatória é pixel art com unidade de **32 × 32 pixels**.
  Sprites individuais e quadros de personagem usam canvas 32 × 32. Elementos
  maiores são compostos por tiles 32 × 32, com a mesma densidade de pixels.
- Leia [docs/DIRETRIZES-ARTE.md](docs/DIRETRIZES-ARTE.md) antes de criar,
  substituir, recortar ou integrar arte. Pranchas ampliadas existentes são
  materiais provisórios; filtro nearest ou redução na Godot não os torna arte
  nativa 32 × 32.
- Preserve os originais e aguarde os arquivos editados pelo proprietário antes
  de substituir as sprites exportadas nesta revisão. Alterar dimensões exige
  atualizar recortes, frames e pivôs, sem alterar automaticamente os saves.

- A premissa vigente é o **refúgio no apocalipse zumbi**, conforme o GDD 3.0 e
  `docs/primeiro-ciclo-refugio.md`; a origem nuclear anterior foi substituída.
- Alimentação, energia e moral são status de 0 a 100. Hordas substituem o jantar
  a cada 3 a 5 dias sem penalidade pela refeição suspensa. Não há combate
  controlável; a defesa tem apresentação animada. Duas derrotas levam ao game
  over, com retomada da preparação pelo salvamento.
- Desenvolver em trechos jogáveis para avaliação de Dener antes de ampliar a
  campanha. Parâmetros do primeiro ciclo são provisórios; preservar partidas
  antigas e os três slots de salvamento.

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

- A premissa vigente é o **refúgio no apocalipse zumbi**, conforme o GDD 3.1;
  a origem nuclear anterior foi substituída. `docs/primeiro-ciclo-refugio.md`
  registra o protótipo .46 e não prevalece sobre as regras aprovadas no GDD.
- Alimentação, energia e moral são **três barras coletivas da cidade**, de 0 a 100.
  Hordas substituem o jantar a cada 3 a 5 dias sem penalidade pela refeição suspensa. Não há combate
  controlável; a defesa tem apresentação animada. **Duas derrotas consecutivas**
  levam ao game over. **Uma vitória zera a sequência de derrotas e restaura o
  estado normal**. A retomada deve permitir refazer a preparação pelo salvamento.
- A versão .47 implementa valores coletivos e derrotas consecutivas, com
  migração dos saves .46. As barras ficam somente em **Gestão → Cidade**,
  sem painel permanente no cenário. Ver `docs/cidade-menu-coletivo.md`.
- Desenvolver em trechos jogáveis para avaliação de Dener antes de ampliar a
  campanha. Parâmetros do primeiro ciclo são provisórios; preservar partidas
  antigas e os três slots de salvamento.

#!/usr/bin/env python3
"""Package untouched sources plus Godot exports. Does not edit image pixels."""
import csv
import hashlib
import io
import json
from pathlib import Path
import struct
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
EXPORT = Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/entre-esquinas-sprites")
DEST = Path(sys.argv[2]) if len(sys.argv) > 2 else EXPORT.parent / "sprites-completas-para-aseprite.zip"
PREFIX = "Entre-Esquinas-sprites/"


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True).strip()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def csv_text(rows, columns):
    out = io.StringIO(newline="")
    writer = csv.DictWriter(out, fieldnames=columns)
    writer.writeheader()
    writer.writerows(rows)
    return out.getvalue().encode("utf-8-sig")


def main():
    manifest = json.loads((EXPORT / "recortes-e-renderizacoes.json").read_text())
    assert len(manifest) >= 541, "Execute primeiro exportar-sprites.gd"
    assert len({entry["file"] for entry in manifest}) == len(manifest)
    tracked = set(git("ls-files").splitlines())
    files = {}
    originals = []
    sources = list((ROOT / "godot").rglob("*")) + list((ROOT / "docs/arte/fontes-preservadas").rglob("*"))
    for path in sorted(sources):
        rel = path.relative_to(ROOT).as_posix()
        if path.suffix.lower() not in {".png", ".svg"} or "/.godot/" in rel or "/qa/" in rel:
            continue
        arc = "01-originais/" + rel
        data = path.read_bytes()
        width, height = struct.unpack(">II", data[16:24]) if path.suffix == ".png" else ("", "")
        files[arc] = path
        originals.append({"arquivo": arc, "origem": rel, "largura": width, "altura": height,
                          "sha256": digest(data), "no_git": rel in tracked,
                          "tipo": "PNG original" if path.suffix == ".png" else "SVG original"})
    assert any(row["origem"] == "godot/arte/taverna/arquitetura.png" for row in originals)
    assert all(any(row["origem"] == "godot/mundo/" + name + ".png" for row in originals)
               for name in ["restaurant", "street", "stock"])
    for path in sorted(EXPORT.rglob("*")):
        if path.is_file():
            files[path.relative_to(EXPORT).as_posix()] = path
    refs = {"manequim-estudo-sprites.png": "docs/arte/manequim-estudo-sprites.png",
            "cozinheira-estudo-sprites.png": "godot/arte/taverna/cozinheira.png",
            "garcom-estudo-sprites.png": "godot/arte/taverna/garcom-estudo-sprites.png",
            "alimentos-estudo-sprites.png": "godot/arte/taverna/alimentos.png",
            "direcao-aprovada.png": "docs/arte/direcao-aprovada.png"}
    for i in [1, 2, 3]:
        name = f"cliente-0{i}-estudo-sprites.png"
        refs[name] = "godot/arte/taverna/" + name
    for name, source in refs.items():
        path = ROOT / source
        assert path.is_file(), name
        files["04-referencias/" + name] = path
    for path in sorted((ROOT / "docs/arte/tilesets").iterdir()):
        if path.suffix in {".png", ".md"}:
            files["04-referencias/tilesets/" + path.name] = path
    for name, source in {"arquitetura.png": "arquitetura.png", "decoracao-vila.png": "decoracao.png", "moveis-cozinha.png": "moveis.png"}.items():
        files["04-referencias/tilesets/" + name] = ROOT / "godot/arte/taverna" / source
    source_files = []
    for folder in ["godot/moveis", "godot/personagens", "godot/mundo"]:
        source_files.extend(p for p in (ROOT / folder).iterdir() if p.suffix in {".gd", ".tscn", ".tres"})
    for rel in ["godot/simulacao/nativa/Alimentos.gd", "godot/simulacao/nativa/Cena.gd",
                "godot/simulacao/nativa/catalogo.json", "godot/simulacao/nativa/icones-controle.json",
                "godot/arte/taverna/recortes.json", "godot/arte/taverna/recorte.gdshader",
                "godot/arte/modular/Modulos.tres", "godot/interface/Comandas.gd",
                "godot/interface/ArteBarras.gd", "godot/interface/IconesAcao.gd",
                "godot/LICENCAS.txt", "scripts/exportar-sprites.gd", "scripts/empacotar-sprites.py",
                "AGENTS.md", "GDD.md", "docs/DIRETRIZES-ARTE.md"]:
        source_files.append(ROOT / rel)
    for path in source_files:
        files["05-fontes/" + path.relative_to(ROOT).as_posix()] = path

    names = {
        "moveis": ["fogao-aceso-estudo", "fogao-apagado", "geladeira-fechada", "geladeira-aberta",
                   "corte-estudo-antigo", "empratamento-estudo-antigo", "mesa-vazia-estudo", "mesa-salao",
                   "cadeira-frente", "cadeira-costas", "cadeira-lateral", "cadeira-lateral-variante",
                   "armario-vazio", "armario-louca", "estante-vazia", "estante-panelas-estudo", "pia", "lixeira",
                   "pilha-pratos-estudo", "prato-limpo-estudo", "prato-sujo-estudo", "panela-vazia", "tampa",
                   "panela-queimada", "prateleira-potes", "suporte-utensilios", "balcao-estudo", "banco",
                   "chaleira", "frigideira"],
        "decoracao": ["lanterna-acesa", "lanterna-apagada", "vela", "vaso", "planta-pendente", "flores",
                      "tapete", "capacho", "toalha-estudo", "bandeira", "placa-perigo", "quadro-avisos",
                      "barraca-produtos", "barraca-vazia", "banca-ferro-velho", "toldo", "engrenagem", "tubos",
                      "caixa-vazia", "caixa-legumes", "barril", "saco-arroz", "caixa-ferramentas", "pecas-geladeira",
                      "floreira", "ruina", "banco-externo", "balde", "vassoura", "lenha"]}
    index = []
    for entry in manifest:
        path = entry["file"]
        assert (EXPORT / path).is_file(), path
        label = entry.get("title", entry.get("action", Path(path).stem))
        parts = Path(path).parts
        if len(parts) == 3 and parts[0] == "02-recortes" and parts[1] in names and Path(path).stem.isdigit():
            label = names[parts[1]][int(Path(path).stem)]
        index.append({"arquivo": path, "nome": label, "tipo": entry["kind"],
                      "largura": entry["size"][0], "altura": entry["size"][1],
                      "origem": entry.get("source", entry.get("scene", "")),
                      "recorte_original": json.dumps(entry.get("sourceRect", [])),
                      "pivo": json.dumps(entry.get("pivot", [])), "vazio_intencional": entry["empty"]})

    generated = {
        "originais.json": json.dumps({"base_game_commit": git("rev-parse", "HEAD"), "originals": originals}, ensure_ascii=False, indent=2).encode(),
        "originais.csv": csv_text(originals, ["arquivo", "origem", "largura", "altura", "sha256", "no_git", "tipo"]),
        "indice-sprites.csv": csv_text(index, ["arquivo", "nome", "tipo", "largura", "altura", "origem", "recorte_original", "pivo", "vazio_intencional"]),
    }
    readme = f"""# Sprites do Entre Esquinas para editar no Aseprite

Diretriz: pixel art em **32 × 32 pixels reais por célula/quadro**. Personagem
com 4 direções × 4 quadros: folha final 128 × 128. Objetos maiores são compostos
por células 32 × 32, mantendo a densidade e a perspectiva do projeto.

Este pacote conserva a arte ATUAL, ainda ampliada/provisória. Nada foi reduzido,
redesenhado ou substituído no jogo. A base é o commit {git('rev-parse', '--short', 'HEAD')}.

## Pastas

- **01-originais**: {len(originals)} imagens/fontes PNG e SVG, copiadas byte a byte
  de godot/arte, godot/personagens, godot/mundo e docs/arte/fontes-preservadas. Inclui atlas atuais, materiais
  antigos e variantes locais existentes (identificadas por no_git em originais.csv).
- **02-recortes**: partes extraídas sem reamostragem dos atlas: pisos, paredes,
  móveis, decoração, ingredientes, receitas, pratos, bancadas e frames de
  personagem. Há também os ícones SVG atuais rasterizados para edição em PNG.
- **03-renderizados**: aparência real em escala nativa da Godot, incluindo todas
  as peças do catálogo e suas quatro orientações, personagens, objetos
  desenhados por código, exterior, panelas, talher, estrelas e estados dos pratos.
- **04-referencias**: manequim, estudos e pranchas de tilesets. Não confundir
  estudos antigos com peças atualmente instaladas no jogo.
- **05-fontes**: cenas, SpriteFrames, TileSet, scripts e diretrizes que explicam
  recortes, pivôs, encaixes e desenho procedural. Não é uma cópia completa do jogo.

## Por onde começar

Pisos atuais: 02-recortes/pisos/madeira-taverna.png e ceramica-cozinha.png
(128 × 128 originais). Paredes: 02-recortes/paredes, também com o SVG original.
Outros mapas: pisos/mapas-40px contém cada tile distinto de rua/estoque/mapa
antigo; tiles-de-mapas.json conserva a associação de cada célula ao PNG.

Móveis: use indice-sprites.csv para encontrar o nome de cada recorte. A mesa
de trabalho atual é mesa-trabalho-atual.png; os desenhos antigos de corte e
empratamento do atlas permanecem como estudos identificados. Bancadas atuais:
01-originais/godot/arte/modular/bancadas-piskel.png, recortes em bancadas e
exportações counterThin/counterWide em 03-renderizados/moveis.

Personagens: fontes ampliadas em 01-originais/godot/arte/taverna; recortes de
quadros em 02-recortes/personagens. As folhas renderizadas têm células 96 × 96
com margem, **não são sprites prontas em 32 × 32**. Os frames são exportados
na ordem real do SpriteFrames (baixo, esquerda, direita, cima), inclusive
repetições de quadros usadas na animação. Regiões originais fracionárias de
313,5 px são mantidas no manifesto e recortadas com borda inteira, sem reduzir.

## Margens e conteúdo dinâmico

Exportações de móveis têm canvas 256 × 256 com pivô (128,224), para não cortar
objetos esticados nas rotações. Personagens têm canvas 96 × 96 e pivô (48,80).
Essas margens transparentes não são a resolução-alvo. Prefira os recortes do
atlas ou remova as margens antes de ajustar a arte/canvas à grade 32 × 32.

O kit de empratamento não tem decoração fixa por decisão atual: seus quatro
PNGs isolados são transparentes intencionalmente. Os pratos reais são camadas
dinâmicas; veja os exemplos pratos-00/01/10/11/20, além do prato individual.
Pratos com comida usam as imagens das receitas; panelas cheias usam a mesma
panela com a camada de conteúdo. Não desenhar estoque fixo como se fosse real.

## Reenvio e verificação

Preserve nomes e identificação ao reenviar as edições. Você pode enviar PNGs
editados, sheets novas com a grade descrita, e/ou arquivos .aseprite. Não há
fontes .aseprite anteriores no repositório; os arquivos fonte existentes são
PNG/SVG e os recursos/scripts incluídos. Após as edições será necessário
adaptar recortes, SpriteFrames, pivôs e TileSets; simplesmente substituir um
atlas grande por um pequeno invalidaria as coordenadas atuais.

originais.csv traz dimensões e SHA256 dos originais. indice-sprites.csv permite
buscar nomes. recortes-e-renderizacoes.json registra cada extração/renderização;
SHA256SUMS.txt confere todos os arquivos. A grade lógica atual do jogo é 40
unidades e não foi mudada por esta exportação.
"""
    generated["LEIA-ME.md"] = readme.encode()
    # Check all source images are byte-identical in the ZIP and every exported
    # file is covered by the checksum list. No image editing occurs here.
    checksums = []
    DEST.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(DEST, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for arc, path in sorted(files.items()):
            archive.write(path, PREFIX + arc)
            checksums.append(f"{digest(path.read_bytes())}  {arc}")
        for arc, data in sorted(generated.items()):
            archive.writestr(PREFIX + arc, data)
            checksums.append(f"{digest(data)}  {arc}")
        archive.writestr(PREFIX + "SHA256SUMS.txt", "\n".join(checksums) + "\n")
    with zipfile.ZipFile(DEST) as archive:
        assert archive.testzip() is None
        for row in originals:
            assert digest(archive.read(PREFIX + row["arquivo"])) == row["sha256"]
    assert DEST.stat().st_size < 100 * 1024 ** 2
    print(json.dumps({"zip": str(DEST), "files": len(files) + len(generated) + 1,
                      "originals": len(originals), "derived_images": len(manifest),
                      "MiB": round(DEST.stat().st_size / 1024 ** 2, 2), "sha256": digest(DEST.read_bytes())}, indent=2))


if __name__ == "__main__":
    main()

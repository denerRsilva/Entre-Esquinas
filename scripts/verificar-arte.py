#!/usr/bin/env python3
"""Validate declared native canvases and prevent shipping unused study sheets."""
import json, struct, subprocess, re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
    registry=json.loads((ROOT/'docs/arte/escala32/registro.json').read_text())
    native={r['path'] for r in registry['native']}
    for row in registry['native']:
        p=ROOT/row['path'];data=p.read_bytes();assert data[:8]==b'\x89PNG\r\n\x1a\n',p
        w,h=struct.unpack('>II',data[16:24]);assert (w,h)==(row['width'],row['height']),p
        assert row['cell']==32 and w%32==0 and h%32==0,p
    tracked=subprocess.check_output(['git','ls-files','godot'],cwd=ROOT,text=True).splitlines()
    known=native|set(registry['legacy'])
    for path in tracked:
        if path.endswith('.png') and '/qa/' not in path:assert path in known,'Declare canvas/grade e revise a densidade: '+path
    excluded=json.loads((ROOT/'docs/arte/escala32/excluidos-exportacao.json').read_text())['files']
    cfg=(ROOT/'godot/export_presets.cfg').read_text()
    for path in excluded:
        assert path in cfg,'Exclusão ausente: '+path
        stem=Path(path).stem
        for src in tracked:
            f=ROOT/src
            if '/qa/' in src or f.suffix not in ['.gd','.tscn','.tres','.json','.svg','.gdshader']:continue
            assert re.search(re.escape(stem)+r"(?![\w-])",f.read_text()) is None,f'Recurso excluído ainda referenciado: {src}: {stem}'
    print(f'{len(native)} imagens nativas declaradas; {len(registry["legacy"])} exceções legadas; {len(excluded)} pranchas excluídas sem referências de execução.')
if __name__=='__main__':main()

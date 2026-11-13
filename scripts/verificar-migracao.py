#!/usr/bin/env python3
"""Exit nonzero while the shipped Godot project still depends on JavaScript."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1] / 'godot'
legacy = sorted((root / 'simulacao').glob('*.js'))
consumers = []
for path in sorted(root.rglob('*.gd')):
    if '.godot' in path.parts or 'qa' in path.parts:
        continue
    text = path.read_text()
    if 'RestauranteVM' in text or 'evaluate.call(' in text:
        consumers.append(path.relative_to(root))
extensions = sorted((root / 'nativo').rglob('*.gdextension'))
print('JavaScript de produção:', len(legacy))
for path in legacy:
    print(' -', path.relative_to(root))
print('Consumidores da ponte:', len(consumers))
for path in consumers:
    print(' -', path)
print('Extensões legadas:', len(extensions))
if legacy or consumers or extensions:
    print('INCOMPLETA: não publicar como versão totalmente GDScript.')
    sys.exit(1)
print('Sem dependências JavaScript detectadas. Ainda são necessários testes funcionais e exportação.')

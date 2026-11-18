#!/usr/bin/env python3
"""Read image headers/export entries; never resize artwork or modify originals."""
import argparse, collections, json, struct, subprocess, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def png_size(data):
    if data[:8]!=b'\x89PNG\r\n\x1a\n':raise ValueError('PNG inválido')
    return struct.unpack('>II',data[16:24])
def audit(pack=None):
    names=subprocess.check_output(['git','ls-files','godot'],cwd=ROOT,text=True).splitlines()
    images=[]
    for name in names:
        p=ROOT/name
        if p.suffix!='.png' or '/qa/' in name:continue
        w,h=png_size(p.read_bytes()[:24])
        images.append({'path':name,'width':w,'height':h,'png_bytes':p.stat().st_size,'rgba8_bytes':w*h*4})
    data={'source_pngs':images,'png_bytes':sum(i['png_bytes'] for i in images),'rgba8_all_exported_sources_theoretical_bytes':sum(i['rgba8_bytes'] for i in images),'note':'RGBA8 is a theoretical sum, not measured resident RAM/VRAM. Large atlases can be valid when composed from native cells.'}
    apk=ROOT/'build/Android/EntreEsquinas.apk'
    if apk.exists():
        groups=collections.Counter();entries=[]
        with zipfile.ZipFile(apk) as z:
            for i in z.infolist():
                group='engine/'+i.filename.split('/')[1] if i.filename.startswith('lib/') else 'textures' if i.filename.endswith('.ctex') else 'other'
                groups[group]+=i.compress_size
                if i.filename.endswith('.ctex'):entries.append({'path':i.filename,'compressed_bytes':i.compress_size})
        data['apk']={'bytes':apk.stat().st_size,'compressed_groups':dict(groups),'textures':entries}
    if pack:
        sizes=collections.Counter();files=[]
        with zipfile.ZipFile(pack) as z:
            for i in z.infolist():
                if not i.filename.lower().endswith('.png'):continue
                w,h=png_size(z.open(i).read(24));sizes[w,h]+=1
                files.append({'path':i.filename,'width':w,'height':h,'bytes':i.file_size})
            total=sum(i.file_size for i in z.infolist() if not i.is_dir())
        data['reference']={'name':Path(pack).name,'zip_bytes':Path(pack).stat().st_size,'uncompressed_bytes':total,'png_count':len(files),'grid32_aligned_count':sum(v for (w,h),v in sizes.items() if w%32==0 and h%32==0),'common_sizes':[{'width':w,'height':h,'count':n} for (w,h),n in sizes.most_common(20)]}
    return data
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--pack');p.add_argument('--out');args=p.parse_args();data=audit(args.pack);raw=json.dumps(data,ensure_ascii=False,indent=2)+'\n'
    if args.out:Path(args.out).write_text(raw)
    else:print(raw)

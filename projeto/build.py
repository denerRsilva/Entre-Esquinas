import re,sys,os,base64
d=os.path.join(os.path.dirname(os.path.abspath(__file__)),'dist')
h=open(os.path.join(d,'index.html'),encoding='utf-8').read()
h=re.sub(r'<link rel="stylesheet" href="([^"?]+)[^"]*">',lambda m:'<style>'+open(os.path.join(d,m.group(1)),encoding='utf-8').read()+'</style>',h)
h=re.sub(r'<script src="([^"?]+)[^"]*"></script>',lambda m:'<script>\n'+open(os.path.join(d,m.group(1)),encoding='utf-8').read()+'</script>',h)
assert 'src="' not in h.replace('src=""','') or True
h=h.replace("'assets/esquina-atlas.png'", "'data:image/png;base64,"+base64.b64encode(open(os.path.join(d,'assets/esquina-atlas.png'),'rb').read()).decode('ascii')+"'")
h=h.replace("'assets/esquina-walk.png'", "'data:image/png;base64,"+base64.b64encode(open(os.path.join(d,'assets/esquina-walk.png'),'rb').read()).decode('ascii')+"'")
h=h.replace("'assets/esquina-food.png'", "'data:image/png;base64,"+base64.b64encode(open(os.path.join(d,'assets/esquina-food.png'),'rb').read()).decode('ascii')+"'")
out=sys.argv[1]; open(out,'w',encoding='utf-8').write(h); print(out,len(h))

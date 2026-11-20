from pathlib import Path
import json,random,math
ROOT=Path(__file__).resolve().parent.parent;assets=json.loads((ROOT/'assets.json').read_text());rng=random.Random(18420)
D={'version':1,'world':[80,64],'tile':32,'spawn':[38,34],'objects':[],'points':[],'routes':[],'people':[],'lamps':[],'terrain':[],'author':'Composição Entre Esquinas / assets LimeZu'}
objs=D['objects'];roads=set();paving=set();plots=set();asphalt=set();used=set()
def rect_cells(x,y,w,h,target=roads):
 for yy in range(y,y+h):
  for xx in range(x,x+w):target.add((xx,yy))
def path(points,width=3):
 for (x,y),(ex,ey) in zip(points,points[1:]):
  assert x==ex or y==ey
  if x==ex:rect_cells(x-width//2,min(y,ey),width,abs(ey-y)+1)
  else:rect_cells(min(x,ex),y-width//2,abs(ex-x)+1,width)
# An arrival axis and a loop connect every neighborhood; short branches meet doors.
path([(40,63),(40,34)],5)
path([(12,35),(69,35)],4)
path([(27,20),(27,52),(65,52),(65,20),(15,20)],3)
path([(20,20),(20,35)],3)
path([(36,20),(36,30),(38,30),(38,34)],3)
path([(57,20),(57,31),(61,31),(61,35)],3)
path([(15,35),(15,47),(27,47)],3)
path([(40,49),(57,49),(57,47)],3)
path([(40,55),(31,55),(31,52)],3)
path([(20,35),(20,33)],3)
path([(15,20),(15,18)],3)
path([(61,20),(61,18)],3)
path([(67,35),(67,32)],3)
rect_cells(31,30,19,12);rect_cells(10,32,14,5);rect_cells(10,45,14,5)
rect_cells(36,55,10,4)
rect_cells(32,32,16,8,paving)
rect_cells(10,33,13,3,paving)
rect_cells(11,46,12,3,paving)
rect_cells(39,59,3,5,asphalt)
rect_cells(61,32,10,12,asphalt)
for x in [49,54,59]:rect_cells(x,42,3,6,plots)
# Origin is the top-left of each unmodified PNG; solid rectangles are ground footprints.
def add(alias,x,y,solid=None,role=None,**extra):
 assert alias in assets,alias
 w,h=assets[alias]['size'];o={'asset':alias,'pos':[x,y],**extra}
 if solid is not None:o['solid']=[x+solid[0],y+solid[1],solid[2],solid[3]]
 if role:o['role']=role
 objs.append(o);used.add(alias);return o

def building(alias,x,y,key,title,access,solid=None):
 w,h=assets[alias]['size']
 if solid is None:solid=[32,h-96,w-64,96]
 add(alias,x,y,solid,key)
 D['points'].append({'id':key,'name':title,'cell':access,'asset':alias,'building':[x,y,w,h]})

building('taverna',960,608,'taverna','Taverna Entre Esquinas',[38,30])
building('moradia_a',288,96,'moradias_oeste','Casas recuperadas',[15,19])
building('casa_rustica',896,96,'moradias_norte','Casa comunitária',[36,20])
building('moradia_b',1728,96,'moradias_leste','Rua das moradias',[61,19])
building('mercado',512,768,'mercador','Mercador de ingredientes',[20,34])
building('oficina',384,1184,'carpinteiro','Oficina do carpinteiro',[16,47])
building('ferro_velho',2016,736,'ferro_velho','Ferro-velho e peças',[67,33])
building('enfermaria',1632,576,'enfermaria','Enfermaria comunitária',[57,32])
building('reconstrucao',224,704,'reconstrucao','Moradia em reconstrução',[10,33])
building('trailer_a',800,1440,'acolhimento','Acolhimento de viajantes',[30,52])
building('trailer_b',544,1632,'campamento','Abrigo provisório',[21,57])
building('estufa_base',1920,1280,'horta','Horta e estufa',[64,49])
add('estufa_vidro',1920,1280)
D['points'].append({'id':'praca','name':'Praça do refúgio','cell':[43,39],'asset':'fonte_anim'})
D['points'].append({'id':'portao','name':'Portão e chegada de viajantes','cell':[40,57],'asset':'torre'})
# Main plaza. A fountain, meeting tables and the tavern entrance define its heart.
add('fonte_anim',1344,1088,[8,64,48,32],animation={'frame':[64,96],'frames':6,'fps':5})
for x,y in [(1056,1088),(1440,1088),(1056,1184),(1440,1184)]:add('banco',x,y,[0,16,64,16])
for x,y in [(1008,992),(1440,992),(1008,1248),(1472,1248)]:add('arbusto',x,y,[16,48,32,16])
for x,y in [(864,1024),(864,1152)]:add('mesa',x,y,[8,32,48,24])
# Supplies near the tavern are organized against its side, with the door left clear.
for a,x,y in [('caixote',896,896),('barril',864,928),('gerador',1408,864),('caixa_comida',768,992),('carrinho_comida',704,944)]:
 w,h=assets[a]['size'];add(a,x,y,[8,max(0,h-32),max(16,w-16),32])
# Market: small stalls and produce crates, no shopping computer.
for a,x,y in [('carrinho_comida',416,992),('caixa_comida',576,1088),('caixa_comida',640,1088),('caixote',736,928),('barril',704,1120)]:
 w,h=assets[a]['size'];add(a,x,y,[8,h-32,w-16,32])
# Workshop: salvaged benches, construction, tools and goods waiting to be finished.
for a,x,y in [('caixa_ferramentas',672,1376),('mesa',672,1280),('caixote',288,1408),('caixote',736,1312),('barril',320,1344),('caixa_vazia',704,1408)]:
 w,h=assets[a]['size'];add(a,x,y,[8,h-32,w-16,32])
for x,y in [(224,1024),(288,1024),(352,1024),(416,1024)]:add('cone',x,y,[8,16,16,16])
# A working scrapyard uses a courtyard of reclaimed asphalt.
for a,x,y in [('carro_velho',2016,1088),('carro_velho_b',2176,1184),('pneus',2208,1056),('pneus',2272,1088),('sucata',2048,1280),('sucata',2208,1312),('caixa_ferramentas',1952,1184)]:
 w,h=assets[a]['size'];add(a,x,y,[16,h-32,w-32 if w>32 else 32,32])
# Community cultivation uses regular rows and an accessible aisle between beds.
for x0 in [49,54,59]:
 for y in [42,44,46]:
  for x in [x0,x0+2]:add('canteiro',x*32,y*32,[8,24,16,8])
for a,x,y in [('regador',1792,1536),('caixa_vazia',1856,1536),('caixote',2176,1472),('barril',2208,1408),('banco',1696,1632)]:
 w,h=assets[a]['size'];add(a,x,y,[8,h-24,w-16,24])
# Recovery and shelter: enough open yard for people to gather.
for a,x,y in [('caixa_militar',1568,896),('caixa_militar',1984,928),('mesa',1728,1056),('caixote',768,1600),('barril',1120,1568),('mesa',896,1664)]:
 w,h=assets[a]['size'];add(a,x,y,[8,h-32,w-16,32])
add('fogueira_anim',1056,1760,[0,40,32,16],animation={'frame':[32,64],'frames':6,'fps':7})
# Reclaimed energy, placed near the community house rather than in the square.
add('moinho_base',1504,224,[32,224,64,32])
add('moinho_anim',1504,224,animation={'frame':[128,128],'frames':4,'fps':5},offset_foot=256)
add('placa_solar',1472,480,[16,96,64,32])
# Defensive perimeter. The timber fence uses its own native ends and straight pieces.
for x in range(5,75):
 for y in [5,58]:
  if y==58 and 38<=x<=43:continue
  alias='cerca_02'
  if x==5:alias='cerca_01' if y==5 else 'cerca_05'
  if x==74:alias='cerca_03' if y==5 else 'cerca_06'
  add(alias,x*32,y*32-32,[0,32,32,32],perimeter=True)
for y in range(6,58):
 for x,alias in [(5,'cerca_04'),(74,'cerca_09')]:add(alias,x*32,y*32-32,[0,32,32,32],perimeter=True)
# Entry lookout and reinforcement leave a wide central lane for travelers.
add('torre',1440,1376,[64,416,64,64])
for x in [1056,1120,1408,1472]:add('saco_h',x,1824,[0,32,64,32])
for x,y in [(1152,1760),(1408,1760)]:add('caixa_militar',x,y,[8,32,48,32])
# Decorative lamps become real point lights in the night view.
for x,y in [(1088,832),(1408,864),(928,1216),(1504,1216),(416,992),(704,992),(384,1376),(704,1472),(2048,992),(2240,1248),(1696,1504),(2144,1568),(1152,1728),(1376,1728),(864,512),(1568,512),(1760,480),(512,512)]:
 add('poste',x,y,[8,96,16,32]);D['lamps'].append([x+48,y+24])
# Trees group around courtyards; avoid roads, doors and other ground footprints.
protected=set(roads|paving|asphalt|plots)
for p in D['points']:
 x,y=p['cell']
 for dx in range(-2,3):
  for dy in range(-2,3):protected.add((x+dx,y+dy))
rects=[o['solid'] for o in objs if 'solid' in o]
def touches(box,other):return box[0]<other[0]+other[2] and box[0]+box[2]>other[0] and box[1]<other[1]+other[3] and box[1]+box[3]>other[1]
def can_tree(x,y,alias):
 w,h=assets[alias]['size'];box=[x+w//2-16,y+h-32,32,32]
 cells=[(int((box[0]+dx)//32),int((box[1]+dy)//32)) for dx in [0,31] for dy in [0,31]]
 if any(c in protected for c in cells):return False
 if any(touches(box,r) for r in rects):return False
 # Do not hide the facade of a useful building.
 for o in objs:
  if o.get('role') and o.get('solid'):
   ox,oy=o['pos'];ow,oh=assets[o['asset']]['size']
   if touches([x,y,w,h],[ox-16,oy+oh-128,ow+32,144]):return False
 rects.append(box);return box
# Forest border establishes a finite refuge; patches inside break the grid.
for y in range(-1,65,3):
 for x in range(-1,81,3):
  outside=x<5 or x>71 or y<4 or y>56
  if not outside and rng.random()>0.24:continue
  if x in range(36,46) and y>54:continue
  alias=rng.choice(['arvore_a','arvore_a','arvore_b','arvore_c']);xx=x*32+rng.choice([0,16]);yy=y*32+rng.choice([0,16]);box=can_tree(xx,yy,alias)
  if box:add(alias,xx,yy,[box[0]-xx,box[1]-yy,32,32])
# Low shrubs, tufts and flowers give density without obscuring routes.
for i in range(210):
 x=rng.randrange(7,73);y=rng.randrange(7,57)
 if (x,y) in protected:continue
 px=x*32;py=y*32
 if any(touches([px,py,32,32],r) for r in rects):continue
 if rng.random()<0.22:add('arbusto',px,py,[16,48,32,16])
 else:add('moita',px,py)
# Small original dirt details break large flat paths without changing their grid.
for x,y in rng.sample(sorted(roads),min(100,len(roads))):
 if (x,y) in paving or (x,y) in asphalt:continue
 add(rng.choice(['terra_detalhe_1','terra_detalhe_7']),x*32,y*32,ground=True)
# Ground layers are authored as tile coordinates and remain editable in the saved scene.
for y in range(64):
 for x in range(80):
  kind='grass'
  if (x,y) in roads or (x,y) in plots:kind='dirt'
  if (x,y) in paving:kind='paving'
  if (x,y) in asphalt:kind='asphalt'
  D['terrain'].append(kind)
# Visible residents follow useful, cached routes and pause at destinations.
D['routes']=[[[38,34],[43,39],[43,35],[38,30]],[[20,34],[27,35],[36,35],[38,30]],[[16,47],[27,47],[27,35],[20,34]],[[67,33],[65,35],[61,35],[57,32]],[[57,49],[64,49],[65,52],[43,52]],[[40,57],[40,49],[40,40],[43,39]],[[15,19],[20,20],[27,20],[27,35]],[[36,20],[28,24],[28,30],[38,30]],[[61,19],[65,20],[65,31],[57,32]],[[30,52],[27,52],[27,47],[16,47]],[[21,57],[27,57],[31,55],[40,55]],[[43,39],[50,35],[61,35],[67,33]]]
for i in range(16):D['people'].append({'route':i%len(D['routes']),'asset':('viajante_'+str(i%3+1)) if i%4==0 else 'morador_'+str(i%6+1),'speed':rng.randrange(25,39),'pause':rng.uniform(2.5,7),'offset':i%4})
# Guard at the arrival checkpoint has no patrol; no combat is part of this study.
D['people'].append({'route':-1,'asset':'morador_3','cell':[44,57],'speed':0,'pause':0,'offset':2})
(ROOT/'cidade.json').write_text(json.dumps(D,ensure_ascii=False,indent=2))
print('Mundo:',D['world'],'objetos:',len(objs),'pontos:',len(D['points']),'moradores visuais:',len(D['people']))

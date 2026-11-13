/* Esquina de Casa — apresentação visual; não altera estado, colisões ou economia. */
(function(root){
'use strict';
const atlas=typeof Image!=='undefined'?new Image():null;
if(atlas)atlas.src='assets/esquina-atlas.png';
const kitchenAtlas=typeof Image!=='undefined'?new Image():null;
if(kitchenAtlas)kitchenAtlas.src='assets/taverna/moveis.png';
const walkAtlas=typeof Image!=='undefined'?new Image():null;
if(walkAtlas)walkAtlas.src='assets/esquina-walk.png';
const walkRects=[[86, 22, 151, 282], [401, 22, 127, 281], [682, 16, 133, 289], [984, 16, 134, 290], [81, 343, 159, 278], [398, 343, 130, 278], [682, 340, 130, 281], [984, 340, 134, 283], [78, 659, 158, 279], [398, 659, 129, 279], [678, 656, 142, 282], [984, 659, 142, 279], [78, 976, 162, 285], [390, 976, 137, 285], [682, 975, 131, 286], [985, 975, 133, 286]];
const facing=new WeakMap();
// Diagonais priorizam o eixo vertical. O deslocamento efetivo preserva a
// animação lateral quando uma parede bloqueia completamente o eixo vertical.
function direction(a){
 let d=facing.get(a)||'down';
 const input=root.Restaurant.playerVelocity(a);
 if(input){
  const dx=input.moving?(input.moveX??input.dx):input.dx,dy=input.moving?(input.moveY??input.dy):input.dy;
  if(Math.abs(dy)>1e-7)d=dy<0?'up':'down';
  else if(Math.abs(dx)>1e-7)d=dx<0?'left':'right';
  facing.set(a,d);
 }else if(a.motion){
  const dx=a.motion.toX-a.motion.fromX,dy=a.motion.toY-a.motion.fromY;
  if(Math.abs(dy)>1e-7)d=dy<0?'up':'down';
  else if(Math.abs(dx)>1e-7)d=dx<0?'left':'right';
  facing.set(a,d);
 }
 return d;
}

const rects=[[68,54,198,241],[339,77,263,216],[683,30,202,265],[1023,20,150,277],[28,393,264,208],[402,357,136,243],[662,334,244,283],[1032,408,131,175],[81,636,158,291],[400,646,141,279],[702,653,160,272],[1014,646,159,281],[90,963,135,274],[335,980,269,242],[659,990,249,225],[997,963,200,262]];
const sprites={stove:0,kitchen:1,prep:1,sink:2,fridge:3,cold:3,table:4,chair:5,shelf:6,potRack:6,bin:7};
const floors=new Map();
function ready(){return !!(atlas&&atlas.complete&&atlas.naturalWidth)}
function box(c,x,y,w,h,color){c.fillStyle=color;c.fillRect(Math.round(x),Math.round(y),Math.round(w),Math.round(h))}
function label(c,t,x,y,color='#25473d'){c.font='bold 10px Trebuchet MS,system-ui';const w=c.measureText(t).width+12;box(c,x-w/2,y-10,w,16,color);c.fillStyle='#fff0ce';c.textAlign='center';c.fillText(t,Math.round(x),Math.round(y+2))}
function sprite(c,id,x,y,w,h,flip=false){const r=rects[id];c.save();c.imageSmoothingEnabled=false;if(flip){c.translate(Math.round(x+w),Math.round(y));c.scale(-1,1);x=0;y=0;}c.drawImage(atlas,...r,Math.round(x),Math.round(y),Math.round(w),Math.round(h));c.restore()}
function plate(c,x,y,recipe,dirty=false,quality=0){
 if(!dirty&&recipe&&typeof FoodArt!=='undefined'&&FoodArt.draw(c,recipe,x-10,y-7,20,14)){FoodArt.star(c,quality,x+3,y-8,8);return;}
 box(c,x-7,y-3,14,6,dirty?'#aa9a76':'#e4d5aa');box(c,x-5,y-5,10,10,dirty?'#cbb78b':'#fff4d5');
 if(dirty){box(c,x-3,y,3,2,'#805332');box(c,x+2,y-2,2,2,'#9a6434');return;}
 if(recipe==='sopa'){box(c,x-4,y-3,8,6,'#ce8138');box(c,x-2,y-2,2,2,'#568241');}
 if(recipe==='arrozLegumes'){box(c,x-4,y-2,5,4,'#fff9de');box(c,x+1,y-3,3,3,'#5e863c');box(c,x+1,y+1,3,2,'#e1a139');}
 if(recipe==='frangoArroz'){box(c,x-4,y-2,4,4,'#fff9de');box(c,x,y-3,5,5,'#ae5e2c');box(c,x+1,y-3,3,2,'#e2a24b');}
}
function pot(c,x,y,filled,active,time){
 if(active){box(c,x-8,y+3,16,4,'#f5a331');box(c,x-5,y+5,10,2,'#cb5428');}
 c.drawImage(kitchenAtlas,710,802,180,140,x-13,y-12,26,20);if(filled)box(c,x-5,y-7,10,3,'#d1963d');
 if(active)for(let i=0;i<3;i++){let rise=(time*7+i*6)%18;box(c,x-5+i*5,y-9-rise,2,4,'#f6ecd5aa');}
}
function base(c,R,room){
 const key=room;if(floors.has(key)){c.drawImage(floors.get(key),0,0);return;}
 const surface=document.createElement('canvas');surface.width=960;surface.height=640;const p=surface.getContext('2d');p.imageSmoothingEnabled=false;
 box(p,0,0,960,640,'#7c6149');
 if(room==='street'){
  box(p,0,0,960,640,'#72845a');box(p,140,30,680,180,'#ead5a1');box(p,150,130,660,80,'#63836a');
  for(let y=30;y<85;y+=12)for(let x=130;x<835;x+=30){box(p,x+(y%24?15:0),y,28,10,'#a85f3e');box(p,x+(y%24?15:0),y,28,2,'#c37e50');}
  for(const x of [190,300,610,720])sprite(p,14,x,108,54,48);
  box(p,415,145,140,55,'#b47b43');box(p,425,155,120,45,'#604b32');label(p,'ENTRE ESQUINAS',480,115);
  for(let y=200;y<640;y+=20)for(let x=0;x<960;x+=40){const road=y>450;box(p,x,y,39,19,road?['#6e7265','#73796c','#77776a'][(x/40+y/20)%3]:['#b8ad8b','#c9bc99','#c1b48f'][(x/40+y/20)%3]);}
  for(let x=20;x<960;x+=100)box(p,x,550,48,3,'#d7c69b');
 }else{
  for(let y=0;y<16;y++)for(let x=0;x<24;x++){
   const wall=R.wall(room,x,y),kitchen=x>=15&&y<10,stock=x>=15&&y>10;
   const colors=kitchen?['#c7c6a6','#d0ceb0','#c4c4a4']:stock?['#b9986b','#c0a374','#b59b70']:['#c38456','#ba774c','#c98c5b','#c08051'];
   const col=colors[(x*7+y*3)%colors.length];box(p,x*40,y*40,40,40,wall?'#59715a':col);
   if(!wall){box(p,x*40,y*40,40,1,kitchen?'#9ea58e':'#9d663f');box(p,x*40,y*40,1,40,kitchen?'#9ea58e':'#9d663f');box(p,x*40+2,y*40+2,36,1,kitchen?'#dfddbd':'#d99867');box(p,x*40+8+(y%3)*5,y*40+30,9,1,kitchen?'#c1c3a2':'#c28758');}
   else {box(p,x*40,y*40,40,24,kitchen?'#eee1ba':'#e9d3a4');box(p,x*40,y*40+24,40,12,'#78916b');box(p,x*40,y*40+36,40,4,'#664934');box(p,x*40,y*40,40,3,'#775038');if(kitchen){box(p,x*40,y*40+12,40,1,'#c9b993');box(p,x*40+20,y*40,1,24,'#c9b993');}}
  }
  // Paredes verticais contínuas: sem repetir faixas horizontais por célula.
  for(let y=1;y<15;y++)for(const x of [0,14,23])if(R.wall(room,x,y)){
   box(p,x*40,y*40,40,40,'#e4d0a3');box(p,x*40,y*40,6,40,'#705039');box(p,x*40+28,y*40,12,40,'#78916b');box(p,x*40+37,y*40,3,40,'#52664d');
  }
  // Ornamentação somente sobre paredes: nenhuma decoração cria obstáculos invisíveis.
  if(room==='restaurant'){
   for(const x of [115,330])sprite(p,14,x,4,40,32);
   sprite(p,13,42,0,38,35);sprite(p,13,490,0,38,35);sprite(p,12,220,1,18,36);
   sprite(p,15,415,0,28,38);label(p,'PRATO DO DIA',429,20);
   for(const y of [125,300,480])sprite(p,14,3,y,33,36);
   // Faixas discretas de luz, sem prejudicar o contraste dos objetos.
   p.save();p.globalAlpha=.11;for(let y=140;y<400;y+=70){box(p,40,y,60,18,'#ffe3a3');box(p,40,y+20,90,14,'#ffe3a3');}p.restore();
   // Administração e recebimento continuam nas posições interativas existentes.
   box(p,640,440,80,40,'#795232');box(p,643,441,74,22,'#b88651');box(p,647,464,7,15,'#513d2b');box(p,707,464,7,15,'#513d2b');
   box(p,659,423,42,30,'#304b40');box(p,663,426,34,22,'#b1c798');box(p,676,453,9,5,'#354b3f');box(p,667,458,29,4,'#dfd6b0');
   box(p,800,440,120,40,'#9d794c');for(let x=803;x<918;x+=20){box(p,x,443,16,33,'#bd945d');box(p,x,449,16,2,'#886239');box(p,x,469,16,2,'#886239');}
  }
 }
 floors.set(key,surface);c.drawImage(surface,0,0);
}
function object(c,R,s,o,selected,preview=false){
 const r=R.rect(o),x=r.x*40,y=r.y*40,w=r.w*40,h=r.h*40;
 c.save();if(preview)c.globalAlpha=.65;
 box(c,x+5,y+h-7,w-7,8,'#624a343f');
 let sw=w-4,sh=h+12;if(o.type==='stove')sh=h+22;if(o.type==='fridge'||o.type==='cold')sh=h+5;if(o.type==='chair'){sw=29;sh=38;}if(o.type==='bin'){sw=27;sh=34;}
 c.furniture(o,x,y,w,h,preview);
 if(o.type==='chair'&&preview){
  // Orientation marker belongs to the seat, never changes its collision footprint.
  const [dx,dy]=R.DIRS[o.rot];box(c,x+19+dx*10,y+20+dy*10,3,3,'#f8deb0');
  {c.fillStyle='#fff2ce';c.textAlign='center';c.font='bold 16px system-ui';c.fillText(['↑','→','↓','←'][o.rot],x+20,y+24);}
 }
 if(o.type==='stove'&&o.pan)pot(c,x+w*.3,y-9,o.pan.startsWith('pot_'),o.pan==='cookingPot'||!!o.readyBatch,s.time);
 if(o.readyBatch){const stage=R.heatState(s,o).stage;if(['over','danger','burned'].includes(stage)){box(c,x+10,y-15,12,7,'#514d40');for(let i=0;i<3;i++)box(c,x+10+i*4,y-22-((s.time*8+i*6)%18),5,7,stage==='burned'?'#383a36aa':'#71695c99');}}
 if(o.type==='potRack'){for(let i=0;i<3;i++)if(o.inventory?.[i]?.item==='pot')pot(c,x+w/2,y-20+i*23,false,false,s.time);}
 // A prévia de construção não possui ID e nunca representa um cozimento ativo.
 const cooking=o.id!==undefined&&s.cooking?.stove===o.id?s.cooking:null;
 if(o.type==='stove'&&(o.ingredients?.length||cooking||o.readyBatch)){
  let i=0;for(const p of o.ingredients||[]){FoodArt.draw(c,p.item,x+5+i*19,y-15,18,18);i++;}
  const recipe=R.recognizedRecipe(o)||cooking?.recipe||o.readyBatch?.recipe;
  if(recipe)FoodArt.draw(c,recipe,x+w/2-14,y-50,28,24);
 }
 if(o.type==='kitchen'){
  if(o.support)pot(c,x+50,y-7,!!R.ITEMS[o.support.item]?.servings,false,s.time);

  const count=o.plates||0;if(count)for(let i=0;i<Math.min(4,Math.ceil(count/3));i++)plate(c,x+12,y+2-i*2);
  if(o.utensil){box(c,x+w-15,y+3,7,11,'#7c5b37');box(c,x+w-13,y-3,2,10,'#dec08c');box(c,x+w-9,y-1,2,9,'#cfad79');}
  let i=0;for(const [dish]of Object.entries(o.dishes||{}))for(let q=0;q<4;q++)for(let j=0;j<R.objectQualityCount(o,dish,q);j++,i++){plate(c,x+27+i%4*11,y+4+Math.floor(i/4)*8,R.ITEMS[dish].recipe,false,q);}
 }
 if(o.type==='table'){
  const chairs=s.objects.filter(ch=>ch.type==='chair'&&R.chairTable(s,ch)?.id===o.id);
  let dishes=0;for(const ch of chairs){const customer=s.customers.find(a=>a.seat===ch.id&&a.state==='eating');if(customer)plate(c,x+18+dishes++*19,y+6,customer.recipe,false,s.orders.find(o=>o.id===customer.order)?.quality??0);if(s.dirtyTables[ch.id])plate(c,x+18+dishes++*19,y+7,null,true);}
 }
 if(selected){c.strokeStyle='#fff0be';c.lineWidth=2;c.strokeRect(x+1,y+1,w-2,h-2);}
 c.restore();
}
// A seleção é uma apresentação do slot, não uma transferência nem reserva física.
function heldItem(R,s,a){
 if(a.hand)return a.hand;
 if(a.carry){
  if(a.carry.kind==='dish'){const order=s.orders.find(o=>o.id===a.carry.order);return order?{item:'dish_'+order.recipe,n:1,quality:a.carry.quality||0}:null;}
  if(a.carry.kind==='food')return {item:a.carry.food,n:a.carry.n,quality:a.carry.quality||0};
  return null;
 }
 return null;
}
function drawHeldItem(c,R,s,p,x,y){
 if(!p)return;
 if(p.item==='pot'||p.item==='cookingPot'||R.ITEMS[p.item]?.servings){pot(c,x,y,!!R.ITEMS[p.item]?.servings,false,s.time);return;}
 if(p.item.startsWith('dish_')){plate(c,x,y,R.ITEMS[p.item]?.recipe,false,p.quality||0);return;}
 if(['plate','dirtyPlate'].includes(p.item)){plate(c,x,y,null,p.item==='dirtyPlate');return;}
 if(p.item==='spoon'){
  box(c,x-1,y-3,3,16,'#527576');box(c,x-4,y-9,9,8,'#d6e5d9');box(c,x-2,y-8,5,5,'#90aaa3');return;
 }
 if(typeof FoodArt!=='undefined'){FoodArt.draw(c,p.item,x-12,y-12,24,24);FoodArt.star(c,p.quality||0,x+4,y-13,9);}
}
function actor(c,R,s,a,selected,construction=false){
 const pose=R.position(a),x=pose.x*40+20,bottom=pose.y*40+38;
 box(c,x-12,bottom-3,24,5,'#4c3e3540');
 const n=Number(String(a.id).replace(/\D/g,''))||0;
 const id=a.id==='player'?8:a.id==='worker2'?9:a.id==='worker1'?10:a.id.startsWith('client')?12+n%3:a.id==='lia'||a.id==='nina'?11:10+n%2;
 const dir=direction(a),moving=R.isMoving(a),frame=moving?Math.floor(s.time*7)%2:1;
 if(a.id==='player'){
 c.actor(x,bottom,dir,moving);
 }else c.commands.push(['npc',a.id,id,x,bottom,dir,moving]);
 const held=heldItem(R,s,a),handX=x+(dir==='left'?-12:dir==='right'?12:8),handY=bottom-(dir==='up'?32:22);
 drawHeldItem(c,R,s,held,handX,handY);
 if(construction)return;
 if(a.id==='player')label(c,'Você',x,bottom+12,'#77603a');
 else if(a.id.startsWith('worker'))label(c,a.id==='worker1'?'Logística':'Garçom',x,bottom+11);
 else if(a.recipe&&a.order&&['ordered','eating'].includes(a.state)&&typeof FoodArt!=='undefined'){box(c,x-17,bottom-82,34,28,'#25473df2');FoodArt.draw(c,a.recipe,x-15,bottom-82,30,26);}else if(selected===a.id)label(c,({lia:'Lia',beto:'Beto',nina:'Nina'})[a.id]||'Cliente',x,bottom+11);
 if(a.wait>=5)label(c,'Aguardando passagem',x,bottom-68,'#78503a');
 if(a.experience){const indicator=R.customerIndicator(s,a);if(indicator){box(c,x+18,bottom-82,28,25,'#25473df2');c.font='20px system-ui';c.textAlign='center';c.fillStyle='#fff3d5';c.fillText(indicator.emoji,x+32,bottom-62);}}
}
function overlays(c,R,s,o,selected,building){
 const r=R.rect(o),x=r.x*40,y=r.y*40,w=r.w*40,h=r.h*40;
 if(selected||building)label(c,R.CATALOG[o.type].name,x+w/2,y+h+11);
 const job=s.chopping?.table===o.id?s.chopping:s.cooking?.stove===o.id?s.cooking:s.plating?.prep===o.id?s.plating:null;
 if(job){label(c,(job.table?'Cortando ':job.stove?'Cozinhando ':'Empratando ')+Math.ceil(job.left)+'s',x+w/2,y-30);box(c,x,y-19,w,4,'#315447');box(c,x,y-19,w*(1-job.left/job.total),4,'#f3c56e');}
 else if(o.type==='stove'&&o.readyBatch){const heat=R.heatState(s,o),color={ready:'#74b66b',over:'#e0a044',danger:'#d75b3e',burned:'#57534b'}[heat.stage];label(c,heat.label,x+w/2,y-30);if(heat.stage!=='burned'){box(c,x,y-19,w,5,'#315447');box(c,x,y-19,w*heat.value,5,color);}}
 else if(o.type==='kitchen'&&R.readyCount(o))label(c,R.readyCount(o)+' pratos prontos',x+w/2,y-20);
 if(o.feedback?.until>s.time)label(c,'✓ '+o.feedback.label,x+w/2,y-47,'#3b6448');
}
function draw(c,R,s,ui){
 c.imageSmoothingEnabled=false;c.floor=s.player.room;
 if(s.player.room==='street'){label(c,s.closing?'ENCERRANDO':s.open?'ABERTO':'FECHADO',675,200,s.open?'#3b6448':'#77503a');}
 if(s.player.room==='restaurant'&&!s.singleRoom){
  if(!ui.constructionMode)label(c,'Computador',680,409);
  if(!ui.constructionMode)label(c,'Recebimento • '+Object.values(s.inv.receiving).reduce((a,b)=>a+b,0)+'/60',860,490);
  const boxes=Math.min(5,Math.ceil(Object.values(s.inv.receiving).reduce((a,b)=>a+b,0)/12));for(let i=0;i<boxes;i++){box(c,804+i*21,444,18,22,'#d0a56d');box(c,810+i*21,444,4,22,'#e3c58c');}
  if(!s.objects.length&&!ui.constructionMode)label(c,'Use Gestão → Modo construção para equipar seu restaurante',280,230);
 }
 for(const p of R.PORTALS[s.player.room]){box(c,p.x*40+2,p.y*40+2,36,36,'#866139');box(c,p.x*40+4,p.y*40+4,32,5,'#d4b77a');if(!ui.constructionMode)label(c,p.name,p.x*40+20,p.y*40+22);}
 const items=s.objects.filter(o=>o.room===s.player.room).map(o=>({depth:(o.y+R.rect(o).h)*40,object:o}));
 for(const a of R.allActors(s).filter(a=>a.room===s.player.room))items.push({depth:(R.position(a).y+1)*40,actor:a});
 items.sort((a,b)=>a.depth-b.depth||(a.actor?1:-1));
 for(const item of items){if(item.object)object(c,R,s,item.object,ui.selectedObject===item.object.id);else actor(c,R,s,item.actor,ui.selectedObject,ui.constructionMode);}
 if(!ui.constructionMode)for(const o of s.objects.filter(o=>o.room===s.player.room))overlays(c,R,s,o,ui.selectedObject===o.id,!!ui.building);
 if(ui.building){for(let y=0;y<R.H;y++)for(let x=0;x<R.W;x++)if(!R.wall(s.player.room,x,y,s)){c.strokeStyle='#33584766';c.lineWidth=1;c.strokeRect(x*40,y*40,40,40);}
  if(ui.hover){const o={type:ui.building.type,room:R.CATALOG[ui.building.type].room,x:ui.hover.x,y:ui.hover.y,rot:ui.building.rot},r=R.rect(o),error=ui.previewError(o);object(c,R,s,o,true,true);box(c,r.x*40,r.y*40,r.w*40,r.h*40,error?'#bb433b55':'#55aa7055');}}
}
function catalogIcon(type,name){
 const icon=document.createElement('canvas');icon.width=160;icon.height=112;
 icon.className='furnitureSprite';icon.setAttribute('role','img');icon.setAttribute('aria-label',name);
 icon.getContext('2d').commands.push(['furniture_icon',type]);return icon;
}
// Three 160 × 112 cells from the approved utensil artwork.
const toolAtlas=typeof Image==='undefined'?null:new Image();
if(toolAtlas)toolAtlas.src='assets/esquina-tools.png';
function toolIcon(type,name){
 const icon=document.createElement('canvas');
 icon.width=160;icon.height=112;icon.className='furnitureSprite toolSprite';
 icon.setAttribute('role','img');icon.setAttribute('aria-label',name);
 function paint(){
  const context=icon.getContext('2d');
  context.imageSmoothingEnabled=false;
  context.drawImage(toolAtlas,{pot:0,spoon:160,plate:320}[type],0,160,112,0,0,160,112);
 }
 if(toolAtlas?.complete&&toolAtlas.naturalWidth)paint();
 else toolAtlas?.addEventListener?.('load',paint,{once:true});
 return icon;
}
root.RestaurantArt={heldItem,base,ready,draw,object,rects,direction,catalogIcon,toolIcon};
})(typeof globalThis!=='undefined'?globalThis:this);

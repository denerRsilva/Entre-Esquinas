'use strict';
const R=Restaurant,$=id=>document.getElementById(id),canvas=$('world'),ctx=canvas.getContext('2d');
let prepOptionsId=null,prepChoice=null,constructionMode=false;
let state=R.fresh(),building=null,hover=null,selectedObject=null,transferQuantity=99,dialogObjectId=null,dialogMode='general',dialogTab='guide',last=performance.now(),renderedKey='',noticeTime=0;
const NAME={street:'Rua da Praça',restaurant:'Restaurante • salão, cozinha e estoque',stock:'Estoque • recebimento e administração'};
const PERSON={lia:'Lia',beto:'Beto',nina:'Nina',worker1:'Logística',worker2:'Garçom'};
function tell(message,bad=false){state.message=message;$('notice').textContent=message;$('notice').classList.toggle('bad',bad);$('notice').style.opacity='1';noticeTime=performance.now()+6000;if($('management').open)$('menuNotice').textContent=message;refresh();}
function button(text,action,parent,disabled=false){let b=document.createElement('button');b.textContent=text;b.disabled=disabled;b.onclick=action;parent.append(b);return b;}
function money(n){return '$'+n.toFixed(2)}
let cameraLevel=1;try{const saved=Number(localStorage.getItem('entre-camera-zoom'));if(saved>=.7&&saved<=2)cameraLevel=saved;}catch{}
const camera={zoom:1,x:0,y:0,mode:null};
function setCameraLevel(value){cameraLevel=Math.round(Math.max(.7,Math.min(2,value))*10)/10;try{localStorage.setItem('entre-camera-zoom',String(cameraLevel))}catch{}updateCamera();positionActions();$('zoomOutBtn').disabled=cameraLevel<=.7;$('zoomInBtn').disabled=cameraLevel>=2;}
$('zoomOutBtn').onclick=()=>setCameraLevel(cameraLevel-.1);$('zoomInBtn').onclick=()=>setCameraLevel(cameraLevel+.1);
const viewport={width:960,height:640};
let buildPointer=null;
function updateCamera(){
 const p=R.position(state.player),mode=constructionMode?'build':'play';
 camera.zoom=Math.max(1,viewport.height/640)*cameraLevel;
 const maxX=Math.max(0,960-viewport.width/camera.zoom),maxY=Math.max(0,640-viewport.height/camera.zoom);
 if(!constructionMode||camera.mode!==mode){camera.x=p.x*40+20-viewport.width/2/camera.zoom;camera.y=p.y*40+20-viewport.height/2/camera.zoom;}
 camera.x=viewport.width/camera.zoom>960?(960-viewport.width/camera.zoom)/2:Math.max(0,Math.min(maxX,camera.x));camera.y=viewport.height/camera.zoom>640?(640-viewport.height/camera.zoom)/2:Math.max(0,Math.min(maxY,camera.y));camera.mode=mode;
}
function worldPointer(e){const r=canvas.getBoundingClientRect();return {x:((e.clientX-r.left)*viewport.width/r.width/camera.zoom+camera.x)/40,y:((e.clientY-r.top)*viewport.height/r.height/camera.zoom+camera.y)/40};}
function screenPoint(x,y){const r=canvas.getBoundingClientRect();return {x:r.left+(x-camera.x)*camera.zoom*r.width/viewport.width,y:r.top+(y-camera.y)*camera.zoom*r.height/viewport.height};}
function resize(){const w=innerWidth,h=Math.max(1,innerHeight-parseInt(getComputedStyle(document.documentElement).getPropertyValue('--top')));viewport.width=960;viewport.height=960*h/w;canvas.style.width=w+'px';canvas.style.height=h+'px';const k=Math.min(2,devicePixelRatio||1);canvas.width=Math.round(w*k);canvas.height=Math.round(h*k);updateCamera();}
function serviceSignPoint(){return state.player.room==='street'?{room:'street',x:13,y:6}:{room:'restaurant',x:7,y:14};}
function positionDoorSign(){const b=$('openBtn'),outside=state.player.room==='street';const p=screenPoint(outside?675:345,outside?245:615),r=canvas.getBoundingClientRect();b.hidden=!['restaurant','street'].includes(state.player.room)||constructionMode||$('management').open||$('welcome').open||p.x<r.left+28||p.x>r.left+r.width-28||p.y<r.top+22||p.y>r.top+r.height-12;b.style.left=p.x+'px';b.style.top=p.y+'px';}
window.addEventListener('resize',resize);document.addEventListener('fullscreenchange',resize);resize();
function RECIPENAME(id){return R.RECIPES[id]?.name||'Morador'}
let previewCache=null;
function previewError(o){
 if(o.room!==state.player.room)return 'Vá ao setor indicado para colocar este objeto.';
 // Cache only the latest candidate. Include geometry and reserved actor cells,
 // so moving, rotating, placing and loading a game cannot reuse a stale result.
 const stamp=JSON.stringify([o.type,o.room,o.x,o.y,o.rot,building.moving,state.objects.map(q=>[q.type,q.room,q.x,q.y,q.rot]),R.allActors(state).map(a=>[a.room,R.reserved(a)])]);
 if(previewCache?.state===state&&previewCache.stamp===stamp)return previewCache.error;
 const error=R.layoutError(state,state.objects.filter(q=>q.id!==building.moving).concat({...o,id:building.moving||state.serial}));
 previewCache={state,stamp,error};return error;
}
function enterConstruction(){
 if(state.open||state.closing||state.customers.length)return tell('Conclua o serviço antes de construir.',true);
 if(state.player.room!=='restaurant')return tell('Entre no restaurante para construir.',true);
 pendingInteraction=null;releaseKeyboard();selectedObject=null;prepOptionsId=null;prepChoice=null;
 constructionMode=true;document.documentElement.classList.add('construction');
 $('management').close();$('constructionControls').hidden=false;$('constructionDrawer').hidden=true;
 $('catalogToggle').setAttribute('aria-expanded','false');dialogMode='build';dialogTab='catalog';
 resetFrameClock();resize();renderDialog();refresh();$('catalogToggle').focus?.();return true;
}
function exitConstruction(){
 stopBuild();constructionMode=false;buildPointer=null;
 document.documentElement.classList.remove('construction');$('constructionControls').hidden=true;$('constructionDrawer').hidden=true;
 resetFrameClock();resize();refresh();$('menuBtn').focus?.();
}
function toggleCatalog(){const drawer=$('constructionDrawer');drawer.hidden=!drawer.hidden;$('catalogToggle').setAttribute('aria-expanded',String(!drawer.hidden));if(!drawer.hidden){renderDialog();$('exitConstruction').focus?.();}}
$('catalogToggle').onclick=toggleCatalog;$('exitConstruction').onclick=exitConstruction;
function beginBuild(type,moving=null){if(!constructionMode)return;pendingInteraction=null;releaseKeyboard();let err=state.open||state.customers.length?'Conclua o serviço antes de montar.':null;if(err)return tell(err,true);if(!constructionMode&&!enterConstruction())return;$('management').close();$('constructionDrawer').hidden=true;$('catalogToggle').setAttribute('aria-expanded','false');building={type,rot:moving?state.objects.find(o=>o.id===moving).rot:0,moving};hover=null;state.player.goal=null;$('buildBar').hidden=false;$('buildLabel').textContent=(moving?'Mover: ':'Instalar: ')+R.CATALOG[type].name;$('buildStatus').textContent='Toque em uma célula do setor '+(R.CATALOG[type].area==='dryStorage'?'Cozinha ou estoque':R.CATALOG[type].area==='storage'?'Estoque':R.CATALOG[type].area==='kitchen'?'Cozinha':'Salão')+'.';$('confirmBtn').disabled=true;$('storeBuild').hidden=!moving;refresh();}
function stopBuild(){resetFrameClock();building=null;hover=null;$('buildBar').hidden=true;refresh()}
function updatePreview(){if(!building||!hover)return;let err=previewError({type:building.type,room:R.CATALOG[building.type].room,...hover,rot:building.rot});$('buildStatus').textContent=err||'Posição válida. Arraste o mapa para explorar. A seta da cadeira aponta para a mesa.';$('confirmBtn').disabled=!!err;}
$('storeBuild').onclick=()=>{if(!constructionMode||!building?.moving)return;const result=R.remove(state,building.moving);if(!result.ok){$('buildStatus').textContent=result.error;return}stopBuild();renderDialog();tell('Objeto guardado e valor devolvido.');};
$('rotateBtn').onclick=()=>{if(!constructionMode||!building)return;building.rot=(building.rot+1)%4;updatePreview()};$('cancelBuild').onclick=stopBuild;
$('confirmBtn').onclick=()=>{if(!constructionMode||!building||!hover)return;let r=R.place(state,building.type,hover.x,hover.y,building.rot,building.moving);if(!r.ok){$('buildStatus').textContent=r.error;return}stopBuild();renderDialog();tell('Objeto instalado. As rotas foram atualizadas.')};
canvas.onpointermove=e=>{if(!constructionMode)return;if(buildPointer&&(e.buttons||e.pointerType==='touch')){const r=canvas.getBoundingClientRect();camera.x-=(e.clientX-buildPointer.x)*viewport.width/r.width/camera.zoom;camera.y-=(e.clientY-buildPointer.y)*viewport.height/r.height/camera.zoom;buildPointer={x:e.clientX,y:e.clientY};updateCamera();if(building)building.locked=false;}if(!building||building.locked)return;hover={x:Math.floor(worldPointer(e).x),y:Math.floor(worldPointer(e).y)};updatePreview();};
canvas.onpointerup=canvas.onpointercancel=()=>{buildPointer=null;};
// One click queues exactly one action; walking and menus never repeat it.
let pendingInteraction=null;
function approachCustomer(c){
 const a=state.player,options=R.DIRS.map(([dx,dy])=>({room:c.room,x:c.x+dx,y:c.y+dy})).filter(p=>!R.blocked(state,p.room,p.x,p.y,a)&&R.route(state,p.room,a,p,a));
 options.sort((p,q)=>Math.abs(p.x-a.x)+Math.abs(p.y-a.y)-Math.abs(q.x-a.x)-Math.abs(q.y-a.y));
 if(!options.length)return false;R.go(a,options[0]);return true;
}
function queueInteraction(kind,target){
 const c=kind==='customer'?state.customers.find(c=>c.id===target):null;
 const o=kind!=='customer'?state.objects.find(o=>o.id===target):null;
 if(c&&!['waiting','ordered'].includes(c.state))return false;
 if(!c&&!o)return false;
 if(!(c?approachCustomer(c):R.goObject(state,state.player,o))){tell('Não há passagem até o alvo.',true);return true;}
 pendingInteraction={state,kind,target,phase:c?.state,until:state.time+30};
 processInteraction();return true;
}
function processInteraction(){
 const job=pendingInteraction;if(!job)return;
 if(job.state!==state||building||state.time>job.until){pendingInteraction=null;return;}
 if(job.kind==='serviceSign'){if(state.player.motion||!R.near(state.player,job.door||{room:'restaurant',x:7,y:14},1))return;pendingInteraction=null;if(state.open!==job.wasOpen||state.period!==job.period||state.closing||state.clock.ending)return;R.toggleOpen(state);tell(state.message,!state.open&&!state.closing);return;}
 const c=job.kind==='customer'?state.customers.find(c=>c.id===job.target):null;
 const o=job.kind!=='customer'?state.objects.find(o=>o.id===job.target):null;
 if(job.kind==='customer'&&(!c||c.state!==job.phase)||job.kind!=='customer'&&!o){pendingInteraction=null;return;}
 if(state.player.motion)return;
 if(!(c?R.near(state.player,c,1):R.objectNear(state,o)))return;
 pendingInteraction=null;
 if(c){const ok=R.interact(state,c.id);tell(state.message,!ok);}
 else {const r=job.kind==='wash'?R.washPlates(state,o.id):R.collectDirty(state,o.id);tell(r.message,!r.ok);}
}
function primaryObjectAction(o){
 if(o.type==='sink'&&R.inventoryCount(state,'dirtyPlate')>0)return queueInteraction('wash',o.id);
 const table=o.type==='table'?o:o.type==='chair'?R.seatTable(state,o):null;
 if(!table)return false;
 const chairs=state.objects.filter(ch=>ch.type==='chair'&&R.seatTable(state,ch)?.id===table.id);
 const clients=state.customers.filter(c=>chairs.some(ch=>ch.id===c.seat)&&['waiting','ordered'].includes(c.state));
 const matching=clients.find(c=>c.state==='ordered'&&(R.inventoryCount(state,'dish_'+c.recipe)>0||state.player.carry?.order===c.order));
 const client=matching||clients.find(c=>c.state==='waiting')||clients[0];
 if(client)return queueInteraction('customer',client.id);
 if(chairs.some(ch=>(state.dirtyTables[ch.id]||0)>0))return queueInteraction('clean',table.id);
 return false;
}
canvas.onpointerdown=e=>{prepOptionsId=null;prepChoice=null;pendingInteraction=null;releaseKeyboard();const r=canvas.getBoundingClientRect(),x=Math.floor(worldPointer(e).x),y=Math.floor(worldPointer(e).y);if(constructionMode){if(!building){const object=state.objects.find(o=>o.room===state.player.room&&R.hit(o,x,y));if(object){beginBuild(object.type,object.id);return}}buildPointer={x:e.clientX,y:e.clientY};canvas.setPointerCapture?.(e.pointerId);if(building){building.locked=true;hover={x,y};updatePreview();}return}let room=state.player.room;selectedObject=null;const portal=R.PORTALS[room].find(p=>p.x===x&&p.y===y);if(portal){selectedObject='portal:'+room+':'+portal.x+':'+portal.y;R.go(state.player,{room:portal.to,x:portal.spawn[0],y:portal.spawn[1]});refresh();return}const clickedClient=state.customers.find(c=>c.room===room&&c.x===x&&c.y===y&&['waiting','ordered'].includes(c.state));if(clickedClient){selectedObject=clickedClient.id;queueInteraction('customer',clickedClient.id);refresh();return}const o=state.objects.find(o=>o.room===room&&R.hit(o,x,y));if(o){selectedObject=o.id;if(primaryObjectAction(o)){refresh();return}if(!R.goObject(state,state.player,o))tell('Móvel sem acesso.',true);refresh();return}const person=R.allActors(state).find(a=>a!==state.player&&a.room===room&&a.x===x&&a.y===y);if(person){selectedObject=person.id;let options=R.DIRS.map(([dx,dy])=>({room,x:x+dx,y:y+dy})).filter(p=>!R.blocked(state,room,p.x,p.y,state.player)&&R.route(state,room,state.player,p,state.player));options.sort((p,q)=>Math.abs(p.x-state.player.x)+Math.abs(p.y-state.player.y)-Math.abs(q.x-state.player.x)-Math.abs(q.y-state.player.y));if(options[0])R.go(state.player,options[0]);refresh();return}if(room==='restaurant'&&x>=16&&x<=17&&y>=10&&y<=11){selectedObject='computer';R.go(state.player,{room,x:16,y:12});refresh();return}if(room==='restaurant'&&x>=20&&x<=22&&y===11){selectedObject='receiving';R.go(state.player,{room,x:21,y:12});refresh();return}if(x<0||x>=R.W||y<0||y>=R.H)return;if(!R.route(state,room,state.player,{x,y},state.player))return tell('Passagem bloqueada. Toque em uma célula livre.',true);R.go(state.player,{room,x,y,offsetX:worldPointer(e).x-x-.5,offsetY:worldPointer(e).y-y-.5});refresh();};
function nearbyObjects(){return state.objects.filter(o=>o.room===state.player.room&&R.accessPoints(state,o).some(p=>R.near(state.player,p,0)))}
function actionRow(o){let row=document.createElement('div');row.className='objectActions';row.anchor={x:o.x,y:o.y,w:R.CATALOG[o.type]?R.rect(o).w:1,lift:state.customers.some(c=>c.id===o.id||c.seat===o.id||o.type==='table'&&state.objects.some(ch=>ch.id===c.seat&&R.hit(o,ch.x+R.DIRS[ch.rot][0],ch.y+R.DIRS[ch.rot][1])))?40:0};$('context').append(row);return row;}
const CONTROL_PATHS={
 "door": "M4 2h9v12H4z M10 8h1",
 "computer": "M2 3h12v8H2z M1 14h14 M7 12h2",
 "box": "M2 5l6-3 6 3v7l-6 3-6-3z M2 5l6 3 6-3 M8 8v7",
 "bag": "M3 6h10v8H3z M5 6V3h6v3 M5 10h6",
 "pot": "M3 6h10v6l-2 2H5l-2-2z M1 7h2 M13 7h2 M4 4h8 M7 2h2",
 "take": "M2 10v4h12v-4 M8 11V2 M4 6l4-4 4 4",
 "flame": "M8 1l3 6 2-2 1 5-3 4H6l-4-4 3-5 1 3z",
 "wash": "M2 9l3-3 9 2-2 5-10-1z M4 3h2 M9 2h2",
 "bin": "M3 4h10 M6 2h4 M4 6l1 8h6l1-8 M7 7v4 M9 7v4",
 "note": "M3 2h10v12H3z M5 5h6 M5 8h6 M5 11h4",
 "serve": "M1 12h14 M3 10a5 5 0 0 1 10 0z M7 3h2",
 "options": "M2 4h12 M2 8h12 M2 12h12 M5 2v4 M11 6v4 M6 10v4",
 "screen": "M2 6V2h4 M10 2h4v4 M14 10v4h-4 M6 14H2v-4",
 "hammer": "M2 12l7-7 2 2-7 7z M7 3l2-2 5 5-2 2z"
};
function controlIcon(kind){
 const icon=document.createElement('span');
 icon.className='controlIcon';icon.setAttribute('aria-hidden','true');
 icon.innerHTML='<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"><path d="'+CONTROL_PATHS[kind]+'"/></svg>';
 return icon;
}
function action(row,icon,label,fn,disabled=false){const b=button('',fn,row,disabled);b.append(controlIcon(icon));b.className='objectAction';const short=({'Instalar panela vazia':'Instalar panela','Retirar panela vazia':'Retirar panela','Retirar panela cheia':'Retirar panela','Escolher receita e cozinhar 4 porções':'Receitas','Instalar pratos limpos':'Instalar pratos','Instalar talher':'Instalar talher','Empratar panela da mochila':'Empratar','Retirar prato pronto para a mochila':'Retirar prato','Cancelar empratamento':'Cancelar'})[label];if(short){const caption=document.createElement('small');caption.textContent=short;b.append(caption);b.className+=' kitchenQuickAction';}b.title=typeof FoodArt!=='undefined'&&FoodArt.parts(label).some(p=>p.food)?'':label;b.setAttribute('aria-label',label);if(icon==='serve'&&typeof FoodArt!=='undefined'){const recipe=Object.entries(R.RECIPES).find(([,r])=>label.includes(r.name));if(recipe)b.replaceChildren(FoodArt.icon(recipe[0]));}return b;}
function positionActions(){positionDoorSign();if(!$('context').children.length)return;const bounds=canvas.getBoundingClientRect(),scale=bounds.width/960,used=[];for(const row of $('context').children){if(row.className.includes('prepPanel'))continue;let a=row.anchor;if(!a)continue;const width=row.getBoundingClientRect().width||row.children.length*48;let x=Math.max(6,Math.min(innerWidth-width-6,bounds.left+((a.x+a.w/2)*40-camera.x)*camera.zoom*scale-width/2)),y=Math.max(62,bounds.top+(a.y*40-camera.y)*camera.zoom*scale-52-(a.lift||0));for(let k=0;k<6&&used.some(p=>Math.abs(p.y-y)<48&&p.x<x+width&&p.x+p.w>x);k++)y=Math.max(58,y-50);row.style.left=x+'px';row.style.top=y+'px';used.push({x,y,w:width});}}
function quickKitchen(o,action,item=null){const r=R.kitchenAction(state,o.id,action,item);tell(r.message,!r.ok)}
// Compact non-modal workstation. Only ambiguous recipe choices expand a selector.
function renderPrepActions(row,o){
 row.className+=' prepPanel';row.setAttribute('aria-label','Mesa de preparo');
 const heading=document.createElement('div');heading.className='prepHeading';
 const title=document.createElement('strong');title.textContent='Mesa de preparo';heading.append(title);
 button('Fechar',()=>{selectedObject=null;prepOptionsId=null;prepChoice=null;refresh()},heading).className='prepClose';row.append(heading);
 const slots=document.createElement('div');slots.className='prepSlots';row.append(slots);
 function slot(kind,label,value,installed,fn,disabled){
  const b=button('',fn,slots,disabled);b.className='prepSlot'+(installed?' installed':' empty');b.setAttribute('aria-label',label);
  const icon=document.createElement('span');icon.className='prepSlotIcon';icon.setAttribute('aria-hidden','true');
  icon.innerHTML=kind==='plate'?'<svg viewBox="0 0 40 32"><path d="M5 18h30v5H5z" fill="#86a89c"/><ellipse cx="20" cy="18" rx="16" ry="8" fill="#fff0cf"/><ellipse cx="20" cy="17" rx="10" ry="4" fill="#b5c9b9"/></svg>':'<svg viewBox="0 0 40 32"><path d="M18 12h5v18h-5z" fill="#92b1ac"/><ellipse cx="20" cy="9" rx="7" ry="8" fill="#d6e5d9"/></svg>';
  const text=document.createElement('span');text.textContent=value;b.append(icon,text);
 }
 slot('plate','Instalar pratos limpos',o.plates+' pratos • Repor',o.plates>0,()=>quickKitchen(o,'installPlates'),!R.inventoryCount(state,'plate')||o.plates>=99);
 slot('spoon',o.utensil?'Talher instalado':'Instalar talher',o.utensil?'Talher instalado':'Talher • Instalar',o.utensil,()=>quickKitchen(o,'installUtensil'),!!o.utensil||!R.inventoryCount(state,'spoon'));
 const recipes=[...new Set(state.inventory.filter(p=>p?.item.startsWith('pot_')&&!p.burned).map(p=>R.ITEMS[p.item].recipe))];
 const eligible=recipes.filter(id=>!R.platingPlan(state,o,id).error);
 const dishes=Object.entries(o.dishes||{}).filter(([,n])=>n>0);
 const working=state.plating?.prep===o.id;
 let reason=working?'Empratando… permaneça perto da bancada.':state.plating?'Outra bancada está em uso.':!o.utensil?'Instale um talher para empratar.':!o.plates?'Reponha os pratos limpos para empratar.':!recipes.length?'Traga uma panela com comida na mochila.':!eligible.length?R.platingPlan(state,o,recipes[0]).error:'Panela pronta para empratar.';
 const status=document.createElement('p');status.className='prepHint';status.textContent=reason;row.append(status);
 function plate(id){prepChoice=null;const r=R.plateFood(state,o.id,id);tell(r.message,!r.ok)}
 function take(id){prepChoice=null;quickKitchen(o,'takeDish',id)}
 const main=document.createElement('div');main.className='prepPrimary';row.append(main);
 const plateButton=button(working?'Empratando…':'Empratar',()=>{if(eligible.length===1)plate(eligible[0]);else{prepChoice=prepChoice==='plate'?null:'plate';refresh()}},main,!!state.plating||!eligible.length);plateButton.setAttribute('aria-label','Empratar panela da mochila');
 const takeButton=button('Retirar prato',()=>{if(dishes.length===1)take(dishes[0][0]);else{prepChoice=prepChoice==='take'?null:'take';refresh()}},main,!dishes.length);takeButton.setAttribute('aria-label','Retirar prato pronto para a mochila');
 const ready=document.createElement('div');ready.className='prepReady';
 const readyTitle=document.createElement('strong');readyTitle.textContent='Prontos: '+R.readyCount(o)+'/'+R.KITCHEN_CONFIG.readyCapacity;ready.append(readyTitle);
 const counts=document.createElement('span');counts.textContent=dishes.length?dishes.map(([id,n])=>R.RECIPES[R.ITEMS[id].recipe].name+' ×'+n).join(' • '):'Nenhum prato pronto';if(dishes.length&&typeof FoodArt!=='undefined'){counts.textContent='';for(const [dish]of dishes)for(let q=0;q<4;q++){const n=R.objectQualityCount(o,dish,q);if(n){counts.append(FoodArt.icon(dish,q),document.createTextNode(' ×'+n+' '));}}}ready.append(counts);row.append(ready);
 if(prepChoice){
  const choices=document.createElement('div');choices.className='prepChoices';
  const label=document.createElement('strong');label.textContent=prepChoice==='plate'?'Qual panela deseja empratar?':'Qual prato levar na mochila?';choices.append(label);
  if(prepChoice==='plate')for(const id of eligible)button(R.RECIPES[id].name,()=>plate(id),choices);
  else for(const [id,n]of dishes)button(R.RECIPES[R.ITEMS[id].recipe].name+' ×'+n,()=>take(id),choices);
  button('Cancelar escolha',()=>{prepChoice=null;refresh()},choices).className='secondary';row.append(choices);
 }
 if(working)button('Cancelar empratamento',()=>{const r=R.cancelPlating(state);tell(r.message,!r.ok)},row).className='prepSecondary';
 if(R.canceledCarry(state,state.player))button('Devolver prato cancelado',()=>{const ok=R.pickupDish(state);tell(ok?'Prato devolvido.':'Sem espaço para devolver o prato.',!ok)},row).className='prepSecondary';
 const more=button(prepOptionsId===o.id?'Menos opções':'Mais opções',()=>{prepOptionsId=prepOptionsId===o.id?null:o.id;refresh()},row);more.className='prepSecondary';more.setAttribute('aria-expanded',String(prepOptionsId===o.id));
 if(prepOptionsId===o.id){
  const options=document.createElement('div');options.className='prepOptions';row.append(options);
  if(!R.canceledCarry(state,state.player))button('Retirar prato para pedido',()=>{const ok=R.pickupDish(state);tell(ok?'Prato retirado. Leve ao cliente.':'Nenhum prato compatível ou suas mãos estão ocupadas.',!ok)},options,!!state.player.carry||!state.orders.some(q=>q.state==='ordered'&&R.objectCount(o,'dish_'+q.recipe)>0));
  if(!state.open&&!state.customers.length){
   button('Retirar pratos limpos',()=>quickKitchen(o,'takePlates'),options,!o.plates);
   button('Retirar talher',()=>quickKitchen(o,'takeUtensil'),options,!o.utensil);
  }
 }
}
function useContext(){const sig=JSON.stringify([prepOptionsId,prepChoice,selectedObject,!!building,$('management').open,state.player.room,state.player.x,state.player.y,R.isMoving(state.player),state.player.carry,state.inventory,state.objects,state.open,state.closing,state.cooking?.stove,state.plating?.prep,state.customers.map(c=>[c.id,c.x,c.y,c.state,c.order]),state.orders.map(o=>[o.id,o.state])]);if(useContext.lastSig===sig)return;useContext.lastSig=sig;let box=$('context');box.replaceChildren();if(constructionMode||$('management').open)return;const a=state.player;if(R.isMoving(a)||selectedObject===null)return;const rows=new Map();function rowFor(o){let k=o.id||o.name||o.x+':'+o.y;if(!rows.has(k))rows.set(k,actionRow(o));return rows.get(k);}
 for(const p of R.PORTALS[a.room].filter(p=>selectedObject==='portal:'+a.room+':'+p.x+':'+p.y&&R.near(a,{...p,room:a.room},1))){let row=actionRow(p);action(row,'door',p.name,()=>R.go(a,{room:p.to,x:p.spawn[0],y:p.spawn[1]}));}
 if(selectedObject==='computer'&&R.near(a,{room:'restaurant',x:16,y:12},1)){let row=actionRow({x:16,y:11});action(row,'computer','Usar computador',()=>openDialog('computer'));}
 if(selectedObject==='receiving'&&R.near(a,{room:'restaurant',x:21,y:12},1)){let row=actionRow({x:21,y:11});action(row,'box','Recolher ingredientes',()=>tell(R.collectReceiving(state)));}
 for(const o of nearbyObjects().filter(o=>o.id===selectedObject)){
 const row=rowFor(o);if(o.inventory&&!['stove','prep','sink','bin'].includes(o.type))action(row,'bag','Abrir '+R.CATALOG[o.type].name,()=>openObjectInventory(o.id));
 if(o.type==='stove'){
  if(!o.pan)action(row,'pot','Instalar panela vazia',()=>quickKitchen(o,'installPan'));
  else if(o.pan!=='cookingPot')action(row,'take',o.pan==='pot'?'Retirar panela vazia':'Retirar panela cheia',()=>quickKitchen(o,'takePan'));
  action(row,'flame','Escolher receita e cozinhar 4 porções',()=>{dialogObjectId=o.id;openDialog('cooking')},!!state.cooking);
 }
 if(o.type==='prep'){renderPrepActions(row,o);continue;}
 if(o.type==='sink')action(row,'wash','Lavar pratos',()=>{let r=R.washPlates(state,o.id);tell(r.message,!r.ok)});
 if(['sink','bin'].includes(o.type))action(row,'bin','Descartar comida e esvaziar panela',()=>{const eligible=(p,i)=>p&&(p.item.startsWith('pot_')||p.item.startsWith('dish_'))&&state.plating?.slot!==i;let i=eligible(state.inventory[state.selectedSlot],state.selectedSlot)?state.selectedSlot:state.inventory.findIndex(eligible);let r=R.discardFood(state,o.id,i);tell(r.message,!r.ok)});
 if(o.type==='table')action(row,'wash','Recolher pratos sujos da mesa',()=>{let r=R.collectDirty(state,o.id);tell(r.message,!r.ok)});
 }
 for(const c of state.customers.filter(c=>R.near(a,c,1))){const chair=state.objects.find(o=>o.id===c.seat),selected=state.objects.find(o=>o.id===selectedObject);let table=null;if(chair){let [dx,dy]=R.DIRS[chair.rot];table=state.objects.find(o=>o.type==='table'&&R.hit(o,chair.x+dx,chair.y+dy));}if(selectedObject!==c.id&&selectedObject!==c.seat&&selectedObject!==table?.id)continue;const row=rowFor(selected||chair||c);if(c.state==='waiting')action(row,'note','Anotar pedido',()=>{R.interact(state,c.id);tell(state.message)});if(c.state==='ordered')action(row,'serve','Servir '+RECIPENAME(c.recipe),()=>{R.interact(state,c.id);tell(state.message)});}
 positionActions();
}

function refresh(){let period=state.period===0?'Almoço':'Jantar',date=R.calendarDate(state.day);$('hud').innerHTML=`<div class="hudLeft"><span class="shiftHud">${period} • ${state.clock.ending?'Encerrando o dia':state.closing?'Concluindo':state.open?'Aberto':state.clock.minute>=R.serviceHours(state)[state.period].end?'Encerrado':state.clock.minute<R.serviceHours(state)[state.period].start?'Preparação':'Fechado'}</span><span class="reputationHud">★ ${state.reputation.score}/100 • ${R.reputationLevel(state.reputation.score)}</span></div><div class="hudRight"><span class="calendarHud">${R.clockText(state)} • ${date.weekday} ${date.day} • ${date.season} • Ano ${date.year}</span><span class="money">${money(state.cash)}</span></div>`;$('location').textContent=NAME[state.player.room];$('openBtn').textContent=state.closing?'Encerrando':state.open?(state.player.room==='street'?'Encerrar restaurante':'Aberto'):state.clock.minute<R.serviceHours(state)[state.period].start?'Abre às '+R.serviceTimeText(R.serviceHours(state)[state.period].start):state.player.room==='street'?'Abrir restaurante':'Fechado';$('openBtn').setAttribute('aria-label',state.closing?'Conclua os pedidos':state.open?'Encerrar '+period.toLowerCase():'Abrir '+period.toLowerCase());$('openBtn').setAttribute('data-open',String(state.open));$('openBtn').disabled=state.clock.ending||state.closing||!!building;positionDoorSign();
 let a=state.player,load=a.carry?(a.carry.kind==='food'?`${a.carry.n} ${R.FOODS[a.carry.food].name}`:'Prato: '+RECIPENAME(state.orders.find(o=>o.id===a.carry.order)?.recipe)):'sem carga';$('hint').textContent=`${NAME[a.room]} • ${load} • Mochila ${state.inventory.filter(Boolean).length}/10`+(state.inventory[state.selectedSlot]?' • Selecionado: '+R.ITEMS[state.inventory[state.selectedSlot].item].name:'')+(a.wait>=5?' • Aguardando passagem.':state.open?' • Anote pedidos, cozinhe e sirva.':' • Prepare-se para '+period.toLowerCase()+'.');
 if(state.clock.ending)$('hint').textContent+=' • 02:00: conclua clientes e preparos; o próximo dia começa às 06:00.';
 if(state.cooking)$('hint').textContent+=' • '+R.RECIPES[state.cooking.recipe].name+': '+Math.ceil(state.cooking.left)+'s'+' • Cozinha avança enquanto você faz outras tarefas.';
 let active=state.orders.filter(o=>!['paid','lost'].includes(o.state));let signature=active.map(o=>o.id+o.state+Math.floor(o.age)).join('|')+';'+state.customers.filter(c=>c.state==='waiting').map(c=>c.id+Math.floor(c.experience.elapsed.service)).join(',');if(renderedKey!==signature){renderedKey=signature;let h=$('ordersHud');h.replaceChildren();for(const c of state.customers.filter(c=>c.state==='waiting')){let d=document.createElement('div');d.className='orderCard';const indicator=R.customerIndicator(state,c);d.textContent=(indicator?indicator.emoji+' ':'')+'Mesa aguardando pedido'+(indicator?' • '+Math.ceil(indicator.remaining)+'s de paciência':'');h.append(d)}for(const o of active){let d=document.createElement('div');d.className='orderCard';let title=document.createElement('b');title.textContent='#'+o.id+' • '+RECIPENAME(o.recipe);d.append(title);const customer=state.customers.find(c=>c.id===o.customer),indicator=customer&&R.customerIndicator(state,customer);let cooking=indicator?' • '+indicator.emoji+(indicator.phase?' '+Math.ceil(indicator.remaining)+'s de paciência':' '+indicator.label):'';d.append(document.createTextNode(({ordered:'A preparar',cooking:'No fogão',ready:'Pronto para servir',eating:'Cliente comendo'})[o.state]+cooking+' • espera '+Math.floor(o.age)+'s'));if(o.state==='ordered')button(state.priority===o.id?'Prioritário':'Priorizar',()=>{state.priority=o.id;renderedKey='';refresh()},d);h.append(d)}}
 if(constructionMode){$('constructionCash').textContent='Disponível: '+money(state.cash);$('constructionNotice').textContent=state.message;}drawKitchenStatus();useContext();if(typeof FoodArt!=='undefined')for(const id of ['panel','context','ordersHud','hint','notice','menuNotice','kitchenStatus','welcome'])FoodArt.decorate($(id));}
$('openBtn').onclick=()=>{
 if(building||state.closing||state.clock.ending||!['restaurant','street'].includes(state.player.room))return;
 pendingInteraction=null;releaseKeyboard();const door=serviceSignPoint();
 if(!R.near(state.player,door,1)){const points=[door,...R.DIRS.map(([dx,dy])=>({...door,x:door.x+dx,y:door.y+dy}))].filter(p=>!R.blocked(state,p.room,p.x,p.y,state.player)&&R.route(state,p.room,state.player,p,state.player));points.sort((p,q)=>Math.abs(p.x-state.player.x)+Math.abs(p.y-state.player.y)-Math.abs(q.x-state.player.x)-Math.abs(q.y-state.player.y));if(!points.length)return tell('Não há passagem até a plaquinha.',true);R.go(state.player,points[0]);}
 pendingInteraction={state,kind:'serviceSign',door,wasOpen:state.open,period:state.period,until:state.time+30};processInteraction();refresh();};
$('inventoryBtn').onclick=()=>openDialog('inventory');$('menuBtn').onclick=()=>openDialog('general');$('optionsBtn').onclick=()=>openDialog('options');$('closeDialog').onclick=()=>$('management').close();
function openObjectInventory(id){const o=state.objects.find(o=>o.id===id);if(['stove','prep','sink','bin'].includes(o?.type))return tell('Use as ações rápidas do equipamento.');if(!o?.inventory||state.player.motion||!R.accessPoints(state,o).some(p=>R.near(state.player,p,0)))return tell('Aproxime-se do objeto.',true);dialogObjectId=id;openDialog('container');}
function openDialog(mode){if(mode==='build')return enterConstruction();if(constructionMode)return;pendingInteraction=null;releaseKeyboard();$('management').setAttribute('data-mode',mode);if(mode==='computer'&&!R.near(state.player,{room:'restaurant',x:16,y:12},1))return tell('Aproxime-se do computador.',true);dialogMode=mode;dialogTab=['cooking','plating'].includes(mode)?mode:mode==='container'?'container':mode==='inventory'?'inventory':mode==='build'?'catalog':mode==='computer'?'supplier':mode==='options'?'camera':'shifts';$('management').showModal();renderDialog();}
function card(title,description,action,label='Selecionar',disabled=false){let d=document.createElement('div');d.className='card';let b=document.createElement('b');b.textContent=title;d.append(b);let p=document.createElement('p');p.textContent=description;d.append(p);if(action)button(label,action,d,disabled);return d;}
function table(headers,rows){let wrap=document.createElement('div');wrap.className='tableWrap';let t=document.createElement('table'),thead=t.createTHead(),tr=thead.insertRow();for(const h of headers){let th=document.createElement('th');th.textContent=h;tr.append(th)}let body=t.createTBody();for(const row of rows){let tr=body.insertRow();for(const cell of row){let td=tr.insertCell();if(cell&&typeof cell==='object')td.append(cell);else td.textContent=cell}}wrap.append(t);return wrap;}
function renderDialog(){let panel=$(constructionMode?'constructionPanel':'panel'),tabs=$(constructionMode?'constructionTabs':'tabs');panel.replaceChildren();tabs.replaceChildren();tabs.hidden=dialogMode==='cooking';$('menuNotice').textContent='';$('dialogTitle').textContent=dialogMode==='cooking'?'Fogão • preparar lote':dialogMode==='plating'?'Mesa • empratar':dialogMode==='container'?'Inventários • '+R.CATALOG[state.objects.find(o=>o.id===dialogObjectId).type].name:dialogMode==='inventory'?'Inventário':dialogMode==='computer'?'Computador • restaurante':dialogMode==='build'?'Modo construção':dialogMode==='options'?'Opções':'Gestão do restaurante';let ts=dialogMode==='cooking'?{}:dialogMode==='plating'?{plating:'Empratamento'}:dialogMode==='container'?{container:'Transferir itens'}:dialogMode==='inventory'?{inventory:'Mochila • 10 espaços'}:dialogMode==='computer'?{supplier:'Fornecedor',tools:'Utensílios',menu:'Cardápio e preços',deliveries:'Entregas'}:dialogMode==='build'?{catalog:'Móveis'}:dialogMode==='options'?{camera:'Câmera',save:'Salvar e carregar',test:'Testes',guide:'Primeiros passos'}:{shifts:'Turnos',build:'Modo construção',team:'Equipe',finance:'Fechamento',customers:'Clientes',calendar:'Calendário',reputation:'Reputação'};for(const [id,name]of Object.entries(ts)){let b=button(name,()=>{if(id==='build')return openDialog('build');if(id==='management')return openDialog('general');dialogTab=id;renderDialog()},tabs);if(dialogTab===id){b.classList.add('active');b.setAttribute('aria-current','page')}}

 if(dialogTab==='camera'){
 panel.innerHTML='<p>Ajuste a distância para ver mais do restaurante ou aproximar os detalhes. A visão mais ampla usa 70%. A proporção da tela também determina o enquadramento.</p>';
 const row=document.createElement('div');row.className='cameraControls';const value=document.createElement('output');value.textContent=Math.round(cameraLevel*100)+'%';
 const change=delta=>{setCameraLevel(cameraLevel+delta);renderDialog()};button('− Afastar',()=>change(-.1),row,cameraLevel<=.7);row.append(value);button('+ Aproximar',()=>change(.1),row,cameraLevel>=2);panel.append(row);button('Restaurar zoom padrão (100%)',()=>{setCameraLevel(1);renderDialog()},panel);
 const fullscreen=button('Alternar tela cheia',()=>{},panel);fullscreen.id='fullscreenBtn';
 }
 if(dialogTab==='shifts'){
 panel.innerHTML='<p>A plaquinha abre o serviço dentro dos horários abaixo. Fechar antes da hora mantém o mesmo turno. No fim do horário, param as entradas e os clientes presentes concluem o atendimento. Horários da madrugada pertencem ao mesmo dia jogável. Alterações exigem o serviço concluído.</p>';
 const inputs=[];const busy=state.open||state.closing||R.servicePending(state);
 R.serviceHours(state).forEach((hours,i)=>{const c=card(i===0?'Almoço':'Jantar','',null);for(const [key,name]of [['start','Início'],['end','Término']]){const label=document.createElement('label');label.textContent=name+' ';const sel=document.createElement('select');sel.setAttribute('aria-label',(i===0?'Almoço':'Jantar')+' — '+name);for(let m=360;m<=1560;m+=10)sel.add(new Option(R.serviceTimeText(m)+(m>=1440?' (madrugada)':''),m));sel.value=hours[key];sel.disabled=busy;label.append(sel);c.append(label);inputs.push({i,key,sel});}panel.append(c);});
 button('Aplicar horários',()=>{const hours=[{},{}];for(const {i,key,sel}of inputs)hours[i][key]=Number(sel.value);const res=R.setServiceHours(state,hours);if(res.ok)renderDialog();tell(res.message,!res.ok)},panel,busy);
 }
 if(dialogTab==='catalog'){panel.innerHTML=constructionMode?'<p>Escolha um móvel para comprar ou clique em um objeto instalado para mover, girar ou guardar. A compra é cobrada ao confirmar.</p>':'<p>Toque em um objeto e depois no mapa. Corredores precisam ficar livres. Mesas/cadeiras vão no salão; fogão/geladeira na cozinha. Prateleira na cozinha ou no estoque; geladeira do estoque no estoque. Rotação e custos de reorganização são provisórios.</p>';let cards=document.createElement('div');cards.className='cards';for(const [id,d]of Object.entries(R.CATALOG)){const itemCard=card(d.name,`${money(d.price)} • ${d.w} × ${d.h} células • ${d.area==='dryStorage'?'Cozinha ou estoque':d.area==='storage'?'Estoque':d.area==='hall'?'Salão':'Cozinha'}`,()=>beginBuild(id),'Posicionar',state.open||state.cash<d.price);const icon=RestaurantArt.catalogIcon(id,d.name);itemCard.append(icon);cards.append(itemCard);};panel.append(cards)}
 if(dialogTab==='tools'&&dialogMode==='computer'){
 const balance=document.createElement('p');balance.className='shopBalance';balance.textContent='Disponível: '+money(state.cash)+' • As compras vão para a mochila.';panel.append(balance);
 let cards=document.createElement('div');cards.className='cards';
 for(const [id,name,price]of [['pot','Panela vazia',25],['spoon','Colher / utensílio',15],['plate','Prato limpo',5]]){
 const item=card(name,`${money(price)} • no inventário: ${R.inventoryCount(state,id)}`,()=>{let ok=R.buyTool(state,id);renderDialog();tell(ok?'Item adicionado ao inventário.':'Saldo insuficiente ou inventário cheio.',!ok)},'Comprar',state.cash<price||R.inventorySpace(state,id)===0);
 item.append(RestaurantArt.toolIcon(id,name));cards.append(item);
 }panel.append(cards)}
 if(dialogTab==='inventory'){
 let help=document.createElement('p');help.textContent='10 espaços • até 99 itens por pilha. Ingredientes são usados diretamente daqui. Instale a panela no fogão por ação rápida, retire a panela cheia e leve-a à bancada para empratar. Pratos e talher ficam instalados na bancada. Panelas com comida são unitárias.';panel.append(help);
 const grid=document.createElement('div');grid.className='inventoryGrid';const icons={arroz:'🌾',legumes:'🥕',frango:'🍗',pot:'🍲',spoon:'🥄'};
 state.inventory.forEach((slot,i)=>{const b=button('',()=>{state.selectedSlot=i;renderDialog()},grid);b.className='inventorySlot'+(state.selectedSlot===i?' selected':'');b.setAttribute('aria-pressed',String(state.selectedSlot===i));b.setAttribute('aria-label','Espaço '+(i+1)+': '+(slot?R.ITEMS[slot.item].name+', '+slot.n+' itens':'vazio'));let icon=document.createElement('span');icon.className='itemIcon';if(slot&&typeof FoodArt!=='undefined'&&FoodArt.key(slot.item))icon.append(FoodArt.icon(slot.item,slot.quality??0));else if(slot&&['pot','spoon','plate'].includes(slot.item))icon.append(RestaurantArt.toolIcon(slot.item,R.ITEMS[slot.item].name));else if(slot)icon.append(controlIcon('wash'));b.append(icon);let name=document.createElement('span');name.textContent=slot?(typeof FoodArt!=='undefined'&&FoodArt.key(slot.item)?(slot.burned?'Queimado • descartar':slot.item.startsWith('pot_')?'Panela • '+R.ITEMS[slot.item].servings+'/4':''):R.ITEMS[slot.item].name):'Vazio';b.append(name);let count=document.createElement('small');count.textContent=slot?slot.n+'/'+R.itemLimit(slot.item):'—';b.append(count);});panel.append(grid);
 if(state.recovery.length){const info=document.createElement('p');info.textContent='Itens preservados do salvamento anterior: '+state.recovery.reduce((n,p)=>n+p.n,0)+'. Retire conforme liberar espaço.';panel.append(info);button('Recolher itens preservados',()=>{const r=R.recoverItems(state);renderDialog();tell(r.message,!r.ok)},panel);}
 let chosen=state.inventory[state.selectedSlot],label=document.createElement('p');label.textContent='Selecionado: '+(chosen?R.ITEMS[chosen.item].name+' × '+chosen.n:'espaço vazio');panel.append(label);
 }
 if(dialogTab==='container'){
 const o=state.objects.find(o=>o.id===dialogObjectId);if(!o?.inventory){$('management').close();return;}
 let help=document.createElement('p');help.textContent='Toque numa pilha para transferir para o outro lado. Cada inventário tem 10 espaços, até 99 por pilha. Panelas com comida ocupam um espaço cada. A transferência respeita o espaço disponível; o restante fica na origem.';panel.append(help);
 const quantityLabel=document.createElement('label');quantityLabel.textContent='Quantidade por transferência (use 1 para separar colheres/panelas): ';const quantityInput=document.createElement('input');quantityInput.type='number';quantityInput.min=1;quantityInput.max=99;quantityInput.value=transferQuantity;quantityInput.setAttribute('aria-label','Quantidade por transferência');quantityInput.onchange=()=>{const n=Number(quantityInput.value);if(Number.isInteger(n)&&n>=1&&n<=99)transferQuantity=n;else{quantityInput.value=transferQuantity;tell('Informe de 1 a 99.',true)}};quantityLabel.append(quantityInput);panel.append(quantityLabel);
 const split=document.createElement('div');split.className='splitInventories';
 for(const [side,title,slots] of [['player','Sua mochila',state.inventory],['object',R.CATALOG[o.type].name+' #'+o.id,o.inventory]]){
 const pane=document.createElement('section');pane.className='inventoryPane';pane.setAttribute('aria-label',title);let heading=document.createElement('h2');heading.textContent=title;pane.append(heading);
 let subtitle=document.createElement('p');subtitle.textContent=side==='player'?'Toque para guardar →':'← Toque para retirar • '+(o.type==='stove'?'ingredientes, panela e colher':o.type==='prep'?'panela com comida, pratos e colher':o.type==='sink'?'pratos sujos e panelas':o.type==='bin'?'comida para descarte':o.type==='shelf'?'ingredientes secos':'ingredientes refrigerados');pane.append(subtitle);
 const grid=document.createElement('div');grid.className='inventoryGrid';const icons={arroz:'🌾',legumes:'🥕',frango:'🍗',pot:'🍲',spoon:'🥄'};
 slots.forEach((slot,i)=>{let b=button('',()=>{let r=R.transferSlot(state,o.id,side,i,transferQuantity);renderDialog();tell(r.ok?'Transferiu '+r.n+' itens.':r.error,!r.ok);},grid,!slot);b.className='inventorySlot';b.setAttribute('aria-label',title+' • espaço '+(i+1)+': '+(slot?R.ITEMS[slot.item].name+' × '+slot.n:'vazio'));let icon=document.createElement('span');icon.className='itemIcon';if(slot&&typeof FoodArt!=='undefined'&&FoodArt.key(slot.item))icon.append(FoodArt.icon(slot.item,slot.quality??0));else if(slot&&['pot','spoon','plate'].includes(slot.item))icon.append(RestaurantArt.toolIcon(slot.item,R.ITEMS[slot.item].name));else if(slot)icon.append(controlIcon('wash'));b.append(icon);let name=document.createElement('span');name.textContent=slot?(typeof FoodArt!=='undefined'&&FoodArt.key(slot.item)?(slot.burned?'Queimado • descartar':slot.item.startsWith('pot_')?'Panela • '+R.ITEMS[slot.item].servings+'/4':''):R.ITEMS[slot.item].name):'Vazio';b.append(name);let n=document.createElement('small');n.textContent=slot?slot.n+'/'+R.itemLimit(slot.item):'—';b.append(n);});pane.append(grid);split.append(pane);
 }panel.append(split);
 }
 if(['cooking','plating'].includes(dialogTab)){
 const o=state.objects.find(o=>o.id===dialogObjectId);if(!o){$('management').close();return;}
 if(dialogTab==='plating'){const help=document.createElement('p');help.textContent='A panela cheia fica na mochila. Instale pratos e talher na bancada; emprate e deixe os pratos na área de retirada para você ou o garçom.';panel.append(help);}
 if(dialogTab==='cooking'){
  const slot=o.pan?document.createElement('div'):button('Vazio',()=>{quickKitchen(o,'installPan');renderDialog()},panel);
  slot.className='panSlot'+(o.pan?' occupied':' empty');
  slot.setAttribute('aria-label',o.pan?R.itemName(o.pan)+' instalada no fogão':'Vazio — instalar panela');
  slot.title=o.pan?.startsWith('pot_')?'':o.pan?R.itemName(o.pan):'Instalar panela vazia';
  if(o.pan){
   slot.setAttribute('role','img');
   const filled=o.pan.startsWith('pot_'),cooking=o.pan==='cookingPot';
   slot.innerHTML='<svg viewBox="0 0 80 80" aria-hidden="true" focusable="false" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges"><path d="M10 33h12v8H10zm48 0h12v8H58z" fill="#68878a"/><path d="M20 30h40v28H20z" fill="#a7bdba"/><path d="M24 34h32v20H24z" fill="#789a99"/><path d="M24 34h5v18h-5z" fill="#d4e3d8"/><path d="M20 54h40v5H20z" fill="#3c6164"/><path d="M18 27h44v8H18z" fill="#d4e3d8"/><path d="M23 29h34v5H23z" fill="'+(filled?'#dca34f':'#335357')+'"/>'+(filled?'<path d="M29 29h6v3h-6zm15 1h5v3h-5z" fill="#749760"/>':'<path d="M26 22h28v5H26zm9-5h10v5H35z" fill="#91b3b0"/>')+(cooking?'<path d="M29 8h4v8h-4zm18-3h4v9h-4z" fill="#e3ddbb"/>':'')+'</svg>';
   panel.append(slot);
  }
 }
 else {
  panel.append(card('Pratos limpos',o.plates+'/99 instalados',()=>{quickKitchen(o,'installPlates');renderDialog()},'Instalar pratos'));
  panel.append(card('Talher',o.utensil?'Instalado e reutilizável':'Sem talher',!o.utensil?()=>{quickKitchen(o,'installUtensil');renderDialog()}:null,'Instalar talher'));
  panel.append(card('Área de retirada',R.readyCount(o)+'/'+R.KITCHEN_CONFIG.readyCapacity+' pratos prontos'));
  for(const [dish,n]of Object.entries(o.dishes||{}))if(n)panel.append(card(R.itemName(dish),'Prontos: '+n,()=>{quickKitchen(o,'takeDish',dish);renderDialog()},'Retirar um prato'));
 }
 const recipeGrid=dialogTab==='cooking'?document.createElement('div'):panel;
 if(dialogTab==='cooking'){recipeGrid.className='recipeGrid';recipeGrid.setAttribute('aria-label','Receitas disponíveis');panel.append(recipeGrid);}
 for(const [id,r]of Object.entries(R.RECIPES)){
  const plan=dialogTab==='plating'?R.platingPlan(state,o,id):null;
  const error=dialogTab==='cooking'?R.cookError(state,o,id):state.plating?'Empratamento em andamento.':plan.error;
  const detail=dialogTab==='cooking'?Object.entries(r.foods).map(([p,n])=>R.FOODS[p].name+': '+R.inventoryCount(state,p)+'/'+n*4).join(' • ')+' • '+r.time+'s':error||plan.count+' pratos em '+R.KITCHEN_CONFIG.platingSeconds+'s • panela '+(plan.count===plan.portions?'vazia':'com sobras')+' fica na mochila';
  recipeGrid.append(card(r.name,detail+(error?' • '+error:''),()=>{const res=dialogTab==='cooking'?R.startCook(state,o.id,id):R.plateFood(state,o.id,id);if(res.ok)$('management').close();tell(res.message,!res.ok)},dialogTab==='cooking'?'Cozinhar':'🍽️ Empratar',!!error));
 }
 }
 if(dialogTab==='supplier'){panel.innerHTML='<p>As entregas levam 5 segundos de jogo e chegam ao recebimento. O jogo pausa nesta tela. Depois, transporte ao estoque e à cozinha, manualmente ou com a equipe de teste.</p>';let cards=document.createElement('div');cards.className='cards';for(const [id,d]of Object.entries(R.FOODS)){let c=card(d.name,`${money(d.cost)}/un. • ${d.kind==='dry'?'Armazenamento seco':'Refrigerado'}`,null),input=document.createElement('input');input.type='number';input.min=1;input.max=100;input.value=10;input.setAttribute('aria-label','Quantidade de '+d.name);let tier=0;const select=document.createElement('select');select.setAttribute('aria-label','Qualidade do ingrediente');for(let q=0;q<4;q++)select.add(new Option(R.QUALITY_CONFIG.names[q],q));const showTier=()=>{c.children[0].replaceChildren(FoodArt.icon(id,tier));c.children[1].textContent=money(d.cost*R.QUALITY_CONFIG.costMultipliers[tier])+'/un. • '+(d.kind==='dry'?'Armazenamento seco':'Refrigerado');};select.onchange=()=>{tier=Number(select.value);showTier()};showTier();c.append(select,input);button('Comprar',()=>{let n=Number(input.value),ok=R.purchase(state,id,n,tier);if(ok)renderDialog();tell(ok?`${n} ${d.name} encomendados por ${money(n*d.cost*R.QUALITY_CONFIG.costMultipliers[tier])}. A entrega avança ao voltar ao jogo.`:'Informe de 1 a 100 unidades e confira o saldo.',!ok)},c);cards.append(c)}panel.append(cards);panel.append(table(['Ingrediente','Recebimento','Estoque','Cozinha'],Object.keys(R.FOODS).flatMap(p=>[0,1,2,3].map(q=>[FoodArt.icon(p,q),R.receivingCount(state,p,q),...['storage','kitchen'].map(loc=>state.objects.filter(o=>o.inventory&&R.objectLocation(o)===loc).reduce((n,o)=>n+R.objectQualityCount(o,p,q),0))]))))}
 if(dialogTab==='menu'){panel.innerHTML='<p>Escolha os pratos oferecidos e ajuste os preços. Receitas e custos são hipóteses de teste. Pedidos já anotados mantêm o preço combinado.</p>';let cards=document.createElement('div');cards.className='cards';for(const [id,r]of Object.entries(R.RECIPES)){let c=card(r.name,Object.entries(r.foods).map(([p,n])=>n+' '+R.FOODS[p].name).join(' + ')+` • custo ${money(R.mealCost(id))} • preparo ${r.time}s por lote de 4`,null),l=document.createElement('label'),ck=document.createElement('input');ck.type='checkbox';ck.checked=state.menu[id];ck.onchange=()=>{state.menu[id]=ck.checked};l.append(ck,' Oferecer no cardápio');c.append(l);let input=document.createElement('input');input.type='number';input.min=1;input.max=100;input.step=.25;input.value=state.prices[id];input.setAttribute('aria-label','Preço de '+r.name);input.onchange=()=>{let n=Number(input.value);if(Number.isFinite(n)&&n>=1&&n<=100){state.prices[id]=n;tell('Preço atualizado. Margem por prato: '+money(n-R.mealCost(id)))}else{input.value=state.prices[id];tell('Informe um preço de 1 a 100.',true)}};c.append(input);cards.append(c)}panel.append(cards)}
 if(dialogTab==='deliveries')panel.append(table(['Pedido','Ingrediente','Total','Recebido','Pendente','Chegada'],state.deliveries.map(o=>['#'+o.id,FoodArt.icon(o.food,o.quality??0),o.total,o.received,o.pending,o.eta>state.time?Math.ceil(o.eta-state.time)+'s':'No recebimento / aguarda espaço'])));
 if(dialogTab==='guide'){
 panel.innerHTML='<p>Use WASD ou as setas para caminhar livremente. Solte as teclas para parar. Ao encostar em uma parede, continue pela direção livre. Também é possível clicar no chão ou em um móvel para se aproximar.</p><ol><li>Compre ingredientes no computador e recolha no recebimento. Mantenha-os na mochila.</li><li>Selecione o fogão e use Instalar panela vazia. Abra 🔥, escolha uma receita e inicie o lote de 4 porções.</li><li>A barra avança enquanto você faz outras tarefas. Quando ficar pronto, volte ao fogão e use Retirar panela cheia.</li><li>Na bancada, instale pratos limpos e um talher pelas ações rápidas. O talher é reutilizável.</li><li>Com a panela cheia na mochila, use Empratar. Fique perto durante os 2 segundos da barra. A panela vazia ou com sobras continua na mochila.</li><li>Pratos prontos ficam na bancada, visíveis para retirada pelo jogador ou garçom. Use Retirar prato para levar comida à mochila. A retirada vinculada a um pedido fica em Mais opções. Reponha pratos pelos slots; manutenção também fica em Mais opções.</li><li>Anote pedidos e sirva. Recolha louça suja e lave na pia como antes.</li></ol><p>Fogão e bancada não têm inventário genérico. Pia e lixo usam os itens da mochila por ação rápida. Apenas geladeiras e prateleiras têm inventário de armazenamento. Sem espaço, os itens permanecem na origem. Menus pausam a simulação.</p>';
 }

 if(dialogTab==='team'){panel.innerHTML='<p>Dois funcionários gratuitos para testes. Salários e contratação ainda não foram definidos. A carga em trânsito é entregue antes da troca de função.</p>';for(const w of state.workers){let c=card(PERSON[w.id],`${NAME[w.room]} • ${w.wait>=5?'Aguardando passagem':w.carry?'Transportando carga':w.goal?'Em deslocamento':'Aguardando trabalho ou ingredientes'}`,null),sel=document.createElement('select');sel.setAttribute('aria-label','Tarefa de '+PERSON[w.id]);for(const [v,n]of [['none','Parado'],['logistics','Recebimento → estoque → cozinha'],['waiter','Anotar pedidos e servir pratos']])sel.add(new Option(n,v));sel.value=w.task;sel.onchange=()=>{w.task=sel.value;tell('Tarefa contínua atribuída. Rotas respeitam móveis e outras pessoas.')};c.append(sel);panel.append(c)}}
 if(dialogTab==='finance'){let r=state.lastReport;panel.innerHTML='<p>O relatório diário é fechado na transição das 02:00 para o próximo dia. Compras reduzem o caixa; ingredientes entram no custo quando usados no preparo. Almoço e jantar seguem os horários definidos em Turnos; despesa de teste: $12/dia.</p>';panel.append(table(['Indicador','Hoje'],[['Receita',money(state.ledger.revenue)],['Ingredientes consumidos',money(state.ledger.foodCost)],['Compras',money(state.ledger.purchases)],['Móveis e kit',money(state.ledger.investment)],['Clientes pagos',state.ledger.sales],['Clientes perdidos (inclui abandono)',state.ledger.lost],['Esperas por circulação',state.flowWaits]]));if(r)panel.append(table(['Último fechamento • dia '+r.day,'Valor'],[['Receita',money(r.revenue)],['Custo dos ingredientes',money(r.foodCost)],['Despesa',money(r.expense)],['Resultado operacional',money(r.result)],['Caixa final',money(r.cash)]]))}
 if(dialogTab==='customers'){
 panel.innerHTML='<p>⏳ acima de 50% • ❗ até 50% • 😠 até 20% • 🤬 desistiu • 😊 satisfação positiva. Os dois tempos são independentes. Menus pausam os contadores. Pesos provisórios: 35% atendimento, 35% espera da comida e 30% qualidade do prato. Elogios, reclamações e abandonos alimentam a reputação uma única vez por visita, sem efeito na demanda ou nos preços.</p>';
 panel.append(table(['Cliente','Perfil','Etapa','Paciência restante'],state.customers.map(c=>{const i=R.customerIndicator(state,c);return [c.id,({impatient:'Impaciente',normal:'Normal',patient:'Paciente'})[c.experience.profile],c.experience.phase==='service'?'Atendimento':c.experience.phase==='food'?'Comida':c.experience.abandoned?'Desistiu':c.state==='eating'?'Comendo':'Em deslocamento',i?.phase?i.emoji+' '+Math.ceil(i.remaining)+'s':i?.emoji||'—']})));
 const labels=Object.fromEntries(R.CUSTOMER_CONFIG.satisfaction.classes.map(v=>[v.id,v.label]));
 panel.append(table(['Últimas 20 visitas','Resultado','Satisfação','Manifestação'],state.experience.visits.slice(-20).reverse().map(v=>[v.id,v.outcome==='abandoned'?'Abandono':'Concluída',v.outcome==='abandoned'?'Insatisfeito':Math.round(v.satisfaction.score)+'/100 • '+labels[v.satisfaction.classification],({praise:'Elogio',complaint:'Reclamação'})[state.experience.events.find(e=>e.visitId===v.id)?.type]||'Nenhuma'])));
 }
 if(dialogTab==='calendar'){
 const date=R.calendarDate(state.day);panel.innerHTML='<p>Dia jogável: 06:00 até 02:00 da madrugada seguinte. Cada bloco de 10 minutos leva 7 segundos de simulação ativa. Menus e aba oculta pausam tudo. Às 02:00, não entram novos clientes; o relógio aguarda a conclusão dos clientes e preparos. A data só muda na transição para 06:00. Sem penalidades de sono, clima ou eventos sazonais.</p>';
 panel.append(table(['Calendário','Agora'],[['Horário',R.clockText(state)],['Data',date.weekday+', '+date.day+' de '+date.season+', ano '+date.year],['Dia acumulado',state.day],['Situação',state.clock.ending?'02:00 — concluindo serviço pendente':'Dia em andamento']]));
 }
 if(dialogTab==='reputation'){
 panel.innerHTML='<p>Reputação: '+state.reputation.score+'/100 — '+R.reputationLevel(state.reputation.score)+'. Valores provisórios: início em '+R.REPUTATION_CONFIG.initial+'; elogio '+R.REPUTATION_CONFIG.deltas.praise+'; reclamação '+R.REPUTATION_CONFIG.deltas.complaint+'; abandono '+R.REPUTATION_CONFIG.deltas.abandonment+'. O abandono não acumula outra penalidade pela reclamação da mesma visita. Fluxo de clientes e preços permanecem sem influência da reputação. Avaliações antigas não são reaplicadas ao carregar.</p>';
 panel.append(table(['Últimos 20 impactos','Tipo','Manifestação','Variação','Pontuação'],state.reputation.history.slice(-20).reverse().map(e=>[e.visitId,({praise:'Elogio',complaint:'Reclamação',abandonment:'Abandono'})[e.type],({praise:'Elogio',complaint:'Reclamação'})[e.manifestation]||'Nenhuma',e.delta>0?'+'+e.delta:String(e.delta),e.before+' → '+e.after])));
 }
 if(dialogTab==='test'){
 const clockHelp=document.createElement('p');clockHelp.textContent='Avançar horário de teste • Agora: '+R.clockText(state)+'. O salto não acelera a paciência, as entregas nem os preparos. Ao passar do fim do turno, a entrada de clientes é encerrada.';panel.append(clockHelp);
 const label=document.createElement('label');label.textContent='Ir para o horário: ';const select=document.createElement('select');select.id='testClock';select.setAttribute('aria-label','Horário de teste');
 for(let minute=360;minute<=1560;minute+=10)select.add(new Option(R.serviceTimeText(minute)+(minute>=1440?' (madrugada)':''),minute));
 select.value=state.clock.minute<=660?660:state.clock.minute;label.append(select);panel.append(label);
 button('Avançar horário',()=>{const res=R.advanceTestClock(state,Number(select.value));renderDialog();tell(res.message,!res.ok)},panel);
 const note=document.createElement('p');note.textContent='O avanço é somente para a frente no dia atual. Às 02:00, valem o fechamento e a virada de dia normais. Para testar clientes, escolha 11:00 e abra o restaurante.';panel.append(note);
 const cleanup=document.createElement('p');cleanup.textContent='Ferramenta provisória de testes. Remove todos os móveis e esvazia a mochila, os inventários dos objetos, o recebimento e as cargas dos personagens. Cancela clientes, pedidos, entregas e preparos. Preserva dinheiro, dia, preços, cardápio e relatórios. Não devolve o valor dos itens apagados. O salvamento só muda ao usar Salvar restaurante.';panel.append(cleanup);
 button('Excluir todos os móveis e limpar inventários',()=>{R.clearTestScene(state);building=null;hover=null;selectedObject=null;dialogObjectId=null;renderedKey='';releaseKeyboard();renderDialog();tell(state.message)},panel);
 }
 if(dialogTab==='save'){panel.innerHTML='<p>Salvamento 0.20.2. Horários dos turnos são preservados.  Qualidade dos ingredientes e pratos preservada; partidas antigas recebem qualidade comum sem recalcular avaliações. Itens dos inventários antigos de fogão, bancada, pia e lixo são preservados na mochila ou em Recolher itens preservados. Saves da 0.11.0 preservam a paciência atual; saves da 0.10.x recebem o sistema de paciência. Saves da 0.12.0 preservam horário e reputação. Somente formatos anteriores à 0.12.0 iniciam o dia às 06:00 com reputação zero, sem reaplicar avaliações antigas. O arquivo anterior permanece preservado. O progresso fica neste computador.</p>';button('Salvar restaurante',()=>{try{if(!R.valid(state))throw Error('Estado inválido');localStorage.setItem('entre-restaurante-09',JSON.stringify(state));tell('Restaurante salvo neste computador.')}catch(e){tell('Não foi possível salvar: '+e.message,true)}},panel);button('Carregar restaurante',()=>{try{let next=R.migrateSave(JSON.parse(localStorage.getItem('entre-restaurante-09')||localStorage.getItem('entre-restaurante-07')||localStorage.getItem('entre-restaurante-06')||localStorage.getItem('entre-restaurante-05')||localStorage.getItem('entre-restaurante-04')));if(!next)throw Error('salvamento ausente ou inválido');state=next;state.cookActive=false;building=null;selectedObject=null;renderedKey='';renderDialog();tell('Progresso carregado. Preparos em andamento continuam; empratamento exige proximidade da bancada.')}catch(e){tell('Não foi possível carregar: '+e.message+'. Estado atual preservado.',true)}},panel);}
 refresh();}
let keyboard={};
const moveKeys=['arrowup','arrowdown','arrowleft','arrowright','w','a','s','d'];
function keyboardDirection(){return {dx:(keyboard.arrowright||keyboard.d?1:0)-(keyboard.arrowleft||keyboard.a?1:0),dy:(keyboard.arrowdown||keyboard.s?1:0)-(keyboard.arrowup||keyboard.w?1:0)}}
function keyboardMove(){const {dx,dy}=keyboardDirection();if(dx||dy)pendingInteraction=null;R.setPlayerInput(state,dx,dy);}
function releaseKeyboard(){keyboard={};R.setPlayerInput(state,0,0);}
function resetFrameClock(){last=performance.now();releaseKeyboard();}
window.addEventListener('blur',releaseKeyboard);document.addEventListener('visibilitychange',resetFrameClock);
$('management').addEventListener('close',resetFrameClock);
 document.addEventListener('keydown',e=>{if($('management').open||$('welcome').open)return;const k=e.key.toLowerCase();if(constructionMode){if(k==='escape'){e.preventDefault();if(building)stopBuild();else if(!$('constructionDrawer').hidden)toggleCatalog();else exitConstruction();return}if(moveKeys.includes(k)){e.preventDefault();camera.x+=k==='a'||k==='arrowleft'?-30:k==='d'||k==='arrowright'?30:0;camera.y+=k==='w'||k==='arrowup'?-30:k==='s'||k==='arrowdown'?30:0;updateCamera();return}if(k==='r'&&building){e.preventDefault();$('rotateBtn').click();}return}if(k==='i'&&!building){openDialog('inventory');return}if(k==='escape'){stopBuild();return}if(building&&moveKeys.includes(k)){e.preventDefault();const dx=k==='a'||k==='arrowleft'?-30:k==='d'||k==='arrowright'?30:0,dy=k==='w'||k==='arrowup'?-30:k==='s'||k==='arrowdown'?30:0;camera.x+=dx;camera.y+=dy;updateCamera();return;}if(building&&k==='r'){$('rotateBtn').click();return}if(moveKeys.includes(k)&&!building){e.preventDefault();keyboard[k]=true;keyboardMove()}if(k==='e'&&!e.repeat){let b=$('context').querySelector('.prepPrimary button:not(:disabled)')||$('context').querySelector('.prepSlot:not(:disabled)')||(!$('context').querySelector('.prepPanel')&&$('context').querySelector('button:not(:disabled)'));if(b)b.click()}});
 document.addEventListener('keyup',e=>{const k=e.key.toLowerCase();if(!moveKeys.includes(k))return;delete keyboard[k];keyboardMove();});
$('tutorialBtn').onclick=()=>{
 const tutorial=$('welcomeTutorial');
 tutorial.hidden=!tutorial.hidden;
 $('tutorialBtn').setAttribute('aria-expanded',String(!tutorial.hidden));
 $('tutorialBtn').textContent=tutorial.hidden?'Tutorial':'Fechar tutorial';
};
$('startFurnishedBtn').onclick=()=>{state=R.furnishedTest();building=null;hover=null;selectedObject=null;renderedKey='';resetFrameClock();$('welcome').close();setCameraLevel(cameraLevel);refresh()};
$('startBtn').onclick=()=>{resetFrameClock();$('welcome').close();refresh()};$('welcome').showModal();
function drawKitchenStatus(){
 const box=$('kitchenStatus');box.replaceChildren();
 const jobs=[state.cooking&&{...state.cooking,label:'Cozinhando '+RECIPENAME(state.cooking.recipe)},state.plating&&{...state.plating,label:'Empratando'+(R.objectNear(state,state.objects.find(o=>o.id===state.plating.prep))?'':' • pausado: aproxime-se')}].filter(Boolean);
 for(const o of state.objects)if(o.readyBatch&&o.pan?.startsWith('pot_')){const h=R.heatState(state,o);jobs.push({label:h.label+' • '+RECIPENAME(o.readyBatch.recipe),total:1,left:1-h.value,heat:h.stage});}
 for(const j of jobs){const line=document.createElement('label');line.textContent=j.label+' • '+Math.ceil(j.left)+'s';const bar=document.createElement('progress');bar.max=j.total;bar.value=j.total-j.left;bar.setAttribute('aria-label',j.label);if(j.heat){line.className='heat-'+j.heat;line.setAttribute('data-heat',j.heat);if(j.heat==='burned')bar.hidden=true;}line.append(bar);box.append(line);}
}
let kitchenAudio=null;const playedHeat=new WeakMap();
document.addEventListener('pointerdown',()=>{try{if(!kitchenAudio&&typeof window.AudioContext==='function')kitchenAudio=new window.AudioContext();if(kitchenAudio?.state==='suspended')kitchenAudio.resume();}catch{}},{once:true});
function kitchenSounds(){for(const o of state.objects){if(!o.readyBatch)continue;const key=o.readyBatch.doneAt+':'+o.heatStage;if(playedHeat.get(o)===key)continue;playedHeat.set(o,key);if(!kitchenAudio||kitchenAudio.state!=='running')continue;try{const tone=kitchenAudio.createOscillator(),gain=kitchenAudio.createGain(),at=kitchenAudio.currentTime;tone.frequency.value=o.heatStage==='ready'?660:o.heatStage==='over'?440:220;gain.gain.setValueAtTime(.04,at);gain.gain.exponentialRampToValueAtTime(.001,at+.18);tone.connect(gain);gain.connect(kitchenAudio.destination);tone.start(at);tone.stop(at+.2);}catch{}}}
for(const [id,kind] of Object.entries({menuBtn:'note',optionsBtn:'options',inventoryBtn:'bag',catalogToggle:'hammer'})){
 $(id).append(controlIcon(kind));
}
let uiTimer=0;function frame(now){let dt=Math.max(0,(now-last)/1000);last=now;if(!document.hidden&&!$('management').open&&!$('welcome').open&&!constructionMode){let msg=state.message,remaining=dt;while(remaining>1e-9){const slice=Math.min(.08,remaining);keyboardMove();R.step(state,slice);processInteraction();remaining=Math.max(0,remaining-slice);}if(state.message!==msg){$('notice').textContent=state.message;$('notice').style.opacity='1';noticeTime=now+4500;}kitchenSounds();uiTimer+=dt;if(uiTimer>.25){uiTimer=0;refresh()}}if(now>noticeTime)$('notice').style.opacity='0';updateCamera();positionActions();requestAnimationFrame(frame)}refresh();requestAnimationFrame(frame);

'use strict';
const R=Restaurant,$=id=>document.getElementById(id),canvas=$('world'),ctx=canvas.getContext('2d');
let prepOptionsId=null,prepChoice=null,constructionMode=false;
let state=R.fresh(true,true),building=null,hover=null,selectedObject=null,transferQuantity=99,dialogObjectId=null,dialogMode='general',dialogTab='guide',last=performance.now(),renderedKey='',noticeTime=0;
const NAME={street:'Rua da Praça',restaurant:'Restaurante • salão e cozinha',stock:'Estoque • recebimento e administração'};
const PERSON={lia:'Lia',beto:'Beto',nina:'Nina',worker1:'Logística',worker2:'Garçom'};
function viewNative(name,args){return JSON.parse(NativeRule(JSON.stringify({name,args})));}
function tell(message,bad=false){state.message=message;$('notice').textContent=message;$('notice').classList.toggle('bad',bad);$('notice').style.opacity='1';noticeTime=performance.now()+6000;if($('management').open)$('menuNotice').textContent=message;refresh();}
function button(text,action,parent,disabled=false){let b=document.createElement('button');b.textContent=text;b.disabled=disabled;b.onclick=action;parent.append(b);return b;}
function money(n){return '$'+n.toFixed(2)}
let cameraLevel=1;try{const saved=Number(localStorage.getItem('entre-camera-zoom'));if(saved>=.7&&saved<=2)cameraLevel=saved;}catch{}
const camera={zoom:1,x:0,y:0,mode:null};
function setCameraLevel(value){cameraLevel=viewNative('camera',['level',value]);try{localStorage.setItem('entre-camera-zoom',String(cameraLevel))}catch{}updateCamera();positionActions();$('zoomOutBtn').disabled=cameraLevel<=.7;$('zoomInBtn').disabled=cameraLevel>=2;}
$('zoomOutBtn').onclick=()=>setCameraLevel(cameraLevel-.1);$('zoomInBtn').onclick=()=>setCameraLevel(cameraLevel+.1);
const viewport={width:960,height:640};
let buildPointer=null;
function updateCamera(){Object.assign(camera,viewNative('camera',['update',{compact:state.compact===true,singleRoom:state.singleRoom===true,player:state.player},camera,viewport,cameraLevel,constructionMode]));}
function worldPointer(e){return viewNative('camera',['worldPointer',{clientX:e.clientX,clientY:e.clientY},canvas.getBoundingClientRect(),viewport,camera]);}
function screenPoint(x,y){return viewNative('camera',['screenPoint',x,y,canvas.getBoundingClientRect(),viewport,camera]);}
function resize(){const out=viewNative('camera',['resize',innerWidth,innerHeight,parseInt(getComputedStyle(document.documentElement).getPropertyValue('--top')),devicePixelRatio||1]);Object.assign(viewport,out.viewport);canvas.style.width=innerWidth+'px';canvas.style.height=out.height+'px';canvas.width=out.pixels.width;canvas.height=out.pixels.height;updateCamera();}
function serviceSignPoint(){return state.player.room==='street'?{room:'street',x:13,y:6}:{room:'restaurant',x:7,y:14};}
function positionDoorSign(){const result=viewNative('camera',['door',{player:{room:state.player.room}},camera,viewport,canvas.getBoundingClientRect(),constructionMode,!!$('management').open,!!$('welcome').open]),b=$('openBtn');b.hidden=result.hidden;b.style.left=result.left+'px';b.style.top=result.top+'px';}
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
 $('management').close();$('constructionControls').hidden=false;$('constructionDrawer').hidden=false;
 $('catalogToggle').setAttribute('aria-expanded','true');dialogMode='build';dialogTab='catalog';
 resetFrameClock();resize();renderDialog();refresh();$('catalogToggle').focus?.();return true;
}
function exitConstruction(){
 stopBuild(false);constructionMode=false;buildPointer=null;
 document.documentElement.classList.remove('construction');$('constructionControls').hidden=true;$('constructionDrawer').hidden=true;
 resetFrameClock();resize();refresh();$('menuBtn').focus?.();
}
function toggleCatalog(){const drawer=$('constructionDrawer');drawer.hidden=!drawer.hidden;$('catalogToggle').setAttribute('aria-expanded',String(!drawer.hidden));if(!drawer.hidden){renderDialog();$('exitConstruction').focus?.();}}
$('catalogToggle').onclick=toggleCatalog;$('exitConstruction').onclick=exitConstruction;
function beginBuild(type,moving=null){if(!constructionMode)return;pendingInteraction=null;releaseKeyboard();let err=state.open||state.customers.length?'Conclua o serviço antes de montar.':null;if(err)return tell(err,true);if(!constructionMode&&!enterConstruction())return;$('management').close();$('constructionDrawer').hidden=true;$('catalogToggle').setAttribute('aria-expanded','false');building={type,rot:moving?state.objects.find(o=>o.id===moving).rot:0,moving};hover=null;state.player.goal=null;$('buildBar').hidden=false;$('buildLabel').textContent=(moving?'Mover: ':'Instalar: ')+R.CATALOG[type].name;$('buildStatus').textContent='Toque em uma célula do setor '+(R.CATALOG[type].area==='utility'?'Salão ou cozinha':R.CATALOG[type].area==='dryStorage'?(state.singleRoom?'Cozinha':'Cozinha ou estoque'):R.CATALOG[type].area==='storage'?'Estoque':R.CATALOG[type].area==='kitchen'?'Cozinha':'Salão')+'.';$('confirmBtn').disabled=true;$('storeBuild').hidden=!moving;refresh();}
function stopBuild(reopen=true){resetFrameClock();building=null;hover=null;$('buildBar').hidden=true;if(reopen&&constructionMode){$('constructionDrawer').hidden=false;$('catalogToggle').setAttribute('aria-expanded','true');renderDialog();}refresh()}
function updatePreview(){if(!building||!hover)return;let err=previewError({type:building.type,room:R.CATALOG[building.type].room,...hover,rot:building.rot});$('buildStatus').textContent=err||'Posição válida. Arraste o mapa para explorar. A seta da cadeira aponta para a mesa.';$('confirmBtn').disabled=!!err;}
$('storeBuild').onclick=()=>{if(!constructionMode||!building?.moving)return;const result=R.remove(state,building.moving);if(!result.ok){$('buildStatus').textContent=result.error;return}stopBuild();renderDialog();tell('Objeto guardado e valor devolvido.');};
$('rotateBtn').onclick=()=>{if(!constructionMode||!building)return;building.rot=(building.rot+1)%4;updatePreview()};$('cancelBuild').onclick=stopBuild;
$('confirmBtn').onclick=()=>{if(!constructionMode||!building||!hover)return;let r=R.place(state,building.type,hover.x,hover.y,building.rot,building.moving);if(!r.ok){$('buildStatus').textContent=r.error;return}stopBuild();renderDialog();tell('Objeto instalado. As rotas foram atualizadas.')};
canvas.onpointermove=e=>{if(!constructionMode)return;if(buildPointer&&(e.buttons||e.pointerType==='touch')){const r=canvas.getBoundingClientRect();Object.assign(camera,viewNative('camera',['drag',camera,{clientX:e.clientX,clientY:e.clientY},buildPointer,r,viewport]));buildPointer={x:e.clientX,y:e.clientY};updateCamera();if(building)building.locked=false;}if(!building||building.locked)return;hover={x:Math.floor(worldPointer(e).x),y:Math.floor(worldPointer(e).y)};updatePreview();};
canvas.onpointerup=canvas.onpointercancel=()=>{buildPointer=null;};
// One click queues exactly one action; walking and menus never repeat it.
let pendingInteraction=null;
// Only transport identity and presentation effects through the temporary UI shell.
function nativeInteraction(operation,params){
 const previousState=pendingInteraction?.state;
 const job=pendingInteraction?Object.fromEntries(Object.entries(pendingInteraction).filter(([key])=>key!=='state')):null;
 const out=R.uiInteraction(state,operation,params,{pending:job,current:!pendingInteraction||previousState===state,selected:selectedObject,building:!!building});
 pendingInteraction=out.pending?{...out.pending,state:out.current?state:previousState}:null;
 selectedObject=out.selected;
 for(const effect of out.effects){
  if(effect.kind==='tell')tell(effect.message,effect.bad);
  else if(effect.kind==='dialog')openDialog(effect.mode);
  else if(effect.kind==='inventory')openObjectInventory(effect.id);
  else if(effect.kind==='refresh')refresh();
  else if(effect.kind==='beginBuild')beginBuild(effect.type,effect.moving);
  else if(effect.kind==='capture'){buildPointer={x:effect.x,y:effect.y};canvas.setPointerCapture?.(effect.pointerId);}
  else if(effect.kind==='preview'){building.locked=true;hover={x:effect.x,y:effect.y};updatePreview();}
 }
 return out.value;
}
function approachCustomer(c){return nativeInteraction("approachCustomer",[c.id]);}
function queueInteraction(kind,target){return nativeInteraction("queueInteraction",[kind,target]);}
function processInteraction(){if(!pendingInteraction)return;return nativeInteraction("processInteraction",[]);}
function queuePhysical(o,action){return nativeInteraction("queuePhysical",[o.id,action]);}
function primaryObjectAction(o){return nativeInteraction("primaryObjectAction",[o.id]);}
canvas.onpointerdown=e=>{prepOptionsId=null;prepChoice=null;pendingInteraction=null;releaseKeyboard();nativeInteraction('pointerDown',[{world:worldPointer(e),clientX:e.clientX,clientY:e.clientY,pointerId:e.pointerId,construction:constructionMode,building}]);};
function nearbyObjects(){return state.objects.filter(o=>o.room===state.player.room&&R.accessPoints(state,o).some(p=>R.near(state.player,p,0)))}
function actionRow(o){let row=document.createElement('div');row.className='objectActions';row.anchor={x:o.x,y:o.y,w:R.CATALOG[o.type]?R.rect(o).w:1,lift:state.customers.some(c=>c.id===o.id||c.seat===o.id||o.type==='table'&&state.objects.some(ch=>ch.id===c.seat&&R.hit(o,ch.x+R.DIRS[ch.rot][0],ch.y+R.DIRS[ch.rot][1])))?40:0};$('context').append(row);return row;}
const CONTROL_PATHS={
 "cut": "M2 13l4-4 M5 8l6-6 3 3-6 6z M2 15h12",
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
function useContext(){const sig=JSON.stringify([prepOptionsId,prepChoice,selectedObject,!!building,$('management').open,state.player.room,state.player.x,state.player.y,R.isMoving(state.player),state.player.carry,state.player.hand,state.chopping,state.plating,state.inventory,state.objects,state.open,state.closing,state.cooking?.stove,state.plating?.prep,state.customers.map(c=>[c.id,c.x,c.y,c.state,c.order]),state.orders.map(o=>[o.id,o.state])]);if(useContext.lastSig===sig)return;useContext.lastSig=sig;let box=$('context');box.replaceChildren();if(constructionMode||$('management').open)return;const a=state.player;if(R.isMoving(a)||selectedObject===null)return;const rows=new Map();function rowFor(o){let k=o.id||o.name||o.x+':'+o.y;if(!rows.has(k))rows.set(k,actionRow(o));return rows.get(k);}
 for(const p of R.PORTALS[a.room].filter(p=>selectedObject==='portal:'+a.room+':'+p.x+':'+p.y&&R.near(a,{...p,room:a.room},1))){let row=actionRow(p);action(row,'door',p.name,()=>R.go(a,{room:p.to,x:p.spawn[0],y:p.spawn[1]}));}
 if(selectedObject==='computer'&&R.near(a,{room:'restaurant',x:16,y:12},1)){let row=actionRow({x:16,y:11});action(row,'computer','Usar computador',()=>openDialog('computer'));}
 if(selectedObject==='receiving'&&R.near(a,{room:'restaurant',x:21,y:12},1)){let row=actionRow({x:21,y:11});action(row,'box','Recolher ingredientes',()=>tell(R.collectReceiving(state)));}
 for(const o of nearbyObjects().filter(o=>o.id===selectedObject)){
 const row=rowFor(o);if(o.type==='computer')action(row,'computer','Usar computador',()=>openDialog('computer'));if(o.type==='receiving')action(row,'box','Recolher ingredientes',()=>tell(R.collectReceiving(state)));if(o.inventory&&!['stove','prep','sink','bin'].includes(o.type))action(row,'bag','Abrir '+R.CATALOG[o.type].name,()=>openObjectInventory(o.id));
 if(['stove','prep','kitchen'].includes(o.type)){
  const add=(kind,label,fn)=>action(row,kind,label,fn);
  const run=(kind,label,cmd)=>add(kind,label,()=>queuePhysical(o,cmd));
  if(o.type==='prep'){
   if(state.chopping?.table===o.id)run('bin','Cancelar corte','cancelCut');
  }else if(o.type==='stove'){
   if(!o.pan&&state.player.hand?.item==='pot')run('pot','Instalar panela','installPan');
   else if(o.pan==='pot'){
    if(o.ingredients?.length)run('take','Retirar último ingrediente','removeIngredient');
    if(R.recognizedRecipe(o))run('flame','Cozinhar','cook');
   }
  }else{
   if(state.player.hand?.item==='plate')run('box','Instalar prato das mãos','installPlates');
   else if(state.player.hand&&(state.player.hand.item==='pot'||R.ITEMS[state.player.hand.item]?.servings||state.player.hand.item.startsWith('dish_')))run('pot','Apoiar item carregado',state.player.hand.item.startsWith('dish_')?'putDish':'support');
   if(o.support)run('take','Retirar panela apoiada','takePan');
   if(o.utensil)run('take','Retirar talher preservado','takeUtensil');
   if(o.plates)run('take','Retirar pratos limpos','takePlates');
   if(o.support?.item.startsWith('pot_'))run('serve','Empratar uma porção','plate');
   if(R.readyCount(o))run('serve','Pegar prato nas mãos','takeDish');
   if(state.plating?.prep===o.id)run('bin','Cancelar empratamento','cancelPlate');
  }
  continue;
 }
 if(o.type==='sink'&&state.player.hand?.item==='dirtyPlate')action(row,'wash','Lavar pratos',()=>{let r=R.washPlates(state,o.id);tell(r.message,!r.ok)});
 if(['sink','bin'].includes(o.type)&&R.ITEMS[state.player.hand?.item]?.recipe)action(row,'bin','Descartar comida das mãos',()=>queuePhysical(o,'discardHand'));
 if(o.type==='table')action(row,'wash','Recolher pratos sujos da mesa',()=>{let r=R.collectDirty(state,o.id);tell(r.message,!r.ok)});
 }
 for(const c of state.customers.filter(c=>R.near(a,c,1))){const chair=state.objects.find(o=>o.id===c.seat),selected=state.objects.find(o=>o.id===selectedObject);let table=null;if(chair){let [dx,dy]=R.DIRS[chair.rot];table=state.objects.find(o=>o.type==='table'&&R.hit(o,chair.x+dx,chair.y+dy));}if(selectedObject!==c.id&&selectedObject!==c.seat&&selectedObject!==table?.id)continue;const row=rowFor(selected||chair||c);if(c.state==='waiting')action(row,'note','Anotar pedido',()=>{R.interact(state,c.id);tell(state.message)});if(c.state==='ordered')action(row,'serve','Servir '+RECIPENAME(c.recipe),()=>{R.interact(state,c.id);tell(state.message)});}
 positionActions();
}

function refresh(){let period=state.period===0?'Almoço':'Jantar',date=R.calendarDate(state.day);$('hud').innerHTML=`<div class="hudLeft"><span class="shiftHud">${period} • ${state.clock.ending?'Encerrando o dia':state.closing?'Concluindo':state.open?'Aberto':state.clock.minute>=R.serviceHours(state)[state.period].end?'Encerrado':state.clock.minute<R.serviceHours(state)[state.period].start?'Preparação':'Fechado'}</span><span class="reputationHud">★ ${state.reputation.score}/100 • ${R.reputationLevel(state.reputation.score)}</span></div><div class="hudRight"><span class="calendarHud">${R.clockText(state)} • ${date.weekday} ${date.day} • ${date.season} • Ano ${date.year}</span><span class="money">${money(state.cash)}</span></div>`;$('location').textContent=NAME[state.player.room];$('openBtn').textContent=state.closing?'Encerrando':state.open?(state.player.room==='street'?'Encerrar restaurante':'Aberto'):state.clock.minute<R.serviceHours(state)[state.period].start?'Abre às '+R.serviceTimeText(R.serviceHours(state)[state.period].start):state.player.room==='street'?'Abrir restaurante':'Fechado';$('openBtn').setAttribute('aria-label',state.closing?'Conclua os pedidos':state.open?'Encerrar '+period.toLowerCase():'Abrir '+period.toLowerCase());$('openBtn').setAttribute('data-open',String(state.open));$('openBtn').disabled=state.clock.ending||state.closing||!!building;positionDoorSign();
 let a=state.player;const held=RestaurantArt.heldItem(R,state,a);$('hint').textContent=NAME[a.room]+' • '+(held?'Nas mãos: '+R.itemName(held.item):'Mãos vazias');
 if(state.clock.ending)$('hint').textContent+=' • 02:00: conclua clientes e preparos; o próximo dia começa às 06:00.';
 if(state.cooking)$('hint').textContent+=' • '+R.RECIPES[state.cooking.recipe].name+': '+Math.ceil(state.cooking.left)+'s'+' • Cozinha avança enquanto você faz outras tarefas.';
 let active=state.orders.filter(o=>!['paid','lost'].includes(o.state));let signature=active.map(o=>o.id+o.state+Math.floor(o.age)).join('|')+';'+state.customers.filter(c=>c.state==='waiting').map(c=>c.id+Math.floor(c.experience.elapsed.service)).join(',');if(renderedKey!==signature){renderedKey=signature;let h=$('ordersHud');h.replaceChildren();for(const c of state.customers.filter(c=>c.state==='waiting')){let d=document.createElement('div');d.className='orderCard';const indicator=R.customerIndicator(state,c);d.textContent=(indicator?indicator.emoji+' ':'')+'Mesa aguardando pedido'+(indicator?' • '+Math.ceil(indicator.remaining)+'s de paciência':'');h.append(d)}for(const o of active){let d=document.createElement('div');d.className='orderCard';let title=document.createElement('b');title.textContent='#'+o.id+' • '+RECIPENAME(o.recipe);d.append(title);const customer=state.customers.find(c=>c.id===o.customer),indicator=customer&&R.customerIndicator(state,customer);let cooking=indicator?' • '+indicator.emoji+(indicator.phase?' '+Math.ceil(indicator.remaining)+'s de paciência':' '+indicator.label):'';d.append(document.createTextNode(({ordered:'A preparar',cooking:'No fogão',ready:'Pronto para servir',eating:'Cliente comendo'})[o.state]+cooking+' • espera '+Math.floor(o.age)+'s'));if(o.state==='ordered')button(state.priority===o.id?'Prioritário':'Priorizar',()=>{state.priority=o.id;renderedKey='';refresh()},d);h.append(d)}}
 if(constructionMode){$('constructionCash').textContent='Disponível: '+money(state.cash);$('constructionNotice').textContent=state.message;}drawKitchenStatus();useContext();if(typeof FoodArt!=='undefined')for(const id of ['panel','context','ordersHud','hint','notice','menuNotice','kitchenStatus','welcome'])FoodArt.decorate($(id));}
$('openBtn').onclick=()=>{
 if(building||state.closing||state.clock.ending||!['restaurant','street'].includes(state.player.room))return;
 pendingInteraction=null;releaseKeyboard();const door=serviceSignPoint();
 if(!R.near(state.player,door,1)){const points=[door,...R.DIRS.map(([dx,dy])=>({...door,x:door.x+dx,y:door.y+dy}))].filter(p=>!R.blocked(state,p.room,p.x,p.y,state.player)&&R.route(state,p.room,state.player,p,state.player));points.sort((p,q)=>Math.abs(p.x-state.player.x)+Math.abs(p.y-state.player.y)-Math.abs(q.x-state.player.x)-Math.abs(q.y-state.player.y));if(!points.length)return tell('Não há passagem até a plaquinha.',true);R.go(state.player,points[0]);}
 pendingInteraction={state,kind:'serviceSign',door,wasOpen:state.open,period:state.period,until:state.time+30};processInteraction();refresh();};
$('menuBtn').onclick=()=>openDialog('general');$('optionsBtn').onclick=()=>openDialog('options');$('recipesBtn').onclick=()=>openDialog('recipes');$('closeDialog').onclick=()=>$('management').close();
function openObjectInventory(id){const o=state.objects.find(o=>o.id===id);if(['stove','prep','kitchen','sink','bin'].includes(o?.type))return tell('Use as ações rápidas do equipamento.');if(!o?.inventory||state.player.motion||!R.accessPoints(state,o).some(p=>R.near(state.player,p,0)))return tell('Aproxime-se do objeto.',true);dialogObjectId=id;openDialog('container');}
function openDialog(mode){if(['cooking','plating'].includes(mode))return;if(mode==='inventory')return;if(mode==='build')return enterConstruction();if(constructionMode)return;pendingInteraction=null;releaseKeyboard();$('management').setAttribute('data-mode',mode);if(mode==='computer'&&!R.utilityNear(state,'computer'))return tell('Aproxime-se do computador.',true);dialogMode=mode;dialogTab=['cooking','plating'].includes(mode)?mode:mode==='container'?'container':mode==='build'?'catalog':mode==='computer'?'supplier':mode==='options'?'camera':mode==='recipes'?'recipes':'shifts';$('management').showModal();renderDialog();}
function card(title,description,action,label='Selecionar',disabled=false){let d=document.createElement('div');d.className='card';let b=document.createElement('b');b.textContent=title;d.append(b);let p=document.createElement('p');p.textContent=description;d.append(p);if(action)button(label,action,d,disabled);return d;}
function table(headers,rows){let wrap=document.createElement('div');wrap.className='tableWrap';let t=document.createElement('table'),thead=t.createTHead(),tr=thead.insertRow();for(const h of headers){let th=document.createElement('th');th.textContent=h;tr.append(th)}let body=t.createTBody();for(const row of rows){let tr=body.insertRow();for(const cell of row){let td=tr.insertCell();if(cell&&typeof cell==='object')td.append(cell);else td.textContent=cell}}wrap.append(t);return wrap;}
function renderDialog(){let panel=$(constructionMode?'constructionPanel':'panel'),tabs=$(constructionMode?'constructionTabs':'tabs');panel.replaceChildren();tabs.replaceChildren();tabs.hidden=dialogMode==='cooking'||dialogMode==='build';$('menuNotice').textContent='';$('dialogTitle').textContent=dialogMode==='cooking'?'Fogão • preparar lote':dialogMode==='plating'?'Mesa • empratar':dialogMode==='container'?'Inventários • '+R.CATALOG[state.objects.find(o=>o.id===dialogObjectId).type].name:dialogMode==='computer'?'Computador • restaurante':dialogMode==='build'?'Modo construção':dialogMode==='options'?'Opções':dialogMode==='recipes'?'Livro de receitas':'Gestão do restaurante';let ts=dialogMode==='recipes'?{}:dialogMode==='cooking'?{}:dialogMode==='plating'?{plating:'Empratamento'}:dialogMode==='container'?{container:'Transferir itens'}:dialogMode==='computer'?{supplier:'Fornecedor',tools:'Utensílios',menu:'Cardápio e preços',deliveries:'Entregas'}:dialogMode==='build'?{catalog:'Móveis'}:dialogMode==='options'?{camera:'Câmera',save:'Salvar e carregar',test:'Testes',guide:'Primeiros passos'}:{shifts:'Turnos',build:'Modo construção',team:'Equipe',finance:'Fechamento',customers:'Clientes',calendar:'Calendário',reputation:'Reputação'};for(const [id,name]of Object.entries(ts)){let b=button(name,()=>{if(id==='build')return openDialog('build');if(id==='management')return openDialog('general');dialogTab=id;renderDialog()},tabs);if(dialogTab===id){b.classList.add('active');b.setAttribute('aria-current','page')}}

 // Recipe pages are generated by LivroReceitasNativo.gd.
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
 if(dialogTab==='tools'&&dialogMode==='computer'){
 const balance=document.createElement('p');balance.className='shopBalance';balance.textContent='Disponível: '+money(state.cash)+' • A compra vai diretamente para as mãos.';panel.append(balance);
 let cards=document.createElement('div');cards.className='cards';
 for(const [id,name,price]of [['pot','Panela vazia',25],['plate','Prato limpo',5]]){
 const item=card(name,`${money(price)} • nas mãos: ${state.player.hand?.item===id?1:0}`,()=>{let ok=R.buyTool(state,id);renderDialog();tell(ok?'Item nas mãos.':'Confira o saldo e libere as mãos.',!ok)},'Comprar',state.cash<price||!!state.player.hand||!!state.player.carry);
 item.append(RestaurantArt.toolIcon(id,name));cards.append(item);
 }panel.append(cards)}
 // Inventory view and callbacks are owned by InventariosNativos.gd.
 if(dialogTab==='supplier'&&state.singleRoom&&!state.objects.some(o=>o.type==='receiving')){panel.innerHTML='<p>Instale as caixas de recebimento pelo modo construção antes de comprar ingredientes.</p>';return;}
 if(dialogTab==='supplier'){panel.innerHTML=state.singleRoom?'<p>As entregas chegam às caixas de recebimento. Recolha os ingredientes e leve-os nas mãos à geladeira ou prateleira.</p>':'<p>As entregas chegam ao recebimento em 5 segundos de jogo. O jogo pausa nesta tela.</p>';let cards=document.createElement('div');cards.className='cards';for(const [id,d]of Object.entries(R.FOODS)){let c=card(d.name,`${money(d.cost)}/un. • ${d.kind==='dry'?'Armazenamento seco':'Refrigerado'}`,null),input=document.createElement('input');input.type='number';input.min=1;input.max=100;input.value=10;input.setAttribute('aria-label','Quantidade de '+d.name);let tier=0;const select=document.createElement('select');select.setAttribute('aria-label','Qualidade do ingrediente');for(let q=0;q<4;q++)select.add(new Option(R.QUALITY_CONFIG.names[q],q));const showTier=()=>{c.children[0].replaceChildren(FoodArt.icon(id,tier));c.children[1].textContent=money(d.cost*R.QUALITY_CONFIG.costMultipliers[tier])+'/un. • '+(d.kind==='dry'?'Armazenamento seco':'Refrigerado');};select.onchange=()=>{tier=Number(select.value);showTier()};showTier();c.append(select,input);button('Comprar',()=>{let n=Number(input.value),ok=R.purchase(state,id,n,tier);if(ok)renderDialog();tell(ok?`${n} ${d.name} encomendados por ${money(n*d.cost*R.QUALITY_CONFIG.costMultipliers[tier])}. A entrega avança ao voltar ao jogo.`:'Informe de 1 a 100 unidades e confira o saldo.',!ok)},c);cards.append(c)}panel.append(cards);panel.append(table(['Ingrediente','Recebimento','Estoque','Cozinha'],Object.keys(R.FOODS).flatMap(p=>[0,1,2,3].map(q=>[FoodArt.icon(p,q),R.receivingCount(state,p,q),...['storage','kitchen'].map(loc=>state.objects.filter(o=>o.inventory&&R.objectLocation(o)===loc).reduce((n,o)=>n+R.objectQualityCount(o,p,q),0))]))))}
 if(dialogTab==='menu'){panel.innerHTML='<p>Escolha os pratos oferecidos e ajuste os preços. Receitas e custos são hipóteses de teste. Pedidos já anotados mantêm o preço combinado.</p>';let cards=document.createElement('div');cards.className='cards';for(const [id,r]of Object.entries(R.RECIPES)){let c=card(r.name,Object.entries(r.foods).map(([p,n])=>n+' '+R.FOODS[p].name).join(' + ')+` • custo ${money(R.mealCost(id))} • preparo ${r.time}s por porção`,null),l=document.createElement('label'),ck=document.createElement('input');ck.type='checkbox';ck.checked=state.menu[id];ck.onchange=()=>{state.menu[id]=ck.checked};l.append(ck,' Oferecer no cardápio');c.append(l);let input=document.createElement('input');input.type='number';input.min=1;input.max=100;input.step=.25;input.value=state.prices[id];input.setAttribute('aria-label','Preço de '+r.name);input.onchange=()=>{let n=Number(input.value);if(Number.isFinite(n)&&n>=1&&n<=100){state.prices[id]=n;tell('Preço atualizado. Margem por prato: '+money(n-R.mealCost(id)))}else{input.value=state.prices[id];tell('Informe um preço de 1 a 100.',true)}};c.append(input);cards.append(c)}panel.append(cards)}
 if(dialogTab==='deliveries')panel.append(table(['Pedido','Ingrediente','Total','Recebido','Pendente','Chegada'],state.deliveries.map(o=>['#'+o.id,FoodArt.icon(o.food,o.quality??0),o.total,o.received,o.pending,o.eta>state.time?Math.ceil(o.eta-state.time)+'s':'No recebimento / aguarda espaço'])));
 if(dialogTab==='guide')panel.innerHTML='<p>O jogador só carrega uma unidade nas mãos. Clique na geladeira e retire arroz, frango ou legumes. Leve frango ou legumes à mesa de preparo para cortar; o resultado fica nas mãos. Arroz dispensa corte. Adicione cada ingrediente à panela e volte à geladeira para o próximo. Cozinhe, retire a panela antes de queimar e apoie na mesa de cozinha. Emprate uma porção, pegue o prato e sirva. Retire a panela vazia para reutilizá-la. Recolha um prato sujo nas mãos, lave na pia e reponha na mesa de cozinha. Geladeiras e prateleiras continuam com inventário e não pausam o tempo. Para liberar as mãos, guarde em um armazenamento compatível ou apoie panela/prato na mesa de cozinha.</p>';
 if(dialogTab==='team'){panel.innerHTML=state.singleRoom?'<p>Garçom do salão. Atribua o atendimento abaixo.</p>':'<p>Funcionários de teste. A carga em trânsito é entregue antes da troca de função.</p>';for(const w of state.workers){let c=card(PERSON[w.id],`${NAME[w.room]} • ${w.wait>=5?'Aguardando passagem':w.carry?'Transportando carga':w.goal?'Em deslocamento':'Aguardando trabalho ou ingredientes'}`,null),sel=document.createElement('select');sel.setAttribute('aria-label','Tarefa de '+PERSON[w.id]);for(const [v,n]of (state.singleRoom?[['none','Parado'],['waiter','Anotar pedidos e servir pratos']]:[['none','Parado'],['logistics','Recebimento → estoque → cozinha'],['waiter','Anotar pedidos e servir pratos']]))sel.add(new Option(n,v));sel.value=w.task;sel.onchange=()=>{w.task=sel.value;tell('Tarefa contínua atribuída. Rotas respeitam móveis e outras pessoas.')};c.append(sel);panel.append(c)}}
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
 const cleanup=document.createElement('p');cleanup.textContent='Ferramenta provisória de testes. Remove os móveis e esvazia os armazenamentos, o recebimento e as mãos dos personagens. Cancela clientes, pedidos, entregas e preparos. Preserva dinheiro, dia, preços, cardápio e relatórios. Não devolve o valor dos itens apagados. O salvamento só muda ao usar Salvar restaurante.';panel.append(cleanup);
 button('Excluir todos os móveis e limpar inventários',()=>{R.clearTestScene(state);building=null;hover=null;selectedObject=null;dialogObjectId=null;renderedKey='';releaseKeyboard();renderDialog();tell(state.message)},panel);
 }
 if(dialogTab==='save'){panel.innerHTML='<p>Salvamento formato 12 • cozinha física. Horários dos turnos são preservados.  Qualidade dos ingredientes e pratos preservada; partidas antigas recebem qualidade comum sem recalcular avaliações. Itens das mochilas antigas são transferidos aos armazenamentos; excedentes podem ser recuperados pelo painel da geladeira. Saves da 0.11.0 preservam a paciência atual; saves da 0.10.x recebem o sistema de paciência. Saves da 0.12.0 preservam horário e reputação. Somente formatos anteriores à 0.12.0 iniciam o dia às 06:00 com reputação zero, sem reaplicar avaliações antigas. O arquivo anterior permanece preservado. O progresso fica neste computador.</p>';button('Salvar restaurante',()=>{try{localStorage.setItem('entre-restaurante-12',R.serializeSave(state));tell('Restaurante salvo neste computador.')}catch(e){tell('Não foi possível salvar: '+e.message,true)}},panel);button('Carregar restaurante',()=>{try{let next=R.parseSave(localStorage.getItem('entre-restaurante-12')||localStorage.getItem('entre-restaurante-11')||localStorage.getItem('entre-restaurante-10')||localStorage.getItem('entre-restaurante-09')||localStorage.getItem('entre-restaurante-07')||localStorage.getItem('entre-restaurante-06')||localStorage.getItem('entre-restaurante-05')||localStorage.getItem('entre-restaurante-04'));if(!next)throw Error('salvamento ausente ou inválido');state=next;state.cookActive=false;building=null;selectedObject=null;renderedKey='';renderDialog();tell('Progresso carregado. Preparos em andamento continuam; empratamento exige proximidade da bancada.')}catch(e){tell('Não foi possível carregar: '+e.message+'. Estado atual preservado.',true)}},panel);}
 refresh();}
let keyboard={};
const moveKeys=['arrowup','arrowdown','arrowleft','arrowright','w','a','s','d'];
function keyboardDirection(){return {dx:(keyboard.arrowright||keyboard.d?1:0)-(keyboard.arrowleft||keyboard.a?1:0),dy:(keyboard.arrowdown||keyboard.s?1:0)-(keyboard.arrowup||keyboard.w?1:0)}}
function keyboardMove(){const {dx,dy}=keyboardDirection();if(dx||dy)pendingInteraction=null;R.setPlayerInput(state,dx,dy);}
function releaseKeyboard(){keyboard={};R.setPlayerInput(state,0,0);}
function resetFrameClock(){last=performance.now();releaseKeyboard();}
window.addEventListener('blur',releaseKeyboard);document.addEventListener('visibilitychange',resetFrameClock);
$('management').addEventListener('close',resetFrameClock);
 document.addEventListener('keydown',e=>{if($('management').open||$('welcome').open)return;const k=e.key.toLowerCase();if(constructionMode){if(k==='escape'){e.preventDefault();if(building)stopBuild();else if(!$('constructionDrawer').hidden)toggleCatalog();else exitConstruction();return}if(moveKeys.includes(k)){e.preventDefault();Object.assign(camera,viewNative('camera',['panKey',camera,k]));updateCamera();return}if(k==='r'&&building){e.preventDefault();$('rotateBtn').click();}return}if(k==='escape'){stopBuild();return}if(building&&moveKeys.includes(k)){e.preventDefault();Object.assign(camera,viewNative('camera',['panKey',camera,k]));updateCamera();return;}if(building&&k==='r'){$('rotateBtn').click();return}if(moveKeys.includes(k)&&!building){e.preventDefault();keyboard[k]=true;keyboardMove()}if(k==='e'&&!e.repeat){let b=$('context').querySelector('.prepPrimary button:not(:disabled)')||$('context').querySelector('.prepSlot:not(:disabled)')||(!$('context').querySelector('.prepPanel')&&$('context').querySelector('button:not(:disabled)'));if(b)b.click()}});
 document.addEventListener('keyup',e=>{const k=e.key.toLowerCase();if(!moveKeys.includes(k))return;delete keyboard[k];keyboardMove();});
$('tutorialBtn').onclick=()=>{
 const tutorial=$('welcomeTutorial');
 tutorial.hidden=!tutorial.hidden;
 $('tutorialBtn').setAttribute('aria-expanded',String(!tutorial.hidden));
 $('tutorialBtn').textContent=tutorial.hidden?'Tutorial':'Fechar tutorial';
};
$('startFurnishedBtn').onclick=()=>{state=R.furnishedTest(true,true);building=null;hover=null;selectedObject=null;renderedKey='';resetFrameClock();$('welcome').close();setCameraLevel(cameraLevel);refresh()};
$('startBtn').onclick=()=>{resetFrameClock();$('welcome').close();refresh()};$('welcome').showModal();
function drawKitchenStatus(){
 const box=$('kitchenStatus');box.replaceChildren();
 const jobs=[state.chopping&&{...state.chopping,label:'Cortando ingrediente'+(R.objectNear(state,state.objects.find(o=>o.id===state.chopping.table))?'':' • pausado: aproxime-se')},state.cooking&&{...state.cooking,label:'Cozinhando '+RECIPENAME(state.cooking.recipe)},state.plating&&{...state.plating,label:'Empratando'+(R.objectNear(state,state.objects.find(o=>o.id===state.plating.prep))?'':' • pausado: aproxime-se')}].filter(Boolean);
 for(const o of state.objects)if(o.readyBatch&&o.pan?.startsWith('pot_')){const h=R.heatState(state,o);jobs.push({label:h.label+' • '+RECIPENAME(o.readyBatch.recipe),total:1,left:1-h.value,heat:h.stage});}
 for(const j of jobs){const line=document.createElement('label');line.textContent=j.label+(j.heat?'':' • '+Math.ceil(j.left)+'s');const bar=document.createElement('progress');bar.max=j.total;bar.value=j.total-j.left;bar.setAttribute('aria-label',j.label);if(j.heat){line.className='heat-'+j.heat;line.setAttribute('data-heat',j.heat);if(j.heat==='burned')bar.hidden=true;}line.append(bar);box.append(line);}
}
let kitchenAudio=null;const playedHeat=new WeakMap();
document.addEventListener('pointerdown',()=>{try{if(!kitchenAudio&&typeof window.AudioContext==='function')kitchenAudio=new window.AudioContext();if(kitchenAudio?.state==='suspended')kitchenAudio.resume();}catch{}},{once:true});
function kitchenSounds(){for(const o of state.objects){if(!o.readyBatch)continue;const key=o.readyBatch.doneAt+':'+o.heatStage;if(playedHeat.get(o)===key)continue;playedHeat.set(o,key);if(!kitchenAudio||kitchenAudio.state!=='running')continue;try{const tone=kitchenAudio.createOscillator(),gain=kitchenAudio.createGain(),at=kitchenAudio.currentTime;tone.frequency.value=o.heatStage==='ready'?660:o.heatStage==='over'?440:220;gain.gain.setValueAtTime(.04,at);gain.gain.exponentialRampToValueAtTime(.001,at+.18);tone.connect(gain);gain.connect(kitchenAudio.destination);tone.start(at);tone.stop(at+.2);}catch{}}}
for(const [id,kind] of Object.entries({menuBtn:'note',optionsBtn:'options',catalogToggle:'hammer'})){
 $(id).append(controlIcon(kind));
}
// Frame timing and pause policy are owned by CicloInterface.gd.
refresh();

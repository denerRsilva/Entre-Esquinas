const verify=(cond,msg)=>{if(!cond)throw Error(msg)};
const tick=dt=>JSON.parse(snapshot(dt,[]));
function at(o){Object.assign(state.player,R.accessPoints(state,o)[0],{motion:null,goal:null,settled:null});selectedObject=o.id;refresh()}
function click(w){verify(w&&!w.disabled,'Controle ausente/desativado');w.click();tick(0)}
function findText(w,t){return w.children.find(c=>c.tag==='button'&&(c.textContent===t||c.attrs['aria-label']===t))||w.children.map(c=>findText(c,t)).find(Boolean)}
function menu(mode){if($('management').open)$('management').close();openDialog(mode);tick(0)}
function tab(id){dialogTab=id;renderDialog();tick(0)}
for(const name of ['shifts','team','finance','customers','calendar','reputation']){menu('general');tab(name)}
for(const name of ['camera','guide','test','save']){menu('options');tab(name)}
$('management').close();
for(const o of state.objects){at(o);tick(0)}
const original=state.objects.find(o=>o.type==='chair');
enterConstruction();beginBuild('chair',original.id);
const cash=state.cash;click($('storeBuild'));verify(!state.objects.includes(original)&&state.cash===cash+45/3,'Reembolso cadeira');
beginBuild('chair');hover={x:original.x,y:original.y};building.rot=original.rot;updatePreview();click($('confirmBtn'));verify(state.cash===cash,'Compra de cadeira');
exitConstruction();
const fridge=state.objects.find(o=>o.type==='fridge');at(fridge);openObjectInventory(fridge.id);tick(0);
verify(dialogMode==='container','Geladeira');$('management').close();
Object.assign(state.player,{room:'restaurant',x:16,y:12,goal:null,motion:null,settled:null});menu('computer');
for(const id of ['supplier','menu','deliveries','tools'])tab(id);
let balance=state.cash;click(findText($('panel'),'Comprar'));verify(state.cash===balance-25,'Compra panela');
$('management').close();state=R.furnishedTest();const stove=state.objects.find(o=>o.type==='stove');at(stove);
dialogObjectId=stove.id;menu('cooking');click(findText($('panel'),'Cozinhar'));verify(!!state.cooking,'Início da receita');
for(let i=0;i<150&&!stove.readyBatch;i++)tick(.1);
verify(stove.readyBatch,'Lote pronto');at(stove);click(findText($('context'),'Retirar panela cheia'));
const prep=state.objects.find(o=>o.type==='prep');at(prep);click(findText($('context'),'Empratar'));
for(let i=0;i<30;i++)tick(.1);verify(R.readyCount(prep)===4,'Quatro pratos prontos');
at(prep);click(findText($('context'),'Retirar prato'));verify(R.readyCount(prep)===3,'Retirada de prato');
verify(R.valid(state),'Conservação após cozinhar');
// Switch scenes via the same pointer coordinates delivered by Godot.
state=R.furnishedTest();selectedObject=null;
const origin=state.player.x;
input({kind:'key',key:'d',down:true});
for(let i=0;i<6;i++)tick(.08);
input({kind:'key',key:'d',down:false});verify(state.player.x!==origin||state.player.motion,'Deslocamento por teclado');
Object.assign(state.player,{x:7,y:13,goal:null,motion:null,settled:null});tick(0);
const portalPoint=screenPoint(7*40+20,14*40+20);
input({kind:'pointer',phase:'down',x:portalPoint.x,y:portalPoint.y});
for(let i=0;i<80&&state.player.room!=='street';i++)tick(.08);
verify(state.player.room==='street','Portal do salão para a rua');
const streetPortal=R.PORTALS.street[0];const back=screenPoint(streetPortal.x*40+20,streetPortal.y*40+20);
input({kind:'pointer',phase:'down',x:back.x,y:back.y});
for(let i=0;i<80&&state.player.room!=='restaurant';i++)tick(.08);
verify(state.player.room==='restaurant','Volta da rua ao salão');
// Reposition each furnished object using the map event and confirmation, and check identity.
for(const type of Object.keys(R.CATALOG)){
 state=R.furnishedTest();selectedObject=null;enterConstruction();tick(0);
 const installed=state.objects.find(o=>o.type===type),qty=state.objects.length,oldCash=state.cash;
 const point=screenPoint(installed.x*40+20,installed.y*40+20);
 input({kind:'pointer',phase:'down',x:point.x,y:point.y});verify(building.moving===installed.id,'Seleção de '+type);
 let target=null;
 for(let y=0;y<R.H&&!target;y++)for(let x=0;x<R.W&&!target;x++){
  if(x===installed.x&&y===installed.y)continue;
  if(!previewError({type,room:'restaurant',rot:installed.rot,x,y}))target={x,y};
 }
 verify(target,'Destino livre para '+type);
 const screen=screenPoint(target.x*40+20,target.y*40+20);
 input({kind:'pointer',phase:'down',x:screen.x,y:screen.y});click($('confirmBtn'));
 const moved=state.objects.find(o=>o.id===installed.id);
 verify(moved.x===target.x&&moved.y===target.y&&state.objects.length===qty&&state.cash===oldCash,'Movimento de '+type);
 exitConstruction();
}

const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const R=require('./dist/restaurant-core.js');
class Element{
 constructor(tag='div'){this.tagName=tag;this.children=[];this.style={};this.attributes={};this.open=false;this.className='';this.classList={toggle(){},add(){},remove(){}};}
 append(...items){this.children.push(...items)}
 replaceChildren(...items){this.children=[...items]}
 setAttribute(k,v){this.attributes[k]=v}
 createTHead(){const e=new Element();this.append(e);return e}
 createTBody(){return this.createTHead()}
 insertRow(){return this.createTHead()}
 insertCell(){return this.createTHead()}
 add(e){this.append(e)}
 addEventListener(){}
 showModal(){this.open=true}
 close(){this.open=false}
 getBoundingClientRect(){return {left:0,top:54,width:Math.max(48,this.children.length*48),height:48}}
 getContext(){this.drawn=[];return new Proxy({measureText:()=>({width:70}),fillText:(...args)=>this.drawn.push(args)},{get:(o,k)=>o[k]||(()=>{})})}
 set innerHTML(v){this.html=v;this.children=[]}
 get innerHTML(){return this.html||''}
}
const html=fs.readFileSync('dist/index.html','utf8'),nodes={};for(const [,id]of html.matchAll(/id="([^"]+)"/g))nodes[id]=new Element();
const sandbox={Option:class{constructor(text,value){this.text=text;this.value=value;}},Image:class{constructor(){this.complete=true;this.naturalWidth=1254;}},Restaurant:R,document:{getElementById:id=>nodes[id],createElement:t=>new Element(t),createTextNode:t=>t,documentElement:new Element(),addEventListener(){},hidden:false},window:{addEventListener(){}},performance:{now:()=>0},innerWidth:1366,innerHeight:768,devicePixelRatio:1,getComputedStyle:()=>({getPropertyValue:()=>52}),requestAnimationFrame(){},console,localStorage:{setItem(){},getItem(){}},screen:{}};

nodes.world.getBoundingClientRect=()=>({left:0,top:54,width:parseFloat(nodes.world.style.width)||960,height:parseFloat(nodes.world.style.height)||640});vm.createContext(sandbox);vm.runInContext(fs.readFileSync('dist/restaurant-food.js','utf8'),sandbox);vm.runInContext(fs.readFileSync('dist/restaurant-art.js','utf8'),sandbox);vm.runInContext(fs.readFileSync('dist/restaurant-ui.js','utf8'),sandbox);nodes.startBtn.onclick();

// Appended to the existing DOM/Canvas harness; exercises real UI callbacks.
const run=code=>vm.runInContext(code,sandbox);
run("state=R.furnishedTest();var stove=state.objects.find(o=>o.type==='stove'),prep=state.objects.find(o=>o.type==='prep');Object.assign(state.player,R.accessPoints(state,stove)[0]);selectedObject=stove.id;refresh();draw()");
const descendants=e=>(e.children||[]).flatMap(c=>typeof c==='object'?[c,...descendants(c)]:[]);
const buttons=()=>descendants(nodes.context).filter(e=>e.tagName==='button');
assert(!buttons().some(b=>b.attributes['aria-label']?.startsWith('Abrir Fogão')));
assert(buttons().some(b=>b.attributes['aria-label']==='Retirar panela vazia'));
buttons().find(b=>b.attributes['aria-label']==='Retirar panela vazia').onclick();
assert(buttons().some(b=>b.attributes['aria-label']==='Instalar panela vazia'));
buttons().find(b=>b.attributes['aria-label']==='Instalar panela vazia').onclick();
buttons().find(b=>b.attributes['aria-label']?.startsWith('Escolher receita')).onclick();
assert.equal(nodes.dialogTitle.textContent,'Fogão • preparar lote');
assert(!nodes.panel.children.some(c=>c.textContent?.includes('Abrir inventário')));
const cookCard=nodes.panel.children.find(c=>c.className==='recipeGrid').children.find(c=>c.children?.some(x=>x.textContent==='Sopa de legumes'));
assert(cookCard);const cookButton=cookCard.children.find(x=>x.textContent==='Cozinhar');assert(!cookButton.disabled);cookButton.onclick();
assert(!nodes.management.open);assert(run('!!state.cooking'));assert(nodes.kitchenStatus.children.length);
const progress=nodes.kitchenStatus.children[0].children.find(x=>x.tagName==='progress');assert(progress);assert(progress.max>0);assert.equal(progress.value,0);
run('R.step(state,2);refresh();draw()');assert(nodes.kitchenStatus.children[0].children.find(x=>x.tagName==='progress').value>0);
run('R.step(state,4);refresh();draw()');buttons().find(b=>b.attributes['aria-label']==='Retirar panela cheia').onclick();assert(run("R.inventoryCount(state,'pot_sopa_4')===1"));
run('Object.assign(state.player,R.accessPoints(state,prep)[0],{motion:null,settled:null,goal:null});selectedObject=prep.id;refresh()');
assert(!buttons().some(b=>b.attributes['aria-label']?.startsWith('Abrir Mesa')));
assert(buttons().some(b=>b.attributes['aria-label']==='Instalar pratos limpos'));
buttons().find(b=>b.attributes['aria-label']==='Empratar panela da mochila').onclick();assert(!nodes.management.open);assert(run('!!state.plating'));
run('R.step(state,1);refresh();draw()');assert(nodes.kitchenStatus.children[0].textContent.includes('Empratando'));
run('R.step(state,2);refresh();draw()');assert(run("R.objectCount(prep,'dish_sopa')===4"));assert(buttons().some(b=>b.attributes['aria-label']==='Retirar prato pronto para a mochila'));
buttons().find(b=>b.attributes['aria-label']==='Retirar prato pronto para a mochila').onclick();assert(run("R.inventoryCount(state,'dish_sopa')===1"));
run("openObjectInventory(stove.id)");assert(!nodes.management.open);
run("var fridge=state.objects.find(o=>o.type==='fridge');Object.assign(state.player,R.accessPoints(state,fridge)[0],{motion:null,goal:null,settled:null});openObjectInventory(fridge.id)");
assert(nodes.management.open);assert(nodes.panel.children.some(c=>c.className==='splitInventories'));
nodes.management.close();
for(const type of ['sink','bin']){
 run(`var station=state.objects.find(o=>o.type==='${type}');Object.assign(state.player,R.accessPoints(state,station)[0],{motion:null,goal:null,settled:null});selectedObject=station.id;refresh();openObjectInventory(station.id)`);
 assert(!nodes.management.open);assert(!buttons().some(b=>b.attributes['aria-label']?.startsWith('Abrir ')));
 assert(buttons().some(b=>b.attributes['aria-label']==='Descartar comida e esvaziar panela'));
 if(type==='sink')assert(buttons().some(b=>b.attributes['aria-label']==='Lavar pratos'));
}
nodes.management.close();run("Object.assign(state.player,{x:7,y:13,motion:null,settled:null,goal:null});selectedObject=null;openDialog('general');dialogTab='save';renderDialog()");
assert(nodes.panel.children.some(c=>c.textContent==='Salvar restaurante'));
// UI frame pauses all progress inside management, welcome, hidden tab and building.
run("state=R.furnishedTest();Object.assign(state.player,R.accessPoints(state,state.objects.find(o=>o.type==='stove'))[0]);R.startCook(state,state.objects.find(o=>o.type==='stove').id,'sopa');last=0;frame(1000)");
assert.equal(run('state.cooking.left'),5);nodes.management.close();run('last=0;frame(1000)');assert(run('state.cooking.left<5'));
// Real pointer callback + walking executes a queued action exactly once.
const clickCell=(x,y)=>{const p=run(`screenPoint(${x*40+20},${y*40+20})`);nodes.world.onpointerdown({clientX:p.x,clientY:p.y});};
run("state=R.furnishedTest();pendingInteraction=null;Object.assign(state.player,{x:10,y:12,motion:null,settled:null,goal:null});R.spawn(state,()=>.5);var client=state.customers[0];for(let t=0;t<200&&client.state==='walk';t++)R.step(state,.1,()=>.99)");
assert.equal(run('client.state'),'waiting');clickCell(run('client.x'),run('client.y'));
assert(run('!!pendingInteraction'));
run("for(let t=0;t<250&&pendingInteraction;t++){R.step(state,.1,()=>.99);processInteraction()}");
assert.equal(run('client.state'),'ordered');assert.equal(run('state.orders.length'),1);
run("for(let t=0;t<10;t++)processInteraction()");assert.equal(run('state.orders.length'),1);
run("R.addInventory(state,'dish_'+client.recipe,1);state.equipment.plate++;state.meals.made[client.recipe]++;Object.assign(state.player,{x:10,y:12,motion:null,settled:null,goal:null})");
clickCell(run('client.x'),run('client.y'));
run("for(let t=0;t<250&&pendingInteraction;t++){R.step(state,.1,()=>.99);processInteraction()}");
assert.equal(run('client.state'),'eating');assert.equal(run("R.inventoryCount(state,'dish_'+client.recipe)"),0);assert(run('R.valid(state)'));
run("state=R.furnishedTest();pendingInteraction=null;var chair=state.objects.find(o=>o.type==='chair');var dirtyTestTable=R.seatTable(state,chair);state.dirtyTables[chair.id]=2;state.equipment.plate+=2;Object.assign(state.player,{x:10,y:12,motion:null,settled:null,goal:null})");
clickCell(run('dirtyTestTable.x'),run('dirtyTestTable.y'));
run("for(let t=0;t<250&&pendingInteraction;t++){R.step(state,.1,()=>.99);processInteraction()}");
assert.equal(run("R.inventoryCount(state,'dirtyPlate')"),2);
run("var sink=state.objects.find(o=>o.type==='sink')");clickCell(run('sink.x'),run('sink.y'));
run("for(let t=0;t<250&&pendingInteraction;t++){R.step(state,.1,()=>.99);processInteraction()}");
assert.equal(run("R.inventoryCount(state,'dirtyPlate')"),0);assert.equal(run("R.inventoryCount(state,'plate')"),2);assert(run('R.valid(state)'));
// Clicking the ground cancels queued work; a changed customer phase cannot trigger another action.
run("R.addInventory(state,'dirtyPlate',1);state.equipment.plate++;Object.assign(state.player,{x:10,y:12,motion:null,settled:null,goal:null})");clickCell(run('sink.x'),run('sink.y'));assert(run('!!pendingInteraction'));clickCell(10,12);assert(!run('pendingInteraction'));
run("for(let t=0;t<100;t++){R.step(state,.1,()=>.99);processInteraction()}");assert.equal(run("R.inventoryCount(state,'dirtyPlate')"),1);
console.log('Um clique: atendimento, serviço, mesa, pia e cancelamento passaram.');
console.log('UI rápida: instalação, receita, barras, retirada, empratamento, inventários de armazenamento e pausa em menus passaram.');

// Bancada: hierarquia, estados indisponíveis e seletores sem pausar a simulação.
run("state=R.furnishedTest();prep=state.objects.find(o=>o.type==='prep');Object.assign(state.player,R.accessPoints(state,prep)[0]);selectedObject=prep.id;prepOptionsId=null;prepChoice=null;refresh()");
assert(!buttons().some(b=>b.textContent==='Mover bancada'));
assert(buttons().find(b=>b.attributes['aria-label']==='Empratar panela da mochila').disabled);
assert(buttons().find(b=>b.attributes['aria-label']==='Retirar prato pronto para a mochila').disabled);
buttons().find(b=>b.textContent==='Mais opções').onclick();
assert(!buttons().some(b=>b.textContent==='Mover bancada'));assert(!buttons().some(b=>b.textContent?.includes('Guardar')));
buttons().find(b=>b.textContent==='Menos opções').onclick();
assert(!buttons().some(b=>b.textContent==='Retirar talher'));
// Test fixture with two cooked recipes; choices must not open management.
run("R.addInventory(state,'pot_sopa_4',1);R.addInventory(state,'pot_arrozLegumes_4',1);state.equipment.pot+=2;state.meals.made.sopa+=4;state.meals.made.arrozLegumes+=4;refresh()");
buttons().find(b=>b.attributes['aria-label']==='Empratar panela da mochila').onclick();
assert(!nodes.management.open);assert.equal(run('prepChoice'),'plate');
buttons().find(b=>b.textContent==='Sopa de legumes').onclick();
assert(run('!!state.plating'));assert.equal(run('prepChoice'),null);assert(!nodes.management.open);
run('R.step(state,2.1);refresh()');assert.equal(run('R.readyCount(prep)'),4);
buttons().find(b=>b.attributes['aria-label']==='Empratar panela da mochila').onclick();
run('R.step(state,2.1);refresh()');assert.equal(run('R.readyCount(prep)'),8);
buttons().find(b=>b.attributes['aria-label']==='Retirar prato pronto para a mochila').onclick();
assert.equal(run('prepChoice'),'take');assert(!nodes.management.open);
buttons().find(b=>b.textContent==='Arroz com legumes ×4').onclick();
assert.equal(run("R.inventoryCount(state,'dish_arrozLegumes')"),1);
assert.equal(run('R.readyCount(prep)'),7);
assert(!nodes.management.open);
console.log('Bancada: ações principais, manutenção recolhida e escolhas sem pausa passaram.');

// Renderização é somente leitura, inclusive previews e todas as rotações.
run("state=R.furnishedTest();var beforeArt=JSON.stringify(state);draw();if(JSON.stringify(state)!==beforeArt)throw Error('arte alterou estado');for(const o of state.objects)for(let rot=0;rot<4;rot++)RestaurantArt.object(ctx,R,state,{...o,rot},true,true);state.player.room='street';draw();state.player.room='restaurant';state.inventory[0]=null;draw()");
assert(run('RestaurantArt.ready()'));
console.log('Arte: cenário, personagens, previews e rotações renderizam sem alterar o estado.');

run("building=null;updateCamera();if(camera.zoom!==1)throw Error('zoom');building={};updateCamera();if(camera.zoom!==1)throw Error('montagem');building=null");

run("var testActor={};for(const [dx,dy,expected]of [[1,0,'right'],[-1,0,'left'],[0,-1,'up'],[0,1,'down']]){testActor.motion={fromX:0,fromY:0,toX:dx,toY:dy};if(RestaurantArt.direction(testActor)!==expected)throw Error('direção incorreta');testActor.motion=null;if(RestaurantArt.direction(testActor)!==expected)throw Error('direção parada incorreta')}");
console.log('Direções laterais, costas e orientação parada passaram.');

assert.equal(run("FoodArt.parts('Sopa de legumes • Legumes: 30/8').filter(p=>p.food).map(p=>p.food).join(',')"),'sopa,legumes');
assert.equal(run("FoodArt.parts('Frango com arroz • Arroz com legumes').filter(p=>p.food).map(p=>p.food).join(',')"),'frangoArroz,arrozLegumes');
assert.equal(run("FoodArt.key('pot_sopa_4')"),'sopa');
assert.equal(run("FoodArt.key('dish_frangoArroz')"),'frangoArroz');
assert.equal(run("FoodArt.key('plate')"),null);
assert(run("FoodArt.draw(ctx,'dish_sopa',0,0)"));
console.log('Comidas: identificação sem ambiguidade, panelas, pratos e desenho dos ícones passaram.');

run("state=R.furnishedTest();Object.assign(state.player,{room:'restaurant',x:16,y:12,motion:null,goal:null,settled:null});openDialog('computer')");
const supplierCard=nodes.panel.children.find(x=>x.className==='cards').children[0];
const qualityPicker=supplierCard.children.find(x=>x.tagName==='select');assert(qualityPicker);qualityPicker.value='3';qualityPicker.onchange();supplierCard.children.find(x=>x.tagName==='button'&&x.textContent==='Comprar').onclick();
assert.equal(run('state.deliveries[0].quality'),3);nodes.management.close();
run("state=R.furnishedTest();var hot=state.objects.find(o=>o.type==='stove');Object.assign(state.player,R.accessPoints(state,hot)[0]);R.startCook(state,hot.id,'sopa');R.step(state,5.1);drawKitchenStatus()");
assert(nodes.kitchenStatus.children.some(x=>x.attributes['data-heat']==='ready'));
assert(!descendants(nodes.kitchenStatus).some(x=>x.textContent?.includes('★')));
const cam=run('JSON.stringify(camera)');run('R.step(state,26);drawKitchenStatus()');assert.equal(run('JSON.stringify(camera)'),cam);assert(nodes.kitchenStatus.children.some(x=>x.attributes['data-heat']==='burned'));
console.log('UI de qualidade: fornecedor, alertas sem estrelas e câmera preservada passaram.');
run("state=R.furnishedTest();hot=state.objects.find(o=>o.type==='stove');Object.assign(state.player,R.accessPoints(state,hot)[0]);R.startCook(state,hot.id,'sopa');R.step(state,5.1);openDialog('inventory');last=0;var pausedTime=state.time;frame(1000);if(state.time!==pausedTime)throw Error('queima avançou durante pausa')");nodes.management.close();
console.log('Pausa em menu preserva também a janela de comida pronta.');

// HUD, plaquinha e câmera em proporções diferentes.
run("state=R.furnishedTest();state.clock.minute=660;building=null;Object.assign(state.player,{room:'restaurant',x:8,y:14,motion:null,goal:null,settled:null});refresh()");
assert.equal(nodes.openBtn.textContent,'Fechado');nodes.openBtn.onclick();assert(run('state.open'));assert.equal(nodes.openBtn.textContent,'Aberto');
assert(nodes.hud.innerHTML.includes('hudLeft'));assert(nodes.hud.innerHTML.includes('hudRight'));
run("R.toggleOpen(state);R.step(state,.1);Object.assign(state.player,{room:'restaurant',x:10,y:12,motion:null,goal:null,settled:null});refresh()");nodes.openBtn.onclick();assert(run("pendingInteraction?.kind==='serviceSign'"));run("for(let t=0;t<250&&pendingInteraction;t++){R.step(state,.1,()=>.99);processInteraction()}");assert(run('state.open'));
for(const [w,h]of [[1536,691],[1366,768],[390,844]]){run(`innerWidth=${w};innerHeight=${h};resize();draw()`);assert.equal(parseFloat(nodes.world.style.width),w);const result=run('({right:camera.x+viewport.width/camera.zoom,bottom:camera.y+viewport.height/camera.zoom})');assert(result.right<=960+1e-7);assert(result.bottom<=640+1e-7);const point=run('screenPoint(320,400)');const world=run(`worldPointer({clientX:${point.x},clientY:${point.y}})`);assert(Math.abs(world.x-8)<1e-7);assert(Math.abs(world.y-10)<1e-7);}
console.log('HUD e viewport: plaquinha próxima/distante, tela preenchida e cliques corretos em três proporções passaram.');

// Menus separados, zoom e formulário real dos horários.
run("innerWidth=1536;innerHeight=691;building=null;resize();setCameraLevel(1)");
const wide=run('camera.zoom');nodes.zoomInBtn.onclick();assert(run('camera.zoom')>wide);nodes.zoomOutBtn.onclick();assert.equal(run('camera.zoom'),wide);assert(!nodes.zoomOutBtn.disabled);
run('state=R.fresh()');nodes.menuBtn.onclick();assert.equal(nodes.dialogTitle.textContent,'Gestão do restaurante');
assert.deepEqual(nodes.tabs.children.map(b=>b.textContent),['Turnos','Modo construção','Equipe','Fechamento','Clientes','Calendário','Reputação']);
let scheduleFields=descendants(nodes.panel).filter(e=>e.tagName==='select');assert.equal(scheduleFields.length,4);scheduleFields[0].value='360';nodes.panel.children.find(e=>e.textContent==='Aplicar horários').onclick();assert.equal(run('state.serviceHours[0].start'),360);
nodes.optionsBtn.onclick();assert.equal(nodes.dialogTitle.textContent,'Opções');assert.deepEqual(nodes.tabs.children.map(b=>b.textContent),['Câmera','Salvar e carregar','Testes','Primeiros passos']);
assert(descendants(nodes.panel).some(e=>e.textContent==='100%'));nodes.management.close();
console.log('Menus distintos, zoom com limites e aplicação dos horários pela interface passaram.');

// Montagem dentro de Gestão e sprites reais do catálogo.
nodes.menuBtn.onclick();nodes.tabs.children.find(b=>b.textContent==='Modo construção').onclick();assert.equal(nodes.dialogTitle.textContent,'Modo construção');
assert(run('constructionMode'));assert(nodes.constructionDrawer.hidden);nodes.catalogToggle.onclick();assert(!nodes.constructionDrawer.hidden);
const furnitureCards=nodes.constructionPanel.children.find(e=>e.className==='cards').children;assert.equal(furnitureCards.length,Object.keys(R.CATALOG).length);for(const card of furnitureCards){const icon=card.children.find(e=>e.className==='furnitureSprite');assert(icon);assert.equal(icon.attributes.role,'img');assert(icon.attributes['aria-label']);}
assert(!html.includes('id="buildBtn"'));nodes.exitConstruction.onclick();assert(!run('constructionMode'));nodes.management.close();
for(const level of [.9,.8,.7]){for(const [w,h]of [[1536,691],[1366,768],[390,844]]){run(`innerWidth=${w};innerHeight=${h};resize();setCameraLevel(${level});draw()`);assert.equal(run('cameraLevel'),level);const point=run('screenPoint(320,400)'),world=run(`worldPointer({clientX:${point.x},clientY:${point.y}})`);assert(Math.abs(world.x-8)<1e-7);assert(Math.abs(world.y-10)<1e-7);}}
run('setCameraLevel(.6)');assert.equal(run('cameraLevel'),.7);assert(nodes.zoomOutBtn.disabled);
run('innerWidth=1536;innerHeight=691;resize();setCameraLevel(.7);state=R.fresh();draw();var outside=screenPoint(-40,300);var goalBefore=JSON.stringify(state.player.goal);canvas.onpointerdown({clientX:outside.x,clientY:outside.y});if(JSON.stringify(state.player.goal)!==goalBefore)throw Error("clique fora do mapa moveu jogador")');
console.log('Montagem em Gestão, sprites e zoom 90/80/70% com cliques corretos passaram.');

// Construction pauses live cooking, including while idle or browsing the drawer.
run("state=R.furnishedTest();var hot=state.objects.find(o=>o.type==='stove');Object.assign(state.player,R.accessPoints(state,hot)[0]);R.startCook(state,hot.id,'sopa');enterConstruction();var frozen=JSON.stringify(state);last=0;frame(30000)");
assert.equal(run('JSON.stringify(state)'),run('frozen'));
assert(nodes.constructionDrawer.hidden);assert.equal(nodes.catalogToggle.attributes['aria-expanded'],'false');
nodes.catalogToggle.onclick();assert(!nodes.constructionDrawer.hidden);run('last=0;frame(40000)');assert.equal(run('JSON.stringify(state)'),run('frozen'));
run("beginBuild('chair');hover={x:0,y:0};updatePreview()");assert(nodes.confirmBtn.disabled);const cash=run('state.cash');nodes.confirmBtn.onclick();assert.equal(run('state.cash'),cash);
run('stopBuild();last=0;frame(50000)');assert(run('constructionMode'));assert.equal(run('state.time'),0);
run("beginBuild('chair');for(let y=1;y<14;y++){for(let x=1;x<15;x++){hover={x,y};if(!previewError({type:'chair',room:'restaurant',x,y,rot:0})){updatePreview();break}}if(!$('confirmBtn').disabled)break}");
assert(!nodes.confirmBtn.disabled);const count=run('state.objects.length');nodes.confirmBtn.onclick();assert.equal(run('state.objects.length'),count+1);assert.equal(run('state.cash'),cash-R.CATALOG.chair.price);assert(run('constructionMode'));nodes.confirmBtn.onclick();assert.equal(run('state.cash'),cash-R.CATALOG.chair.price);
run('last=0;frame(60000)');assert.equal(run('state.time'),0);nodes.catalogToggle.onclick();nodes.exitConstruction.onclick();run('frame(16)');assert(run('state.time')>0);assert(run('state.time')<.1);assert(nodes.constructionControls.hidden);
run("state=R.furnishedTest();state.open=true;enterConstruction()");assert(!run('constructionMode'));
console.log('Construção: pausa sem seleção, catálogo recolhido, preparo congelado, posição inválida, compra única, cancelamento e retomada sem salto passaram.');

// Utensílios pertencem ao computador; catálogo com artes e compras reais.
run('state=R.furnishedTest();enterConstruction()');
assert.deepEqual(nodes.constructionTabs.children.map(b=>b.textContent),['Móveis']);
nodes.exitConstruction.onclick();
run("state=R.fresh();Object.assign(state.player,{room:'restaurant',x:16,y:12});openDialog('computer')");
assert.deepEqual(nodes.tabs.children.map(b=>b.textContent),['Fornecedor','Utensílios','Cardápio e preços','Entregas']);
nodes.tabs.children.find(b=>b.textContent==='Utensílios').onclick();
const toolCards=()=>nodes.panel.children.find(e=>e.className==='cards').children;
assert.equal(toolCards().length,3);
for(const c of toolCards()){const image=c.children.find(e=>e.className==='furnitureSprite toolSprite');assert(image);assert.equal(image.attributes.role,'img');assert(image.attributes['aria-label']);}
const toolCash=run('state.cash');
for(const [i,id,price]of [[0,'pot',25],[1,'spoon',15],[2,'plate',5]]){const before=run(`R.inventoryCount(state,'${id}')`);toolCards()[i].children.find(e=>e.tagName==='button').onclick();assert.equal(run(`R.inventoryCount(state,'${id}')`),before+1);}
assert.equal(run('state.cash'),toolCash-45);
run('state.cash=0;renderDialog()');assert(toolCards().every(c=>c.children.find(e=>e.tagName==='button').disabled));
run("state.cash=100;state.inventory=Array.from({length:10},()=>({item:'arroz',n:99}));renderDialog()");assert(toolCards().every(c=>c.children.find(e=>e.tagName==='button').disabled));
run("state.player.x=2;state.player.y=2;$('management').close();openDialog('computer')");assert(!nodes.management.open);
console.log('Computador: utensílios com três artes, compra/custo/quantidade, saldo insuficiente, mochila cheia e acesso presencial passaram.');

// Installed objects are selected from any sector, without approaching them.
for(const type of Object.keys(R.CATALOG)){
 run(`state=R.furnishedTest();enterConstruction();var existing=state.objects.find(o=>o.type==='${type}');var beforeObject=JSON.parse(JSON.stringify(existing));var beforeCash=state.cash;var point=screenPoint(existing.x*40+20,existing.y*40+20);canvas.onpointerdown({clientX:point.x,clientY:point.y})`);
 assert.equal(run('building.moving'),run('existing.id'));assert(!nodes.storeBuild.hidden);assert.equal(run('state.cash'),run('beforeCash'));
 run('stopBuild()');assert.equal(run('JSON.stringify(state.objects.find(o=>o.id===existing.id))'),run('JSON.stringify(beforeObject)'));
 run("beginBuild(existing.type,existing.id);var found=false;for(let y=0;y<R.H&&!found;y++)for(let x=0;x<R.W&&!found;x++){if(x===existing.x&&y===existing.y)continue;hover={x,y};if(!previewError({type:existing.type,room:existing.room,x,y,rot:building.rot})){found=true;updatePreview()}}if(!found)throw Error('Sem destino de teste: '+existing.type)");
 const id=run('existing.id'),count=run('state.objects.length');nodes.confirmBtn.onclick();assert.equal(run('state.objects.length'),count);assert.equal(run('state.cash'),run('beforeCash'));assert.equal(run(`state.objects.filter(o=>o.id===${id}).length`),1);assert(run('constructionMode'));assert(run('R.valid(state)'));
 for(const key of ['inventory','pan','readyBatch','plates','utensil','dishes','dishQuality'])assert.equal(run(`JSON.stringify(state.objects.find(o=>o.id===existing.id).${key})`),run(`JSON.stringify(beforeObject.${key})`));
 nodes.exitConstruction.onclick();
}
// Store/refund is available only during construction, respects installed contents.
run("state=R.furnishedTest();enterConstruction();var prep=state.objects.find(o=>o.type==='prep');beginBuild(prep.type,prep.id);var before=JSON.stringify(state); ");nodes.storeBuild.onclick();assert.equal(run('JSON.stringify(state)'),run('before'));assert(nodes.buildStatus.textContent.includes('Retire'));
run("stopBuild();var chair=state.objects.find(o=>o.type==='chair');beginBuild(chair.type,chair.id);var oldCount=state.objects.length;var oldCash=state.cash");nodes.storeBuild.onclick();assert.equal(run('state.objects.length'),run('oldCount-1'));assert.equal(run('state.cash'),run('oldCash+R.CATALOG.chair.price'));assert(run('constructionMode'));nodes.storeBuild.onclick();assert.equal(run('state.cash'),run('oldCash+R.CATALOG.chair.price'));
nodes.exitConstruction.onclick();run("beginBuild('chair')");assert.equal(run('building'),null);
run("state=R.furnishedTest();for(const o of state.objects){Object.assign(state.player,R.accessPoints(state,o)[0]);selectedObject=o.id;prepOptionsId=o.type==='prep'?o.id:null;useContext.lastSig=null;refresh()}");assert(!buttons().some(b=>/Mover|Guardar/.test(b.textContent||b.attributes['aria-label']||'')));
console.log('Construção: selecionar/mover todos os nove tipos sem proximidade, cancelar, conservar itens/identidade/caixa, guardar com bloqueio de conteúdo, reembolso único e ações removidas fora do modo passaram.');

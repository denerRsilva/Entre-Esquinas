const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const R=require('./dist/restaurant-core.js');
class Element{
 constructor(tag='div'){this.tagName=tag;this.children=[];this.style={};this.attributes={};this.open=false;this.className='';this.classList={toggle(){},add(){}};}
 append(...items){this.children.push(...items)}
 replaceChildren(...items){this.children=[...items]}
 setAttribute(k,v){this.attributes[k]=v}
 createTHead(){const e=new Element();this.append(e);return e}
 createTBody(){return this.createTHead()}
 insertRow(){return this.createTHead()}
 insertCell(){return this.createTHead()}
 addEventListener(){}
 showModal(){this.open=true}
 close(){this.open=false}
 getBoundingClientRect(){return {left:0,top:54,width:Math.max(48,this.children.length*48),height:48}}
 getContext(){this.drawn=[];return new Proxy({measureText:()=>({width:70}),fillText:(...args)=>this.drawn.push(args)},{get:(o,k)=>o[k]||(()=>{})})}
 set innerHTML(v){this.html=v;this.children=[]}
 get innerHTML(){return this.html||''}
}
const html=fs.readFileSync('dist/index.html','utf8'),nodes={};for(const [,id]of html.matchAll(/id="([^"]+)"/g))nodes[id]=new Element();
const sandbox={Restaurant:R,document:{getElementById:id=>nodes[id],createElement:t=>new Element(t),createTextNode:t=>t,documentElement:new Element(),addEventListener(){},hidden:false},window:{addEventListener(){}},performance:{now:()=>0},innerWidth:1366,innerHeight:768,devicePixelRatio:1,getComputedStyle:()=>({getPropertyValue:()=>52}),requestAnimationFrame(){},console,localStorage:{setItem(){},getItem(){}},screen:{}};

nodes.world.getBoundingClientRect=()=>({left:0,top:54,width:960,height:640});vm.createContext(sandbox);vm.runInContext(fs.readFileSync('dist/restaurant-ui.js','utf8'),sandbox);nodes.startBtn.onclick();

vm.runInContext("state=R.fresh();state.cash=10000;R.place(state,'stove',16,2);R.place(state,'prep',16,5);R.place(state,'sink',20,6);R.place(state,'bin',22,8);let stove=state.objects.find(o=>o.type==='stove');Object.assign(state.player,R.accessPoints(state,stove)[0]);refresh();draw();positionActions()",sandbox);
assert.equal(nodes.context.children.length,0,'Aproximar sem clicar mostrou ícones');nodes.world.onpointerdown({clientX:16*40+20,clientY:54+2*40+20});let rows=nodes.context.children;assert(rows.length>0);let stoveRow=rows.find(row=>row.children.some(b=>b.attributes['aria-label']==='Escolher receita e cozinhar 4 porções'));assert(stoveRow);assert(stoveRow.children.length>=2);for(const b of stoveRow.children){assert(b.textContent);assert(b.attributes['aria-label']);}assert(parseFloat(stoveRow.style.top)<54+2*40);
stoveRow.children.find(b=>b.attributes['aria-label'].startsWith('Escolher receita')).onclick();assert.equal(nodes.dialogTitle.textContent,'Fogão • preparar lote');assert(nodes.panel.children.some(c=>c.children?.some(b=>b.textContent==='🔥 Cozinhar 4 porções'&&b.disabled)));
nodes.closeDialog.onclick();
vm.runInContext("var o=state.objects.find(o=>o.type==='stove');R.buyTool(state,'pot');R.buyTool(state,'spoon');for(const item of ['pot','spoon']){let i=state.inventory.findIndex(p=>p?.item===item);R.transferSlot(state,o.id,'player',i)}for(const food of ['arroz','legumes']){state.purchased[food]=4;R.addInventory(state,food,4);R.transferSlot(state,o.id,'player',state.inventory.findIndex(p=>p?.item===food))}openObjectInventory(o.id)",sandbox);
let split=nodes.panel.children.find(e=>e.className==='splitInventories');assert(split);assert.equal(split.children.length,2);assert.equal(split.children[0].children[0].textContent,'Sua mochila');assert(split.children[1].children[0].textContent.startsWith('Fogão'));
let qlabel=nodes.panel.children.find(e=>e.tagName==='label');assert(qlabel);let input=qlabel.children.find(e=>e.tagName==='input');input.value=1;input.onchange();assert.equal(vm.runInContext('transferQuantity',sandbox),1);
vm.runInContext("openDialog('cooking')",sandbox);let recipe=nodes.panel.children.find(c=>c.children?.some(b=>b.textContent==='Arroz com legumes'));assert(recipe);let cook=recipe.children.find(b=>b.textContent==='🔥 Cozinhar 4 porções');assert(!cook.disabled);cook.onclick();assert(!nodes.management.open);assert(vm.runInContext('!!state.cooking',sandbox));
vm.runInContext("for(let i=0;i<100;i++)R.step(state,.1);refresh();draw();positionActions()",sandbox);assert.equal(vm.runInContext('state.cooking',sandbox),null);
// The new objects render even as previews and actions belong to their own objects.
for(const type of ['shelf','prep','sink','bin'])vm.runInContext("drawObject({type:'"+type+"',room:'restaurant',x:16,y:7,rot:0},true)",sandbox);
for(const type of ['prep','sink','bin']){vm.runInContext("$('management').close();var o=state.objects.find(o=>o.type==='"+type+"');Object.assign(state.player,R.accessPoints(state,o)[0]);state.player.motion=null;state.player.goal=null;state.player.settled=null;selectedObject=o.id;refresh();positionActions()",sandbox);assert(nodes.context.children.some(row=>row.children.some(b=>(b.attributes['aria-label']||'').includes(type==='prep'?'Empratar':type==='sink'?'Lavar':'Descartar'))));}
assert(!html.includes('<div id="actions"><button id="fullscreenBtn" class="secondary">⛶ Fullscreen</button><div id="context">'));
console.log('UI: ícones alinhados acima dos objetos, receitas com requisitos, inventários lado a lado, quantidade de transferência, cozinhar pelo botão e prévias dos novos móveis OK');

// Clicar no chão cancela a seleção imediatamente.
nodes.world.onpointerdown({clientX:15*40+20,clientY:54+8*40+20});assert.equal(nodes.context.children.length,0);assert.equal(vm.runInContext('selectedObject',sandbox),null);
// Computador e recebimento também exigem clique próprio, sem vazar ações próximas.
vm.runInContext("selectedObject=null;state.player.x=16;state.player.y=12;state.player.goal=null;state.player.motion=null;refresh()",sandbox);assert.equal(nodes.context.children.length,0);
nodes.world.onpointerdown({clientX:16*40+20,clientY:54+11*40+20});assert.equal(vm.runInContext('selectedObject',sandbox),'computer');assert(nodes.context.children.some(row=>row.children.some(b=>b.attributes['aria-label']==='Usar computador')));
nodes.world.onpointerdown({clientX:21*40+20,clientY:54+11*40+20});assert.equal(vm.runInContext('selectedObject',sandbox),'receiving');assert(!nodes.context.children.some(row=>row.children.some(b=>b.attributes['aria-label']==='Usar computador')));
vm.runInContext("state.player.x=21;state.player.y=12;state.player.goal=null;refresh()",sandbox);assert(nodes.context.children.some(row=>row.children.some(b=>b.attributes['aria-label']==='Recolher ingredientes')));
console.log('Seleção: aproximação sem ícones, clique seleciona só o alvo, chão oculta e computador/recebimento isolados OK');

vm.runInContext("$('management').close();state=R.fresh();selectedObject=null;refresh()",sandbox);assert(!nodes.openBtn.disabled);assert(!nodes.hint.textContent.includes('Montagem: falta'));nodes.openBtn.onclick();assert(vm.runInContext('state.open',sandbox));assert(!nodes.notice.className?.includes('bad'));console.log('UI: Abrir habilitado no restaurante vazio, sem mensagem de exigência mínima OK');

nodes.startFurnishedBtn.onclick();assert(!nodes.welcome.open);assert(vm.runInContext('R.valid(state)&&R.seats(state).length===12',sandbox));assert.equal(vm.runInContext('state.objects.length',sandbox),22);
nodes.menuBtn.onclick();let testTab=nodes.tabs.children.find(b=>b.textContent==='Testes');assert(testTab);testTab.onclick();let clear=nodes.panel.children.find(b=>b.textContent==='🧹 Excluir todos os móveis e limpar inventários');assert(clear);clear.onclick();assert(vm.runInContext('R.valid(state)&&!state.objects.length&&state.inventory.every(p=>p===null)',sandbox));assert.equal(vm.runInContext('selectedObject',sandbox),null);assert(nodes.notice.textContent.includes('itens removidos'));assert(!html.includes('id="startBtn">Começar</button>'));
console.log('UI: início mobiliado e botão Gestão → Testes limpam o cenário sem invalidar a partida OK');

// O mesmo frame de produção deve pausar a paciência em menus, início e aba oculta.
vm.runInContext("$('management').close();state=R.furnishedTest();state.player.x=10;state.player.y=12;R.spawn(state,()=>0);for(let i=0;i<100&&state.customers[0].state==='walk';i++)R.step(state,.1);refresh();draw();openDialog('general')",sandbox);
const beforePause=vm.runInContext('JSON.stringify([state.time,state.clock,state.customers[0].experience.elapsed])',sandbox);
vm.runInContext('frame(1000);frame(2000)',sandbox);assert.equal(vm.runInContext('JSON.stringify([state.time,state.clock,state.customers[0].experience.elapsed])',sandbox),beforePause);
nodes.closeDialog.onclick();sandbox.document.hidden=true;vm.runInContext('frame(3000)',sandbox);assert.equal(vm.runInContext('JSON.stringify([state.time,state.clock,state.customers[0].experience.elapsed])',sandbox),beforePause);sandbox.document.hidden=false;
nodes.welcome.showModal();vm.runInContext('frame(4000)',sandbox);assert.equal(vm.runInContext('JSON.stringify([state.time,state.clock,state.customers[0].experience.elapsed])',sandbox),beforePause);nodes.welcome.close();
vm.runInContext('frame(4100)',sandbox);assert.notEqual(vm.runInContext('JSON.stringify([state.time,state.clock,state.customers[0].experience.elapsed])',sandbox),beforePause);
assert(nodes.world.drawn.some(args=>args[0]==='⏳'),'Canvas não desenhou o emoji');assert(nodes.ordersHud.children.some(e=>e.textContent?.includes('paciência')));
vm.runInContext("openDialog('general');dialogTab='customers';renderDialog()",sandbox);assert(nodes.panel.innerHTML.includes('alimentam a reputação'));assert.equal(nodes.panel.children.length,2);
console.log('UI: emoji no Canvas, tempo restante no HUD, painel Clientes e pausa real do frame em menus/início/aba oculta OK');

vm.runInContext("openDialog('general');dialogTab='calendar';renderDialog()",sandbox);assert(nodes.panel.innerHTML.includes('7 segundos'));assert(nodes.hud.innerHTML.includes('Ano 1'));assert(nodes.hud.innerHTML.includes('/100'));vm.runInContext("dialogTab='reputation';renderDialog()",sandbox);assert(nodes.panel.innerHTML.includes('Desconhecido'));assert(nodes.panel.innerHTML.includes('não acumula outra penalidade'));
vm.runInContext("$('management').close();state.clock={minute:1560,remainder:0,ending:true};state.closing=true;refresh()",sandbox);assert(nodes.openBtn.disabled);assert(nodes.hint.textContent.includes('02:00'));assert(nodes.hud.innerHTML.includes('Encerrando o dia'));
console.log('UI: calendário/reputação no HUD e menus, pausa do relógio e aviso de conclusão às 02:00 OK');

vm.runInContext("$('management').close();$('welcome').close();state=R.fresh();last=1000;frame(8000)",sandbox);assert.equal(vm.runInContext('R.clockText(state)',sandbox),'06:10');assert(Math.abs(vm.runInContext('state.time',sandbox)-7)<1e-7);vm.runInContext("openDialog('general');frame(18000)",sandbox);assert.equal(vm.runInContext('R.clockText(state)',sandbox),'06:10');
console.log('UI: 7 segundos ativos contam um bloco mesmo com frame atrasado, sem avanço nos menus OK');

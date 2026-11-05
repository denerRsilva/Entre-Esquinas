const vm=require('vm'),fs=require('fs'),assert=require('assert');const nodes={};const ctx=new Proxy({},{get:()=>()=>{}});const doc={hidden:false,getElementById(id){return nodes[id]??={style:{},dataset:{},value:3,textContent:'',open:false,getContext:()=>ctx,showModal(){this.open=true},close(){this.open=false}}}};const sandbox={document:doc,performance:{now:()=>0},requestAnimationFrame:()=>{},localStorage:{setItem(k,v){this[k]=v},getItem(k){return this[k]}},console};vm.createContext(sandbox);vm.runInContext(fs.readFileSync('dist/game.js','utf8'),sandbox);vm.runInContext(`
function check(x){if(!x)throw Error('Teste falhou')}
$('buy').onclick();$('unload').onclick();check(s.stock.receiving===12&&pending()===8&&conserved());
s.task='Transportar';for(let i=0;i<2000;i++)step(.05);check(s.stock.pallet===12&&s.stock.worker===0);
$('unload').onclick();for(let i=0;i<2000;i++)step(.05);check(s.stock.pallet===18&&s.stock.rack===2&&conserved());
s.task='Repor';for(let i=0;i<2000;i++)step(.05);check(s.stock.sales===6&&conserved());
$('save').onclick();let old=s.cash;s.cash=0;$('restore').onclick();check(s.cash===old&&conserved());
$('shop').onclick();for(let i=0;i<200;i++)step(.05);check(s.sold>0&&conserved());
check(!valid({...s,stock:{...s.stock,player:-1}}));
console.log('7 fluxos verificados: parcial, transporte, retomada, reposição, persistência, venda e rejeição de dados inválidos');
`,sandbox);
vm.runInContext(fs.readFileSync('dist/spatial.js','utf8'),sandbox);
vm.runInContext(`
s=initial();check(s.room==='street');
function travel(room,index){s.room=room;let d=doors[room][index];playerPath=route(room,s.player,d.p);check(playerPath!==null);doorTarget=d;for(let i=0;i<1000;i++)step(.05);check(s.room===d.to)}
travel('street',0);travel('shop',1);check(s.room==='stock');
s.player=[140,235];$('buy').onclick();$('unload').onclick();check(s.stock.receiving===12&&pending()===8);
s.task='Transportar';for(let i=0;i<3000;i++)step(.05);check(s.stock.pallet===12);
s.task='Repor';for(let i=0;i<6000;i++)step(.05);check(s.stock.sales===6&&conserved());
s.room='shop';s.player=[140,235];check(near()!=='receiving');
for(let room of ['shop','stock']){let path=route(room,[60,350],[740,350]);check(path&&path.every(p=>!blocked(room,p[0],p[1])))}
$('save').onclick();s.room='street';$('restore').onclick();check(s.room==='shop');
travel('shop',0);check(s.room==='street');
console.log('Ambientes: entrada/saída, recebimento local, rotas de funcionário entre salas, obstáculos, isolamento e persistência OK');
`,sandbox);
vm.runInContext(fs.readFileSync('dist/customers.js','utf8'),sandbox);
vm.runInContext(`
s=initial();s.room='shop';s.player=[60,350];s.cash=300;
$('buy').onclick();s.room='stock';s.player=[140,235];$('unload').onclick();move('receiving','sales',6);s.room='shop';s.player=[60,350];$('shop').onclick();
for(let i=0;i<1800;i++)step(.05);
check(s.sold===0&&s.cash===180&&queue().length>=2&&conserved());
let first=queue()[0];check(s.customers.some(c=>c.room==='street')||s.customers.some(c=>c.room==='shop'));
$('serve').onclick();check(!first.serving);
s.player=[560,330];$('serve').onclick();check(first.serving);
for(let i=0;i<20;i++)step(.05);let progress=first.progress;check(progress>0&&s.sold===0);
s.room='stock';for(let i=0;i<100;i++)step(.05);check(first.progress===progress&&s.sold===0);
s.room='shop';s.player=[560,330];for(let i=0;i<70;i++)step(.05);check(s.sold===1&&s.cash===198&&conserved());
check(queue().every(c=>c.id>first.id));
$('save').onclick();s.cash=0;$('restore').onclick();check(s.cash===198&&conserved()&&s.customers.length>0);
$('shop').onclick();check(s.closing);let highest=s.nextCustomer;
for(let i=0;i<18000&&s.open;i++){let c=queue()[0];if(c&&!c.serving&&Math.hypot(c.pos[0]-700,c.pos[1]-230)<8)$('serve').onclick();step(.05)}
check(!s.open&&s.customers.length===0&&s.nextCustomer===highest&&conserved());
check(s.sold===6&&s.day===2);
console.log('Clientes OK: percurso, reserva, ausência de venda automática, fila FIFO, caixa presencial, pausa, persistência e fechamento');
`,sandbox);
vm.runInContext(fs.readFileSync('dist/operations.js','utf8'),sandbox);
vm.runInContext(`
s=initial();$('quantity').value='5';$('buy').onclick();check(s.purchased===5&&s.cash===270&&s.orders[0].pending===5&&conserved());
let snap=JSON.stringify(s);for(let n of ['0','1.5','-2','abc','1001']){$('quantity').value=n;$('buy').onclick();check(JSON.stringify(s)===snap)}
$('quantity').value='100';$('buy').onclick();check(JSON.stringify(s)===snap);purchaseInfo();check($('buy').disabled);
s.room='stock';s.player=[140,235];contextualUI();check($('unload').hidden&&!$('take').hidden&&$('take').disabled);$('unload').onclick();contextualUI();check(!$('take').disabled&&s.stock.receiving===5);
s.task='Transportar';check(workerDescription().includes('Buscando'));for(let i=0;i<3000;i++)step(.05);check(workerDescription().includes('Aguardando mercadorias'));
s.task='Repor';for(let i=0;i<4000;i++)step(.05);check(workerDescription().includes('Sem mercadoria'));
s.room='shop';s.player=[280,280];contextualUI();check($('drop').textContent==='Repor expositor'&&!$('take').hidden&&$('serve').hidden);
s.player=[560,330];contextualUI();check(!$('serve').hidden&&$('take').hidden&&$('serve').disabled);
s.room='street';s.player=[400,340];contextualUI();check(!$('contextDoor').hidden);$('contextDoor').onclick();for(let i=0;i<1000;i++)step(.05);check(s.room==='shop');
$('quantity').value='20';purchaseInfo();check($('purchaseInfo').textContent.includes('Total: $120.00'));
check(conserved());console.log('Operação OK: quantidades, custos, validação, contexto, portas e feedback do funcionário');
`,sandbox);
vm.runInContext(fs.readFileSync('dist/street-life.js','utf8'),sandbox);
vm.runInContext(`
s=initial();let x=pedestrians[0].pos[0];step(.05);check(pedestrians[0].pos[0]!==x&&!s.open);
for(let i=0;i<2000;i++)step(.05);check(pedestrians.length>0&&pedestrians.length<=4&&s.customers.length===0&&s.sold===0&&s.cash===300&&conserved());
s.room='stock';let id=pedestrianId;for(let i=0;i<2000;i++)step(.05);check(pedestrianId>id&&pedestrians.length<=4);
s.room='street';draw();$('shop').onclick();for(let i=0;i<500;i++)step(.05);check(s.customers.length>0&&pedestrians.length>0);$('shop').onclick();for(let i=0;i<4000;i++)step(.05);check(!s.open&&s.customers.length===0&&pedestrians.length>0&&conserved());
console.log('Rua OK: circulação fechada/aberta, renovação, limite de pedestres, mudança de ambiente e fechamento sem bloqueio');
`,sandbox);
vm.runInContext(fs.readFileSync('dist/automatic-receiving.js','utf8'),sandbox);
vm.runInContext(`
s=initial();$('quantity').value='20';$('buy').onclick();check(s.stock.receiving===12&&pending()===8&&s.orders[0].received===12&&conserved());
check(!s.open&&s.room==='street');let cash=s.cash;for(let i=0;i<20;i++)step(.05);check(s.stock.receiving===12&&s.cash===cash&&pending()===8);
move('receiving','player',1);step(.05);check(s.stock.receiving===12&&pending()===7&&s.stock.player===1&&conserved());
$('quantity').value='5';$('buy').onclick();check(s.orders[1].received===0&&s.orders[1].pending===5);
move('receiving','pallet',12);step(.05);check(s.stock.receiving===12&&s.orders[0].pending===0&&s.orders[1].pending===0&&conserved());
$('save').onclick();s.cash=0;$('restore').onclick();check(conserved()&&s.stock.receiving===12&&s.stock.player===1);
s.task='Transportar';for(let i=0;i<6000;i++)step(.05);check(s.stock.pallet===18&&s.stock.rack===6&&s.stock.receiving===0&&conserved());
s=initial();$('quantity').value='1';$('buy').onclick();check(s.stock.receiving===1&&pending()===0&&s.cash===294);
console.log('Descarga automática OK: compra, capacidade, retomada, FIFO, loja fechada, outros ambientes, persistência e conservação');
`,sandbox);
vm.runInContext(fs.readFileSync('dist/economy.js','utf8'),sandbox);
vm.runInContext(`
{
s=initial();syncStock();check(verifyEconomy(s));check(orderProduct('arroz',10));check(orderProduct('leite',5));check(orderProduct('cafe',2));check(s.cash===159&&total('receiving')===72&&pendingUnits()===30&&conserved());
check(s.orders[0].received===60&&s.orders[1].received===12&&s.orders[2].received===0);
transferUnits('receiving','pallet','arroz',60);receive();check(pendingUnits()===0&&conserved());
let before=JSON.stringify(s);check(!orderProduct('arroz',1000)&&JSON.stringify(s)===before);
s.task='Transportar';for(let i=0;i<5000;i++)step(.05);check(total('receiving')===0&&total('pallet')+total('rack')===102&&conserved());
s.task='Repor';for(let i=0;i<7000;i++)step(.05);check(s.inv.sales.arroz===18&&s.inv.sales.leite===12&&s.inv.sales.cafe===6&&conserved());
for(let p of IDS)check(demandFactor(p,GOODS[p].reference*.5,'Econômico')>demandFactor(p,GOODS[p].reference*2,'Econômico'));
check(profileFor(1)==='Econômico'&&profileFor(2)==='Família'&&profileFor(3)==='Seletivo');
s.open=true;for(let i=0;i<1400;i++)step(.05);check(s.sold.arroz+s.sold.leite+s.sold.cafe===0&&queue().length>0&&conserved());
setMode('manual');s.room='shop';s.player=[560,330];let front=queue()[0];$('serve').onclick();for(let i=0;i<15;i++)step(.05);check(front.progress>0);let progress=front.progress;s.room='stock';for(let i=0;i<60;i++)step(.05);check(front.progress===progress);s.room='shop';s.player=[560,330];for(let i=0;i<100;i++)step(.05);check(IDS.reduce((n,p)=>n+s.sold[p],0)===front.quantity&&conserved());
setMode('continuous');$('serve').onclick();for(let i=0;i<1000;i++)step(.05);check(s.metrics.continuous.sales>0&&conserved());s.room='stock';step(.05);check(!s.continuous);
$('save').onclick();let saved=s.cash;s.cash=0;$('restore').onclick();check(s.cash===saved&&conserved()&&verifyEconomy(s));
let corrupt=JSON.parse(JSON.stringify(s));corrupt.inv.sales.arroz++;check(!verifyEconomy(corrupt));
s=initial();s.cash=600;syncStock();for(let k of Object.keys(UPGRADES))check(buyUpgrade(k));check(s.upgrades.length===4&&unitCap('player')===18&&unitCap('sales')===60&&duration()===1.5);let balance=s.cash;check(!buyUpgrade('cart')&&s.cash===balance);
orderProduct('arroz',3);orderProduct('leite',2);orderProduct('cafe',1);s.task='Abastecer';for(let i=0;i<15000;i++)step(.05);check(s.inv.sales.arroz===18&&s.inv.sales.leite===12&&s.inv.sales.cafe===6&&conserved());
s.room='shop';s.player=[560,330];s.open=true;setMode('continuous');s.continuous=true;for(let i=0;i<600;i++)step(.05);s.closing=true;for(let i=0;i<20000&&s.open;i++)step(.05);check(!s.open&&s.day===2&&s.history.length===1&&conserved());
let legacy={stock:{receiving:12,pallet:0,rack:0,sales:0,player:0,worker:0},orders:[{total:20,received:12,pending:8}],purchased:20,sold:0,cash:180,price:3,customers:[],investment:'Carrinho'};let imported=migrateLegacy(legacy);check(imported&&imported.inv.receiving.arroz===72&&imported.purchased.arroz===120&&imported.upgrades.includes('cart'));
s=imported;syncStock();draw();check(verifyEconomy(s));
console.log('0.8 OK: produtos, FIFO, custos, mix, perfis, elasticidade, unidades, caixa A/B, melhorias combinadas, rotina, fechamento, persistência e migração');
}
`,sandbox);
vm.runInContext(`
{
s=initial();resetNavigation();orderProduct('arroz',6);orderProduct('leite',4);orderProduct('cafe',2);s.task='Transportar';s.worker2.task='Repor';
for(let i=0;i<12000;i++)step(.05);
check(s.inv.sales.arroz===18&&s.inv.sales.leite===12&&s.inv.sales.cafe===6&&total('receiving')===0&&conserved());
check(s.task==='Transportar'&&s.worker2.task==='Repor');
s=initial();resetNavigation();orderProduct('arroz',1);s.task='Transportar';s.worker2.task='Transportar';for(let i=0;i<1000;i++)step(.05);check(total('pallet')===6&&conserved());
s=initial();resetNavigation();orderProduct('leite',2);s.worker2.task='Transportar';for(let i=0;i<1000&&!total('worker2');i++)step(.05);check(total('worker2')===6);s.worker2.task='Parado';let pos=[...s.worker2.pos];$('save').onclick();s.cash=0;$('restore').onclick();check(total('worker2')===6&&s.worker2.task==='Parado'&&s.worker2.pos[0]===pos[0]&&verifyEconomy(s));for(let i=0;i<1000;i++)step(.05);check(total('worker2')===0&&s.inv.pallet.leite===6&&s.inv.receiving.leite===6&&conserved());
let previous=JSON.parse(JSON.stringify(s));delete previous.worker2;delete previous.inv.worker2;check(verifyEconomy(previous)&&previous.worker2.task==='Parado'&&previous.inv.worker2.leite===0);
let bad=JSON.parse(JSON.stringify(s));bad.worker2.pos=[NaN,2];check(!verifyEconomy(bad));
s.room=s.worker2.room;draw();console.log('Dois funcionários OK: tarefas paralelas, disputa de estoque, troca segura, carga individual, salvar/carregar e migração');
}
`,sandbox);
vm.runInContext(`
{
s=initial();resetNavigation();selectTransportProduct('arroz');selectProduct('cafe');check(transportSelected==='arroz'&&$('quickProduct').value==='arroz');
$('management').open=true;$('quantity').value='3';$('buy').onclick();check(s.purchased.cafe===18&&s.cash===246&&$('menuNotice').textContent.includes('18 unidades de Café')&&$('menuNotice').textContent.includes('Recebidas: 18')&&$('menuNotice').dataset.status==='success');
selectTransportProduct('leite');check(selected==='cafe'&&$('product').value==='cafe');$('price').value='7';$('price').oninput();check(s.prices.cafe===7&&s.prices.leite===3);
$('quantity').value='1000';$('buy').onclick();check($('menuNotice').dataset.status==='error'&&s.cash===246);
$('upgrade-cart').onclick();check($('menuNotice').textContent.includes('Carrinho')&&$('menuNotice').textContent.includes('$60.00'));$('management').open=false;
orderProduct('leite',2);s.room='stock';s.player=[140,235];$('take').onclick();check(s.inv.player.leite===12&&s.inv.player.cafe===0);s.room='shop';s.player=[280,280];$('drop').onclick();check(s.inv.sales.leite===12&&conserved());
let drawn=[],originalText=text;text=function(t,...args){drawn.push(t);originalText(t,...args)};draw();text=originalText;check(drawn.includes('Esgotado')&&drawn.includes('0 un.')&&drawn.includes('12 un.')&&$('displayStock').textContent.includes('Café: Esgotado'));
setMode('manual');let client={id:101,profile:'Família',product:'leite',quantity:3,room:'shop',pos:[700,230],state:'queue',basket:true,price:3,progress:1.2,serving:true,path:[],goal:''};s.inv.sales.leite-=3;s.customers=[client];s.open=true;s.room='stock';update();check($('checkoutStatus').textContent.includes('Atendimento pausado — volte ao caixa'));
let progress=client.progress;for(let i=0;i<30;i++)step(.05);check(client.progress===progress&&s.sold.leite===0&&conserved());s.room='shop';s.player=[560,330];step(.05);check(client.progress>progress&&$('checkoutStatus').textContent.includes('Atendimento em andamento'));
s.mode='continuous';s.continuous=true;s.room='stock';step(.05);progress=client.progress;s.room='shop';s.player=[560,330];step(.05);check(client.progress===progress&&$('checkoutStatus').textContent.includes('toque em Iniciar atendimento contínuo'));$('serve').onclick();step(.05);check(client.progress>progress);
console.log('UI/UX 0.8.2 OK: confirmações e erros no menu, seleções isoladas, compra/preço/transporte, expositor real e pausa manual/contínua');
}
`,sandbox);
vm.runInContext(`
for(let n=0;n<=60;n++){let boxes=shelfPackages(n);check(boxes.length===Math.ceil(n/6)&&boxes.reduce((a,b)=>a+b,0)===n&&boxes.every(q=>q>=1&&q<=6));}
console.log('Prateleira OK: preenchimento de 0 a 60 unidades e caixas parciais');
`,sandbox);
vm.runInContext(`
{
s=initial();resetNavigation();check(s.mode==='continuous'&&!s.continuous);
s.room='shop';s.player=[560,330];
function waitingBuyer(id,index=0){s.purchased.arroz++;s.customers.push({id,profile:'Econômico',product:'arroz',quantity:1,room:'shop',pos:[...QUEUE[index]],state:'queue',basket:true,price:2,progress:0,serving:false,path:[],goal:''});syncStock()}
waitingBuyer(201);waitingBuyer(202,1);
for(let i=0;i<100;i++)step(.05);check(s.sold.arroz===0);
$('serve').onclick();for(let i=0;i<300;i++)step(.05);
check(s.sold.arroz===2&&s.metrics.continuous.clicks===1&&s.continuous&&conserved());
check($('checkoutStatus').textContent.includes('ativo — aguardando cliente'));
waitingBuyer(203);for(let i=0;i<100;i++)step(.05);
check(s.sold.arroz===3&&s.metrics.continuous.clicks===1&&conserved());
waitingBuyer(204);step(.5);let buyer=queue()[0],progress=buyer.progress;check(progress>0);
s.player=[280,280];step(.5);check(!s.continuous&&buyer.progress===progress);
s.player=[560,330];step(.5);check(buyer.progress===progress&&s.sold.arroz===3);
$('serve').onclick();for(let i=0;i<100;i++)step(.05);
check(s.sold.arroz===4&&s.metrics.continuous.clicks===2&&conserved());
waitingBuyer(205);$('serve').onclick();step(.5);check(queue()[0].progress===0&&!s.continuous);
$('serve').onclick();s.open=true;$('shop').onclick();check(s.closing&&s.continuous);
for(let i=0;i<1000&&s.open;i++)step(.05);
check(!s.open&&s.day===2&&s.sold.arroz===5&&s.history[0].metrics.continuous.clicks===4&&conserved());
s=initial();s.mode='manual';$('save').onclick();$('restore').onclick();
check(s.mode==='continuous'&&!s.continuous&&$('cashMode').value==='continuous'&&verifyEconomy(s));
console.log('Caixa 0.8.6 OK: um toque atende a fila, novas chegadas, espera vazia, pausa presencial, retomada, fechamento e salvamento anterior');
}
`,sandbox);
// Menu geral e computador usam o mesmo diálogo pausado, com áreas distintas.
const panelIds=['goods','orders','logistics','upgrades','evaluation','progress'];
for(const id of panelIds){const n=doc.getElementById(id);n.id=id;n.classList={toggle(){}}}
const panelButtons=panelIds.map(id=>({dataset:{panel:id},hidden:false,setAttribute(k,v){this[k]=v}}));
doc.querySelectorAll=selector=>selector==='.panel'?panelIds.map(id=>doc.getElementById(id)):selector==='[data-panel]'?panelButtons:[];
const canvasMock=doc.getElementById('map');canvasMock.getBoundingClientRect=()=>({left:0,top:0,width:800,height:460});
vm.runInContext(fs.readFileSync('dist/management.js','utf8'),sandbox);
vm.runInContext(fs.readFileSync('dist/computer.js','utf8'),sandbox);
vm.runInContext(`
{
s=initial();resetNavigation();$('management').open=false;
$('manage').onclick();check(managementSection==='general'&&$('goods').hidden&&$('orders').hidden&&!$('logistics').hidden);
showManagementPanel('goods');check($('goods').hidden);
$('closeManagement').onclick();$('useComputer').onclick();check(!$('management').open);
$('quantity').value='2';$('buy').onclick();check(s.purchased.arroz===0);
s.room='stock';s.player=[680,370];syncStock();update();check($('useComputer').hidden);
canvas.onpointerdown({clientX:140,clientY:320});check(playerPath.length>0&&doorTarget===null);
for(let i=0;i<200;i++)step(.05);
check(atComputer()&&!$('useComputer').hidden&&conserved());
$('useComputer').onclick();check($('management').open&&managementSection==='computer'&&!$('goods').hidden&&$('logistics').hidden);
showManagementPanel('logistics');check($('logistics').hidden);
selectTransportProduct('leite');selectProduct('cafe');$('buy').onclick();check(s.purchased.cafe===12&&s.cash===264&&transportSelected==='leite'&&$('menuNotice').textContent.includes('12 unidades de Café'));
$('price').value='7';$('price').oninput();check(s.prices.cafe===7);
showManagementPanel('orders');check(!$('orders').hidden&&$('ordersRows').innerHTML.includes('Café')&&$('ordersSummary').textContent.includes('12 unidades recebidas'));
$('closeManagement').onclick();let price=s.prices.cafe,balance=s.cash;$('price').value='8';$('price').oninput();$('buy').onclick();check(s.prices.cafe===price&&s.cash===balance);
$('manage').onclick();check($('goods').hidden&&$('orders').hidden&&!$('logistics').hidden);$('closeManagement').onclick();
for(const p of [COMPUTER.point,[140,235],[410,235],[650,235]]){let path=route('stock',[680,370],p);check(path&&path.every(q=>!blocked('stock',q[0],q[1])))}
s.player=[140,320];$('save').onclick();s.player=[680,370];$('restore').onclick();check(atComputer()&&!blocked('stock',s.player[0],s.player[1])&&verifyEconomy(s));
s=initial();resetNavigation();orderProduct('arroz',6);orderProduct('leite',4);orderProduct('cafe',2);s.task='Transportar';s.worker2.task='Repor';for(let i=0;i<12000;i++)step(.05);
check(s.inv.sales.arroz===18&&s.inv.sales.leite===12&&s.inv.sales.cafe===6&&conserved());
s.room='stock';draw();console.log('Computador 0.8.8 OK: acesso local, navegação, menu separado, compras/preços protegidos, pedidos, salvamentos e rotas dos dois funcionários');
}
`,sandbox);

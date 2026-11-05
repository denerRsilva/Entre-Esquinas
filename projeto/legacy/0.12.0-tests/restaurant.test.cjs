const assert=require('node:assert/strict'),R=require('./dist/restaurant-core.js');
function setup(){const s=R.fresh();s.cash=10000;for(const [t,x,y,r=0]of [['table',4,4],['chair',3,4,1],['stove',16,2],['fridge',21,2],['prep',16,5],['sink',20,6],['bin',22,8]]){let p=R.place(s,t,x,y,r);assert(p.ok,p.error)}return s;}
const obj=(s,type)=>s.objects.find(o=>o.type===type);
function stand(s,o){let p=R.accessPoints(s,o).find(p=>!R.allActors(s).some(a=>a!==s.player&&a.room===p.room&&a.x===p.x&&a.y===p.y));assert(p);Object.assign(s.player,p);s.player.motion=null;s.player.goal=null;s.player.settled=null;}
function giveFood(s,food,n){s.purchased[food]+=n;assert(R.addInventory(s,food,n));}
function deposit(s,o,item){stand(s,o);let i=s.inventory.findIndex(p=>p?.item===item);assert(i>=0,item);let r=R.transferSlot(s,o.id,'player',i);assert(r.ok,r.error);}
function withdraw(s,o,item){stand(s,o);let i=o.inventory.findIndex(p=>p?.item===item);assert(i>=0,item);let r=R.transferSlot(s,o.id,'object',i);assert(r.ok,r.error);}
function ticks(s,n){for(let i=0;i<n;i++){R.step(s,.1);assert(R.foodConserved(s));assert(R.equipmentConserved(s));assert(R.mealsConserved(s));}}
{
 const s=setup(),stove=obj(s,'stove'),prep=obj(s,'prep'),sink=obj(s,'sink'),bin=obj(s,'bin');assert(R.valid(s));
 stand(s,stove);let before=JSON.stringify(s.inventory);assert(!R.startCook(s,stove.id,'arrozLegumes').ok);assert.equal(JSON.stringify(s.inventory),before);
 R.buyTool(s,'pot');deposit(s,stove,'pot');R.buyTool(s,'spoon');deposit(s,stove,'spoon');giveFood(s,'arroz',4);deposit(s,stove,'arroz');
 // Ingrediente fora do fogão não conta.
 giveFood(s,'legumes',4);deposit(s,obj(s,'fridge'),'legumes');stand(s,stove);assert(!R.startCook(s,stove.id,'arrozLegumes').ok);withdraw(s,obj(s,'fridge'),'legumes');deposit(s,stove,'legumes');
 assert(R.startCook(s,stove.id,'arrozLegumes').ok);assert.equal(s.used.arroz,4);assert.equal(R.objectCount(stove,'cookingPot'),1);assert(R.valid(s));assert(!R.transferSlot(s,stove.id,'object',stove.inventory.findIndex(p=>p?.item==='cookingPot')).ok);
 assert(!R.startCook(s,stove.id,'arrozLegumes').ok);let saved=JSON.parse(JSON.stringify(s));assert(R.valid(saved));
 s.player.x=7;s.player.y=13;let left=s.cooking.left;ticks(s,10);assert.equal(s.cooking.left,left);stand(s,stove);ticks(s,70);assert.equal(s.cooking,null);assert.equal(R.objectCount(stove,'pot_arrozLegumes_4'),1);assert.equal(R.objectCount(stove,'pot'),0);assert(R.valid(s));
 assert(!R.startCook(s,stove.id,'arrozLegumes').ok,'reutilizou panela cheia');withdraw(s,stove,'pot_arrozLegumes_4');deposit(s,prep,'pot_arrozLegumes_4');assert(!R.plateFood(s,prep.id,'arrozLegumes').ok);
 R.buyTool(s,'spoon');deposit(s,prep,'spoon');R.buyTool(s,'plate');R.buyTool(s,'plate');deposit(s,prep,'plate');assert(R.plateFood(s,prep.id,'arrozLegumes').ok);assert.equal(R.objectCount(prep,'dish_arrozLegumes'),2);assert.equal(R.objectCount(prep,'pot_arrozLegumes_2'),1);assert.equal(R.objectCount(prep,'pot'),0);assert(R.valid(s));
 R.buyTool(s,'plate');R.buyTool(s,'plate');deposit(s,prep,'plate');assert(R.plateFood(s,prep.id,'arrozLegumes').ok);assert.equal(R.objectCount(prep,'dish_arrozLegumes'),4);assert.equal(R.objectCount(prep,'pot'),1);assert(!R.plateFood(s,prep.id,'arrozLegumes').ok);assert(R.valid(s));
 // Serviço real de almoço e jantar com pratos da bancada.
 s.menu={arrozLegumes:true,sopa:false,frangoArroz:false};s.player.x=10;s.player.y=12;
 for(let period=0;period<2;period++){
  assert(R.toggleOpen(s));assert(R.spawn(s));R.toggleOpen(s);for(let i=0;i<300&&s.customers[0]?.state!=='waiting';i++)ticks(s,1);let c=s.customers[0];assert(c&&c.state==='waiting');
  R.goObject(s,s.player,s.objects.find(o=>o.id===c.seat));for(let i=0;i<300&&(!R.near(s.player,c,1)||s.player.motion);i++)ticks(s,1);assert(R.interact(s,c.id));
  if(!R.inventoryCount(s,'dish_arrozLegumes'))withdraw(s,prep,'dish_arrozLegumes');R.goObject(s,s.player,s.objects.find(o=>o.id===c.seat));for(let i=0;i<300&&(!R.near(s.player,c,1)||s.player.motion);i++)ticks(s,1);assert(R.interact(s,c.id));for(let i=0;i<300&&s.open;i++)ticks(s,1);assert(!s.open);
 }
 assert.equal(s.day,1);assert.equal(s.reports.length,0);assert.equal(s.ledger.sales,2);assert.equal(s.meals.eaten.arrozLegumes,2);assert.equal(s.dirtyTables[s.objects.find(o=>o.type==='chair').id],2);assert(R.valid(s));
 stand(s,obj(s,'table'));assert(R.collectDirty(s,obj(s,'table').id).ok);assert.equal(R.inventoryCount(s,'dirtyPlate'),2);deposit(s,sink,'dirtyPlate');assert(R.washPlates(s,sink.id).ok);assert.equal(R.objectCount(sink,'plate'),2);assert.equal(R.objectCount(sink,'dirtyPlate'),0);assert(!R.washPlates(s,sink.id).ok);assert(R.valid(s));
 // Descarte de prato pronto devolve prato sujo e conserva os equipamentos.
 deposit(s,bin,'dish_arrozLegumes');let ix=bin.inventory.findIndex(p=>p?.item==='dish_arrozLegumes');assert(R.discardFood(s,bin.id,ix).ok);assert.equal(R.objectCount(bin,'dirtyPlate'),1);assert.equal(s.meals.wasted.arrozLegumes,1);assert(R.valid(s));
 console.log('Ciclo: fogão físico → panela 4 porções → empratar parcial/total → servir almoço/jantar → recolher/lavar pratos OK');
 // Novo lote, descartado na pia e no lixo. Nenhum ingrediente surge de outras geladeiras.
 withdraw(s,prep,'pot');deposit(s,stove,'pot');giveFood(s,'legumes',8);deposit(s,stove,'legumes');assert(R.startCook(s,stove.id,'sopa').ok);ticks(s,60);withdraw(s,stove,'pot_sopa_4');deposit(s,sink,'pot_sopa_4');assert(R.discardFood(s,sink.id,sink.inventory.findIndex(p=>p?.item==='pot_sopa_4')).ok);assert.equal(R.objectCount(sink,'pot'),1);assert.equal(s.meals.wasted.sopa,4);assert(R.valid(s));
 withdraw(s,sink,'pot');deposit(s,stove,'pot');giveFood(s,'legumes',8);deposit(s,stove,'legumes');assert(R.startCook(s,stove.id,'sopa').ok);ticks(s,60);withdraw(s,stove,'pot_sopa_4');deposit(s,bin,'pot_sopa_4');assert(R.discardFood(s,bin.id,bin.inventory.findIndex(p=>p?.item==='pot_sopa_4')).ok);assert.equal(s.meals.wasted.sopa,8);assert(R.valid(s));
 const load=JSON.parse(JSON.stringify(s));assert(R.valid(load));load.meals.made.sopa++;assert(!R.valid(load));console.log('Descarte na pia/lixo, panela reutilizável, save em preparo e conservação de porções/panelas/pratos OK');
}
{
 const s=setup(),stove=obj(s,'stove');R.buyTool(s,'pot');deposit(s,stove,'pot');R.buyTool(s,'spoon');deposit(s,stove,'spoon');giveFood(s,'arroz',4);deposit(s,stove,'arroz');giveFood(s,'frango',4);deposit(s,stove,'frango');assert(R.startCook(s,stove.id,'frangoArroz').ok);ticks(s,90);assert(R.valid(s));
 // Panela cheia é unitária, e inventário lotado não duplica nem perde o item.
 for(let i=0;i<10;i++)s.inventory[i]={item:'pot',n:99};s.equipment.pot+=990;const before=JSON.stringify(s);assert(!R.transferSlot(s,stove.id,'object',stove.inventory.findIndex(p=>p?.item==='pot_frangoArroz_4')).ok);assert.equal(JSON.stringify(s),before);
 assert(!R.accepts(obj(s,'fridge'),'pot'));assert(R.accepts(stove,'frango'));assert(!R.accepts(obj(s,'bin'),'cookingPot'));assert.equal(R.itemLimit('pot_frangoArroz_4'),1);assert(R.valid(s));console.log('Frango, restrições, inventário cheio e panelas sem empilhamento de comida OK');
}
{
 const s=setup(),stove=obj(s,'stove'),prep=obj(s,'prep');R.buyTool(s,'pot');deposit(s,stove,'pot');R.buyTool(s,'spoon');deposit(s,stove,'spoon');giveFood(s,'legumes',8);deposit(s,stove,'legumes');assert(R.startCook(s,stove.id,'sopa').ok);ticks(s,60);withdraw(s,stove,'pot_sopa_4');deposit(s,prep,'pot_sopa_4');R.buyTool(s,'spoon');deposit(s,prep,'spoon');for(let i=0;i<4;i++)R.buyTool(s,'plate');deposit(s,prep,'plate');assert(R.plateFood(s,prep.id,'sopa').ok);
 s.menu={arrozLegumes:false,sopa:true,frangoArroz:false};s.player.x=10;s.player.y=12;s.player.goal=null;s.player.motion=null;s.player.settled=null;s.workers[1].task='waiter';assert(R.toggleOpen(s));assert(R.spawn(s));R.toggleOpen(s);for(let i=0;i<300&&s.customers[0]?.state!=='waiting';i++)ticks(s,1);let c=s.customers[0];R.goObject(s,s.player,s.objects.find(o=>o.id===c.seat));for(let i=0;i<300&&(!R.near(s.player,c,1)||s.player.motion);i++)ticks(s,1);assert(R.interact(s,c.id));for(let i=0;i<1000&&s.open;i++)ticks(s,1);assert(!s.open);assert.equal(s.ledger.sales,1);assert.equal(R.objectCount(prep,'dish_sopa'),3);assert(R.valid(s));console.log('Garçom: retirada física na mesa de preparo, serviço, pagamento e prato sujo OK');
}
{
 const s=setup(),stove=obj(s,'stove'),prep=obj(s,'prep');R.buyTool(s,'spoon');R.buyTool(s,'spoon');stand(s,stove);const index=s.inventory.findIndex(p=>p?.item==='spoon');assert(R.transferSlot(s,stove.id,'player',index,1).ok);assert.equal(R.inventoryCount(s,'spoon'),1);deposit(s,prep,'spoon');assert.equal(R.objectCount(stove,'spoon'),1);assert.equal(R.objectCount(prep,'spoon'),1);assert(R.valid(s));
 let snapshot=JSON.stringify(s);assert(!R.transferSlot(s,prep.id,'object',0,-1).ok);assert.equal(JSON.stringify(s),snapshot);assert(!R.transferSlot(s,prep.id,'object',0,1.5).ok);console.log('Divisão de utensílios entre estações e quantidades inválidas sem perda OK');
}

{
 const s=R.fresh();assert.equal(s.objects.length,0);assert(R.toggleOpen(s));assert(s.open);ticks(s,150);assert.equal(s.customers.length,0);assert(s.ledger.lost>0);assert(R.valid(s));assert(R.toggleOpen(s));ticks(s,1);assert(!s.open);assert.equal(s.period,1);assert(R.toggleOpen(s));assert(R.toggleOpen(s));ticks(s,1);assert.equal(s.day,1);assert.equal(s.reports.length,0);assert(R.valid(s));
 // Cardápio vazio também é escolha do jogador: nenhuma receita inválida é criada.
 s.menu={arrozLegumes:false,sopa:false,frangoArroz:false};assert(R.toggleOpen(s));ticks(s,150);assert(!s.customers.length);assert(R.valid(s));
 const t=R.fresh();assert(R.place(t,'table',4,4).ok);assert(R.place(t,'chair',3,4,1).ok);t.player.x=10;t.player.y=12;assert(R.toggleOpen(t));assert(R.spawn(t));ticks(t,50);assert(t.customers.length>0);assert(!t.objects.some(o=>o.type==='stove'));assert(R.valid(t));
 console.log('Abertura livre: vazio, sem equipamentos/comida/utensílios, cardápio vazio, dois serviços e clientes sem cozinha OK');
}

// Atalho de teste: assentos utilizáveis, recursos nas estações e ciclo real de cozinha.
{
 const s=R.furnishedTest(),stove=obj(s,'stove'),prep=obj(s,'prep');
 assert(R.valid(s));assert.equal(s.cash,R.fresh().cash);assert.equal(s.ledger.investment,0);
 assert.equal(s.objects.filter(o=>o.type==='table').length,3);assert.equal(R.seats(s).length,12);
 for(const table of s.objects.filter(o=>o.type==='table'))assert.equal(R.seats(s).filter(c=>{const [dx,dy]=R.DIRS[c.rot];return R.hit(table,c.x+dx,c.y+dy)}).length,4);
 for(const food of Object.keys(R.FOODS))assert.equal(R.objectCount(stove,food),30);
 assert.equal(R.objectCount(stove,'pot'),3);assert.equal(R.objectCount(prep,'plate'),12);
 assert.equal(R.objectCount(stove,'spoon'),1);assert.equal(R.objectCount(prep,'spoon'),1);
 for(const type of ['stove','fridge','prep','sink','bin','shelf','cold'])assert(obj(s,type));
 stand(s,stove);assert(R.startCook(s,stove.id,'sopa').ok);ticks(s,60);withdraw(s,stove,'pot_sopa_4');deposit(s,prep,'pot_sopa_4');assert(R.plateFood(s,prep.id,'sopa').ok);
 s.menu={arrozLegumes:false,sopa:true,frangoArroz:false};s.player.x=10;s.player.y=12;s.player.settled=null;assert(R.toggleOpen(s));assert(R.spawn(s));
 for(let i=0;i<300&&s.customers[0].state!=='waiting';i++)ticks(s,1);
 const c=s.customers[0];R.goObject(s,s.player,s.objects.find(o=>o.id===c.seat));for(let i=0;i<300&&(!R.near(s.player,c,1)||s.player.motion);i++)ticks(s,1);assert(R.interact(s,c.id));
 stand(s,prep);assert(R.pickupDish(s));assert(s.player.carry);
 stand(s,stove);assert(R.startCook(s,stove.id,'arrozLegumes').ok);
 R.takeObject(s,stove,'arroz',2);s.workers[0].carry={kind:'food',food:'arroz',n:2,to:'storage'};s.workers[0].task='logistics';
 assert(R.purchase(s,'frango',7));s.inv.receiving.legumes=3;s.purchased.legumes+=3;
 assert(R.addInventory(s,'plate',1));s.equipment.plate++;
 R.takeObject(s,prep,'plate',1);s.dirtyTables[c.seat]=1;
 s.day=3;const cash=s.cash,ledger=JSON.stringify(s.ledger),menu=JSON.stringify(s.menu);assert(R.valid(s));
 R.clearTestScene(s);assert(R.valid(s));assert.equal(s.cash,cash);assert.equal(s.day,3);assert.equal(JSON.stringify(s.ledger),ledger);assert.equal(JSON.stringify(s.menu),menu);
 for(const k of ['objects','orders','customers','deliveries','ready'])assert.equal(s[k].length,0);
 assert(s.inventory.every(p=>p===null));assert(R.allActors(s).every(a=>!a.carry&&!a.goal&&!a.motion));assert(!s.open&&!s.closing&&!s.cooking);
 assert.deepEqual(s.equipment,{pot:0,spoon:0,plate:0});assert.deepEqual(s.inv,R.fresh().inv);assert.deepEqual(s.dirtyTables,{});
 ticks(s,120);assert.equal(s.objects.length,0);assert.equal(s.customers.length,0);assert.deepEqual(s.inv,R.fresh().inv);assert(R.valid(JSON.parse(JSON.stringify(s))));
 R.clearTestScene(s);assert(R.valid(s));assert(R.toggleOpen(s));assert(s.open);
 console.log('Cenário mobiliado: 12 assentos, quantidades, cozinha/empratamento reais; limpeza durante serviço/preparo/cargas/entrega, sem reaparecimento e salvamento válido OK');
}

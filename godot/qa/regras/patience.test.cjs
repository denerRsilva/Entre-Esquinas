function testRestaurant(){const s=R.furnishedTest();s.serviceHours[0].start=360;return s;}
const assert=require('node:assert/strict'),R=require('./dist/restaurant-core.js');
let passed=0;const test=(name,fn)=>{fn();console.log('OK '+(++passed)+' — '+name)};
const obj=(s,t)=>s.objects.find(o=>o.type===t);
function ticks(s,seconds,rng=()=>.99){for(let left=seconds;left>1e-8;left-=.1){R.step(s,Math.min(.1,left),rng);assert(R.valid(s),'estado inválido durante simulação');}}
function fixture(rng=()=>.5){const s=testRestaurant();s.player.x=10;s.player.y=12;s.menu={arrozLegumes:false,sopa:true,frangoArroz:false};assert(R.spawn(s,rng));const c=s.customers[0];for(let i=0;i<300&&c.state==='walk';i++)ticks(s,.1);assert.equal(c.state,'waiting');return {s,c};}
function near(s,c,actor=s.player){const p=R.DIRS.map(([dx,dy])=>({room:c.room,x:c.x+dx,y:c.y+dy})).find(p=>!R.blocked(s,p.room,p.x,p.y,actor)&&!R.allActors(s).some(a=>a!==actor&&a.room===p.room&&a.x===p.x&&a.y===p.y));assert(p);Object.assign(actor,p,{goal:null,motion:null,settled:null});}
function stand(s,o,actor=s.player){const p=R.accessPoints(s,o).find(p=>!R.allActors(s).some(a=>a!==actor&&a.room===p.room&&a.x===p.x&&a.y===p.y));assert(p);Object.assign(actor,p,{goal:null,motion:null,settled:null});}
function request(s,c){near(s,c);assert(R.interact(s,c.id));assert.equal(c.experience.phase,'food');}
function makeDishes(s){fixtureDishes(s);}
function giveDish(s,c){const prep=obj(s,'kitchen');stand(s,prep);assert(R.kitchenAction(s,prep.id,'takeDish','dish_sopa').ok);near(s,c);assert(R.interact(s,c.id));}

test('Atendimento rápido, duas etapas isoladas e satisfação positiva após refeição',()=>{
 const {s,c}=fixture();assert.equal(c.experience.elapsed.service,0);ticks(s,1);request(s,c);const first=c.experience.elapsed.service;assert.equal(c.experience.results.service,1-first/c.experience.limits.service);assert.equal(c.experience.elapsed.food,0);ticks(s,1);assert.equal(c.experience.elapsed.service,first);assert(Math.abs(c.experience.elapsed.food-1)<1e-8);
 makeDishes(s);giveDish(s,c);assert.equal(c.experience.phase,null);assert.equal(c.state,'eating');assert(c.experience.satisfaction.score>=85);assert.equal(R.customerIndicator(s,c).emoji,'😊');assert.equal(s.experience.visits.length,0);ticks(s,4.1,()=>0);assert.equal(s.ledger.sales,1);assert.equal(s.experience.visits.length,1);assert.equal(s.experience.events.length,1);assert.equal(s.experience.events[0].type,'praise');assert.equal(s.experience.visits[0].satisfaction.quality,0);
 const elapsed={...c.experience.elapsed};ticks(s,15);assert.deepEqual(c.experience.elapsed,elapsed);assert.equal(s.experience.events.length,1);assert.equal(s.experience.visits.length,1);
});
test('Atendimento quase no limite mantém resultado ruim sem contaminar limite da comida',()=>{
 const {s,c}=fixture(()=>0);ticks(s,39);assert.equal(R.customerIndicator(s,c).emoji,'😠');request(s,c);assert(c.experience.results.service<.03);assert.equal(c.experience.limits.food,60);assert.equal(c.experience.elapsed.food,0);assert.equal(R.customerIndicator(s,c).emoji,'⏳');
});
test('Abandono antes do pedido, sem venda e remoção pela saída existente',()=>{
 const {s,c}=fixture(()=>0);const cash=s.cash;R.step(s,40,()=>0);assert(c.experience.abandoned);assert.equal(c.state,'leave');assert.equal(R.customerIndicator(s,c).emoji,'🤬');assert.equal(s.orders.length,0);assert.equal(s.ledger.sales,0);assert.equal(s.cash,cash);assert.equal(s.experience.events.length,1);assert(!R.interact(s,c.id));ticks(s,30,()=>0);assert(!s.customers.includes(c));assert.equal(s.experience.events.length,1);assert(R.valid(s));
});
test('Abandono após pedido sem estorno de ingredientes usados em preparo',()=>{
 const {s,c}=fixture(()=>0);request(s,c);const stove=obj(s,'stove');stand(s,stove);stageRecipe(s,stove,'sopa');assert(R.startCook(s,stove.id,'sopa').ok);const cash=s.cash,used=s.used.legumes;R.step(s,60,()=>0);assert(c.experience.abandoned);assert.equal(s.orders[0].state,'lost');assert.equal(s.cash,cash);assert.equal(s.used.legumes,used);assert.equal(R.inventoryCount(s,'legumes'),28);assert.equal(s.ledger.sales,0);assert.equal(s.experience.visits[0].outcome,'abandoned');assert(R.valid(s));
});
test('Entrega imediatamente antes do limite encerra o contador e permite pagamento',()=>{
 const {s,c}=fixture(()=>0);makeDishes(s);request(s,c);R.step(s,59.999,()=>.99);giveDish(s,c);const waited=c.experience.elapsed.food;ticks(s,4.1);assert(!c.experience.abandoned);assert.equal(c.experience.elapsed.food,waited);assert.equal(s.ledger.sales,1);assert.equal(s.experience.visits.length,1);
});
test('Perfis e limites individuais, sorteio de faixas e distribuição configurável',()=>{
 const {s}=fixture(()=>0);assert(R.spawn(s,()=>.5));const b=s.customers[1];ticks(s,3);assert(R.spawn(s,()=>.999));const c=s.customers[2];assert.equal(s.customers[0].experience.profile,'impatient');assert.equal(b.experience.profile,'normal');assert.equal(c.experience.profile,'patient');assert.notEqual(s.customers[0].experience.elapsed,b.experience.elapsed);assert(c.experience.limits.food>=150&&c.experience.limits.food<=210);
 const weights=Object.fromEntries(Object.entries(R.CUSTOMER_CONFIG.profiles).map(([k,p])=>[k,p.weight]));try{R.CUSTOMER_CONFIG.profiles.impatient.weight=0;R.CUSTOMER_CONFIG.profiles.normal.weight=0;assert.equal(R.newExperience(()=>0).profile,'patient');}finally{for(const [k,v]of Object.entries(weights))R.CUSTOMER_CONFIG.profiles[k].weight=v;}
 const low=R.newExperience(()=>0),high=R.newExperience(()=>1);assert.equal(low.limits.service,40);assert(high.limits.service<=120&&high.limits.service>=119);const before=JSON.stringify(s);R.step(s,0);assert.equal(JSON.stringify(s),before);
});
test('Fechamento aguarda abandono/saída dos pedidos pendentes sem criar clientes',()=>{
 const {s,c}=fixture(()=>0);request(s,c);assert(R.toggleOpen(s));assert(R.toggleOpen(s));assert(s.closing);R.step(s,60,()=>0);assert(c.experience.abandoned);assert(s.closing);ticks(s,40);assert(!s.open&&!s.closing);assert.equal(s.period,0);assert.equal(s.customers.length,0);assert.equal(s.ledger.sales,0);assert.equal(s.experience.visits.length,1);
});
test('Empate lógico: desistência precede entrega do garçom e preserva prato em trânsito',()=>{
 const {s,c}=fixture(()=>0);makeDishes(s);request(s,c);const w=s.workers[1];stand(s,obj(s,'kitchen'),w);assert(R.pickupDish(s,w));w.task='waiter';near(s,c,w);c.experience.elapsed.food=c.experience.limits.food-.1;R.step(s,.1,()=>0);assert(c.experience.abandoned);assert.equal(s.ledger.sales,0);assert(R.canceledCarry(s,w));assert.equal(s.orders[0].state,'lost');assert.equal(s.experience.events.length,1);assert(R.valid(s));ticks(s,30);assert.equal(w.carry,null);assert.equal(R.objectCount(obj(s,'kitchen'),'dish_sopa'),4);assert.equal(s.experience.events.length,1);assert.equal(s.ledger.sales,0);
});
test('Entrega manual no limite é recusada, sem consumir prato ou concluir venda',()=>{
 const {s,c}=fixture(()=>0);makeDishes(s);request(s,c);stand(s,obj(s,'kitchen'));assert(R.pickupDish(s));near(s,c);c.experience.elapsed.food=c.experience.limits.food;assert(!R.interact(s,c.id));assert(R.canceledCarry(s,s.player));assert(!R.serve(s,s.player,c));assert.equal(s.ledger.sales,0);stand(s,obj(s,'kitchen'));assert(R.pickupDish(s));assert.equal(s.player.carry,null);assert.equal(R.objectCount(obj(s,'kitchen'),'dish_sopa'),4);assert(R.valid(s));
});
test('Bancada cheia não destrói prato cancelado nem bloqueia fechamento do serviço',()=>{
 const {s,c}=fixture(()=>0);makeDishes(s);request(s,c);stand(s,obj(s,'kitchen'));assert(R.pickupDish(s));const prep=obj(s,'kitchen'); // Teste de capacidade com louça comprada adicional.
 const previousPlates=R.objectCount(prep,'plate');R.takeObject(s,prep,'plate',previousPlates);assert(R.addInventory(s,'plate',previousPlates));
 // Ocupa os doze lugares de retirada com pratos de outra receita.
 for(const p of R.stationSlots(prep).filter(Boolean)){const {item,n}=p;assert.equal(R.takeObject(s,prep,item,n),n);assert(R.addInventory(s,item,n));}
 assert.equal(R.putObject(s,prep,'dish_arrozLegumes',12),12);s.equipment.plate+=12;s.meals.made.arrozLegumes+=12;
 assert(R.valid(s));assert(R.toggleOpen(s));assert(R.toggleOpen(s));R.step(s,60,()=>.99);assert(R.canceledCarry(s,s.player));stand(s,prep);assert(!R.pickupDish(s));assert(R.canceledCarry(s,s.player));ticks(s,30);assert(!s.closing&&!s.open);assert(R.valid(s));
});
test('Limiares visuais e pesos redistribuídos, classes e duração configuráveis',()=>{
 const {s,c}=fixture(()=>0),p=c.experience;
 for(const [elapsed,emoji]of [[19.9,'⏳'],[20,'❗'],[31.9,'❗'],[32,'😠'],[39.9,'😠']]){p.elapsed.service=elapsed;assert.equal(R.customerIndicator(s,c).emoji,emoji);}
 p.results={service:1,food:0};assert.equal(R.satisfactionFor(p).score,50);p.results={service:1,food:1};assert.equal(R.satisfactionFor(p).classification,'verySatisfied');p.results={service:.7,food:.7};assert.equal(R.satisfactionFor(p).classification,'satisfied');p.results={service:.2,food:.2};assert.equal(R.satisfactionFor(p).classification,'unsatisfied');
 p.elapsed.service=0;makeDishes(s);request(s,c);giveDish(s,c);assert.equal(R.customerIndicator(s,c).emoji,'😊');s.time=p.indicatorUntil;assert.equal(R.customerIndicator(s,c),null);
});
test('Eventos de reputação: cinco probabilidades nos dois lados do limiar, sem duplicação',()=>{
 const config=R.CUSTOMER_CONFIG.reviews;
 for(const [classification,rule]of Object.entries(config))for(const shouldHappen of [true,false]){
  const {s,c}=fixture(()=>0);
  if(classification==='abandoned'){R.step(s,40,()=>shouldHappen?rule.probability-.001:rule.probability);ticks(s,20);}
  else {makeDishes(s);request(s,c);giveDish(s,c);c.experience.satisfaction={score:50,classification,quality:null};R.step(s,4.01,()=>shouldHappen?rule.probability-.001:rule.probability);ticks(s,20);}
  assert.equal(s.experience.events.length,shouldHappen?1:0,classification);if(shouldHappen)assert.equal(s.experience.events[0].type,rule.type);assert.equal(s.experience.visits.length,1);ticks(s,10);assert.equal(s.experience.events.length,shouldHappen?1:0);
 }
});
test('Salvar/carregar preserva contadores e avaliações; migração da 0.10.x sem sobrescrever',()=>{
 const {s,c}=fixture();request(s,c);ticks(s,2);const serialized=JSON.stringify(s),copy=R.migrateSave(JSON.parse(serialized));assert(copy);assert.equal(JSON.stringify(copy),serialized);assert.notEqual(copy.customers[0].experience,c.experience);
 const legacy=JSON.parse(serialized);legacy.objects=legacy.objects.filter(o=>o.type!=='prep');legacy.version=4;delete legacy.experience;delete legacy.customers[0].experience;const before=JSON.stringify(legacy),migrated=R.migrateSave(legacy,()=>0);assert(migrated);assert.equal(JSON.stringify(legacy),before);assert.equal(migrated.customers[0].experience.elapsed.food,0);assert.equal(migrated.orders.length,1);assert.deepEqual(migrated.inventory,s.inventory);
 const bad=JSON.parse(serialized);bad.customers[0].experience.elapsed.food=-1;assert(!R.migrateSave(bad));assert(!R.valid(bad));const duplicate=JSON.parse(serialized);duplicate.customers.push({...duplicate.customers[0]});assert(!R.valid(duplicate));
 R.step(copy,copy.customers[0].experience.limits.food,()=>0);assert(R.valid(copy));const reviewed=R.migrateSave(copy);assert(reviewed);ticks(reviewed,30,()=>0);assert.equal(reviewed.experience.events.length,1);assert.equal(reviewed.experience.visits.length,1);
});
test('Prato cancelado na mão pode atender outro pedido compatível, sem duplicação',()=>{
 const {s,c}=fixture(()=>0);makeDishes(s);request(s,c);stand(s,obj(s,'kitchen'));assert(R.pickupDish(s));R.step(s,60,()=>.99);assert(R.canceledCarry(s,s.player));ticks(s,20);s.player.x=10;s.player.y=12;s.player.settled=null;assert(R.spawn(s,()=>0));const next=s.customers[0];for(let i=0;i<300&&next.state==='walk';i++)ticks(s,.1);request(s,next);near(s,next);assert(R.interact(s,next.id));ticks(s,4.1);assert.equal(s.ledger.sales,1);assert.equal(s.meals.eaten.sopa,1);assert.equal(s.orders.filter(o=>o.state==='lost').length,1);assert(R.valid(s));
});
test('Migração de clientes comendo não inventa notas nem avaliações retroativas',()=>{
 const {s,c}=fixture(()=>0);makeDishes(s);request(s,c);giveDish(s,c);const legacy=JSON.parse(JSON.stringify(s));legacy.objects=legacy.objects.filter(o=>o.type!=='prep');legacy.version=4;delete legacy.experience;for(const customer of legacy.customers)delete customer.experience;
 const migrated=R.migrateSave(legacy,()=>0);assert(migrated);ticks(migrated,20,()=>0);assert.equal(migrated.ledger.sales,1);assert.equal(migrated.experience.events.length,0);assert.equal(migrated.experience.visits.length,0);
 const {s:other,c:otherCustomer}=fixture(()=>0);R.step(other,40,()=>0);const duplicate=JSON.parse(JSON.stringify(other));duplicate.experience.events.push({...duplicate.experience.events[0]});assert(!R.valid(duplicate));duplicate.experience.events.pop();duplicate.experience.visits.push({...duplicate.experience.visits[0]});assert(!R.valid(duplicate));
});
console.log(passed+' cenários do sistema de paciência e satisfação passaram.');


function stageRecipe(s,stove,recipe){
 for(const [raw,n]of Object.entries(R.RECIPES[recipe].foods))for(let j=0;j<n;j++){
  const i=s.inventory.findIndex(p=>p?.item===raw),p=s.inventory[i];assert(p);
  if(raw!=='arroz'){R.removeInventory(s,i,1);assert(R.addInventory(s,raw+'_cut',1,p.quality||0));}
  s.selectedSlot=s.inventory.findIndex(p=>p?.item===(raw==='arroz'?raw:raw+'_cut'));
  assert(R.physicalAction(s,stove.id,'add').ok);
 }
}
function fixtureDishes(s){
 const o=s.objects.find(o=>o.type==='kitchen');let left=8;
 for(let i=0;i<10&&left;i++)if(s.inventory[i]?.item==='legumes'){const n=Math.min(left,s.inventory[i].n);R.removeInventory(s,i,n);left-=n;}
 assert.equal(left,0);s.used.legumes+=8;s.meals.made.sopa+=4;o.plates-=4;assert.equal(R.putObject(s,o,'dish_sopa',4),4);assert(R.valid(s));
}

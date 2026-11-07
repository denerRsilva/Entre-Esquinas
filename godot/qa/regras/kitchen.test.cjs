function testRestaurant(){const s=R.furnishedTest();s.serviceHours[0].start=360;return s;}
const assert=require('node:assert/strict'),R=require('./dist/restaurant-core.js'),Old=require('./legacy/restaurant-core-0.12.0.cjs');
let passed=0;const test=(name,fn)=>{fn();console.log('OK '+(++passed)+' — '+name)};
const obj=(s,t)=>s.objects.find(o=>o.type===t);
function stand(s,o){const p=R.accessPoints(s,o).find(p=>!R.allActors(s).some(a=>a!==s.player&&a.room===p.room&&a.x===p.x&&a.y===p.y));assert(p);Object.assign(s.player,p,{motion:null,goal:null,settled:null});}
function ticks(s,n){for(let t=0;t<n-1e-8;t+=.1){R.step(s,Math.min(.1,n-t),()=>.99);assert(R.valid(s),'estado inválido em '+t);}}
function cook(s,recipe='sopa'){const stove=obj(s,'stove');stand(s,stove);if(!stove.pan)assert(R.kitchenAction(s,stove.id,'installPan').ok);assert(R.startCook(s,stove.id,recipe).ok);ticks(s,R.RECIPES[recipe].time);assert(R.kitchenAction(s,stove.id,'takePan').ok);}
test('Sem inventário genérico; instalação e retirada exclusivas',()=>{
 const s=testRestaurant(),stove=obj(s,'stove'),prep=obj(s,'prep');assert(!('inventory' in stove));assert(!('inventory' in prep));assert(R.valid(s));stand(s,stove);assert(!R.kitchenAction(s,stove.id,'installPan').ok);assert(R.kitchenAction(s,stove.id,'takePan').ok);assert(R.kitchenAction(s,stove.id,'installPan').ok);assert.equal(stove.pan,'pot');assert(!R.accepts(stove,'arroz'));assert(!R.accepts(prep,'pot_sopa_4'));assert(!R.transferSlot(s,stove.id,'player',0).ok);assert(R.valid(s));
});
test('Ingredientes da mochila e confirmação sem consumo duplicado',()=>{
 const s=testRestaurant(),o=obj(s,'stove');stand(s,o);const n=R.inventoryCount(s,'legumes');assert(R.startCook(s,o.id,'sopa').ok);assert.equal(R.inventoryCount(s,'legumes'),n-8);assert(!R.startCook(s,o.id,'sopa').ok);assert.equal(s.used.legumes,8);assert(!R.kitchenAction(s,o.id,'takePan').ok);assert(R.valid(s));
 const t=testRestaurant(),st=obj(t,'stove');R.removeInventory(t,t.inventory.findIndex(p=>p?.item==='legumes'),30);R.putObject(t,obj(t,'fridge'),'legumes',30);stand(t,st);const before=JSON.stringify(t.inventory);assert(!R.startCook(t,st.id,'sopa').ok);assert.equal(JSON.stringify(t.inventory),before);assert(R.valid(t));
});
test('Cozimento longe do fogão e retirada da panela cheia',()=>{
 const s=testRestaurant(),o=obj(s,'stove');stand(s,o);assert(R.startCook(s,o.id,'sopa').ok);Object.assign(s.player,{x:7,y:13,settled:null});ticks(s,5);assert.equal(o.pan,'pot_sopa_4');assert(!s.cooking);assert(!R.kitchenAction(s,o.id,'takePan').ok);stand(s,o);assert(R.kitchenAction(s,o.id,'takePan').ok);assert.equal(o.pan,null);assert.equal(R.inventoryCount(s,'pot_sopa_4'),1);assert(!R.kitchenAction(s,o.id,'takePan').ok);assert(R.valid(s));
});
test('Mochila cheia mantém panela pronta sem perda',()=>{
 const s=testRestaurant(),o=obj(s,'stove');stand(s,o);assert(R.startCook(s,o.id,'sopa').ok);ticks(s,5);for(let i=0;i<10;i++)if(!s.inventory[i]){s.inventory[i]={item:'pot',n:99};s.equipment.pot+=99;}const before=JSON.stringify(s.inventory);assert(!R.kitchenAction(s,o.id,'takePan').ok);assert.equal(o.pan,'pot_sopa_4');assert.equal(JSON.stringify(s.inventory),before);assert(R.valid(s));
});
test('Pratos e talher instalados por ação rápida',()=>{
 const s=testRestaurant(),o=obj(s,'prep');stand(s,o);assert(R.kitchenAction(s,o.id,'takePlates').ok);assert(R.kitchenAction(s,o.id,'takeUtensil').ok);assert.equal(o.plates,0);assert(!o.utensil);assert(R.kitchenAction(s,o.id,'installPlates').ok);assert.equal(o.plates,12);assert(R.kitchenAction(s,o.id,'installUtensil').ok);assert(!R.kitchenAction(s,o.id,'installUtensil').ok);assert(R.valid(s));
});
test('Empratamento tem duração pausa por distância e devolve panela',()=>{
 const s=testRestaurant(),o=obj(s,'prep');cook(s);stand(s,o);assert(R.plateFood(s,o.id,'sopa').ok);assert(!R.plateFood(s,o.id,'sopa').ok);ticks(s,.5);const left=s.plating.left;Object.assign(s.player,{x:7,y:13,settled:null});ticks(s,1);assert.equal(s.plating.left,left);assert.equal(o.plates,12);stand(s,o);ticks(s,2);assert(!s.plating);assert.equal(o.dishes.dish_sopa,4);assert.equal(o.plates,8);assert.equal(R.inventoryCount(s,'pot'),3);assert(o.utensil);assert(R.valid(s));
});
test('Empratamento parcial conserva sobras na mochila',()=>{
 const s=testRestaurant(),o=obj(s,'prep');cook(s);stand(s,o);R.takeObject(s,o,'plate',10);R.addInventory(s,'plate',10);assert(R.plateFood(s,o.id,'sopa').ok);ticks(s,2);assert.equal(o.dishes.dish_sopa,2);assert.equal(R.inventoryCount(s,'pot_sopa_2'),1);assert(!R.plateFood(s,o.id,'sopa').ok);assert(R.kitchenAction(s,o.id,'installPlates').ok);assert(R.plateFood(s,o.id,'sopa').ok);ticks(s,2);assert.equal(o.dishes.dish_sopa,4);assert.equal(R.inventoryCount(s,'pot'),3);assert(R.valid(s));
});
test('Área cheia não consome entradas e permite retirada sem pedido',()=>{
 const s=testRestaurant(),o=obj(s,'prep');cook(s);stand(s,o);R.putObject(s,o,'dish_arrozLegumes',12);s.equipment.plate+=12;s.meals.made.arrozLegumes+=12;const before=JSON.stringify(s.inventory);assert(!R.plateFood(s,o.id,'sopa').ok);assert.equal(JSON.stringify(s.inventory),before);assert.equal(o.plates,12);assert(R.kitchenAction(s,o.id,'takeDish','dish_arrozLegumes').ok);assert(R.plateFood(s,o.id,'sopa').ok);ticks(s,2);assert.equal(R.readyCount(o),12);assert.equal(R.inventoryCount(s,'pot_sopa_3'),1);assert(R.valid(s));
});
test('Cancelar não consome itens; panela em uso bloqueada; salvar durante ação',()=>{
 const s=testRestaurant(),o=obj(s,'prep');cook(s);stand(s,o);assert(R.plateFood(s,o.id,'sopa').ok);ticks(s,.5);const j=s.plating;stand(s,obj(s,'sink'));assert(!R.transferSlot(s,obj(s,'sink').id,'player',j.slot).ok);assert(R.migrateSave(s));stand(s,o);assert(R.cancelPlating(s).ok);assert.equal(R.inventoryCount(s,'pot_sopa_4'),1);assert.equal(o.plates,12);assert(R.plateFood(s,o.id,'sopa').ok);ticks(s,2);assert(R.valid(s));
});
test('Migração real 0.12.0 preserva calendário itens e arquivo original',()=>{
 const old=Old.furnishedTest();old.clock.minute=780;old.day=30;const before=JSON.stringify(old),s=R.migrateSave(old);assert(s);assert.equal(JSON.stringify(old),before);assert.equal(s.clock.minute,780);assert.equal(s.day,30);assert.equal(R.inventoryCount(s,'legumes'),30);assert.equal(obj(s,'stove').pan,'pot');assert.equal(obj(s,'prep').plates,12);assert(R.valid(s));assert.deepEqual(R.migrateSave(s).inventory,s.inventory);
});
test('Migração com mochila cheia e cozimento ativo preserva excedentes',()=>{
 const old=Old.furnishedTest(),o=obj(old,'stove');stand(old,o);assert(Old.startCook(old,o.id,'sopa').ok);for(let i=0;i<10;i++){old.inventory[i]={item:'plate',n:99};old.equipment.plate+=99;}const s=R.migrateSave(old);assert(s);assert(s.recovery.length>0);assert.equal(obj(s,'stove').pan,'cookingPot');ticks(s,5);assert.equal(obj(s,'stove').pan,'pot_sopa_4');assert(!R.recoverItems(s).ok);R.removeInventory(s,0,99);s.equipment.plate-=99;assert(R.recoverItems(s).ok);assert(R.valid(s));
});
test('Três receitas e limpeza de cenário durante empratamento',()=>{
 for(const recipe of Object.keys(R.RECIPES)){const s=testRestaurant(),prep=obj(s,'prep');cook(s,recipe);stand(s,prep);assert(R.plateFood(s,prep.id,recipe).ok);ticks(s,2);assert(R.kitchenAction(s,prep.id,'takeDish','dish_'+recipe).ok);assert(R.valid(s));}
 const s=testRestaurant();cook(s);stand(s,obj(s,'prep'));R.plateFood(s,obj(s,'prep').id,'sopa');R.clearTestScene(s);assert(!s.plating);assert(R.valid(s));assert.equal(R.migrateSave({version:7}),null);
});
test('Garçom retira prato da bancada serve recebe pagamento e conserva louça',()=>{
 const s=testRestaurant(),prep=obj(s,'prep');cook(s);stand(s,prep);assert(R.plateFood(s,prep.id,'sopa').ok);ticks(s,2);
 s.menu={sopa:true,arrozLegumes:false,frangoArroz:false};s.workers[1].task='waiter';Object.assign(s.player,{x:10,y:12,settled:null,goal:null});assert(R.toggleOpen(s));assert(R.spawn(s,()=>.5));assert(R.toggleOpen(s));
 for(let i=0;i<300&&s.customers[0]?.state==='walk';i++)ticks(s,.1);
 const c=s.customers[0],chair=s.objects.find(o=>o.id===c.seat),[dx,dy]=R.DIRS[chair.rot],table=s.objects.find(o=>o.type==='table'&&R.hit(o,chair.x+dx,chair.y+dy));
 const point=R.DIRS.map(([dx,dy])=>({room:c.room,x:c.x+dx,y:c.y+dy})).find(p=>!R.blocked(s,p.room,p.x,p.y)&&!R.allActors(s).some(a=>a!==s.player&&a.room===p.room&&a.x===p.x&&a.y===p.y));assert(point);Object.assign(s.player,point,{motion:null,goal:null,settled:null});assert(R.interact(s,c.id));Object.assign(s.player,{x:10,y:12,motion:null,goal:null,settled:null});
 ticks(s,45);assert.equal(s.ledger.sales,1);assert.equal(R.objectCount(prep,'dish_sopa'),3);stand(s,table);assert(R.collectDirty(s,table.id).ok);const sink=obj(s,'sink');stand(s,sink);assert(!R.transferSlot(s,sink.id,'player',s.inventory.findIndex(p=>p?.item==='dirtyPlate')).ok);assert(R.washPlates(s,sink.id).ok);assert(R.valid(s));
});
test('Pia e lixo sem armazenamento; lavar usa e devolve na mochila',()=>{
 const s=testRestaurant(),sink=obj(s,'sink'),bin=obj(s,'bin');
 for(const o of [sink,bin]){assert(!('inventory' in o));assert.equal(R.putObject(s,o,'pot',1),0);stand(s,o);assert(!R.transferSlot(s,o.id,'player',0).ok);}
 R.addInventory(s,'dirtyPlate',3);s.equipment.plate+=3;stand(s,sink);
 assert(R.washPlates(s,sink.id).ok);assert.equal(R.inventoryCount(s,'dirtyPlate'),0);assert.equal(R.inventoryCount(s,'plate'),3);assert(!R.washPlates(s,sink.id).ok);assert(R.valid(s));
});
test('Descarte de panela e prato conserva recipientes e bloqueia mochila cheia',()=>{
 for(const type of ['sink','bin']){
  const s=testRestaurant(),o=obj(s,type);cook(s);stand(s,o);
  assert(R.discardFood(s,o.id,s.inventory.findIndex(p=>p?.item==='pot_sopa_4')).ok);
  assert.equal(R.inventoryCount(s,'pot'),3);assert.equal(s.meals.wasted.sopa,4);assert(R.valid(s));
 }
 const s=testRestaurant(),bin=obj(s,'bin');R.addInventory(s,'dish_sopa',2);s.meals.made.sopa+=2;s.equipment.plate+=2;
 for(let i=0;i<10;i++)if(!s.inventory[i]){s.inventory[i]={item:'pot',n:99};s.equipment.pot+=99;}
 stand(s,bin);const index=s.inventory.findIndex(p=>p?.item==='dish_sopa'),before=JSON.stringify(s);
 assert(!R.discardFood(s,bin.id,index).ok);assert.equal(JSON.stringify({...s,message:''}),JSON.stringify({...JSON.parse(before),message:''}));
 const free=s.inventory.findIndex(p=>p?.item==='pot');s.equipment.pot-=s.inventory[free].n;s.inventory[free]=null;
 assert(R.discardFood(s,bin.id,index).ok);assert.equal(R.inventoryCount(s,'dirtyPlate'),1);assert.equal(s.meals.wasted.sopa,1);assert(R.valid(s));
});
test('Migração de pia e lixo preserva itens inclusive sem espaço e não altera origem',()=>{
 const old=testRestaurant();old.version=7;
 const sink=obj(old,'sink'),bin=obj(old,'bin');sink.inventory=Array(10).fill(null);bin.inventory=Array(10).fill(null);
 const i=old.inventory.findIndex(p=>p?.item==='pot');sink.inventory[0]=old.inventory[i];old.inventory[i]=null;
 bin.inventory[0]={item:'dirtyPlate',n:2};old.equipment.plate+=2;
 for(let j=0;j<10;j++)if(!old.inventory[j]){old.inventory[j]={item:'pot',n:99};old.equipment.pot+=99;}
 const before=JSON.stringify(old),s=R.migrateSave(old);assert(s);assert.equal(JSON.stringify(old),before);
 assert(!('inventory' in obj(s,'sink')));assert(!('inventory' in obj(s,'bin')));assert(s.recovery.some(p=>p.item==='dirtyPlate'));assert(R.valid(s));assert(R.migrateSave(s));
});
console.log(passed+' cenários de cozinha passaram.');

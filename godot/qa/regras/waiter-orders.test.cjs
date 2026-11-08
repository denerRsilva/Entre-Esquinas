const assert=require('node:assert/strict'),R=require('./dist/restaurant-core.js');
function tick(s,seconds){for(let i=0;i<seconds*10;i++){R.step(s,.1,()=>.5);assert(R.valid(s));}}
function stand(s,o){Object.assign(s.player,R.accessPoints(s,o).find(p=>!R.allActors(s).some(a=>a!==s.player&&a.room===p.room&&a.x===p.x&&a.y===p.y)),{goal:null,motion:null,settled:null});}
const s=R.furnishedTest(),stove=s.objects.find(o=>o.type==='stove'),prep=s.objects.find(o=>o.type==='kitchen');
fixtureDishes(s);
Object.assign(s.player,{x:10,y:12,goal:null,motion:null,settled:null});s.menu={sopa:true,arrozLegumes:false,frangoArroz:false};assert(R.spawn(s,()=>.5));const c=s.customers[0];s.workers[1].task='waiter';
for(let i=0;i<400&&c.state!=='ordered';i++)tick(s,.1);assert.equal(c.state,'ordered');assert.equal(s.orders.length,1);assert.equal(c.experience.phase,'food');const orderId=c.order;assert(!R.takeOrder(s,s.workers[1],c));assert.equal(s.orders.length,1);
for(let i=0;i<500&&s.ledger.sales===0;i++)tick(s,.1);assert.equal(s.ledger.sales,1);assert.equal(s.orders.find(o=>o.id===orderId).state,'paid');assert.equal(R.objectCount(prep,'dish_sopa'),3);assert(R.valid(s));
// Changing roles leaves no autonomous order-taking behind.
const t=R.furnishedTest();Object.assign(t.player,{x:10,y:12});assert(R.spawn(t,()=>.5));tick(t,10);assert.equal(t.customers[0].state,'waiting');assert.equal(t.orders.length,0);
// Two employees acting as waiters must never duplicate an order.
for(const w of t.workers)w.task='waiter';for(let i=0;i<250&&t.orders.length===0;i++)tick(t,.1);assert.equal(t.orders.length,1);tick(t,2);assert.equal(t.orders.length,1);
// Expired customer is rejected, even when a waiter is already adjacent.
const u=R.furnishedTest();Object.assign(u.player,{x:10,y:12});R.spawn(u,()=>.5);tick(u,10);const guest=u.customers[0],waiter=u.workers[1];const point=R.DIRS.map(([dx,dy])=>({room:guest.room,x:guest.x+dx,y:guest.y+dy})).find(p=>!R.blocked(u,p.room,p.x,p.y,waiter));Object.assign(waiter,point,{motion:null,goal:null,settled:null});guest.experience.elapsed.service=guest.experience.limits.service;assert(!R.takeOrder(u,waiter,guest));assert.equal(u.orders.length,0);assert(guest.experience.abandoned);
console.log('Garçom: anota à mesa, serve e recebe pagamento, evita duplicação, respeita função e paciência.');


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

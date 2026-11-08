const assert=require('node:assert/strict');
const R=require('../simulacao/restaurant-core.js');
function near(s,o){const p=R.closestAccess(s,s.player,o);assert(p);Object.assign(s.player,{room:o.room,x:p.x,y:p.y,motion:null,goal:null,settled:null});}
function action(s,o,a){near(s,o);const r=R.physicalAction(s,o.id,a);assert(r.ok,r.message);assert(R.valid(s),'valid after '+a);return r;}
function step(s,n){for(let i=0;i<n*20;i++)R.step(s,.05);assert(R.valid(s),'valid after time');}
function cut(s,p,food){s.selectedSlot=s.inventory.findIndex(p=>p?.item===food);action(s,p,'chop');step(s,2.1);}
let s=R.furnishedTest(),p=s.objects.find(o=>o.type==='prep'),k=s.objects.find(o=>o.type==='kitchen'),f=s.objects.find(o=>o.type==='stove');
assert(R.valid(s));cut(s,p,'legumes');
s.selectedSlot=s.inventory.findIndex(p=>p?.item==='legumes_cut');action(s,f,'add');
assert.equal(R.recognizedRecipe(f),null);
action(s,f,'removeIngredient');action(s,f,'add');
s.selectedSlot=s.inventory.findIndex(p=>p?.item==='arroz');action(s,f,'add');assert.equal(R.recognizedRecipe(f),'arrozLegumes');
assert(!R.physicalAction(s,f.id,'add').ok);action(s,f,'cook');assert(!R.physicalAction(s,f.id,'cook').ok);step(s,6.1);
assert.equal(f.pan,'pot_arrozLegumes_1');action(s,f,'takePan');assert.equal(s.player.hand.item,'pot_arrozLegumes_1');assert.equal(f.pan,null);
let saved=JSON.stringify(s);s=R.migrateSave(JSON.parse(saved));assert(s);assert.equal(s.player.hand.item,'pot_arrozLegumes_1');
k=s.objects.find(o=>o.type==='kitchen');p=s.objects.find(o=>o.type==='prep');f=s.objects.find(o=>o.type==='stove');
action(s,k,'support');action(s,k,'plate');step(s,2.1);assert.equal(k.support.item,'pot');assert.equal(R.readyCount(k),1);
action(s,k,'takeDish');assert.equal(s.player.hand.item,'dish_arrozLegumes');assert(!R.physicalAction(s,k.id,'takePan').ok);action(s,k,'putDish');action(s,k,'takePan');action(s,f,'installPan');
// Manual tasks cancel atomically; a save can resume cutting.
s.selectedSlot=s.inventory.findIndex(p=>p?.item==='frango');action(s,p,'chop');step(s,.5);assert(R.migrateSave(s));action(s,p,'cancelCut');assert.equal(R.inventoryCount(s,'frango_cut'),0);
// Full pack must not destroy the input or create output.
const full=R.furnishedTest(),fp=full.objects.find(o=>o.type==='prep');for(let i=0;i<5;i++)full.inventory[i]={item:'legumes',n:99};near(full,fp);full.selectedSlot=0;assert(!R.physicalAction(full,fp.id,'chop').ok);assert.equal(full.inventory[0].n,99);
// Heating stops once carried. Preserve remaining legacy portions, plate one at a time.
let t=R.furnishedTest(),tf=t.objects.find(o=>o.type==='stove'),tk=t.objects.find(o=>o.type==='kitchen');tf.pan='pot_sopa_4';tf.readyBatch={recipe:'sopa',quality:3,doneAt:0};t.meals.made.sopa=4;
action(t,tf,'takePan');step(t,30);assert.equal(t.player.hand.quality,3);action(t,tk,'support');action(t,tk,'plate');step(t,2.1);assert.equal(tk.support.item,'pot_sopa_3');assert.equal(R.readyCount(tk),1);
// A pre-change save remains untouched and its former plating table is retained.
const prev=require('./fixtures/cozinha-v9.json'),raw=JSON.stringify(prev);const migrated=R.migrateSave(prev);assert(migrated);assert.equal(JSON.stringify(prev),raw);assert(migrated.objects.some(o=>o.type==='kitchen'));assert(R.valid(migrated));
// Heat boundaries, high quality, burn discard and input quality preservation.
for(const [time,stage] of [[0,'ready'],[8,'over'],[20,'danger'],[25,'burned']]){
 const h=R.furnishedTest(),st=h.objects.find(o=>o.type==='stove');
 st.pan='pot_sopa_1';st.readyBatch={recipe:'sopa',quality:3,doneAt:0};h.meals.made.sopa=1;
 if(time)step(h,time);assert.equal(R.heatState(h,st).stage,stage);
 action(h,st,'takePan');assert.equal(!!h.player.hand.burned,stage==='burned');
 if(stage==='burned'){
  const kt=h.objects.find(o=>o.type==='kitchen');action(h,kt,'support');near(h,kt);assert(!R.physicalAction(h,kt.id,'plate').ok);
  action(h,kt,'takePan');action(h,h.objects.find(o=>o.type==='bin'),'discardHand');assert.equal(h.player.hand.item,'pot');assert.equal(h.meals.wasted.sopa,1);
 }
}
const high=R.furnishedTest(),hp=high.objects.find(o=>o.type==='prep');high.inventory.find(p=>p?.item==='legumes').quality=3;cut(high,hp,'legumes');assert.equal(high.inventory.find(p=>p?.item==='legumes_cut').quality,3);
// Removal/movement cannot erase a pan supported on the new table.
const safe=R.migrateSave(t);assert(safe);const sk=safe.objects.find(o=>o.type==='kitchen');assert(!R.remove(safe,sk.id).ok);
const malformed=JSON.parse(JSON.stringify(safe));malformed.player.hand={item:'pot',n:2};assert.equal(R.migrateSave(malformed),null);
console.log('PASSOU: fluxo físico, conservação, cancelamento, save, legado, mãos ocupadas e porção individual');

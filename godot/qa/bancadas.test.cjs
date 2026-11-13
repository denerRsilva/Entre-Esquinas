const assert=require('node:assert/strict'),R=require('../simulacao/restaurant-core');
for(const type of ['counterH','counterV','counterCorner'])for(let rot=0;rot<4;rot++){
 const s=R.furnishedTest(true,true),cash=s.cash;
 assert(!R.place(s,type,4,6,rot).ok,'Parede bloqueia compra');assert.equal(s.cash,cash);
 const placed=R.place(s,type,16,11,rot);assert(placed.ok,type);
 assert.equal(s.cash,cash-35);assert.equal(placed.object.rot,rot);
 assert(!R.place(s,type,16,11).ok,'Colisão impede sobreposição');
 const copy=R.migrateSave(JSON.parse(JSON.stringify(s)));assert(copy);assert.deepEqual(copy.objects,s.objects);
 assert(R.place(s,type,17,11,rot,placed.object.id).ok);assert.equal(s.cash,cash-35);
 assert(R.remove(s,placed.object.id).ok);assert.equal(s.cash,cash);assert(R.valid(s));
}
console.log('PASSOU: bancadas, rotações, colisões, compra, mudança, remoção e save.');

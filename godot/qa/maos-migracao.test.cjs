const assert=require('node:assert/strict'),R=require('../simulacao/restaurant-core');
for(const file of ['cozinha-v9.json','cozinha-v11.json']){
 const old=require('./fixtures/'+file),before=JSON.stringify(old),s=R.migrateSave(old);assert(s,file);assert.equal(JSON.stringify(old),before);assert.equal(s.version,12);assert.equal(s.inventory.length,0);assert.equal(s.selectedSlot,0);assert(R.valid(s));assert(R.foodConserved(s));assert(R.equipmentConserved(s));assert(R.migrateSave(s));assert.equal(R.objectCount(s.objects.find(o=>o.type==='fridge'),'arroz'),30);
}
const full=structuredClone(require('./fixtures/cozinha-v11.json'));
for(const o of full.objects.filter(o=>o.inventory))o.inventory=Array.from({length:10},()=>({item:o.type==='shelf'?'arroz':'frango',n:99}));
full.purchased.arroz=1020;full.purchased.frango=2010;R.syncContainers(full);const before=JSON.stringify(full),copy=R.migrateSave(full);assert(copy);assert.equal(JSON.stringify(full),before);assert(copy.recovery.length);assert.equal(copy.inventory.length,0);assert(R.recoverHand(copy,0).ok);assert.equal(copy.player.hand.n,1);assert(!R.recoverHand(copy,0).ok);assert(R.valid(copy));assert(R.migrateSave(copy));
const invalid=structuredClone(copy);invalid.inventory=[{item:'arroz',n:1}];assert.equal(R.migrateSave(invalid),null);
const badHand=structuredClone(copy);badHand.player.hand.n=2;assert.equal(R.migrateSave(badHand),null);
// Qualidade e porções de panelas antigas permanecem armazenadas fisicamente.
const oldPan=structuredClone(require('./fixtures/cozinha-v11.json'));oldPan.inventory[3]={item:'pot_sopa_4',n:1,quality:3};oldPan.recovery.push({item:'pot',n:1});oldPan.meals.made.sopa=4;
const preserved=R.migrateSave(oldPan);assert(preserved);const pan=preserved.objects.flatMap(o=>o.inventory||[]).find(p=>p?.item==='pot_sopa_4');assert.equal(pan.quality,3);assert(R.mealsConserved(preserved));
console.log('PASSOU: migração v9/v11 sem mochila ou perda, excedentes recuperáveis, saves inválidos recusados e qualidade/porções preservadas.');

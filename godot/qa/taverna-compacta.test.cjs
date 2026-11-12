const assert=require('node:assert/strict');
const R=require('../simulacao/restaurant-core');
const s=R.furnishedTest(true);
assert(R.valid(s));assert.equal(R.layoutError(s,s.objects),null);
assert.equal(s.objects.filter(o=>o.type==='table').length,3);
assert.equal(s.objects.filter(o=>o.type==='chair').length,12);
assert(R.blocked(s,'restaurant',4,5));assert(R.blocked(s,'restaurant',10,2));
assert.equal(R.route(s,'restaurant',s.player,{x:3,y:5},s.player),null);
for(const o of s.objects.filter(o=>o.type!=='chair')) {
 const access=R.closestAccess(s,s.player,o);
 assert(access,`Acesso a ${o.type}`);
 assert(R.route(s,'restaurant',s.player,access,s.player),`Percurso a ${o.type}`);
}
assert(R.route(s,'restaurant',s.player,{x:7,y:14},s.player),'Saída acessível');
const cash=s.cash;
assert(!R.place(s,'table',2,5).ok);assert.equal(s.cash,cash);
const restored=R.migrateSave(s);assert(restored?.compact);assert.deepEqual(restored.objects,s.objects);
const old=R.furnishedTest();delete old.compact;
const legacy=R.migrateSave(old);assert(legacy);assert(!legacy.compact);
assert(!R.blocked(legacy,'restaurant',2,5));assert.deepEqual(legacy.objects,old.objects);
R.clearTestScene(s);assert(s.compact);assert(R.valid(s));
const malformed=R.furnishedTest(true);malformed.compact='yes';assert.equal(R.migrateSave(malformed),null);
console.log('PASSOU: planta compacta, 12 assentos, acesso aos equipamentos/saída, limites de construção, conservação e saves antigos.');

function testRestaurant(){const s=R.furnishedTest();s.serviceHours[0].start=360;return s;}
const assert=require('node:assert/strict'),R=require('./dist/restaurant-core.js');
const s=testRestaurant();Object.assign(s.player,{x:10,y:12});R.toggleOpen(s);
R.step(s,7.9,()=>.5);assert.equal(s.customers.length,0);R.step(s,.2,()=>.5);assert.equal(s.customers.length,1);
R.step(s,24.8,()=>.5);assert.equal(s.customers.length,1);R.step(s,.3,()=>.5);assert.equal(s.customers.length,2);
const tables=s.customers.map(c=>R.seatTable(s,s.objects.find(o=>o.id===c.seat)).id);assert.equal(new Set(tables).size,2);assert(R.valid(s));
const t=testRestaurant();Object.assign(t.player,{x:10,y:12});assert(R.spawn(t,()=>.5));R.step(t,3,()=>.5);assert(R.spawn(t,()=>.5));R.step(t,3,()=>.5);assert(R.spawn(t,()=>.5));R.step(t,3,()=>.5);assert(!R.spawn(t,()=>.5));assert.equal(t.customers.length,3);
const c=t.customers.shift(),chair=t.objects.find(o=>o.id===c.seat);t.dirtyTables[chair.id]=1;t.equipment.plate++;assert(!R.spawn(t,()=>.5));t.dirtyTables[chair.id]=0;t.equipment.plate--;assert(R.spawn(t,()=>.5));
console.log('Chegadas espaçadas, mesa exclusiva e liberação após limpeza passaram.');

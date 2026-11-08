const assert=require('node:assert/strict'),R=require('../simulacao/restaurant-core');
function base(rot){const s=R.fresh();assert(R.place(s,'table',4,4,rot).ok);return s;}
const allowed=[[[4,3,2],[5,3,2],[4,5,0],[5,5,0]],[[3,4,1],[3,5,1],[5,4,3],[5,5,3]]];
const ends=[[[3,4],[6,4]],[[4,3],[4,6]]];
for(let tableRot=0;tableRot<4;tableRot++){
 for(const [x,y,rot]of allowed[tableRot%2]){
  const s=base(tableRot),placed=R.place(s,'chair',x,y,rot);assert(placed.ok,placed.error);assert.equal(R.seatTable(s,placed.object).type,'table');assert(R.valid(s));
  for(const bad of [0,1,2,3].filter(r=>r!==rot)){const t=base(tableRot),before=JSON.stringify(t);assert(!R.place(t,'chair',x,y,bad).ok);assert.equal(JSON.stringify(t),before);}
 }
 for(const [x,y]of ends[tableRot%2])for(let rot=0;rot<4;rot++){
  const s=base(tableRot),before=JSON.stringify(s);const result=R.place(s,'chair',x,y,rot);assert(!result.ok);assert.match(result.error,/pontas/);assert.equal(JSON.stringify(s),before);
  assert.equal(R.seatTable(s,{type:'chair',room:'restaurant',x,y,rot}),undefined);
 }
}
const furnished=R.furnishedTest();assert.equal(R.seats(furnished).length,12);for(const t of furnished.objects.filter(o=>o.type==='table')){const chairs=furnished.objects.filter(o=>o.type==='chair'&&R.seatTable(furnished,o)?.id===t.id);assert.equal(chairs.length,4);assert.equal(chairs.filter(o=>o.y===t.y-1).length,2);assert.equal(chairs.filter(o=>o.y===t.y+1).length,2);}
const legacy=base(0);legacy.objects.push({id:legacy.serial++,type:'chair',room:'restaurant',x:3,y:4,rot:1});assert(R.valid(legacy));assert.equal(R.seats(legacy).length,0);assert(R.migrateSave(legacy));assert(R.place(legacy,'bin',20,8).ok);
const c=legacy.objects.find(o=>o.type==='chair');assert(!R.place(legacy,'chair',6,4,3,c.id).ok);assert(R.place(legacy,'chair',4,3,2,c.id).ok);assert.equal(R.seats(legacy).length,1);
const rotation=base(0);assert(R.place(rotation,'chair',4,3,2).ok);const table=rotation.objects.find(o=>o.type==='table');const before=JSON.stringify(rotation);assert(!R.place(rotation,'table',4,4,1,table.id).ok);assert.equal(JSON.stringify(rotation),before);
console.log('PASSOU: lados compridos, quatro rotações, orientação, bloqueio nas pontas, cobrança atômica, 12 assentos mobiliados e saves antigos.');

// Louça de saves antigos continua recolhível nas cadeiras que deixaram de ser assentos.
const oldDirty=base(0);oldDirty.objects.push({id:oldDirty.serial++,type:'chair',room:'restaurant',x:3,y:4,rot:1});const ch=oldDirty.objects.find(o=>o.type==='chair');oldDirty.dirtyTables[ch.id]=1;oldDirty.equipment.plate=1;const tbl=oldDirty.objects.find(o=>o.type==='table');Object.assign(oldDirty.player,R.closestAccess(oldDirty,oldDirty.player,tbl));assert(R.collectDirty(oldDirty,tbl.id).ok);assert.equal(R.inventoryCount(oldDirty,'dirtyPlate'),1);assert(R.valid(oldDirty));

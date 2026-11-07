const assert = require('node:assert/strict');
const R = require('../simulacao/restaurant-core.js');

// Original validator: deliberately uses route() as an independent reference.
function reference(s, objects) {
  const occupied = new Set();
  for (const o of objects) {
    if (!R.CATALOG[o.type] || o.room !== R.CATALOG[o.type].room) return 'Objeto fora do setor permitido.';
    for (const p of R.cells(o)) {
      if (R.wall(o.room,p.x,p.y) || R.fixed(o.room,p.x,p.y) || R.PORTALS[o.room].some(d=>Math.abs(d.x-p.x)+Math.abs(d.y-p.y)<=1)) return 'Parede, porta ou infraestrutura reservada.';
      if (o.room === 'restaurant' && ((R.CATALOG[o.type].area==='hall' && p.x>=14) || (R.CATALOG[o.type].area==='kitchen' && (p.x<=14 || p.y>=10)) || (R.CATALOG[o.type].area==='storage' && (p.x<=14 || p.y<=10)) || (R.CATALOG[o.type].area==='dryStorage' && p.x<=14))) return 'Mesas e cadeiras: salão. Fogão e geladeira de cozinha: cozinha. Prateleira: cozinha ou estoque. Geladeira de estoque: estoque.';
      const key=o.room+':'+R.key(p);
      if (occupied.has(key)) return 'Esta célula já está ocupada.';
      occupied.add(key);
      if (R.allActors(s).some(a=>a.room===o.room && R.reserved(a).some(q=>q.x===p.x && q.y===p.y))) return 'Há uma pessoa nesta posição.';
    }
  }
  const room='restaurant', start={x:7,y:13};
  for (const door of R.PORTALS[room]) if (!R.route(s,room,start,door,null,new Set(),objects)) return 'A disposição bloqueia uma porta.';
  for (const o of objects.filter(o=>o.room===room)) if (!R.accessPoints(s,o,objects).some(p=>R.route(s,room,start,p,null,new Set(),objects))) return 'Deixe uma passagem até cada móvel.';
  return null;
}
let cases=0, valid=0;
const outcomes=new Set();
function compare(s, objects) {
  const expected=reference(s,objects);
  assert.equal(R.layoutError(s,objects),expected,JSON.stringify(objects));
  outcomes.add(expected);valid+=expected===null;cases++;
}
let seed=918273;
const random=n=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed%n;};
for (const s of [R.fresh(),R.furnishedTest()]) {
  compare(s,s.objects);
  for (const type of Object.keys(R.CATALOG)) for(let rot=0;rot<4;rot++) for(let i=0;i<16;i++) {
    const moving=s.objects.find(o=>o.type===type);
    const o={id:moving?.id||999,type,room:'restaurant',x:random(R.W),y:random(R.H),rot};
    compare(s,s.objects.filter(q=>q.id!==moving?.id).concat(o));
  }
}
// Door, diagonal bottleneck, isolated furniture and reserved actor cells.
for(let gap=0;gap<15;gap++) {
  const s=R.fresh();
  const wall=[];
  for(let y=1;y<15;y++) if(y!==gap) wall.push({id:y,type:'chair',room:'restaurant',x:13,y,rot:0});
  wall.push({id:99,type:'stove',room:'restaurant',x:16,y:2,rot:0});
  compare(s,wall);
}
const s=R.fresh();
s.player.motion={x:8,y:12,fromX:7,fromY:13,toX:8,toY:12,elapsed:0,duration:.25};
for(const [x,y] of [[8,12],[7,12],[8,13],[2,7]]) compare(s,[{id:1,type:'chair',room:'restaurant',x,y,rot:0}]);
assert(valid>10,'Reference must cover accepted layouts too');
assert(outcomes.has('Deixe uma passagem até cada móvel.'),'Must cover disconnected furniture');
assert(outcomes.has('Há uma pessoa nesta posição.'),'Must cover reserved motion cells');
console.log(`${cases} layouts equivalentes ao algoritmo anterior; ${valid} aceitos; ${outcomes.size} resultados distintos.`);

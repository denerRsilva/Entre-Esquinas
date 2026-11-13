const assert=require('node:assert/strict'),R=require('../simulacao/restaurant-core');
for(const id of ['worker1','worker2','lia','beto','nina','player']){
 const s=R.fresh();const a=R.allActors(s).find(a=>a.id===id);
 const target={room:a.room,x:a.x,y:a.y+1};R.go(a,target);R.moveActors(s,.01);
 assert(a.motion,id+' começou a caminhar');
 assert.equal(a.motion.duration,id==='player'?.18:.4,id+' velocidade');
 assert(R.valid(s),id+' estado válido em movimento');assert(R.migrateSave(s),id+' save em movimento');
}
console.log('PASSOU: funcionários e moradores a 2,5 células/s; jogador preservado; saves em movimento válidos.');

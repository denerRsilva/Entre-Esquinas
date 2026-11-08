const assert=require('node:assert/strict'),R=require('../simulacao/restaurant-core.js');
let cases=0;const test=(name,fn)=>{fn();cases++;console.log('OK '+name)};
function walk(s,dx,dy,seconds){R.setPlayerInput(s,dx,dy);for(let left=seconds;left>1e-9;left-=1/60)R.moveActors(s,Math.min(left,1/60));R.setPlayerInput(s,0,0);}
test('06:00 → 11:00 sem simular espera, gastos ou recursos',()=>{
 const s=R.furnishedTest(),cash=s.cash,inventory=JSON.stringify(s.inventory);
 assert(R.advanceTestClock(s,660).ok);assert.equal(R.clockText(s),'11:00');assert.equal(s.time,0);assert.equal(s.cash,cash);assert.equal(s.day,1);assert.equal(JSON.stringify(s.inventory),inventory);assert(R.valid(s));
});
test('Selecionar 18:00 prepara o turno de jantar',()=>{
 const s=R.fresh();assert(R.advanceTestClock(s,1080).ok);assert.equal(s.period,1);assert(R.toggleOpen(s));assert(R.valid(s));
});
test('Horários inválidos e retrocesso não alteram estado',()=>{
 const s=R.fresh();R.advanceTestClock(s,660);
 for(const value of [650,659,0,1600,NaN,'660']){const before=JSON.stringify(s);assert.equal(R.advanceTestClock(s,value).ok,false);assert.equal(JSON.stringify(s),before);}
});
test('Mesmo horário não rebobina o resto do bloco',()=>{
 const s=R.fresh();s.clock.remainder=3;assert(R.advanceTestClock(s,360).ok);assert.equal(s.clock.remainder,3);
});
test('Salto preserva preparo em andamento',()=>{
 const s=R.furnishedTest(),o=s.objects.find(o=>o.type==='stove');Object.assign(s.player,R.accessPoints(s,o)[0]);
 stageRecipe(s,o,'arrozLegumes');assert(R.startCook(s,o.id,'arrozLegumes').ok);const before=JSON.stringify(s.cooking);
 R.advanceTestClock(s,660);assert.equal(JSON.stringify(s.cooking),before);assert(R.valid(s));
});
test('Rua: abrir às 11h gera clientes normalmente dentro do restaurante',()=>{
 const s=R.furnishedTest();Object.assign(s.player,{room:'street',x:12,y:6});R.advanceTestClock(s,660);
 assert(R.toggleOpen(s));R.step(s,8.1,()=>.1);assert(s.customers.length>0);assert.equal(s.player.room,'street');assert(R.valid(s));
 const before=JSON.stringify(s.customers);R.advanceTestClock(s,900);
 assert(s.closing);assert.equal(JSON.stringify(s.customers),before);assert(R.valid(s));
});
test('Fim do dia sem pendências faz uma única virada e cobrança',()=>{
 const s=R.fresh();assert(R.advanceTestClock(s,1560).ok);assert.equal(s.day,2);assert.equal(s.cash,1488);assert.equal(s.reports.length,1);assert.equal(R.clockText(s),'06:00');R.step(s,.1);assert.equal(s.reports.length,1);assert(R.valid(s));
});
test('02:00 aguarda preparo antes de virar o dia',()=>{
 const s=R.furnishedTest(),o=s.objects.find(o=>o.type==='stove');Object.assign(s.player,R.accessPoints(s,o)[0]);stageRecipe(s,o,'sopa');assert(R.startCook(s,o.id,'sopa').ok);
 assert(R.advanceTestClock(s,1560).ok);assert.equal(s.day,1);assert(s.clock.ending);assert(s.closing);assert(R.valid(s));
});
test('Porta funciona por movimento livre, sem retorno em loop',()=>{
 const s=R.fresh();walk(s,0,1,.3);assert.equal(s.player.room,'street');assert(R.valid(s));
 walk(s,0,1,.1);assert.equal(s.player.room,'street');walk(s,0,-1,.6);assert.equal(s.player.room,'restaurant');assert(R.valid(s));
 walk(s,0,-1,.1);assert.equal(s.player.room,'restaurant');
});
test('Porta ocupada aguarda liberar o ponto de chegada',()=>{
 const s=R.fresh();Object.assign(s.player,{room:'street',x:12,y:6});Object.assign(s.workers[0],{x:7,y:13});
 walk(s,0,-1,.5);assert.equal(s.player.room,'street');s.workers[0].x=9;walk(s,0,-1,.1);assert.equal(s.player.room,'restaurant');assert(R.valid(s));
});
console.log(cases+' cenários de rua e horário passaram.');

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

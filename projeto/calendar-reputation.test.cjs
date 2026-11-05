function testRestaurant(){const s=R.furnishedTest();s.serviceHours[0].start=360;return s;}
const assert=require('node:assert/strict'),R=require('./dist/restaurant-core.js');let passed=0;
const test=(label,fn)=>{fn();console.log('OK '+(++passed)+' — '+label)};
const approx=(a,b)=>assert(Math.abs(a-b)<1e-7,a+' != '+b);
function ticks(s,seconds,rng=()=>.99){for(let left=seconds;left>1e-8;left-=.1){R.step(s,Math.min(.1,left),rng);assert(R.valid(s));}}
function fixture(){const s=testRestaurant();s.player.x=10;s.player.y=12;s.menu={arrozLegumes:false,sopa:true,frangoArroz:false};assert(R.spawn(s,()=>0));const c=s.customers[0];for(let i=0;i<200&&c.state==='walk';i++)ticks(s,.1);assert.equal(c.state,'waiting');return {s,c};}
function stand(s,o){const p=R.accessPoints(s,o).find(p=>!R.allActors(s).some(a=>a!==s.player&&a.room===p.room&&a.x===p.x&&a.y===p.y));Object.assign(s.player,p,{motion:null,goal:null,settled:null});}
function near(s,c){const p=R.DIRS.map(([dx,dy])=>({room:c.room,x:c.x+dx,y:c.y+dy})).find(p=>!R.blocked(s,p.room,p.x,p.y)&&!R.allActors(s).some(a=>a!==s.player&&a.room===p.room&&a.x===p.x&&a.y===p.y));Object.assign(s.player,p,{motion:null,goal:null,settled:null});}
function reviewFixture(s,type,id,outcome='completed'){
 const p=R.newExperience(()=>.5);p.results={service:1,food:1};p.satisfaction=R.satisfactionFor(p);
 const visit={id,day:s.day,period:s.period,time:s.time,outcome,profile:p.profile,limits:p.limits,elapsed:p.elapsed,results:p.results,satisfaction:p.satisfaction};s.experience.visits.push(visit);
 const event=type?{visitId:id,day:s.day,period:s.period,time:s.time,type,outcome}:null;if(event)s.experience.events.push(event);return {visit,event};
}
test('06:00, blocos de 7 segundos, minutos e horas sem dependência do relógio real',()=>{
 const s=R.fresh();assert.equal(R.clockText(s),'06:00');R.step(s,6.9);assert.equal(R.clockText(s),'06:00');R.step(s,.1);assert.equal(R.clockText(s),'06:10');R.step(s,35);assert.equal(R.clockText(s),'07:00');approx(s.time,42);assert(R.valid(s));
 const t=R.fresh();for(let i=0;i<420;i++)R.step(t,.1);assert.deepEqual(t.clock,s.clock);approx(t.time,s.time);
 const before=JSON.stringify(s);R.step(s,0);R.step(s,-1);R.step(s,NaN);assert.equal(JSON.stringify(s),before);
});
test('23:50 → 00:00 mantém a data do dia jogável; madrugada chega a 01:50',()=>{
 const s=R.fresh();s.clock.minute=23*60+50;R.step(s,7);assert.equal(R.clockText(s),'00:00');assert.equal(s.day,1);assert.equal(R.calendarDate(s.day).weekday,'Segunda');R.step(s,77);assert.equal(R.clockText(s),'01:50');assert(!s.clock.ending);assert(R.valid(s));
});
test('01:50 → 02:00 conclui serviço pendente, sem novas chegadas ou cancelamento forçado',()=>{
 const {s,c}=fixture();assert(R.toggleOpen(s));s.clock={minute:1550,remainder:0,ending:false};R.step(s,7,()=>.99);assert.equal(R.clockText(s),'02:00');assert(s.clock.ending&&s.closing);assert.equal(s.day,1);assert(!c.experience.abandoned);assert(!R.toggleOpen(s));assert(!R.spawn(s));const elapsed=c.experience.elapsed.service;R.step(s,1,()=>.99);assert.equal(R.clockText(s),'02:00');assert(c.experience.elapsed.service>elapsed);
 for(let i=0;i<1000&&s.day===1;i++)ticks(s,.1);assert.equal(s.day,2);assert.equal(R.clockText(s),'06:00');assert(!s.open&&!s.closing&&!s.clock.ending);assert.equal(s.reports.length,1);assert.equal(s.reports[0].sales,0);assert.equal(s.customers.length,0);
});
test('Preparo híbrido avança longe do fogão e cruza a virada preservando itens',()=>{
 const s=testRestaurant(),stove=s.objects.find(o=>o.type==='stove');stand(s,stove);assert(R.startCook(s,stove.id,'sopa').ok);s.player.x=7;s.player.y=13;s.player.settled=null;s.clock={minute:1550,remainder:0,ending:false};const objects=s.objects.length;R.step(s,7);assert.equal(s.day,2);assert.equal(R.clockText(s),'06:00');assert.equal(s.objects.length,objects);assert.equal(R.objectCount(stove,'pot_sopa_4'),1);assert.equal(s.used.legumes,8);assert(R.valid(s));
});
test('Calendário atravessa quatro estações, dias da semana e ano',()=>{
 for(const [day,season,year]of [[28,'Verão',1],[56,'Outono',1],[84,'Inverno',1],[112,'Primavera',2]]){const s=R.fresh();s.day=day;s.clock.minute=1550;R.step(s,7);const d=R.calendarDate(s.day);assert.equal(s.day,day+1);assert.equal(d.day,1);assert.equal(d.season,season);assert.equal(d.year,year);assert.equal(d.weekday,'Segunda');assert(R.valid(s));}
 assert.equal(R.calendarDate(7).weekday,'Domingo');assert.equal(R.calendarDate(8).weekday,'Segunda');
});
test('Almoço/jantar não avançam data; despesa e relatório diário ocorrem uma única vez na virada',()=>{
 const s=R.fresh(),cash=s.cash;s.serviceHours[0].start=360;for(let i=0;i<2;i++){assert(R.toggleOpen(s));assert(R.toggleOpen(s));R.step(s,.1);}assert.equal(s.day,1);assert.equal(s.period,0);assert.equal(s.cash,cash);assert.equal(s.reports.length,0);s.ledger.revenue=20;s.ledger.sales=2;s.clock={minute:1550,remainder:0,ending:false};R.step(s,7);assert.equal(s.day,2);assert.equal(s.cash,cash-12);assert.equal(s.reports.length,1);assert.equal(s.reports[0].sales,2);assert.equal(s.reports[0].result,8);R.step(s,7);assert.equal(s.reports.length,1);assert.equal(s.cash,cash-12);
});
test('Elogio de visita real aumenta reputação; abandono + reclamação tem só um impacto',()=>{
 const {s,c}=fixture(),stove=s.objects.find(o=>o.type==='stove'),prep=s.objects.find(o=>o.type==='prep');near(s,c);assert(R.interact(s,c.id));stand(s,stove);assert(R.startCook(s,stove.id,'sopa').ok);ticks(s,6);assert(R.kitchenAction(s,stove.id,'takePan').ok);stand(s,prep);assert(R.plateFood(s,prep.id,'sopa').ok);ticks(s,2);assert(R.kitchenAction(s,prep.id,'takeDish','dish_sopa').ok);near(s,c);assert(R.interact(s,c.id));ticks(s,4.1,()=>0);assert.equal(s.reputation.score,1);assert.equal(s.reputation.history.length,1);assert.equal(s.reputation.history[0].type,'praise');
 const visit=reviewFixture(s,'complaint','abandon-test','abandoned');assert(R.applyVisitReputation(s,visit.visit,visit.event));assert.equal(s.reputation.score,0);assert.equal(s.reputation.history.length,2);assert.equal(s.reputation.history[1].type,'abandonment');assert(!R.applyVisitReputation(s,visit.visit,visit.event));assert.equal(s.reputation.history.length,2);assert(R.valid(s));
});
test('Abandono sem manifestação verbal ainda registra o resultado uma única vez',()=>{
 const {s,c}=fixture();R.step(s,40,()=>.99);assert(c.experience.abandoned);assert.equal(s.experience.events.length,0);assert.equal(s.reputation.history.length,1);assert.equal(s.reputation.history[0].manifestation,null);assert.equal(s.reputation.history[0].requestedDelta,-1);assert.equal(s.reputation.score,0);ticks(s,20);assert.equal(s.reputation.history.length,1);assert(R.valid(s));
});
test('Limites 0/100, cinco níveis e parâmetros graduais configuráveis',()=>{
 const s=R.fresh();for(let i=0;i<150;i++){const {visit,event}=reviewFixture(s,'praise','positive'+i);assert(R.applyVisitReputation(s,visit,event));}assert.equal(s.reputation.score,100);assert(R.valid(s));for(let i=0;i<150;i++){const {visit,event}=reviewFixture(s,'complaint','negative'+i);assert(R.applyVisitReputation(s,visit,event));}assert.equal(s.reputation.score,0);assert(R.valid(s));
 for(const [n,label]of [[0,'Desconhecido'],[19,'Desconhecido'],[20,'Pouco conhecido'],[39,'Pouco conhecido'],[40,'Reconhecido'],[59,'Reconhecido'],[60,'Bem avaliado'],[79,'Bem avaliado'],[80,'Referência local'],[100,'Referência local']])assert.equal(R.reputationLevel(n),label);
 const before=R.REPUTATION_CONFIG.deltas.praise;try{R.REPUTATION_CONFIG.deltas.praise=.25;const {visit,event}=reviewFixture(s,'praise','fraction');R.applyVisitReputation(s,visit,event);assert.equal(s.reputation.score,.25);assert(R.valid(s));}finally{R.REPUTATION_CONFIG.deltas.praise=before;}
});
test('Reputação preservada no save, sem duplicações e sem replay de avaliações antigas',()=>{
 const {s,c}=fixture();R.step(s,40,()=>0);const copy=R.migrateSave(s);assert(copy);const {visitId}=copy.reputation.history[0];assert(!R.applyVisitReputation(copy,copy.experience.visits.find(v=>v.id===visitId),copy.experience.events.find(v=>v.visitId===visitId)));assert.equal(copy.reputation.history.length,1);
 const legacy=JSON.parse(JSON.stringify(s));legacy.version=5;delete legacy.clock;delete legacy.reputation;const before=JSON.stringify(legacy),migrated=R.migrateSave(legacy);assert(migrated);assert.equal(JSON.stringify(legacy),before);assert.equal(migrated.clock.minute,360);assert.equal(migrated.reputation.score,0);assert.equal(migrated.reputation.history.length,0);assert.deepEqual(migrated.customers[0].experience,c.experience);assert.deepEqual(migrated.experience,s.experience);assert(!R.applyVisitReputation(migrated,migrated.experience.visits[0],migrated.experience.events[0]));assert.equal(migrated.reputation.history.length,0);
 assert.equal(R.migrateSave({version:5}),null);const duplicate=R.migrateSave(s);duplicate.reputation.history.push({...duplicate.reputation.history[0]});assert(!R.valid(duplicate));const bad=R.migrateSave(s);bad.reputation.score=101;assert(!R.valid(bad));bad.reputation.score=-1;assert(!R.valid(bad));
});
test('Fluxo de clientes não muda com a reputação',()=>{
 const a=testRestaurant(),b=testRestaurant();a.player.x=b.player.x=10;a.player.y=b.player.y=12;b.reputation.initial=b.reputation.score=100;R.toggleOpen(a);R.toggleOpen(b);for(let i=0;i<400;i++){R.step(a,.1,()=>.5);R.step(b,.1,()=>.5);}assert.equal(a.customers.length,b.customers.length);assert.deepEqual(a.customers.map(c=>[c.id,c.recipe,c.state,c.x,c.y]),b.customers.map(c=>[c.id,c.recipe,c.state,c.x,c.y]));assert.equal(a.arrival,b.arrival);assert(R.valid(a)&&R.valid(b));
});
test('Visita neutra sem manifestação não pode gerar efeito retroativo',()=>{const s=R.fresh(),{visit}=reviewFixture(s,null,'quiet');assert(!R.applyVisitReputation(s,visit));assert(s.reputation.processed.includes(visit.id));assert(!R.applyVisitReputation(s,visit));assert.equal(s.reputation.history.length,0);assert(R.valid(s));});
console.log(passed+' cenários de tempo, calendário e reputação passaram.');

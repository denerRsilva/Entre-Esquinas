/* Entre Esquinas Restaurante 0.12.0. Parâmetros abaixo são hipóteses de protótipo. */
(function(root){
'use strict';
const W=24,H=16,CELL=40,VERSION=6;
const FOODS={arroz:{name:'Arroz',cost:2,kind:'dry'},legumes:{name:'Legumes',cost:2,kind:'cold'},frango:{name:'Frango',cost:4,kind:'cold'}};
const CATALOG={table:{name:'Mesa',price:45,w:2,h:1,room:'restaurant',area:'hall',color:'#ba8654'},chair:{name:'Cadeira',price:15,w:1,h:1,room:'restaurant',area:'hall',color:'#d5ad70'},stove:{name:'Fogão',price:150,w:2,h:1,room:'restaurant',area:'kitchen',color:'#718d91'},fridge:{name:'Geladeira da cozinha',price:120,w:1,h:2,room:'restaurant',area:'kitchen',color:'#8dbdb5'},shelf:{name:'Prateleira seca',price:65,w:2,h:1,room:'restaurant',area:'dryStorage',color:'#b69969'},cold:{name:'Geladeira do estoque',price:140,w:1,h:2,room:'restaurant',area:'storage',color:'#91b6cb'}};
Object.assign(CATALOG,{prep:{name:'Mesa de preparo',price:90,w:2,h:1,room:'restaurant',area:'kitchen',color:'#d1af79'},sink:{name:'Pia',price:70,w:2,h:1,room:'restaurant',area:'kitchen',color:'#82b8bb'},bin:{name:'Lixo',price:25,w:1,h:1,room:'restaurant',area:'dryStorage',color:'#71877a'}});
const RECIPES={arrozLegumes:{name:'Arroz com legumes',foods:{arroz:1,legumes:1},price:14,time:6},sopa:{name:'Sopa de legumes',foods:{legumes:2},price:12,time:5},frangoArroz:{name:'Frango com arroz',foods:{arroz:1,frango:1},price:20,time:8}};
const PORTALS={street:[{x:12,y:5,to:'restaurant',spawn:[7,13],name:'Entrar no restaurante'}],restaurant:[{x:7,y:14,to:'street',spawn:[12,6],name:'Sair para a cidade'}],stock:[{x:21,y:14,to:'restaurant',spawn:[21,13],name:'Voltar à cozinha'}]};
const DIRS=[[0,-1],[1,0],[0,1],[-1,0]];
const key=p=>p.x+','+p.y;
const actor=(id,room,x,y)=>({id,room,x,y,goal:null,wait:0,hold:0,state:'idle',carry:null});
// Parâmetros de protótipo, independentes do relógio do dispositivo.
const TIME_CONFIG={startMinute:6*60,endMinute:26*60,blockMinutes:10,secondsPerBlock:7,daysPerSeason:28,seasons:['Primavera','Verão','Outono','Inverno'],weekdays:['Segunda','Terça','Quarta','Quinta','Sexta','Sábado','Domingo'],dailyExpense:12};
const REPUTATION_CONFIG={initial:0,min:0,max:100,deltas:{praise:1,complaint:-1,abandonment:-1},levels:[{min:80,label:'Referência local'},{min:60,label:'Bem avaliado'},{min:40,label:'Reconhecido'},{min:20,label:'Pouco conhecido'},{min:0,label:'Desconhecido'}]};
function newClock(){return {minute:TIME_CONFIG.startMinute,remainder:0,ending:false};}
function calendarDate(day){const index=day-1,seasonIndex=Math.floor(index/TIME_CONFIG.daysPerSeason)%TIME_CONFIG.seasons.length;return {day:index%TIME_CONFIG.daysPerSeason+1,weekday:TIME_CONFIG.weekdays[index%TIME_CONFIG.weekdays.length],season:TIME_CONFIG.seasons[seasonIndex],seasonIndex,year:Math.floor(index/(TIME_CONFIG.daysPerSeason*TIME_CONFIG.seasons.length))+1};}
function clockText(s){const minute=s.clock.minute%(24*60);return String(Math.floor(minute/60)).padStart(2,'0')+':'+String(minute%60).padStart(2,'0');}
function clampReputation(n){return Math.max(REPUTATION_CONFIG.min,Math.min(REPUTATION_CONFIG.max,n));}
function newReputation(){const initial=clampReputation(REPUTATION_CONFIG.initial);return {initial,score:initial,history:[],processed:[]};}
function reputationLevel(score){return REPUTATION_CONFIG.levels.find(level=>score>=level.min)?.label||REPUTATION_CONFIG.levels.at(-1).label;}
function applyVisitReputation(s,visit,event=null){
 // Abandono tem prioridade: eventual reclamação da mesma visita não soma outra penalidade.
 const type=visit.outcome==='abandoned'?'abandonment':event?.type;
 if(event&&(!s.experience.events.includes(event)||event.visitId!==visit.id||visit.outcome==='abandoned'&&event.type==='praise'))return false;
 if(s.reputation.processed.includes(visit.id)||type&&!Object.hasOwn(REPUTATION_CONFIG.deltas,type))return false;
 if(!s.experience.visits.includes(visit))return false;
 s.reputation.processed.push(visit.id);if(!type)return false;
 const before=s.reputation.score,requestedDelta=REPUTATION_CONFIG.deltas[type],after=clampReputation(before+requestedDelta);
 s.reputation.score=after;s.reputation.history.push({visitId:visit.id,type,manifestation:event?.type||null,requestedDelta,delta:after-before,before,after,day:s.day,time:s.time});return true;
}
function servicePending(s){return !!(s.customers.length||s.cooking||s.ready.length||s.orders.some(o=>!['paid','lost'].includes(o.state))||allActors(s).some(a=>a.carry?.kind==='dish'&&!canceledCarry(s,a)));}
function advanceClock(s,dt){
 if(s.clock.ending)return;s.clock.remainder+=dt;
 if(s.clock.remainder+1e-9<TIME_CONFIG.secondsPerBlock)return;
 s.clock.remainder=Math.max(0,s.clock.remainder-TIME_CONFIG.secondsPerBlock);
 s.clock.minute=Math.min(TIME_CONFIG.endMinute,s.clock.minute+TIME_CONFIG.blockMinutes);
 if(s.clock.minute===TIME_CONFIG.endMinute){s.clock.ending=true;s.clock.remainder=0;if(s.open||servicePending(s))s.closing=true;s.message='02:00: entrada encerrada. Conclua clientes e preparos para começar o próximo dia.';}
}
function finishCalendarDay(s){
 if(!s.clock.ending||servicePending(s))return false;
 const expense=TIME_CONFIG.dailyExpense,r={day:s.day,...s.ledger,expense,result:s.ledger.revenue-s.ledger.foodCost-expense,cash:s.cash-expense};
 s.cash-=expense;s.reports.push(r);s.lastReport=r;s.ledger={revenue:0,foodCost:0,purchases:0,investment:0,lost:0,sales:0};s.day++;s.period=0;s.open=false;s.closing=false;s.clock=newClock();
 s.message='Novo dia às 06:00. Relatório diário disponível na Gestão.';return true;
}
function validTimeReputation(s){
 const c=s.clock,r=s.reputation;
 if(!c||!Number.isInteger(c.minute)||c.minute<TIME_CONFIG.startMinute||c.minute>TIME_CONFIG.endMinute||(c.minute-TIME_CONFIG.startMinute)%TIME_CONFIG.blockMinutes!==0||!Number.isFinite(c.remainder)||c.remainder<0||c.remainder>=TIME_CONFIG.secondsPerBlock||typeof c.ending!=='boolean'||c.ending!==(c.minute===TIME_CONFIG.endMinute)||c.ending&&c.remainder!==0)return false;
 if(!r||!Number.isFinite(r.score)||r.score<0||r.score>100||!Number.isFinite(r.initial)||r.initial<0||r.initial>100||!Array.isArray(r.history)||!Array.isArray(r.processed)||new Set(r.processed).size!==r.processed.length||r.processed.some(id=>!s.experience.visits.some(v=>v.id===id)))return false;
 let expected=r.initial;const visits=new Set();
 for(const e of r.history){const visit=s.experience.visits.find(v=>v.id===e.visitId),manifest=s.experience.events.find(v=>v.visitId===e.visitId);
  if(!r.processed.includes(e.visitId)||!visit||visits.has(e.visitId)||!['praise','complaint','abandonment'].includes(e.type)||visit.outcome==='abandoned'&&e.type!=='abandonment'||e.type==='abandonment'&&visit.outcome!=='abandoned'||e.manifestation!==(manifest?.type||null)||e.type!=='abandonment'&&e.type!==manifest?.type||!Number.isFinite(e.requestedDelta)||!Number.isFinite(e.delta)||e.before!==expected||e.after!==Math.max(0,Math.min(100,e.before+e.requestedDelta))||e.delta!==e.after-e.before||!Number.isFinite(e.time)||e.time>s.time||!Number.isInteger(e.day)||e.day<1)return false;
  visits.add(e.visitId);expected=e.after;
 }
 return r.score===expected;
}

// Balanceamento provisório v1.0. Pesos relativos de perfil, sem probabilidades definitivas.
const CUSTOMER_CONFIG={
 profiles:{impatient:{weight:1,service:[40,60],food:[60,90]},normal:{weight:1,service:[60,90],food:[90,150]},patient:{weight:1,service:[90,120],food:[150,210]}},
 thresholds:{patient:.5,stressed:.2},
 satisfaction:{weights:{service:35,food:35,quality:30},classes:[{id:'verySatisfied',label:'Muito satisfeito',min:85},{id:'satisfied',label:'Satisfeito',min:65},{id:'neutral',label:'Neutro',min:40},{id:'unsatisfied',label:'Insatisfeito',min:0}]},
 reviews:{verySatisfied:{probability:.6,type:'praise'},satisfied:{probability:.2,type:'praise'},neutral:{probability:.05,type:'complaint'},unsatisfied:{probability:.35,type:'complaint'},abandoned:{probability:.75,type:'complaint'}},
 indicators:{happySeconds:8,abandonSeconds:null,emoji:{patient:'⏳',impatient:'❗',stressed:'😠',leaving:'🤬',happy:'😊'},size:21}
};
function drawRandom(rng){return Math.max(0,Math.min(1-Number.EPSILON,rng()));}
function newExperience(rng=Math.random){
 const entries=Object.entries(CUSTOMER_CONFIG.profiles).filter(([,p])=>p.weight>0),total=entries.reduce((n,[,p])=>n+p.weight,0);
 if(!total)throw Error('Configure ao menos um perfil de paciência com peso positivo.');
 let roll=drawRandom(rng)*total,[profile,config]=entries[entries.length-1];
 for(const entry of entries){roll-=entry[1].weight;if(roll<0){[profile,config]=entry;break;}}
 const sample=range=>range[0]+drawRandom(rng)*(range[1]-range[0]);
 return {profile,limits:{service:sample(config.service),food:sample(config.food)},elapsed:{service:0,food:0},phase:null,visual:null,results:{service:null,food:null},satisfaction:null,abandoned:false,reviewResolved:false,legacy:false,indicatorUntil:null};
}
function waitRatio(p,phase=p.phase){return phase?Math.max(0,1-p.elapsed[phase]/p.limits[phase]):null;}
function refreshCustomerVisual(s,c){const p=c.experience;if(p.phase){let ratio=waitRatio(p);p.visual=ratio>CUSTOMER_CONFIG.thresholds.patient?'patient':ratio>CUSTOMER_CONFIG.thresholds.stressed?'impatient':'stressed';}
 else if(p.abandoned)p.visual=p.indicatorUntil===null||s.time<p.indicatorUntil?'leaving':null;
 else p.visual=p.satisfaction&&['verySatisfied','satisfied'].includes(p.satisfaction.classification)&&s.time<p.indicatorUntil?'happy':null;
}
function customerIndicator(s,c){const p=c.experience;if(!p)return null;refreshCustomerVisual(s,c);if(!p.visual)return null;return {emoji:CUSTOMER_CONFIG.indicators.emoji[p.visual],label:{patient:'Paciente',impatient:'Perdendo a paciência',stressed:'Estressado',leaving:'Indo embora',happy:'Feliz'}[p.visual],phase:p.phase,remaining:p.phase?Math.max(0,p.limits[p.phase]-p.elapsed[p.phase]):null,ratio:waitRatio(p)};}
function beginWait(s,c,phase){c.experience.phase=phase;refreshCustomerVisual(s,c);}
function finishWait(c){const p=c.experience;if(p.phase)p.results[p.phase]=waitRatio(p);p.phase=null;}
function satisfactionFor(p){
 const config=CUSTOMER_CONFIG.satisfaction,weights=config.weights;
 // Não existe qualidade culinária: normalizar somente os dois pesos de espera.
 const score=100*((p.results.service??0)*weights.service+(p.results.food??0)*weights.food)/(weights.service+weights.food);
 const classification=config.classes.find(v=>score>=v.min)||config.classes[config.classes.length-1];
 return {score,classification:classification.id,quality:null};
}
function finalizeVisit(s,c,outcome,rng=Math.random){
 const p=c.experience;if(p.reviewResolved)return false;p.reviewResolved=true;
 const rule=CUSTOMER_CONFIG.reviews[outcome==='abandoned'?'abandoned':p.satisfaction.classification];
 const event=drawRandom(rng)<rule.probability?{visitId:c.id,day:s.day,period:s.period,time:s.time,type:rule.type,outcome}:null;
 if(event)s.experience.events.push(event);
 const visit={id:c.id,day:s.day,period:s.period,time:s.time,outcome,profile:p.profile,limits:{...p.limits},elapsed:{...p.elapsed},results:{...p.results},satisfaction:p.satisfaction?{...p.satisfaction}:null};
 s.experience.visits.push(visit);applyVisitReputation(s,visit,event);
 return true;
}
function abandonCustomer(s,c,rng=Math.random){
 const p=c.experience;if(p.abandoned||!p.phase)return false;
 finishWait(c);p.abandoned=true;p.satisfaction={score:0,classification:'unsatisfied',quality:null};p.indicatorUntil=CUSTOMER_CONFIG.indicators.abandonSeconds===null?null:s.time+CUSTOMER_CONFIG.indicators.abandonSeconds;
 const order=s.orders.find(o=>o.id===c.order);if(order){order.state='lost';s.ready=s.ready.filter(id=>id!==order.id);if(s.priority===order.id)s.priority=null;}
 c.state='leave';go(c,{room:'restaurant',x:7,y:14});s.ledger.lost++;refreshCustomerVisual(s,c);finalizeVisit(s,c,'abandoned',rng);s.message='Cliente desistiu por demora. Pedido cancelado, sem venda.';return true;
}
function expiredCustomer(s,c,rng=Math.random){const p=c.experience;if(p.abandoned)return true;if(p.phase&&p.elapsed[p.phase]>=p.limits[p.phase]){abandonCustomer(s,c,rng);return true;}return false;}
function patienceStep(s,dt,rng){for(const c of s.customers){const p=c.experience;if(p.phase){p.elapsed[p.phase]=Math.min(p.limits[p.phase],p.elapsed[p.phase]+dt);expiredCustomer(s,c,rng);}refreshCustomerVisual(s,c);}}
// O prato continua existindo após o cancelamento; devolução física na bancada.
function canceledCarry(s,a){return a.carry?.kind==='dish'&&s.orders.find(o=>o.id===a.carry.order)?.state==='lost';}
function returnCanceledDish(s,a){
 if(a.motion||!canceledCarry(s,a))return false;const order=s.orders.find(o=>o.id===a.carry.order),item='dish_'+order.recipe;
 const prep=s.objects.find(o=>o.type==='prep'&&objectSpace(o,item)>0&&objectNear(s,o,a));if(!prep)return false;
 putObject(s,prep,item,1);a.carry=null;s.message='Pedido cancelado: prato devolvido à mesa de preparo.';return true;
}
function validExperience(s){
 const history=s.experience;if(!history||!Array.isArray(history.visits)||!Array.isArray(history.events))return false;
 const classes=CUSTOMER_CONFIG.satisfaction.classes.map(c=>c.id),phases=['service','food'];
 const validScore=v=>v===null||v&&Number.isFinite(v.score)&&v.score>=0&&v.score<=100&&classes.includes(v.classification)&&v.quality===null;
 const validData=p=>p&&CUSTOMER_CONFIG.profiles[p.profile]&&phases.every(k=>Number.isFinite(p.limits?.[k])&&p.limits[k]>0&&Number.isFinite(p.elapsed?.[k])&&p.elapsed[k]>=0&&p.elapsed[k]<=p.limits[k]&&(p.results?.[k]===null||Number.isFinite(p.results?.[k])&&p.results[k]>=0&&p.results[k]<=1))&&validScore(p.satisfaction);
 const visits=new Set(),events=new Set(),customers=new Set();
 for(const v of history.visits){if(!validData(v)||typeof v.id!=='string'||visits.has(v.id)||!['completed','abandoned'].includes(v.outcome)||!Number.isFinite(v.time)||v.time>s.time||!Number.isInteger(v.day)||v.day<1||![0,1].includes(v.period))return false;visits.add(v.id);}
 for(const e of history.events){if(e.outcome==='abandoned'&&e.type==='praise'||!visits.has(e.visitId)||events.has(e.visitId)||!['praise','complaint'].includes(e.type)||!Number.isFinite(e.time)||e.time>s.time||!history.visits.some(v=>v.id===e.visitId&&v.outcome===e.outcome))return false;events.add(e.visitId);}
 for(const c of s.customers){const p=c.experience;if(!validData(p)||customers.has(c.id))return false;customers.add(c.id);
  if(![null,...phases].includes(p.phase)||![null,'patient','impatient','stressed','leaving','happy'].includes(p.visual)||typeof p.abandoned!=='boolean'||typeof p.reviewResolved!=='boolean'||typeof p.legacy!=='boolean'||p.indicatorUntil!==null&&(!Number.isFinite(p.indicatorUntil)||p.indicatorUntil<0))return false;
  if(p.phase!==(c.state==='waiting'?'service':c.state==='ordered'?'food':null)||p.abandoned&&c.state!=='leave')return false;
  if(p.phase&&p.elapsed[p.phase]>=p.limits[p.phase])return false;
  if(!p.reviewResolved&&visits.has(c.id))return false;
  if(!p.legacy&&(c.state==='ordered'&&p.results.service===null||c.state==='eating'&&!p.satisfaction))return false;
 }
 return true;
}
function migrateSave(value,rng=Math.random){
 if(!value||![4,5,VERSION].includes(value.version))return null;
 const s=JSON.parse(JSON.stringify(value));
 if(s.version===4){s.version=5;s.experience={visits:[],events:[]};if(!Array.isArray(s.customers))return null;
  for(const c of s.customers){c.experience=newExperience(rng);c.experience.legacy=true;c.experience.reviewResolved=true;if(c.state==='waiting')beginWait(s,c,'service');else if(c.state==='ordered')beginWait(s,c,'food');}
 }
 if(s.version===5){if(!Array.isArray(s.experience?.visits))return null;s.version=VERSION;s.clock=newClock();s.reputation=newReputation();s.reputation.processed=s.experience.visits.map(v=>v.id);}
 return valid(s)?s:null;
}

function fresh(){return {version:VERSION,clock:newClock(),reputation:newReputation(),day:1,period:0,open:false,closing:false,cash:1500,time:0,tick:0,arrival:0,serial:1,objects:[],equipment:{pot:0,spoon:0,plate:0},meals:{made:{arrozLegumes:0,sopa:0,frangoArroz:0},eaten:{arrozLegumes:0,sopa:0,frangoArroz:0},wasted:{arrozLegumes:0,sopa:0,frangoArroz:0}},dirtyTables:{},inventory:Array(10).fill(null),selectedSlot:0,tools:{pot:false,spoon:false},inv:{receiving:{arroz:0,legumes:0,frango:0},storage:{arroz:0,legumes:0,frango:0},kitchen:{arroz:0,legumes:0,frango:0}},purchased:{arroz:0,legumes:0,frango:0},used:{arroz:0,legumes:0,frango:0},orders:[],deliveries:[],customers:[],experience:{visits:[],events:[]},residents:[actor('lia','street',5,10),actor('beto','street',18,8),actor('nina','street',17,12)],player:actor('player','restaurant',7,13),workers:[{...actor('worker1','restaurant',18,12),task:'none'},{...actor('worker2','restaurant',20,12),task:'none'}],prices:Object.fromEntries(Object.entries(RECIPES).map(([k,v])=>[k,v.price])),menu:Object.fromEntries(Object.keys(RECIPES).map(k=>[k,true])),cookActive:false,cooking:null,ready:[],ledger:{revenue:0,foodCost:0,purchases:0,investment:0,lost:0,sales:0},reports:[],friends:{lia:0,beto:0,nina:0},talked:{},message:'Seu restaurante está vazio. Use Montar para comprar e posicionar os móveis.',lastReport:null,priority:null,flowWaits:0};}
// Cenário opcional de teste; os recursos são gratuitos e não alteram a partida vazia.
function furnishedTest(){
 const s=fresh();s.cash=10000;
 const layout=[];
 for(const [x,y]of [[4,4],[9,4],[7,9]])layout.push(['table',x,y],['chair',x-1,y,1],['chair',x+2,y,3],['chair',x,y-1,2],['chair',x+1,y+1,0]);
 layout.push(['stove',16,2],['fridge',21,2],['prep',16,5],['sink',20,6],['bin',22,8],['shelf',16,13],['cold',21,13]);
 for(const [type,x,y,rot=0]of layout){let r=place(s,type,x,y,rot);if(!r.ok)throw Error('Cenário de teste: '+r.error);}
 const stove=s.objects.find(o=>o.type==='stove'),prep=s.objects.find(o=>o.type==='prep');
 for(const food of Object.keys(FOODS)){putObject(s,stove,food,30);s.purchased[food]=30;}
 addInventory(stove,'pot',3);addInventory(stove,'spoon',1);addInventory(prep,'plate',12);addInventory(prep,'spoon',1);
 s.equipment={pot:3,plate:12,spoon:2};s.tools={pot:true,spoon:true};s.cash=1500;s.ledger.investment=0;
 s.message='Cenário de teste pronto. Ingredientes e panelas no fogão; pratos e colher na mesa de preparo.';
 if(!valid(s))throw Error('Cenário de teste inválido.');return s;
}
function clearTestScene(s){
 // Cancelar o serviço elimina referências a móveis, itens e pratos removidos.
 const clean=fresh();
 for(const k of ['open','closing','tick','arrival','objects','equipment','meals','dirtyTables','inventory','selectedSlot','tools','inv','purchased','used','orders','deliveries','customers','residents','player','workers','cookActive','cooking','ready','priority','flowWaits'])s[k]=clean[k];
 s.message='Teste limpo: móveis e itens removidos. Serviço, entregas e preparos cancelados; dinheiro e dia preservados.';
 return s;
}
function rect(o){let d=CATALOG[o.type];return {x:o.x,y:o.y,w:o.rot%2?d.h:d.w,h:o.rot%2?d.w:d.h};}
function cells(o){let r=rect(o),a=[];for(let y=r.y;y<r.y+r.h;y++)for(let x=r.x;x<r.x+r.w;x++)a.push({x,y});return a;}
function hit(o,x,y){return cells(o).some(p=>p.x===x&&p.y===y);}
function wall(room,x,y){if(x<1||y<1||x>=W-1||y>=H-1)return true;if(room==='restaurant')return x===14&&y!==7||x>=15&&y===10&&x!==18;if(room==='street')return y<5||x<4&&y<11||x>19&&y<11;return false;}
function fixed(room,x,y){return room==='restaurant'&&((x===16||x===17)&&y===11||x>=20&&x<=22&&y===11);}
function blocked(s,room,x,y,a=null,objects=s.objects){if(wall(room,x,y)||fixed(room,x,y))return true;return objects.some(o=>o.room===room&&hit(o,x,y)&&!(o.type==='chair'&&a&&a.seat===o.id));}
function near(a,p,r=1){return a.room===p.room&&Math.abs(a.x-p.x)+Math.abs(a.y-p.y)<=r;}
function allActors(s){return [s.player,...s.workers,...s.residents,...s.customers.filter(c=>!c.done)];}
const NAV=DIRS.concat([[1,-1],[1,1],[-1,1],[-1,-1]]),WALK_TIME=.18;
function route(s,room,from,to,a=null,avoid=new Set(),objects=s.objects){
 if(blocked(s,room,to.x,to.y,a,objects))return null;
 let q=[{x:from.x,y:from.y,cost:0}],cost=new Map([[key(from),0]]),prev=new Map([[key(from),null]]),end=null;
 while(q.length){q.sort((p,q)=>(p.cost+Math.hypot(to.x-p.x,to.y-p.y))-(q.cost+Math.hypot(to.x-q.x,to.y-q.y)));let p=q.shift();if(p.cost>cost.get(key(p)))continue;if(p.x===to.x&&p.y===to.y){end=p;break}
  for(const [dx,dy]of NAV){let n={x:p.x+dx,y:p.y+dy},k=key(n);if(avoid.has(k)||blocked(s,room,n.x,n.y,a,objects))continue;
   if(dx&&dy&&([{x:p.x+dx,y:p.y},{x:p.x,y:p.y+dy}].some(c=>avoid.has(key(c))||blocked(s,room,c.x,c.y,a,objects))))continue;
   let next=p.cost+Math.hypot(dx,dy);if(next>=(cost.get(k)??Infinity))continue;cost.set(k,next);prev.set(k,p);q.push({...n,cost:next});
  }
 }
 if(!end)return null;let out=[];while(prev.get(key(end))){out.unshift({x:end.x,y:end.y});end=prev.get(key(end))}return out;
}
function position(a){if(a.motion){let m=a.motion,t=Math.min(1,m.elapsed/m.duration);return {x:m.fromX+(m.toX-m.fromX)*t,y:m.fromY+(m.toY-m.fromY)*t}}let p=a.settled;return p&&p.room===a.room&&p.x===a.x&&p.y===a.y?{x:p.px,y:p.py}:{x:a.x,y:a.y};}
function startMotion(a,to,offsetX=0,offsetY=0){let p=position(a),x=to.x+offsetX,y=to.y+offsetY,d=Math.hypot(x-p.x,y-p.y);if(d<1e-7)return false;a.motion={fromX:p.x,fromY:p.y,toX:x,toY:y,x:to.x,y:to.y,elapsed:0,duration:d*WALK_TIME};return true;}
function advanceMotion(a,dt){let m=a.motion;if(!m)return dt;let used=Math.min(dt,m.duration-m.elapsed);m.elapsed+=used;if(m.elapsed>=m.duration-1e-8){a.x=m.x;a.y=m.y;a.settled={room:a.room,x:a.x,y:a.y,px:m.toX,py:m.toY};a.motion=null;}return Math.max(0,dt-used);}
function reserved(a){let out=[{x:a.x,y:a.y}];if(a.motion){out.push({x:a.motion.x,y:a.motion.y});if(a.motion.x!==a.x&&a.motion.y!==a.y)out.push({x:a.motion.x,y:a.y},{x:a.x,y:a.motion.y})}return out.filter((p,i)=>out.findIndex(q=>q.x===p.x&&q.y===p.y)===i);}
function accessPoints(s,o,objects=s.objects){let r=rect(o),ps=[];for(let y=r.y-1;y<=r.y+r.h;y++)for(let x=r.x-1;x<=r.x+r.w;x++){if((x===r.x-1||x===r.x+r.w)&&(y>=r.y&&y<r.y+r.h)||(y===r.y-1||y===r.y+r.h)&&(x>=r.x&&x<r.x+r.w)){if(!blocked(s,o.room,x,y,null,objects))ps.push({room:o.room,x,y})}}return ps;}
function closestAccess(s,a,o){let ps=accessPoints(s,o);if(a.room!==o.room)return ps[0]||null;return ps.map(p=>({p,path:route(s,a.room,a,p,a)})).filter(v=>v.path).sort((a,b)=>a.path.length-b.path.length)[0]?.p||null;}
function goObject(s,a,o){let p=closestAccess(s,a,o);if(!p)return false;a.goal=p;return true;}
function go(a,p){a.goal={room:p.room||a.room,x:p.x,y:p.y};if(Number.isFinite(p.offsetX)&&Number.isFinite(p.offsetY)){a.goal.offsetX=Math.max(-.25,Math.min(.25,p.offsetX));a.goal.offsetY=Math.max(-.25,Math.min(.25,p.offsetY))}}
function arrived(a){return a.goal&&!a.motion&&near(a,a.goal,0)&&Math.hypot(position(a).x-a.goal.x-(a.goal.offsetX||0),position(a).y-a.goal.y-(a.goal.offsetY||0))<1e-6;}
function occupants(s,a){return new Set(allActors(s).filter(b=>b!==a&&b.room===a.room).flatMap(b=>reserved(b).map(key)));}
function goalInRoom(a){if(!a.goal)return null;if(a.goal.room===a.room)return a.goal;return PORTALS[a.room].find(p=>p.to===a.goal.room)||PORTALS[a.room][0];}
function pushAside(s,b,requester,locked,seen=new Set()){
 if(b.motion||b.id==='player'||seen.has(b.id)||seen.size>8)return false;seen.add(b.id);
 let opts=DIRS.map(([dx,dy])=>({x:b.x+dx,y:b.y+dy})).filter(p=>!blocked(s,b.room,p.x,p.y,b)&&!locked.has(b.room+':'+key(p))&&!near(requester,{...p,room:b.room},0));
 opts.sort((p,q)=>{const score=v=>DIRS.filter(([dx,dy])=>!blocked(s,b.room,v.x+dx,v.y+dy)).length*10+Math.abs(v.x-requester.x)+Math.abs(v.y-requester.y);return score(q)-score(p)});
 for(const p of opts){let other=allActors(s).find(c=>c!==b&&c.room===b.room&&reserved(c).some(q=>q.x===p.x&&q.y===p.y));if(other&&!pushAside(s,other,b,locked,seen))continue;locked.add(b.room+':'+key(b));startMotion(b,p);b.hold=s.time+1.2;return true}return false;
}
function moveActors(s,dt=WALK_TIME){
 const locked=new Set();
 for(const a of allActors(s)){
  let budget=dt;
  if(a.motion){let before={room:a.room,x:a.x,y:a.y};budget=advanceMotion(a,budget);if(!a.motion)locked.add(before.room+':'+key(before));if(a.motion||budget<1e-8)continue;}
  if(!a.goal||a.hold>s.time)continue;let g=goalInRoom(a);if(!g)continue;
  if(a.x===g.x&&a.y===g.y){
   if(a.goal.room!==a.room){let dest=PORTALS[a.room].find(p=>p.x===g.x&&p.y===g.y),[x,y]=dest.spawn;if(!allActors(s).some(b=>b!==a&&b.room===dest.to&&reserved(b).some(p=>p.x===x&&p.y===y))){locked.add(a.room+':'+key(a));a.room=dest.to;a.x=x;a.y=y;a.settled=null;}}
   else {a.wait=0;if(startMotion(a,g,a.goal.offsetX||0,a.goal.offsetY||0))advanceMotion(a,budget);}
   continue;
  }
  let avoid=occupants(s,a);for(const k of locked)if(k.startsWith(a.room+':'))avoid.add(k.split(':')[1]);const unavailable=new Set(avoid);avoid.delete(key(g));let path=route(s,a.room,a,g,a,avoid);if(path?.length&&unavailable.has(key(path[0])))path=null;
  if(!path?.length){const fallback=route(s,a.room,a,g,a),n=fallback?.[0];if(n&&!unavailable.has(key(n))&&(!(n.x!==a.x&&n.y!==a.y)||![{x:n.x,y:a.y},{x:a.x,y:n.y}].some(p=>unavailable.has(key(p)))))path=fallback;}
  if(!path?.length){a.wait+=dt/WALK_TIME;s.flowWaits++;let staticPath=route(s,a.room,a,g,a);if(a.wait>=5&&staticPath?.length){let n=staticPath[0],b=allActors(s).find(b=>b!==a&&b.room===a.room&&reserved(b).some(p=>p.x===n.x&&p.y===n.y));if(b&&b.state!=='waiting'&&b.state!=='eating')pushAside(s,b,a,locked)}continue;}
  let n=path[0],final=a.goal.room===a.room&&n.x===g.x&&n.y===g.y;locked.add(a.room+':'+key(a));startMotion(a,n,final?(a.goal.offsetX||0):0,final?(a.goal.offsetY||0):0);advanceMotion(a,budget);a.wait=0;
 }
}
function editError(s){return s.open||s.customers.length||s.orders.some(o=>!['paid','lost'].includes(o.state))?'Feche o serviço e conclua os clientes antes de reorganizar.':null;}
function layoutError(s,objects){let occupied=new Set();for(const o of objects){if(!CATALOG[o.type]||o.room!==CATALOG[o.type].room)return 'Objeto fora do setor permitido.';for(const p of cells(o)){if(wall(o.room,p.x,p.y)||fixed(o.room,p.x,p.y)||PORTALS[o.room].some(d=>Math.abs(d.x-p.x)+Math.abs(d.y-p.y)<=1))return 'Parede, porta ou infraestrutura reservada.';if(o.room==='restaurant'&&((CATALOG[o.type].area==='hall'&&p.x>=14)||(CATALOG[o.type].area==='kitchen'&&(p.x<=14||p.y>=10))||(CATALOG[o.type].area==='storage'&&(p.x<=14||p.y<=10))||(CATALOG[o.type].area==='dryStorage'&&p.x<=14)))return 'Mesas e cadeiras: salão. Fogão e geladeira de cozinha: cozinha. Prateleira: cozinha ou estoque. Geladeira de estoque: estoque.';let k=o.room+':'+key(p);if(occupied.has(k))return 'Esta célula já está ocupada.';occupied.add(k);if(allActors(s).some(a=>a.room===o.room&&reserved(a).some(q=>q.x===p.x&&q.y===p.y)))return 'Há uma pessoa nesta posição.';}}
 for(const room of ['restaurant']){let start=room==='stock'?{x:21,y:13}:{x:7,y:13};for(const d of PORTALS[room])if(!route(s,room,start,d,null,new Set(),objects))return 'A disposição bloqueia uma porta.';for(const o of objects.filter(o=>o.room===room)){let access=accessPoints(s,o,objects);if(!access.some(p=>route(s,room,start,p,null,new Set(),objects)))return 'Deixe uma passagem até cada móvel.';}}
 return null;}
function place(s,type,x,y,rot=0,moving=null){let error=editError(s);if(error)return {ok:false,error};let d=CATALOG[type];if(!d)return {ok:false,error:'Objeto desconhecido.'};if(!Number.isInteger(x)||!Number.isInteger(y)||!Number.isInteger(rot))return {ok:false,error:'Posição inválida.'};let old=moving?s.objects.find(o=>o.id===moving):null;if(moving&&(!old||old.type!==type))return {ok:false,error:'Objeto não encontrado.'};if(old&&(s.dirtyTables[old.id]||old.type==='table'&&s.objects.some(c=>c.type==='chair'&&seatTable(s,c)?.id===old.id&&s.dirtyTables[c.id])))return {ok:false,error:'Recolha os pratos sujos antes de mover.'};let o={id:old?.id||s.serial,type,x,y,rot:((rot%4)+4)%4,room:d.room,...(['shelf','cold','stove','fridge','prep','sink','bin'].includes(type)?{inventory:old?.inventory||Array(10).fill(null)}:{})};let objects=s.objects.filter(q=>q.id!==moving).concat(o);error=layoutError(s,objects);if(error)return {ok:false,error};if(!old&&s.cash<d.price)return {ok:false,error:'Dinheiro insuficiente.'};if(!old){s.cash-=d.price;s.ledger.investment+=d.price;s.serial++}s.objects=objects;syncContainers(s);return {ok:true,object:o};}
function remove(s,id){let error=editError(s);if(error)return {ok:false,error};let o=s.objects.find(o=>o.id===id);if(!o)return {ok:false,error:'Objeto não encontrado.'};if(o.type==='table'&&s.objects.some(c=>c.type==='chair'&&seatTable(s,c)?.id===o.id&&s.dirtyTables[c.id]))return {ok:false,error:'Recolha os pratos sujos antes de guardar a mesa.'};if(o.inventory?.some(Boolean)||s.dirtyTables[o.id])return {ok:false,error:'Esvazie o inventário deste objeto antes de guardar.'};s.objects=s.objects.filter(o=>o.id!==id);s.cash+=CATALOG[o.type].price;s.ledger.investment-=CATALOG[o.type].price;return {ok:true};}
function seatTable(s,chair){let [dx,dy]=DIRS[chair.rot%4];return s.objects.find(o=>o.room==='restaurant'&&o.type==='table'&&hit(o,chair.x+dx,chair.y+dy));}
function seats(s){return s.objects.filter(o=>o.type==='chair'&&seatTable(s,o)&&route(s,'restaurant',{x:7,y:13},o,{seat:o.id}));}
function kit(s){let a=[];if(!seats(s).length)a.push('mesa com cadeira voltada para ela e caminho livre');for(const [t,n] of [['stove','fogão'],['fridge','geladeira na cozinha']])if(!s.objects.some(o=>o.type===t))a.push(n);if(!s.objects.some(o=>o.type==='prep'))a.push('mesa de preparo');return a;}
const ITEMS={...FOODS,pot:{name:'Panela'},spoon:{name:'Colher / utensílio'},plate:{name:'Prato limpo'},dirtyPlate:{name:'Prato sujo'},cookingPot:{name:'Panela em preparo',limit:1}};
for(const [r,d]of Object.entries(RECIPES)){ITEMS['dish_'+r]={name:'Prato de '+d.name,recipe:r};for(let n=1;n<=4;n++)ITEMS['pot_'+r+'_'+n]={name:'Panela: '+d.name+' ('+n+'/4 porções)',recipe:r,servings:n,limit:1};}
function itemLimit(item){return ITEMS[item]?.limit||99;}
function itemName(item){return ITEMS[item]?.name||'Item desconhecido';}
function itemIcon(item){return FOODS[item]?{arroz:'🌾',legumes:'🥕',frango:'🍗'}[item]:item==='spoon'?'🥄':item==='plate'?'🍽️':item==='dirtyPlate'?'🧽':item.startsWith('dish_')?'🍛':item==='pot'?'🥘':'🍲';}
function inventoryCount(s,item){return s.inventory.reduce((n,slot)=>n+(slot?.item===item?slot.n:0),0);}
function inventorySpace(s,item){return s.inventory.reduce((n,slot)=>n+(!slot?itemLimit(item):slot.item===item?itemLimit(item)-slot.n:0),0);}
function addInventory(s,item,n){if(!ITEMS[item]||!Number.isInteger(n)||n<1||inventorySpace(s,item)<n)return false;let left=n;for(let i=0;i<10&&left;i++){let slot=s.inventory[i];if(slot?.item===item){let q=Math.min(left,itemLimit(item)-slot.n);slot.n+=q;left-=q;}}for(let i=0;i<10&&left;i++)if(!s.inventory[i]){let q=Math.min(left,itemLimit(item));s.inventory[i]={item,n:q};left-=q;}return true;}
function removeInventory(s,index,n){let slot=s.inventory[index];if(!slot||!Number.isInteger(n)||n<1||n>slot.n)return false;slot.n-=n;if(!slot.n)s.inventory[index]=null;return true;}
function buyTool(s,type){if(!['pot','spoon','plate'].includes(type))return false;let price={pot:25,spoon:15,plate:5}[type];if(s.cash<price||!addInventory(s,type,1))return false;s.cash-=price;s.ledger.investment+=price;s.equipment[type]++;if(type!=='plate')s.tools[type]=true;return true;}
function collectReceiving(s){if(s.player.motion||!near(s.player,{room:'restaurant',x:21,y:12},1))return 'Aproxime-se do recebimento.';let total=0;for(const food of Object.keys(FOODS)){let n=Math.min(s.inv.receiving[food],inventorySpace(s,food));if(n&&addInventory(s,food,n)){s.inv.receiving[food]-=n;total+=n;}}return total?'Recolheu '+total+' ingredientes. Abra o Inventário para selecionar uma pilha.':'Sem ingredientes disponíveis ou inventário cheio.';}
function objectLocation(o){if(o.type==='shelf')return o.y>10?'storage':'kitchen';return o.type==='cold'?'storage':'kitchen';}
function accepts(o,item){if(!ITEMS[item])return false;if(o.type==='stove')return !!FOODS[item]||['pot','spoon','cookingPot'].includes(item)||item.startsWith('pot_');if(o.type==='prep')return ['pot','plate','spoon'].includes(item)||item.startsWith('pot_')||item.startsWith('dish_');if(o.type==='sink')return ['pot','plate','dirtyPlate','spoon'].includes(item)||item.startsWith('pot_');if(o.type==='bin')return item==='pot'||item==='dirtyPlate'||item.startsWith('pot_')||item.startsWith('dish_');return !!FOODS[item]&&(o.type==='shelf'?FOODS[item].kind==='dry':['cold','fridge'].includes(o.type)&&FOODS[item].kind==='cold');}
function objectCount(o,food){return (o.inventory||[]).reduce((n,p)=>n+(p?.item===food?p.n:0),0);}
function objectSpace(o,food){return accepts(o,food)?inventorySpace({inventory:o.inventory},food):0;}
function syncContainers(s){for(const loc of ['storage','kitchen'])for(const food of Object.keys(FOODS))s.inv[loc][food]=s.objects.filter(o=>o.inventory&&objectLocation(o)===loc).reduce((n,o)=>n+objectCount(o,food),0);}
function putObject(s,o,food,n){let q=Math.min(n,objectSpace(o,food));if(q)addInventory({inventory:o.inventory},food,q);syncContainers(s);return q;}
function takeObject(s,o,food,n){let left=Math.min(n,objectCount(o,food)),total=left;for(let i=0;i<10&&left;i++){let slot=o.inventory[i];if(slot?.item===food){let q=Math.min(slot.n,left);removeInventory({inventory:o.inventory},i,q);left-=q;}}syncContainers(s);return total;}
function changeLocation(s,loc,food,n){if(loc==='receiving'){s.inv.receiving[food]+=n;return Math.abs(n);}let left=Math.abs(n);for(const o of s.objects.filter(o=>o.inventory&&objectLocation(o)===loc)){let q=n>0?putObject(s,o,food,left):takeObject(s,o,food,left);left-=q;if(!left)break;}return Math.abs(n)-left;}
function capacity(s,loc,food){if(loc==='receiving')return 60;return s.objects.filter(o=>o.inventory&&objectLocation(o)===loc&&accepts(o,food)).length*990;}
function amount(s,loc,food){if(loc==='receiving')return Object.values(s.inv.receiving).reduce((a,b)=>a+b,0);return s.objects.filter(o=>o.inventory&&objectLocation(o)===loc&&accepts(o,food)).reduce((n,o)=>n+o.inventory.reduce((a,p)=>a+(p?.n||0),0),0);}
function transfer(s,from,to,food,n){let q=Math.max(0,Math.min(Math.floor(n),s.inv[from][food],capacity(s,to,food)-amount(s,to,food)));changeLocation(s,from,food,-q);changeLocation(s,to,food,q);return q;}
function transferSlot(s,id,side,index,quantity=99){if(!Number.isInteger(quantity)||quantity<1||quantity>99)return {ok:false,error:'Escolha uma quantidade entre 1 e 99.'};let o=s.objects.find(o=>o.id===id);if(!o?.inventory||s.player.motion||!accessPoints(s,o).some(p=>near(s.player,p,0)))return {ok:false,error:'Aproxime-se do objeto para abrir seu inventário.'};if(!Number.isInteger(index)||index<0||index>9)return {ok:false,error:'Espaço inválido.'};
 if(side==='player'){let slot=s.inventory[index];if(!slot)return {ok:false,error:'Espaço vazio.'};if(slot.item==='cookingPot')return {ok:false,error:'Panela em preparo não pode ser movida.'};if(!accepts(o,slot.item))return {ok:false,error:'Este equipamento não armazena este item.'};let q=Math.min(quantity,slot.n,objectSpace(o,slot.item));if(!q)return {ok:false,error:'Inventário do objeto cheio.'};putObject(s,o,slot.item,q);removeInventory(s,index,q);return {ok:true,n:q};}
 if(side==='object'){let slot=o.inventory[index];if(slot?.item==='cookingPot')return {ok:false,error:'A panela está em preparo.'};if(!slot)return {ok:false,error:'Espaço vazio.'};let q=Math.min(quantity,slot.n,inventorySpace(s,slot.item));if(!q)return {ok:false,error:'Mochila cheia.'};addInventory(s,slot.item,q);removeInventory({inventory:o.inventory},index,q);syncContainers(s);return {ok:true,n:q};}return {ok:false,error:'Origem inválida.'};}
function purchase(s,food,n){if(!FOODS[food]||!Number.isInteger(n)||n<1||n>100)return false;let cost=FOODS[food].cost*n;if(s.cash<cost)return false;s.cash-=cost;s.ledger.purchases+=cost;s.purchased[food]+=n;s.deliveries.push({id:s.serial++,food,total:n,pending:n,received:0,eta:s.time+5});return true;}
function deliver(s){for(const o of s.deliveries){if(s.time<o.eta)continue;let q=Math.min(o.pending,60-amount(s,'receiving',o.food));s.inv.receiving[o.food]+=q;o.pending-=q;o.received+=q;}}
function storageObject(s,loc,food,mode=null){return s.objects.find(o=>o.inventory&&objectLocation(o)===loc&&accepts(o,food)&&(mode==='take'?objectCount(o,food)>0:mode==='put'?objectSpace(o,food)>0:true));}
function supplyAction(s,loc,food,deposit=false){if(loc==='receiving')return collectReceiving(s);let o=s.objects.find(o=>o.inventory&&objectLocation(o)===loc&&accepts(o,food)&&accessPoints(s,o).some(p=>near(s.player,p,0)));if(!o)return 'Aproxime-se do equipamento adequado.';let index=deposit?s.selectedSlot:o.inventory.findIndex(p=>p?.item===food);let r=transferSlot(s,o.id,deposit?'player':'object',index);return r.ok?'Transferiu '+r.n+' '+FOODS[food].name+'.':r.error;}
function kitchenEnough(s,r){return inventoryCount(s,'dish_'+r)>0||s.objects.some(o=>o.type==='stove'&&(!cookError(s,o,r)||o.inventory.some(p=>p?.item.startsWith('pot_'+r+'_'))))||s.objects.some(o=>o.type==='prep'&&o.inventory.some(p=>p&&(p.item.startsWith('pot_'+r+'_')||p.item==='dish_'+r)));}

function toggleOpen(s){if(s.clock.ending){s.message='Conclua o serviço pendente das 02:00 antes de reabrir.';return false;}if(s.closing)return false;if(s.open){s.closing=true;s.message='Entrada encerrada. Conclua os pedidos e deixe os clientes saírem.';return true}s.open=true;s.arrival=3;s.message=`${s.period===0?'Almoço':'Jantar'} aberto. Receba pedidos nas mesas, prepare e sirva.`;return true;}
function chooseRecipe(s){let ids=Object.keys(RECIPES).filter(r=>s.menu[r]);return ids[s.serial%ids.length];}
function spawn(s,rng=Math.random){if(s.clock.ending)return false;if(!Object.values(s.menu).some(Boolean)){s.ledger.lost++;return false}let free=seats(s).find(o=>!s.customers.some(c=>c.seat===o.id&&!c.done));if(!free){s.ledger.lost++;return false}let id=s.serial++,c={...actor('client'+id,'restaurant',7,13),seat:free.id,state:'walk',recipe:chooseRecipe(s),order:null,timer:0,experience:newExperience(rng)};if(allActors(s).some(a=>a.room===c.room&&a.x===c.x&&a.y===c.y))return false;c.goal={room:'restaurant',x:free.x,y:free.y};s.customers.push(c);return true;}
function atStove(s,a=s.player){if(a.motion)return false;return s.objects.filter(o=>o.type==='stove').some(o=>accessPoints(s,o).some(p=>near(a,p,0)));}
function readyPoint(s){let o=s.objects.find(o=>o.type==='prep'&&s.orders.some(q=>q.state==='ordered'&&objectCount(o,'dish_'+q.recipe)>0));return o?accessPoints(s,o)[0]:null;}
function interact(s,target){let a=s.player;if(a.motion){s.message='Aguarde o personagem se aproximar.';return false}let c=s.customers.find(c=>c.id===target);if(!c||!near(a,c,1)){s.message='Aproxime-se da mesa.';return false}if(expiredCustomer(s,c))return false;if(c.state==='waiting'){finishWait(c);let o={id:s.serial++,customer:c.id,recipe:c.recipe,state:'ordered',age:0,price:s.prices[c.recipe]};s.orders.push(o);c.order=o.id;c.state='ordered';beginWait(s,c,'food');s.message='Pedido anotado: '+RECIPES[c.recipe].name;return true}if(c.state==='ordered'){if(canceledCarry(s,a)&&s.orders.find(o=>o.id===a.carry.order).recipe===c.recipe){a.carry.order=c.order;s.orders.find(o=>o.id===c.order).state='ready';return serve(s,a,c);}if(a.carry?.kind==='dish'&&a.carry.order===c.order)return serve(s,a,c);if(a.carry){s.message='Entregue primeiro o prato que está na sua mão.';return false}let item='dish_'+c.recipe,i=s.inventory.findIndex(p=>p?.item===item);if(i>=0){removeInventory(s,i,1);s.orders.find(o=>o.id===c.order).state='ready';a.carry={kind:'dish',order:c.order};return serve(s,a,c);}}s.message='Emprate a receita pedida e traga o prato pronto.';return false;}
function pickupDish(s,a=s.player){if(canceledCarry(s,a))return returnCanceledDish(s,a);if(a.carry||a.motion)return false;const prep=s.objects.find(o=>o.type==='prep'&&accessPoints(s,o).some(p=>near(a,p,0))&&s.orders.some(q=>q.state==='ordered'&&objectCount(o,'dish_'+q.recipe)>0));if(!prep)return false;const o=s.orders.find(q=>q.state==='ordered'&&objectCount(prep,'dish_'+q.recipe)>0);takeObject(s,prep,'dish_'+o.recipe,1);o.state='ready';a.carry={kind:'dish',order:o.id};return true;}
function serve(s,a,c){if(a.motion||!c||c.state!=='ordered'||expiredCustomer(s,c)||!near(a,c,1))return false;let o=s.orders.find(o=>o.id===c.order);if(!o||o.state!=='ready'||a.carry?.order!==o.id)return false;finishWait(c);c.experience.satisfaction=c.experience.legacy?null:satisfactionFor(c.experience);c.experience.indicatorUntil=s.time+CUSTOMER_CONFIG.indicators.happySeconds;refreshCustomerVisual(s,c);o.state='eating';c.state='eating';c.timer=4;a.carry=null;s.message='Prato servido. O cliente paga depois de comer.';return true;}
function mealCost(r){return Object.entries(RECIPES[r].foods).reduce((n,[p,q])=>n+q*FOODS[p].cost,0);}
function kitchenStep(s,dt){if(!s.cooking)return;let o=s.objects.find(o=>o.id===s.cooking.stove),slot=o?.inventory[s.cooking.slot];if(!o||slot?.item!=='cookingPot')return;if(!objectNear(s,o)||!objectCount(o,'spoon'))return;s.cooking.left=Math.max(0,s.cooking.left-dt);if(!s.cooking.left){slot.item='pot_'+s.cooking.recipe+'_4';s.meals.made[s.cooking.recipe]+=4;s.cooking=null;s.cookActive=false;s.message='Panela pronta: 4 porções. Leve-a à mesa de preparo com pratos e colher.';}}
function workerStep(s,w){if(w.task==='none'&&!w.carry){w.goal=null;return}if(w.task==='waiter'&&!w.carry||w.carry?.kind==='dish'){if(w.carry?.kind==='dish'){if(canceledCarry(s,w)){const order=s.orders.find(o=>o.id===w.carry.order),prep=s.objects.find(o=>o.type==='prep'&&objectSpace(o,'dish_'+order.recipe)>0);if(prep){goObject(s,w,prep);returnCanceledDish(s,w);}else w.goal=null;return;}let c=s.customers.find(c=>c.order===w.carry.order);if(!c){w.goal=null;return}let points=DIRS.map(([dx,dy])=>({room:c.room,x:c.x+dx,y:c.y+dy})).filter(p=>!blocked(s,p.room,p.x,p.y,w));let p=points[0];if(!p)return;go(w,p);if(near(w,c,1))serve(s,w,c);return}if(w.carry)return;{let p=readyPoint(s);if(p){go(w,p);if(arrived(w))pickupDish(s,w)}else w.goal=null;}return}
 if(w.carry?.kind==='food'){let loc=w.carry.to,o=storageObject(s,loc,w.carry.food,'put');if(!o){w.goal=null;return}goObject(s,w,o);if(arrived(w)){let q=Math.min(w.carry.n,objectSpace(o,w.carry.food));putObject(s,o,w.carry.food,q);w.carry.n-=q;if(!w.carry.n)w.carry=null}return}
 for(const [from,to]of [['storage','kitchen'],['receiving','storage']]){let food=Object.keys(FOODS).find(p=>s.inv[from][p]>0&&storageObject(s,to,p,'put'));if(!food)continue;let source=from==='receiving'?null:storageObject(s,from,food,'take');let p=from==='receiving'?{room:'restaurant',x:21,y:12}:closestAccess(s,w,source);if(!p)continue;go(w,p);if(arrived(w)){let n=Math.min(4,source?objectCount(source,food):s.inv[from][food],capacity(s,to,food)-amount(s,to,food));if(source)takeObject(s,source,food,n);else changeLocation(s,from,food,-n);w.carry={kind:'food',food,n,to}}return}w.goal=null;}
function finishPeriod(s){s.open=false;s.closing=false;s.cookActive=false;s.period=s.period===0?1:0;s.message=s.period===1?'Almoço concluído. Intervalo antes do jantar.':'Jantar concluído. A data e o relatório diário mudam ao terminar o dia do calendário.';}
function simulate(s,dt,rng){patienceStep(s,dt,rng);deliver(s);s.tick=(s.tick+dt)%WALK_TIME;moveActors(s,dt);for(const w of s.workers)workerStep(s,w);kitchenStep(s,dt);for(const o of s.orders)if(!['paid','lost'].includes(o.state))o.age+=dt;for(const c of s.customers){if(c.state==='walk'&&arrived(c)){c.state='waiting';c.goal=null;beginWait(s,c,'service');}if(c.state==='eating'){c.timer-=dt;if(c.timer<=0){let o=s.orders.find(o=>o.id===c.order);o.state='paid';finalizeVisit(s,c,'completed',rng);s.meals.eaten[o.recipe]++;s.dirtyTables[c.seat]=(s.dirtyTables[c.seat]||0)+1;s.cash+=o.price;s.ledger.revenue+=o.price;s.ledger.sales++;c.state='leave';go(c,{room:'restaurant',x:7,y:14});s.message='Pagamento recebido: $'+o.price.toFixed(2);}}if(c.state==='leave'&&arrived(c)){c.done=true;}}s.customers=s.customers.filter(c=>!c.done);if(s.open&&!s.closing){s.arrival+=dt;if(s.arrival>=12){s.arrival=0;spawn(s,rng)}}if(s.closing&&!s.customers.length&&!s.cooking&&!s.ready.length&&!allActors(s).some(a=>a.carry?.kind==='dish'&&!canceledCarry(s,a)))finishPeriod(s);}
function step(s,dt,rng=Math.random){
 if(!Number.isFinite(dt)||dt<=0)return;
 let remaining=dt;
 while(remaining>1e-9){
  const slice=s.clock.ending?remaining:Math.min(remaining,TIME_CONFIG.secondsPerBlock-s.clock.remainder);
  s.time+=slice;advanceClock(s,slice);simulate(s,slice,rng);remaining=Math.max(0,remaining-slice);finishCalendarDay(s);
 }
}
function foodConserved(s){return Object.keys(FOODS).every(p=>Object.values(s.inv).reduce((n,loc)=>n+loc[p],0)+s.deliveries.filter(o=>o.food===p).reduce((n,o)=>n+o.pending,0)+allActors(s).reduce((n,a)=>n+(a.carry?.kind==='food'&&a.carry.food===p?a.carry.n:0),0)+inventoryCount(s,p)+s.used[p]===s.purchased[p]);}
function valid(s){try{if(!validExperience(s)||!validTimeReputation(s))return false;for(const o of s.objects.filter(o=>['shelf','cold','fridge','stove','prep','sink','bin'].includes(o.type))){if(!Array.isArray(o.inventory)||o.inventory.length!==10||o.inventory.some(p=>p!==null&&(!accepts(o,p.item)||!Number.isInteger(p.n)||p.n<1||p.n>itemLimit(p.item))))return false;}for(const loc of ['storage','kitchen'])for(const p of Object.keys(FOODS))if(s.inv[loc][p]!==s.objects.filter(o=>o.inventory&&objectLocation(o)===loc).reduce((n,o)=>n+objectCount(o,p),0))return false;if(!Array.isArray(s.inventory)||s.inventory.length!==10||!Number.isInteger(s.selectedSlot)||s.selectedSlot<0||s.selectedSlot>9||s.inventory.some(slot=>slot!==null&&(!ITEMS[slot.item]||!Number.isInteger(slot.n)||slot.n<1||slot.n>itemLimit(slot.item))))return false;let reservations=new Map();for(const a of allActors(s))for(const p of reserved(a)){let k=a.room+':'+key(p);if(reservations.has(k)&&reservations.get(k)!==a.id)return false;reservations.set(k,a.id)}if(!Number.isInteger(s.serial)||s.serial<1||typeof s.open!=='boolean'||typeof s.closing!=='boolean'||!Number.isFinite(s.tick)||!Number.isFinite(s.arrival)||!s.tools||typeof s.tools.pot!=='boolean'||typeof s.tools.spoon!=='boolean'||!Array.isArray(s.residents)||s.residents.length!==3||!Array.isArray(s.ready)||!Array.isArray(s.reports))return false;for(const v of Object.values(s.ledger))if(!Number.isFinite(v))return false;for(const k of ['lia','beto','nina'])if(!Number.isInteger(s.friends[k])||s.friends[k]<0)return false;for(const w of s.workers)if(!['none','logistics','waiter'].includes(w.task))return false;let orderIds=new Set();for(const o of s.orders){if(!Number.isInteger(o.id)||orderIds.has(o.id)||!RECIPES[o.recipe]||!['ordered','cooking','ready','eating','paid','lost'].includes(o.state)||!Number.isFinite(o.price)||o.price<1||!Number.isFinite(o.age)||o.age<0)return false;orderIds.add(o.id)}if(new Set(s.ready).size!==s.ready.length||s.ready.some(id=>!s.orders.some(o=>o.id===id&&o.state==='ready')))return false;if(s.cooking&&(!RECIPES[s.cooking.recipe]||!s.objects.some(o=>o.id===s.cooking.stove&&o.type==='stove'&&o.inventory[s.cooking.slot]?.item==='cookingPot')||!Number.isFinite(s.cooking.left)||s.cooking.left<0))return false;for(const c of s.customers)if(!RECIPES[c.recipe]||!['walk','waiting','ordered','eating','leave'].includes(c.state)||!s.objects.some(o=>o.id===c.seat&&o.type==='chair')||c.order!==null&&!s.orders.some(o=>o.id===c.order&&o.customer===c.id))return false;if(s.version!==VERSION||!Number.isFinite(s.cash)||!Number.isInteger(s.day)||s.day<1||![0,1].includes(s.period)||!Number.isFinite(s.time)||!Array.isArray(s.objects)||s.objects.length>180||!Array.isArray(s.orders)||s.orders.length>5000||!Array.isArray(s.customers)||s.customers.length>50||s.workers.length!==2)return false;let ids=new Set();for(const o of s.objects){if(!CATALOG[o.type]||!Number.isInteger(o.id)||ids.has(o.id)||!Number.isInteger(o.x)||!Number.isInteger(o.y)||!Number.isInteger(o.rot)||o.rot<0||o.rot>3||o.room!==CATALOG[o.type].room)return false;ids.add(o.id);for(const p of cells(o))if(wall(o.room,p.x,p.y)||fixed(o.room,p.x,p.y))return false}let occupied=new Set();for(const o of s.objects)for(const p of cells(o)){let k=o.room+':'+key(p);if(occupied.has(k))return false;occupied.add(k)}let persons=new Set();for(const a of allActors(s)){if(!PORTALS[a.room]||!Number.isInteger(a.x)||!Number.isInteger(a.y)||a.x<1||a.x>=W-1||a.y<1||a.y>=H-1||blocked(s,a.room,a.x,a.y,a))return false;if(a.goal&&(!PORTALS[a.goal.room]||!Number.isInteger(a.goal.x)||!Number.isInteger(a.goal.y)||a.goal.x<1||a.goal.x>=W-1||a.goal.y<1||a.goal.y>=H-1))return false;if(a.motion){let m=a.motion;if(!['fromX','fromY','toX','toY','duration','elapsed','x','y'].every(k=>Number.isFinite(m[k]))||m.duration<=0||m.duration>WALK_TIME*3||m.elapsed<0||m.elapsed>=m.duration||!Number.isInteger(m.x)||!Number.isInteger(m.y)||Math.abs(m.x-a.x)>1||Math.abs(m.y-a.y)>1||Math.abs(m.toX-m.x)>.25||Math.abs(m.toY-m.y)>.25||blocked(s,a.room,m.x,m.y,a))return false;}if(a.settled&&!['x','y','px','py'].every(k=>Number.isFinite(a.settled[k])))return false;if(a.goal&&['offsetX','offsetY'].some(k=>a.goal[k]!==undefined&&(!Number.isFinite(a.goal[k])||Math.abs(a.goal[k])>.25)))return false;if(!Number.isFinite(a.hold)||!Number.isFinite(a.wait))return false;if(a.carry&&!['food','dish'].includes(a.carry.kind))return false;if(a.carry?.kind==='dish'&&!s.orders.some(o=>o.id===a.carry.order&&['ready','lost'].includes(o.state)))return false;let k=a.room+':'+key(a);if(persons.has(k))return false;persons.add(k);if(a.carry&&a.carry.kind==='food'&&(!FOODS[a.carry.food]||!Number.isInteger(a.carry.n)||a.carry.n<1))return false;}for(const loc of Object.keys(s.inv))for(const p of Object.keys(FOODS))if(!Number.isInteger(s.inv[loc][p])||s.inv[loc][p]<0||amount(s,loc,p)>capacity(s,loc,p))return false;for(const o of s.deliveries)if(!FOODS[o.food]||!Number.isInteger(o.total)||o.total<1||o.pending<0||o.received<0||o.total!==o.pending+o.received||!Number.isFinite(o.eta))return false;for(const p of Object.keys(FOODS))if(!Number.isInteger(s.purchased[p])||!Number.isInteger(s.used[p])||s.purchased[p]<0||s.used[p]<0)return false;for(const r of Object.keys(RECIPES))if(!Number.isFinite(s.prices[r])||s.prices[r]<1||s.prices[r]>100||typeof s.menu[r]!=='boolean')return false;return foodConserved(s)&&equipmentConserved(s)&&mealsConserved(s);}catch{return false}}
function talk(s,id){if(!['lia','beto','nina'].includes(id))return '';const p=s.residents.find(a=>a.id===id);if(!near(s.player,{room:'street',...p},1))return 'Aproxime-se para conversar.';let k=s.day+':'+id;if(!s.talked[k]){s.friends[id]++;s.talked[k]=true}return {lia:'Lia • agricultora: "Estou testando legumes para os restaurantes do bairro. Prepare sua cozinha antes de abrir!"',beto:'Beto • cozinheiro: "Uma panela e um utensílio já rendem os primeiros pratos. Duas mesas não ajudam quando o fogão é o gargalo."',nina:'Nina • moradora: "Gosto de uma sopa no jantar. Deixe um corredor livre: ninguém quer esbarrar no garçom."'}[id]+' Vínculo: '+s.friends[id]+'. Conversas demonstrativas; desbloqueios e economia social ainda pendentes.';}
function objectNear(s,o,a=s.player){return !!o&&!a.motion&&o.room===a.room&&accessPoints(s,o).some(p=>near(a,p,0));}
function result(s,ok,message){s.message=message;return {ok,error:ok?null:message,message};}
function cookError(s,o,recipe){if(!o||o.type!=='stove'||!RECIPES[recipe])return 'Selecione um fogão e uma receita válida.';if(s.cooking)return 'Há uma panela em preparo. Conclua o lote atual.';if(!objectCount(o,'pot'))return 'Coloque uma panela vazia no inventário deste fogão.';if(!objectCount(o,'spoon'))return 'Coloque uma colher no inventário deste fogão.';const missing=Object.entries(RECIPES[recipe].foods).filter(([p,n])=>objectCount(o,p)<n*4).map(([p,n])=>n*4+' '+FOODS[p].name);return missing.length?'Faltam ingredientes no fogão para 4 porções: '+missing.join(', ')+'.':null;}
function startCook(s,id,recipe){let o=s.objects.find(o=>o.id===id);if(!objectNear(s,o))return result(s,false,'Aproxime-se do fogão.');let err=cookError(s,o,recipe);if(err)return result(s,false,err);let next={inventory:o.inventory.map(p=>p?{...p}:null)},i=next.inventory.findIndex(p=>p?.item==='pot');removeInventory(next,i,1);if(!addInventory(next,'cookingPot',1))return result(s,false,'Deixe um espaço para a panela em preparo.');for(const [p,n]of Object.entries(RECIPES[recipe].foods)){let left=n*4;for(let j=0;j<10&&left;j++)if(next.inventory[j]?.item===p){let q=Math.min(left,next.inventory[j].n);removeInventory(next,j,q);left-=q;}}
 o.inventory=next.inventory;for(const [p,n]of Object.entries(RECIPES[recipe].foods))s.used[p]+=n*4;s.ledger.foodCost+=mealCost(recipe)*4;s.cooking={stove:id,slot:o.inventory.findIndex(p=>p?.item==='cookingPot'),recipe,left:RECIPES[recipe].time};s.cookActive=true;syncContainers(s);return result(s,true,'Preparando 4 porções. Permaneça perto do fogão para avançar.');}
function plateFood(s,id,recipe){let o=s.objects.find(o=>o.id===id);if(o?.type!=='prep'||!objectNear(s,o))return result(s,false,'Aproxime-se da mesa de preparo.');if(!objectCount(o,'spoon'))return result(s,false,'Coloque uma colher na mesa de preparo.');let i=o.inventory.findIndex(p=>p&&ITEMS[p.item]?.recipe===recipe&&p.item.startsWith('pot_'));if(i<0||!objectCount(o,'plate'))return result(s,false,'Coloque uma panela com essa comida e pratos limpos na mesa.');
 let portions=ITEMS[o.inventory[i].item].servings,count=Math.min(portions,objectCount(o,'plate'));for(let n=count;n>=1;n--){let next={inventory:o.inventory.map(p=>p?{...p}:null)},left=n;for(let j=0;j<10&&left;j++)if(next.inventory[j]?.item==='plate'){let q=Math.min(left,next.inventory[j].n);removeInventory(next,j,q);left-=q;}next.inventory[i]=null;if(!addInventory(next,portions===n?'pot':'pot_'+recipe+'_'+(portions-n),1)||!addInventory(next,'dish_'+recipe,n))continue;o.inventory=next.inventory;syncContainers(s);return result(s,true,n+' prato(s) empratado(s). '+(portions===n?'A panela ficou vazia.':(portions-n)+' porções continuam na panela.'));}return result(s,false,'Inventário da mesa cheio. Libere espaço para os pratos prontos.');}
function discardFood(s,id,index){let o=s.objects.find(o=>o.id===id);if(!['sink','bin'].includes(o?.type)||!objectNear(s,o))return result(s,false,'Aproxime-se da pia ou do lixo.');let p=o.inventory[index],d=ITEMS[p?.item];if(!p||!(p.item.startsWith('pot_')||p.item.startsWith('dish_')))return result(s,false,'Coloque a panela com comida ou o prato pronto neste objeto.');let next={inventory:o.inventory.map(p=>p?{...p}:null)};removeInventory(next,index,1);if(!addInventory(next,p.item.startsWith('pot_')?'pot':'dirtyPlate',1))return result(s,false,'Libere espaço para devolver a panela ou o prato.');o.inventory=next.inventory;s.meals.wasted[d.recipe]+=d.servings||1;syncContainers(s);return result(s,true,'Comida descartada. '+(d.servings?'A panela está vazia e pode ser usada novamente.':'O prato ficou sujo.'));}
function washPlates(s,id){let o=s.objects.find(o=>o.id===id);if(o?.type!=='sink'||!objectNear(s,o))return result(s,false,'Aproxime-se da pia.');let n=objectCount(o,'dirtyPlate');if(!n)return result(s,false,'Coloque pratos sujos no inventário da pia.');let next={inventory:o.inventory.map(p=>p?{...p}:null)};next.inventory=next.inventory.map(p=>p?.item==='dirtyPlate'?null:p);if(!addInventory(next,'plate',n))return result(s,false,'Libere espaço na pia para os pratos limpos.');o.inventory=next.inventory;return result(s,true,n+' prato(s) lavado(s). Retire os pratos limpos da pia.');}
function collectDirty(s,id){let table=s.objects.find(o=>o.id===id);if(table?.type!=='table'||!objectNear(s,table))return result(s,false,'Aproxime-se da mesa.');let count=0;for(const c of s.objects.filter(o=>o.type==='chair'&&seatTable(s,o)?.id===id)){let n=Math.min(s.dirtyTables[c.id]||0,inventorySpace(s,'dirtyPlate'));if(n){addInventory(s,'dirtyPlate',n);s.dirtyTables[c.id]-=n;count+=n;}}return result(s,!!count,count?count+' prato(s) sujo(s) recolhido(s). Leve à pia.':'Sem pratos sujos ou mochila cheia.');}
function equipmentConserved(s){let sums={pot:0,spoon:0,plate:0};for(const loc of [s.inventory,...s.objects.filter(o=>o.inventory).map(o=>o.inventory)])for(const p of loc.filter(Boolean)){if(p.item==='pot'||p.item==='cookingPot'||p.item.startsWith('pot_'))sums.pot+=p.n;else if(p.item==='spoon')sums.spoon+=p.n;else if(['plate','dirtyPlate'].includes(p.item)||p.item.startsWith('dish_'))sums.plate+=p.n;}sums.plate+=allActors(s).filter(a=>a.carry?.kind==='dish').length+s.customers.filter(c=>c.state==='eating').length;for(const [id,n]of Object.entries(s.dirtyTables)){if(!Number.isInteger(n)||n<0||!s.objects.some(o=>o.id===Number(id)&&o.type==='chair'))return false;sums.plate+=n;}return Object.keys(sums).every(k=>Number.isInteger(s.equipment[k])&&s.equipment[k]>=0&&sums[k]===s.equipment[k]);}
function mealsConserved(s){for(const r of Object.keys(RECIPES)){let n=0;for(const loc of [s.inventory,...s.objects.filter(o=>o.inventory).map(o=>o.inventory)])for(const p of loc.filter(Boolean))if(ITEMS[p.item]?.recipe===r)n+=p.n*(ITEMS[p.item].servings||1);for(const a of allActors(s))if(a.carry?.kind==='dish'&&s.orders.find(o=>o.id===a.carry.order)?.recipe===r)n++;n+=s.customers.filter(c=>c.state==='eating'&&c.recipe===r).length;for(const name of ['made','eaten','wasted'])if(!Number.isInteger(s.meals[name][r])||s.meals[name][r]<0)return false;if(n+s.meals.eaten[r]+s.meals.wasted[r]!==s.meals.made[r])return false;}const busy=s.objects.flatMap(o=>o.inventory||[]).filter(p=>p?.item==='cookingPot').reduce((n,p)=>n+p.n,0);return busy===(s.cooking?1:0)&&!s.inventory.some(p=>p?.item==='cookingPot');}

const api={TIME_CONFIG,REPUTATION_CONFIG,calendarDate,clockText,reputationLevel,applyVisitReputation,servicePending,CUSTOMER_CONFIG,newExperience,customerIndicator,satisfactionFor,canceledCarry,migrateSave,serve,furnishedTest,clearTestScene,itemLimit,itemName,itemIcon,objectNear,cookError,startCook,plateFood,discardFood,washPlates,collectDirty,equipmentConserved,mealsConserved,objectLocation,accepts,objectCount,objectSpace,syncContainers,putObject,takeObject,transferSlot,ITEMS,inventoryCount,inventorySpace,addInventory,removeInventory,collectReceiving,storageObject,W,H,CELL,VERSION,NAV,WALK_TIME,position,reserved,FOODS,CATALOG,RECIPES,PORTALS,DIRS,key,actor,fresh,rect,cells,hit,wall,fixed,blocked,near,allActors,route,accessPoints,closestAccess,goObject,go,arrived,moveActors,pushAside,place,remove,layoutError,seats,kit,buyTool,capacity,amount,transfer,purchase,deliver,supplyAction,toggleOpen,spawn,interact,pickupDish,atStove,kitchenEnough,step,foodConserved,valid,talk,mealCost};root.Restaurant=api;if(typeof module!=='undefined')module.exports=api;
})(typeof globalThis!=='undefined'?globalThis:this);

/* Entre Esquinas Restaurante 0.17.0. Parâmetros abaixo são hipóteses de protótipo. */
(function(root){
'use strict';
const W=24,H=16,CELL=40,VERSION=12;
const FOODS={arroz:{name:'Arroz',cost:2,kind:'dry'},legumes:{name:'Legumes',cost:2,kind:'cold'},frango:{name:'Frango',cost:4,kind:'cold'}};
const CATALOG={table:{name:'Mesa',price:45,w:2,h:1,room:'restaurant',area:'hall',color:'#ba8654'},chair:{name:'Cadeira',price:15,w:1,h:1,room:'restaurant',area:'hall',color:'#d5ad70'},stove:{name:'Fogão',price:150,w:2,h:1,room:'restaurant',area:'kitchen',color:'#718d91'},fridge:{name:'Geladeira da cozinha',price:120,w:1,h:2,room:'restaurant',area:'kitchen',color:'#8dbdb5'},shelf:{name:'Prateleira seca',price:65,w:2,h:1,room:'restaurant',area:'dryStorage',color:'#b69969'},cold:{name:'Geladeira do estoque',price:140,w:1,h:2,room:'restaurant',area:'storage',color:'#91b6cb'}};
Object.assign(CATALOG,{potRack:{name:'Estante de panelas',price:65,w:2,h:1,room:'restaurant',area:'kitchen',color:'#a57b4c'},prep:{name:'Mesa de preparo • corte',price:90,w:2,h:1,room:'restaurant',area:'kitchen',color:'#bc955e'},kitchen:{name:'Mesa de cozinha',price:90,w:2,h:1,room:'restaurant',area:'kitchen',color:'#d1af79'},sink:{name:'Pia',price:70,w:2,h:1,room:'restaurant',area:'kitchen',color:'#82b8bb'},bin:{name:'Lixo',price:25,w:1,h:1,room:'restaurant',area:'dryStorage',color:'#71877a'}});
Object.assign(CATALOG,{computer:{name:'Computador',price:100,w:2,h:1,room:'restaurant',area:'utility',color:'#735b45'},receiving:{name:'Caixas de recebimento',price:40,w:2,h:1,room:'restaurant',area:'utility',color:'#a27a4b'}});
Object.assign(CATALOG,{counterH:{name:'Bancada horizontal',price:35,w:1,h:1,room:'restaurant',area:'utility',color:'#bd9360'},counterV:{name:'Bancada vertical',price:35,w:1,h:1,room:'restaurant',area:'utility',color:'#bd9360'},counterCorner:{name:'Bancada de canto',price:35,w:1,h:1,room:'restaurant',area:'utility',color:'#bd9360'}});
const RECIPES={arrozLegumes:{name:'Arroz com legumes',foods:{arroz:1,legumes:1},price:14,time:6},sopa:{name:'Sopa de legumes',foods:{legumes:2},price:12,time:5},frangoArroz:{name:'Frango com arroz',foods:{arroz:1,frango:1},price:20,time:8}};
const PORTALS={street:[{x:12,y:5,to:'restaurant',spawn:[7,13],name:'Entrar no restaurante'}],restaurant:[{x:7,y:14,to:'street',spawn:[12,6],name:'Sair para a cidade'}],stock:[{x:21,y:14,to:'restaurant',spawn:[21,13],name:'Voltar à cozinha'}]};
const DIRS=[[0,-1],[1,0],[0,1],[-1,0]];
const key=p=>p.x+','+p.y;
const actor=(id,room,x,y)=>({id,room,x,y,goal:null,wait:0,hold:0,state:'idle',carry:null});
// Parâmetros de protótipo, independentes do relógio do dispositivo.
const TIME_CONFIG={startMinute:6*60,endMinute:26*60,blockMinutes:10,secondsPerBlock:7,daysPerSeason:28,seasons:['Primavera','Verão','Outono','Inverno'],weekdays:['Segunda','Terça','Quarta','Quinta','Sexta','Sábado','Domingo'],dailyExpense:12};
const ARRIVAL_CONFIG={intervalSeconds:25,firstDelaySeconds:8};
const REPUTATION_CONFIG={initial:0,min:0,max:100,deltas:{praise:1,complaint:-1,abandonment:-1},levels:[{min:80,label:'Referência local'},{min:60,label:'Bem avaliado'},{min:40,label:'Reconhecido'},{min:20,label:'Pouco conhecido'},{min:0,label:'Desconhecido'}]};

const DEFAULT_SERVICE_HOURS=[{start:660,end:900},{start:1080,end:1320}];
function newServiceHours(){return DEFAULT_SERVICE_HOURS.map(h=>({...h}));}
function validServiceHours(hours){return Array.isArray(hours)&&hours.length===2&&hours.every(h=>h&&Number.isInteger(h.start)&&Number.isInteger(h.end)&&h.start>=360&&h.end<=1560&&h.start<h.end&&h.start%10===0&&h.end%10===0)&&hours[0].end<=hours[1].start;}
function serviceHours(s){return s.serviceHours||DEFAULT_SERVICE_HOURS;}
function serviceTimeText(minute){return String(Math.floor(minute%1440/60)).padStart(2,'0')+':'+String(minute%60).padStart(2,'0');}
function syncService(s){
 const hours=serviceHours(s),now=s.clock.minute;
 if(s.open&&!s.closing&&now>=hours[s.period].end){s.closing=true;s.message='Horário encerrado. Novas entradas suspensas; conclua os clientes presentes.';}
 if(!s.open&&!s.closing)s.period=now>=hours[0].end?1:0;
}
function serviceOpenError(s){const h=serviceHours(s)[s.period];return s.clock.minute<h.start?'Este turno começa às '+serviceTimeText(h.start)+'.':s.clock.minute>=h.end?'O horário deste turno já terminou.':'';}
function setServiceHours(s,hours){
 if(s.open||s.closing||servicePending(s))return {ok:false,message:'Conclua o serviço antes de alterar os horários.'};
 if(!validServiceHours(hours))return {ok:false,message:'Use horários entre 06:00 e 02:00, em intervalos de 10 minutos. O almoço deve terminar antes do jantar começar.'};
 s.serviceHours=hours.map(h=>({...h}));syncService(s);return {ok:true,message:'Horários atualizados. Abra o serviço pela plaquinha durante o período escolhido.'};
}

// Test-only jump: change the clock, not elapsed simulation or customer patience.
function advanceTestClock(s,minute){
 if(!Number.isInteger(minute)||minute<TIME_CONFIG.startMinute||minute>TIME_CONFIG.endMinute||minute%TIME_CONFIG.blockMinutes!==0)return {ok:false,message:'Escolha um horário entre 06:00 e 02:00, em intervalos de 10 minutos.'};
 if(s.clock.ending)return {ok:false,message:'Conclua o dia atual antes de avançar o horário.'};
 if(minute<s.clock.minute)return {ok:false,message:'Escolha um horário igual ou posterior ao atual. Esta ferramenta não volta o relógio.'};
 if(minute===s.clock.minute)return {ok:true,message:'O relógio já está em '+clockText(s)+'.'};
 const day=s.day;
 s.clock.minute=minute;s.clock.remainder=0;s.clock.ending=minute===TIME_CONFIG.endMinute;
 if(s.clock.ending&&(s.open||servicePending(s)))s.closing=true;
 syncService(s);
 if(s.closing&&!servicePending(s))finishPeriod(s);
 finishCalendarDay(s);
 return {ok:true,message:s.day!==day?'Horário de teste avançado: novo dia às 06:00.':'Horário de teste avançado para '+clockText(s)+'.'+(s.closing?' Conclua os clientes e preparos pendentes.':'')};
}

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
function servicePending(s){return !!(s.customers.length||s.chopping||s.cooking||s.plating||s.ready.length||s.orders.some(o=>!['paid','lost'].includes(o.state))||allActors(s).some(a=>a.carry?.kind==='dish'&&!canceledCarry(s,a)));}
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
 if(s.serviceHours!==undefined&&!validServiceHours(s.serviceHours))return false;
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
 const q=p.servedQuality;const score=100*((p.results.service??0)*weights.service+(p.results.food??0)*weights.food+(q===undefined?0:QUALITY_CONFIG.satisfaction[q]*weights.quality))/(weights.service+weights.food+(q===undefined?0:weights.quality));
 const classification=config.classes.find(v=>score>=v.min)||config.classes[config.classes.length-1];
 return {score,classification:classification.id,quality:p.servedQuality??null};
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
 const prep=s.objects.find(o=>o.type==='kitchen'&&objectSpace(o,item)>0&&objectNear(s,o,a));if(!prep)return false;
 putObject(s,prep,item,1,a.carry.quality??0);a.carry=null;s.message='Pedido cancelado: prato devolvido à mesa de preparo.';return true;
}
function validExperience(s){
 const history=s.experience;if(!history||!Array.isArray(history.visits)||!Array.isArray(history.events))return false;
 const classes=CUSTOMER_CONFIG.satisfaction.classes.map(c=>c.id),phases=['service','food'];
 const validScore=v=>v===null||v&&Number.isFinite(v.score)&&v.score>=0&&v.score<=100&&classes.includes(v.classification)&&(v.quality===null||Number.isFinite(v.quality)&&v.quality>=0&&v.quality<=3);
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
function migrateSave(value,rng=Math.random){try{
 if(!value||![4,5,6,7,8,9,10,11,VERSION].includes(value.version))return null;
 const s=JSON.parse(JSON.stringify(value));const sourceVersion=s.version;if(sourceVersion<10)for(const o of s.objects||[])if(o.type==='prep')o.type='kitchen';
 if(s.serviceHours===undefined)s.serviceHours=newServiceHours();
 if(s.version===4){s.version=5;s.experience={visits:[],events:[]};if(!Array.isArray(s.customers))return null;
  for(const c of s.customers){c.experience=newExperience(rng);c.experience.legacy=true;c.experience.reviewResolved=true;if(c.state==='waiting')beginWait(s,c,'service');else if(c.state==='ordered')beginWait(s,c,'food');}
 }
 if(s.version===5){if(!Array.isArray(s.experience?.visits))return null;s.version=6;s.clock=newClock();s.reputation=newReputation();s.reputation.processed=s.experience.visits.map(v=>v.id);}
 if(s.version===6)migrateKitchen(s);
 if([7,8,9,10,11,VERSION].includes(s.version))migrateCleaning(s);
 for(const o of s.objects)if(o.type==='stove'&&o.pan?.startsWith('pot_')&&!o.readyBatch)o.readyBatch={recipe:ITEMS[o.pan].recipe,quality:0,doneAt:s.time};
 migratePhysicalKitchen(s,sourceVersion);
 if(sourceVersion<12){
  if(s.chopping&&!s.chopping.hand)s.chopping=null;
  if(!Array.isArray(s.inventory)||![0,5,10].includes(s.inventory.length)||!valid(s,s.inventory.length))return null;
  const preserved=[...s.inventory.filter(Boolean),...s.recovery];
  if(s.player.carry?.kind==='food'){preserved.push({item:s.player.carry.food,n:s.player.carry.n,quality:s.player.carry.quality||0});s.player.carry=null;}
  else if(s.player.carry?.kind==='dish'){
   const order=s.orders.find(o=>o.id===s.player.carry.order);
   s.player.hand={item:'dish_'+order.recipe,n:1,quality:s.player.carry.quality||0};s.player.carry=null;
   if(order.state==='ready')order.state='ordered';
  }
  s.inventory=[];s.selectedSlot=0;s.recovery=[];
  for(const original of preserved){let left=original.n;
   for(const o of s.objects.filter(o=>o.inventory&&accepts(o,original.item))){const n=Math.min(left,objectSpace(o,original.item,original.quality||0));if(n&&(o.type==='potRack'?putObject(s,o,original.item,n,original.quality||0)===n:addInventory({inventory:o.inventory},original.item,n,original.quality||0,!!original.burned)))left-=n;if(!left)break;}
   if(left)s.recovery.push({...original,n:left});
  }
  syncContainers(s);
 }
 return valid(s)?s:null;
}catch{return null}}

// Transitional adapter: Godot creates these states in Partida.gd.
// Node regression tests use frozen reference data, not a second implementation.
function nativeInitial(compact,singleRoom,mode){
 const templates=typeof NativePartidas!=='undefined'?NativePartidas:require('./partidas.json');
 const template=templates[String(+compact)+String(+singleRoom)];
 if(!template||mode==='furnished'&&singleRoom&&!compact)throw Error('Cenário de teste inválido.');
 return JSON.parse(JSON.stringify(template[mode]));
}
function fresh(compact=false,singleRoom=false){return nativeInitial(compact,singleRoom,'empty');}
function furnishedTest(compact=false,singleRoom=false){return nativeInitial(compact,singleRoom,'furnished');}
function clearTestScene(s){delete s.receivingQuality;
 // Cancelar o serviço elimina referências a móveis, itens e pratos removidos.
 const clean=fresh(s.compact===true,s.singleRoom===true);
 for(const k of ['open','closing','tick','arrival','objects','equipment','meals','dirtyTables','inventory','selectedSlot','tools','inv','purchased','used','orders','deliveries','customers','residents','player','workers','cookActive','cooking','plating','chopping','recovery','ready','priority','flowWaits'])s[k]=clean[k];
 s.message='Teste limpo: móveis e itens removidos. Serviço, entregas e preparos cancelados; dinheiro e dia preservados.';
 return s;
}
function rect(o){let d=CATALOG[o.type];return {x:o.x,y:o.y,w:o.rot%2?d.h:d.w,h:o.rot%2?d.w:d.h};}
function cells(o){let r=rect(o),a=[];for(let y=r.y;y<r.y+r.h;y++)for(let x=r.x;x<r.x+r.w;x++)a.push({x,y});return a;}
function hit(o,x,y){return cells(o).some(p=>p.x===x&&p.y===y);}
// Obstacle rules are computed by Mapa.gd. Node uses frozen parity references.
const OBSTACLES=typeof NativeObstacles!=='undefined'?NativeObstacles:require('./obstaculos.json');
function obstacle(room,x,y,s){
 if(x<0||y<0||x>=W||y>=H)return 1;
 const map=OBSTACLES[String(+(s?.compact===true))+String(+(s?.singleRoom===true))];
 return map[room] ? map[room][y*W+x] : map.stock[y*W+x];
}
function wall(room,x,y,s=null){return !!(obstacle(room,x,y,s)&1);}
function fixed(room,x,y,s=null){return !!(obstacle(room,x,y,s)&2);}
function blocked(s,room,x,y,a=null,objects=s.objects){if(wall(room,x,y,s)||fixed(room,x,y,s))return true;return objects.some(o=>o.room===room&&hit(o,x,y)&&!(o.type==='chair'&&a&&a.seat===o.id));}
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
// Continuous player input is transient; only the settled world position is saved.
const PLAYER_SPEED=3.3,PLAYER_RADIUS=.20,playerInput=new WeakMap();
function playerVelocity(a){return playerInput.get(a)||null;}
function isMoving(a){return !!a.motion||!!playerInput.get(a)?.moving;}
function setPlayerInput(s,dx,dy){
 const a=s.player,input=playerInput.get(a);
 if(!Number.isFinite(dx)||!Number.isFinite(dy))return;
 const length=Math.hypot(dx,dy);
 if(!length){if(input)playerInput.delete(a);return;}
 const p=position(a);
 a.x=Math.floor(p.x+.5);a.y=Math.floor(p.y+.5);
 a.settled={room:a.room,x:a.x,y:a.y,px:p.x,py:p.y};
 a.motion=null;a.goal=null;
 playerInput.set(a,{dx:dx/length,dy:dy/length,moving:input?.moving||false});
}
function moveFreePlayer(s,a,input,dt){
 const p=position(a),before={...p},occupied=occupants(s,a),solid=new Map();
 function collision(x,y){
  const cx=x+.5,cy=y+.5,r=PLAYER_RADIUS;
  for(let iy=Math.floor(cy-r);iy<=Math.floor(cy+r);iy++)for(let ix=Math.floor(cx-r);ix<=Math.floor(cx+r);ix++){
   const k=ix+','+iy;
   if(!solid.has(k))solid.set(k,blocked(s,a.room,ix,iy,a)||occupied.has(k));
   if(!solid.get(k))continue;
   const ox=Math.max(ix-cx,0,cx-ix-1),oy=Math.max(iy-cy,0,cy-iy-1);
   if(ox*ox+oy*oy<r*r-1e-10)return true;
  }
  return false;
 }
 function axis(dx,dy){
  if(!dx&&!dy)return;
  let amount=1;
  if(collision(p.x+dx,p.y+dy)){
   let lo=0,hi=1;
   for(let i=0;i<14;i++){const mid=(lo+hi)/2;if(collision(p.x+dx*mid,p.y+dy*mid))hi=mid;else lo=mid;}
   amount=lo;
  }
  p.x+=dx*amount;p.y+=dy*amount;
 }
 // Short swept steps prevent tunnelling even after a slow frame. Resolve each
 // axis independently, so a blocked diagonal slides instead of locking both axes.
 const distance=PLAYER_SPEED*dt,count=Math.max(1,Math.ceil(distance/.08));
 for(let i=0;i<count;i++){axis(input.dx*distance/count,0);axis(0,input.dy*distance/count);}
 a.x=Math.floor(p.x+.5);a.y=Math.floor(p.y+.5);
 a.settled={room:a.room,x:a.x,y:a.y,px:p.x,py:p.y};
 a.motion=null;a.goal=null;a.wait=0;
 input.moveX=p.x-before.x;input.moveY=p.y-before.y;
 input.moving=Math.hypot(input.moveX,input.moveY)>1e-7;
 // Walking through the restaurant doorway uses the same links as clicking it.
 const portal=['restaurant','street'].includes(a.room)&&PORTALS[a.room]?.find(d=>Math.abs(p.x-d.x)<.35&&Math.abs(p.y-d.y)<.35&&(a.room==='restaurant'?input.dy>0&&p.y>=d.y-.2:input.dy<0&&p.y<=d.y+.2));
 if(portal){const [x,y]=portal.spawn;
  if(!blocked(s,portal.to,x,y,a)&&!allActors(s).some(b=>b!==a&&b.room===portal.to&&reserved(b).some(q=>q.x===x&&q.y===y))){
   a.room=portal.to;a.x=x;a.y=y;a.settled=null;
  }
 }
}
const NPC_WALK_TIME=.4;
function actorWalkTime(a){return a.id==='player'?1/PLAYER_SPEED:NPC_WALK_TIME;}
function startMotion(a,to,offsetX=0,offsetY=0){let p=position(a),x=to.x+offsetX,y=to.y+offsetY,d=Math.hypot(x-p.x,y-p.y);if(d<1e-7)return false;a.motion={fromX:p.x,fromY:p.y,toX:x,toY:y,x:to.x,y:to.y,elapsed:0,duration:d*actorWalkTime(a)};return true;}
function advanceMotion(a,dt){let m=a.motion;if(!m)return dt;let used=Math.min(dt,m.duration-m.elapsed);m.elapsed+=used;if(m.elapsed>=m.duration-1e-8){a.x=m.x;a.y=m.y;a.settled={room:a.room,x:a.x,y:a.y,px:m.toX,py:m.toY};a.motion=null;}return Math.max(0,dt-used);}
function reserved(a){let out=[{x:a.x,y:a.y}];if(a.id==='player'&&!a.motion){const p=position(a),r=PLAYER_RADIUS;for(let y=Math.floor(p.y+.5-r);y<=Math.floor(p.y+.5+r);y++)for(let x=Math.floor(p.x+.5-r);x<=Math.floor(p.x+.5+r);x++){const dx=Math.max(x-p.x-.5,0,p.x-.5-x),dy=Math.max(y-p.y-.5,0,p.y-.5-y);if(dx*dx+dy*dy<r*r-1e-10)out.push({x,y});}}if(a.motion){out.push({x:a.motion.x,y:a.motion.y});if(a.motion.x!==a.x&&a.motion.y!==a.y)out.push({x:a.motion.x,y:a.y},{x:a.x,y:a.motion.y})}return out.filter((p,i)=>out.findIndex(q=>q.x===p.x&&q.y===p.y)===i);}
function accessPoints(s,o,objects=s.objects){let r=rect(o),ps=[];for(let y=r.y-1;y<=r.y+r.h;y++)for(let x=r.x-1;x<=r.x+r.w;x++){if((x===r.x-1||x===r.x+r.w)&&(y>=r.y&&y<r.y+r.h)||(y===r.y-1||y===r.y+r.h)&&(x>=r.x&&x<r.x+r.w)){if(!blocked(s,o.room,x,y,null,objects))ps.push({room:o.room,x,y})}}return ps;}
function closestAccess(s,a,o){let ps=accessPoints(s,o);if(a.room!==o.room)return ps[0]||null;return ps.map(p=>({p,path:route(s,a.room,a,p,a)})).filter(v=>v.path).sort((a,b)=>a.path.length-b.path.length)[0]?.p||null;}
function goObject(s,a,o){let p=closestAccess(s,a,o);if(!p)return false;playerInput.delete(a);a.goal=p;return true;}
function go(a,p){playerInput.delete(a);a.goal={room:p.room||a.room,x:p.x,y:p.y};if(Number.isFinite(p.offsetX)&&Number.isFinite(p.offsetY)){a.goal.offsetX=Math.max(-.25,Math.min(.25,p.offsetX));a.goal.offsetY=Math.max(-.25,Math.min(.25,p.offsetY))}}
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
  const manual=a===s.player&&playerInput.get(a);
  if(manual){moveFreePlayer(s,a,manual,dt);continue;}
  // Return from a free position to a safe cell centre before an automatic route.
  // This is interpolated, never snapped, and prevents cutting wall corners.
  if(a===s.player&&!a.motion&&a.goal&&(a.goal.room!==a.room||a.goal.x!==a.x||a.goal.y!==a.y))startMotion(a,{x:a.x,y:a.y});
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
function layoutError(s,objects){let occupied=new Set();for(const o of objects){if(!CATALOG[o.type]||o.room!==CATALOG[o.type].room)return 'Objeto fora do setor permitido.';for(const p of cells(o)){if(wall(o.room,p.x,p.y,s)||fixed(o.room,p.x,p.y,s)||PORTALS[o.room].some(d=>Math.abs(d.x-p.x)+Math.abs(d.y-p.y)<=1))return 'Parede, porta ou infraestrutura reservada.';if(o.room==='restaurant'&&((CATALOG[o.type].area==='hall'&&p.x>=14)||(CATALOG[o.type].area==='kitchen'&&(p.x<=14||(!s.singleRoom&&p.y>=10)))||(CATALOG[o.type].area==='storage'&&(p.x<=14||(!s.singleRoom&&p.y<=10)))||(CATALOG[o.type].area==='dryStorage'&&p.x<=14)))return 'Mesas e cadeiras: salão. Fogão e geladeira de cozinha: cozinha. Prateleira: cozinha ou estoque. Geladeira de estoque: estoque.';let k=o.room+':'+key(p);if(occupied.has(k))return 'Esta célula já está ocupada.';occupied.add(k);if(allActors(s).some(a=>a.room===o.room&&reserved(a).some(q=>q.x===p.x&&q.y===p.y)))return 'Há uma pessoa nesta posição.';}}
 for(const chair of objects.filter(o=>o.type==='chair')){const error=chairLayoutError(s,chair,objects);if(error)return error;}
 // Layout validation needs connectivity, not a separate shortest path per object.
 // A legal diagonal requires both adjacent cardinal cells to be free, so a
 // cardinal flood reaches exactly the same cells as route(), without changing it.
 const room='restaurant',solid=new Uint8Array(W*H),reached=new Uint8Array(W*H);
 for(let y=0;y<H;y++)for(let x=0;x<W;x++)solid[y*W+x]=wall(room,x,y,s)||fixed(room,x,y,s)||occupied.has(room+':'+x+','+y)?1:0;
 const start=13*W+7,queue=[start];
 // route() may leave an occupied start, but cannot use it as a destination.
 reached[start]=1;
 for(let head=0;head<queue.length;head++){
  const cell=queue[head],x=cell%W,y=Math.floor(cell/W);
  for(const [dx,dy]of DIRS){const nx=x+dx,ny=y+dy;
   if(nx<0||ny<0||nx>=W||ny>=H)continue;
   const next=ny*W+nx;if(solid[next]||reached[next])continue;
   reached[next]=1;queue.push(next);
  }
 }
 if(solid[start])reached[start]=0;
 for(const d of PORTALS[room])if(!reached[d.y*W+d.x])return 'A disposição bloqueia uma porta.';
 for(const o of objects.filter(o=>o.room===room))if(!accessPoints(s,o,objects).some(p=>reached[p.y*W+p.x]))return 'Deixe uma passagem até cada móvel.';
 return null;}
function place(s,type,x,y,rot=0,moving=null){let error=editError(s);if(error)return {ok:false,error};let d=CATALOG[type];if(!d)return {ok:false,error:'Objeto desconhecido.'};if(s.singleRoom&&type==='cold')return {ok:false,error:'Esta planta não possui estoque separado.'};if(['computer','receiving'].includes(type)&&s.objects.some(o=>o.type===type&&o.id!==moving))return {ok:false,error:'Este equipamento já está instalado.'};if(!Number.isInteger(x)||!Number.isInteger(y)||!Number.isInteger(rot))return {ok:false,error:'Posição inválida.'};let old=moving?s.objects.find(o=>o.id===moving):null;if(moving&&(!old||old.type!==type))return {ok:false,error:'Objeto não encontrado.'};if(old&&(s.chopping?.table===old.id||s.cooking?.stove===old.id||s.plating?.prep===old.id))return {ok:false,error:'Conclua o preparo antes de mover.'};if(old&&(s.dirtyTables[old.id]||old.type==='table'&&s.objects.some(c=>c.type==='chair'&&chairTable(s,c)?.id===old.id&&s.dirtyTables[c.id])))return {ok:false,error:'Recolha os pratos sujos antes de mover.'};let o={...old,id:old?.id||s.serial,type,x,y,rot:((rot%4)+4)%4,room:d.room,...(type==='stove'?{ingredients:old?.ingredients||[],pan:old?.pan||null,...(old?.readyBatch?{readyBatch:{...old.readyBatch},burned:!!old.burned}:{} )}:type==='kitchen'?{plates:old?.plates||0,utensil:old?.utensil||false,dishes:old?.dishes||{},dishQuality:old?.dishQuality||{}}:['shelf','cold','fridge','potRack'].includes(type)?{inventory:old?.inventory||Array(type==='potRack'?3:10).fill(null)}:{})};let objects=s.objects.filter(q=>q.id!==moving).concat(o);error=layoutError(s,objects);if(error)return {ok:false,error};if(!old&&s.cash<d.price)return {ok:false,error:'Dinheiro insuficiente.'};if(!old){s.cash-=d.price;s.ledger.investment+=d.price;s.serial++}s.objects=objects;syncContainers(s);return {ok:true,object:o};}
function remove(s,id){let error=editError(s);if(error)return {ok:false,error};let o=s.objects.find(o=>o.id===id);if(!o)return {ok:false,error:'Objeto não encontrado.'};if(o.type==='receiving'&&(Object.values(s.inv.receiving).some(n=>n>0)||s.deliveries.some(d=>d.pending>0)))return {ok:false,error:'Recolha as entregas antes de guardar o recebimento.'};if(o.type==='table'&&s.objects.some(c=>c.type==='chair'&&chairTable(s,c)?.id===o.id&&s.dirtyTables[c.id]))return {ok:false,error:'Recolha os pratos sujos antes de guardar a mesa.'};if(s.chopping?.table===id||s.cooking?.stove===id||s.plating?.prep===id||stationSlots(o).some(Boolean)||s.dirtyTables[o.id])return {ok:false,error:'Retire os itens instalados e a comida antes de guardar.'};s.objects=s.objects.filter(o=>o.id!==id);s.cash+=CATALOG[o.type].price;s.ledger.investment-=CATALOG[o.type].price;return {ok:true};}
function longSideSeat(chair,table){
 const r=rect(table);
 if(r.w===2&&r.h===1)return chair.x>=r.x&&chair.x<r.x+r.w&&(chair.y===r.y-1&&chair.rot===2||chair.y===r.y+r.h&&chair.rot===0);
 if(r.w===1&&r.h===2)return chair.y>=r.y&&chair.y<r.y+r.h&&(chair.x===r.x-1&&chair.rot===1||chair.x===r.x+r.w&&chair.rot===3);
 return true;
}
function chairTable(s,chair,objects=s.objects){
 if(!chair)return undefined;
 const [dx,dy]=DIRS[chair.rot%4];
 return objects.find(o=>o.room===chair.room&&o.type==='table'&&hit(o,chair.x+dx,chair.y+dy));
}
function seatTable(s,chair,objects=s.objects){
 const table=chairTable(s,chair,objects);
 return table&&longSideSeat(chair,table)?table:undefined;
}
function chairLayoutError(s,chair,objects){
 const touching=list=>list.filter(t=>t.type==='table'&&t.room===chair.room&&DIRS.some(([dx,dy])=>hit(t,chair.x+dx,chair.y+dy)));
 const tables=touching(objects);
 if(!tables.length)return null; // Cadeira isolada é móvel, mas não assento de atendimento.
 const onEnd=t=>{const r=rect(t);return r.w===2&&r.h===1?(chair.x===r.x-1||chair.x===r.x+r.w):r.w===1&&r.h===2?(chair.y===r.y-1||chair.y===r.y+r.h):false;};
 if(!tables.some(onEnd)&&seatTable(s,chair,objects))return null;
 // Saves antigos conservam móveis; cadeiras incompatíveis deixam de receber clientes.
 // Uma reforma não relacionada pode prosseguir até essas cadeiras serem reorganizadas.
 const geometry=o=>[o.id,o.type,o.room,o.x,o.y,o.rot];
 const old=s.objects.find(o=>o.id===chair.id&&o.type==='chair');
 if(old&&JSON.stringify(geometry(old))===JSON.stringify(geometry(chair))&&JSON.stringify(touching(s.objects).map(geometry))===JSON.stringify(tables.map(geometry)))return null;
 return 'Posicione a cadeira no lado comprido da mesa, virada para ela. As pontas não aceitam cadeiras.';
}
function seats(s){return s.objects.filter(o=>o.type==='chair'&&seatTable(s,o)&&route(s,'restaurant',{x:7,y:13},o,{seat:o.id}));}
function kit(s){let a=[];if(!seats(s).length)a.push('mesa com cadeira voltada para ela e caminho livre');for(const [t,n] of [['stove','fogão'],['fridge','geladeira na cozinha']])if(!s.objects.some(o=>o.type===t))a.push(n);if(!s.objects.some(o=>o.type==='kitchen'))a.push('mesa de preparo');return a;}
const ITEMS={legumes_cut:{name:'Legumes cortados',raw:'legumes'},frango_cut:{name:'Frango cortado',raw:'frango'},...FOODS,pot:{name:'Panela'},spoon:{name:'Colher / utensílio'},plate:{name:'Prato limpo'},dirtyPlate:{name:'Prato sujo'},cookingPot:{name:'Panela em preparo',limit:1}};
for(const [r,d]of Object.entries(RECIPES)){ITEMS['dish_'+r]={name:'Prato de '+d.name,recipe:r};for(let n=1;n<=4;n++)ITEMS['pot_'+r+'_'+n]={name:'Panela: '+d.name+' ('+n+'/4 porções)',recipe:r,servings:n,limit:1};}
function itemLimit(item){return ITEMS[item]?.limit||99;}
function itemName(item){return ITEMS[item]?.name||'Item desconhecido';}
function itemIcon(item){return FOODS[item]?{arroz:'🌾',legumes:'🥕',frango:'🍗'}[item]:item==='spoon'?'🥄':item==='plate'?'🍽️':item==='dirtyPlate'?'🧽':item.startsWith('dish_')?'🍛':item==='pot'?'🥘':'🍲';}
function inventoryCount(s,item){return s.inventory.reduce((n,slot)=>n+(slot?.item===item?slot.n:0),0);}
function inventorySpace(s,item,quality=0){return s.inventory.reduce((n,slot)=>n+(!slot?itemLimit(item):slot.item===item&&(slot.quality??0)===quality?itemLimit(item)-slot.n:0),0);}
function addInventory(s,item,n,quality=0,burned=false){if(!ITEMS[item]||!Number.isInteger(n)||n<1||inventorySpace(s,item,quality)<n)return false;let left=n;for(let i=0;i<s.inventory.length&&left;i++){let slot=s.inventory[i];if(slot?.item===item&&(slot.quality??0)===quality&&!slot.burned&&!burned){let q=Math.min(left,itemLimit(item)-slot.n);slot.n+=q;left-=q;}}for(let i=0;i<s.inventory.length&&left;i++)if(!s.inventory[i]){let q=Math.min(left,itemLimit(item));s.inventory[i]={item,n:q,...(quality?{quality}:{}),...(burned?{burned:true}:{})};left-=q;}return true;}
function removeInventory(s,index,n){let slot=s.inventory[index];if(!slot||!Number.isInteger(n)||n<1||n>slot.n)return false;slot.n-=n;if(!slot.n)s.inventory[index]=null;return true;}
function buyTool(s,type){
 if(!['pot','plate'].includes(type)||s.player.hand||s.player.carry||s.chopping||s.plating)return false;
 const price={pot:25,plate:5}[type];if(s.cash<price)return false;
 s.player.hand={item:type,n:1};s.cash-=price;s.ledger.investment+=price;s.equipment[type]++;if(type!=='plate')s.tools[type]=true;return true;
}

function utilityNear(s,type){if(!s.singleRoom)return near(s.player,{room:'restaurant',x:type==='computer'?16:21,y:12},1);return s.objects.some(o=>o.type===type&&objectNear(s,o));}
function collectReceiving(s){
 if(isMoving(s.player)||!utilityNear(s,'receiving'))return 'Aproxime-se do recebimento.';
 if(s.player.hand||s.player.carry||s.chopping||s.plating)return 'Libere as mãos antes de recolher.';
 for(const food of Object.keys(FOODS))for(let q=0;q<4;q++)if(receivingCount(s,food,q)>0){receiveQuality(s,food,-1,q);s.player.hand={item:food,n:1,quality:q};return 'Uma unidade de '+FOODS[food].name+' nas mãos.';}
 return 'Não há entregas para recolher.';
}

function objectLocation(o){if(o.type==='shelf')return o.y>10?'storage':'kitchen';return o.type==='cold'?'storage':'kitchen';}
function accepts(o,item){if(!ITEMS[item])return false;if(o.type==='potRack')return item==='pot';if(o.type==='stove')return ['pot','cookingPot'].includes(item)||item.startsWith('pot_');if(o.type==='kitchen')return ['plate','spoon'].includes(item)||item.startsWith('dish_');if(['sink','bin'].includes(o.type))return false;if(['fridge','cold'].includes(o.type))return item!=='cookingPot';const food=FOODS[ITEMS[item].raw||item];return !!food&&(o.type==='shelf'?food.kind==='dry':['cold','fridge'].includes(o.type)&&food.kind==='cold');}
function objectCount(o,item){return stationSlots(o).reduce((n,p)=>n+(p?.item===item?p.n:0),0);}
function objectSpace(o,item,quality=0){
 if(o.type==='potRack')return item==='pot'?Math.max(0,3-objectCount(o,'pot')):0;
 if(o.type==='stove')return (!o.pan&&(item==='pot'||item==='cookingPot'||item.startsWith('pot_')))?1:0;
 if(o.type==='kitchen')return item==='plate'?99-o.plates:item==='spoon'?Number(!o.utensil):item.startsWith('dish_')&&ITEMS[item]?Math.max(0,KITCHEN_CONFIG.readyCapacity-readyCount(o)):0;
 return accepts(o,item)?inventorySpace({inventory:o.inventory},item,quality):0;
}
function syncContainers(s){for(const loc of ['storage','kitchen'])for(const food of Object.keys(FOODS))s.inv[loc][food]=s.objects.filter(o=>o.inventory&&objectLocation(o)===loc).reduce((n,o)=>n+objectCount(o,food),0);}
function putObject(s,o,item,n,quality=0){
 if(!Number.isInteger(n)||n<1||!ITEMS[item])return 0;
 const q=Math.min(n,objectSpace(o,item,quality));if(!q)return 0;
 if(o.type==='potRack'){let left=q;for(let i=0;i<o.inventory.length&&left;i++)if(!o.inventory[i]){o.inventory[i]={item:'pot',n:1,...(quality?{quality}:{})};left--;}}
 else if(o.type==='stove')o.pan=item;
 else if(o.type==='kitchen'){if(item==='plate')o.plates+=q;else if(item==='spoon')o.utensil=true;else {o.dishes[item]=(o.dishes[item]||0)+q;if(quality){o.dishQuality??={};o.dishQuality[item]??=[0,0,0,0];o.dishQuality[item][quality]+=q;}}}
 else addInventory({inventory:o.inventory},item,q,quality);
 syncContainers(s);return q;
}
function takeObject(s,o,item,n,quality=null){
 const total=Math.min(n,quality===null?objectCount(o,item):objectQualityCount(o,item,quality));if(!total)return 0;
 if(o.type==='stove')o.pan=null;
 else if(o.type==='kitchen'){if(item==='plate')o.plates-=total;else if(item==='spoon')o.utensil=false;else {const common=objectQualityCount(o,item,0);o.dishes[item]-=total;let left=total;for(let q=0;q<4&&left;q++){if(quality!==null&&q!==quality)continue;const count=q?o.dishQuality?.[item]?.[q]||0:common;const taken=Math.min(left,count);if(q)o.dishQuality[item][q]-=taken;left-=taken;}}}
 else {let left=total;for(let i=0;i<10&&left;i++){const p=o.inventory[i];if(p?.item===item&&(quality===null||(p.quality??0)===quality)){const q=Math.min(left,p.n);removeInventory({inventory:o.inventory},i,q);left-=q;}}}
 syncContainers(s);return total;
}
function changeLocation(s,loc,food,n){if(loc==='receiving'){s.inv.receiving[food]+=n;return Math.abs(n);}let left=Math.abs(n);for(const o of s.objects.filter(o=>o.inventory&&objectLocation(o)===loc)){let q=n>0?putObject(s,o,food,left):takeObject(s,o,food,left);left-=q;if(!left)break;}return Math.abs(n)-left;}
function capacity(s,loc,food){if(loc==='receiving')return 60;return s.objects.filter(o=>o.inventory&&objectLocation(o)===loc&&accepts(o,food)).length*990;}
function amount(s,loc,food){if(loc==='receiving')return Object.values(s.inv.receiving).reduce((a,b)=>a+b,0);return s.objects.filter(o=>o.inventory&&objectLocation(o)===loc&&accepts(o,food)).reduce((n,o)=>n+o.inventory.reduce((a,p)=>a+(p?.n||0),0),0);}
function transfer(s,from,to,food,n){let moved=0;while(moved<n){const chunk=locationChunk(s,from,food);if(!chunk)break;const target=to==='receiving'?null:storageObject(s,to,food,'put',chunk.quality);const space=to==='receiving'?60-amount(s,to,food):target?objectSpace(target,food,chunk.quality):0;const q=Math.min(n-moved,chunk.n,space);if(q<=0)break;takeChunk(s,from,food,chunk,q);if(target)putObject(s,target,food,q,chunk.quality);else receiveQuality(s,food,q,chunk.quality);moved+=q;}return moved;}
function transferSlot(s,id,side,index){return handStorage(s,id,side==='object'?'take':'put',index);}

function purchase(s,food,n,quality=0){if(s.singleRoom&&!s.objects.some(o=>o.type==='receiving'))return false;if(!Number.isInteger(quality)||quality<0||quality>3||!FOODS[food]||!Number.isInteger(n)||n<1||n>100)return false;let cost=FOODS[food].cost*n*QUALITY_CONFIG.costMultipliers[quality];if(s.cash<cost)return false;s.cash-=cost;s.ledger.purchases+=cost;s.purchased[food]+=n;s.deliveries.push({id:s.serial++,food,quality,total:n,pending:n,received:0,eta:s.time+5});return true;}
function deliver(s){for(const o of s.deliveries){if(s.time<o.eta)continue;let q=Math.min(o.pending,60-amount(s,'receiving',o.food));receiveQuality(s,o.food,q,o.quality??0);o.pending-=q;o.received+=q;}}
function storageObject(s,loc,food,mode=null,quality=0){return s.objects.find(o=>o.inventory&&objectLocation(o)===loc&&accepts(o,food)&&(mode==='take'?objectCount(o,food)>0:mode==='put'?objectSpace(o,food,quality)>0:true));}
function supplyAction(s,loc,food,deposit=false){if(loc==='receiving')return collectReceiving(s);let o=s.objects.find(o=>o.inventory&&objectLocation(o)===loc&&accepts(o,food)&&accessPoints(s,o).some(p=>near(s.player,p,0)));if(!o)return 'Aproxime-se do equipamento adequado.';let index=deposit?s.selectedSlot:o.inventory.findIndex(p=>p?.item===food);let r=transferSlot(s,o.id,deposit?'player':'object',index);return r.ok?'Transferiu '+r.n+' '+FOODS[food].name+'.':r.error;}
function kitchenEnough(s,r){return inventoryCount(s,'dish_'+r)>0||s.inventory.some(p=>p?.item.startsWith('pot_'+r+'_'))||s.objects.some(o=>o.type==='stove'&&(!cookError(s,o,r)||o.pan?.startsWith('pot_'+r+'_'))||o.type==='kitchen'&&objectCount(o,'dish_'+r)>0);}
function toggleOpen(s){if(s.clock.ending){s.message='Conclua o serviço pendente das 02:00 antes de reabrir.';return false;}if(s.closing)return false;if(!s.open){syncService(s);const error=serviceOpenError(s);if(error){s.message=error;return false;}}if(s.open){s.closing=true;s.message='Entrada encerrada. Conclua os pedidos e deixe os clientes saírem.';return true}s.open=true;s.arrival=ARRIVAL_CONFIG.intervalSeconds-ARRIVAL_CONFIG.firstDelaySeconds;s.message=`${s.period===0?'Almoço':'Jantar'} aberto. Receba pedidos nas mesas, prepare e sirva.`;return true;}
function chooseRecipe(s){let ids=Object.keys(RECIPES).filter(r=>s.menu[r]);return ids[s.serial%ids.length];}
function spawn(s,rng=Math.random){if(s.clock.ending)return false;if(!Object.values(s.menu).some(Boolean)){s.ledger.lost++;return false}let free=seats(s).find(o=>{const table=seatTable(s,o);return !s.objects.some(ch=>ch.type==='chair'&&chairTable(s,ch)?.id===table.id&&((s.dirtyTables[ch.id]||0)>0||s.customers.some(c=>c.seat===ch.id&&!c.done)));});if(!free){s.ledger.lost++;return false}let id=s.serial++,c={...actor('client'+id,'restaurant',7,13),seat:free.id,state:'walk',recipe:chooseRecipe(s),order:null,timer:0,experience:newExperience(rng)};if(allActors(s).some(a=>a.room===c.room&&a.x===c.x&&a.y===c.y))return false;c.goal={room:'restaurant',x:free.x,y:free.y};s.customers.push(c);return true;}
function atStove(s,a=s.player){if(a.motion)return false;return s.objects.filter(o=>o.type==='stove').some(o=>accessPoints(s,o).some(p=>near(a,p,0)));}
function readyPoint(s,a=s.player){for(const o of s.objects.filter(o=>o.type==='kitchen'&&s.orders.some(q=>q.state==='ordered'&&objectCount(o,'dish_'+q.recipe)>0))){const p=closestAccess(s,a,o);if(p)return p;}return null;}
function takeOrder(s,a,c){
 if(a.motion||!c||c.state!=='waiting'||!near(a,c,1)||expiredCustomer(s,c))return false;
 finishWait(c);const o={id:s.serial++,customer:c.id,recipe:c.recipe,state:'ordered',age:0,price:s.prices[c.recipe]};s.orders.push(o);c.order=o.id;c.state='ordered';beginWait(s,c,'food');s.message='Pedido anotado: '+RECIPES[c.recipe].name;return true;
}
function customerAccess(s,a,c){return DIRS.map(([dx,dy])=>({room:c.room,x:c.x+dx,y:c.y+dy})).filter(p=>!blocked(s,p.room,p.x,p.y,a)).map(p=>({p,path:route(s,a.room,a,p,a)})).filter(v=>v.path).sort((u,v)=>u.path.length-v.path.length)[0]?.p||null;}
function interact(s,target){let a=s.player;if(a.motion){s.message='Aguarde o personagem se aproximar.';return false}let c=s.customers.find(c=>c.id===target);if(!c||!near(a,c,1)){s.message='Aproxime-se da mesa.';return false}if(expiredCustomer(s,c))return false;if(c.state==='waiting')return takeOrder(s,a,c);if(c.state==='ordered'){if(a.hand?.item==='dish_'+c.recipe){if(a.carry)return false;const p=a.hand;a.hand=null;removeHandDish(s,a,c,p);return serve(s,a,c);}if(canceledCarry(s,a)&&s.orders.find(o=>o.id===a.carry.order).recipe===c.recipe){a.carry.order=c.order;s.orders.find(o=>o.id===c.order).state='ready';return serve(s,a,c);}if(a.carry?.kind==='dish'&&a.carry.order===c.order)return serve(s,a,c);if(a.carry){s.message='Entregue primeiro o prato que está na sua mão.';return false}let item='dish_'+c.recipe,i=s.inventory.findIndex(p=>p?.item===item);if(i>=0){const quality=s.inventory[i].quality??0;removeInventory(s,i,1);s.orders.find(o=>o.id===c.order).state='ready';a.carry={kind:'dish',order:c.order,quality};return serve(s,a,c);}}s.message='Emprate a receita pedida e traga o prato pronto.';return false;}
function pickupDish(s,a=s.player){if(canceledCarry(s,a))return returnCanceledDish(s,a);if(a.carry||a.motion)return false;const prep=s.objects.find(o=>o.type==='kitchen'&&accessPoints(s,o).some(p=>near(a,p,0))&&s.orders.some(q=>q.state==='ordered'&&objectCount(o,'dish_'+q.recipe)>0));if(!prep)return false;const o=s.orders.find(q=>q.state==='ordered'&&objectCount(prep,'dish_'+q.recipe)>0);const quality=firstDishQuality(prep,'dish_'+o.recipe);takeObject(s,prep,'dish_'+o.recipe,1,quality);o.state='ready';a.carry={kind:'dish',order:o.id,quality};return true;}
function serve(s,a,c){if(a.motion||!c||c.state!=='ordered'||expiredCustomer(s,c)||!near(a,c,1))return false;let o=s.orders.find(o=>o.id===c.order);if(!o||o.state!=='ready'||a.carry?.order!==o.id)return false;finishWait(c);c.experience.servedQuality=a.carry.quality??0;o.quality=c.experience.servedQuality;c.experience.satisfaction=c.experience.legacy?null:satisfactionFor(c.experience);c.experience.indicatorUntil=s.time+CUSTOMER_CONFIG.indicators.happySeconds;refreshCustomerVisual(s,c);o.state='eating';c.state='eating';c.timer=4;a.carry=null;s.message='Prato servido. O cliente paga depois de comer.';return true;}
function mealCost(r){return Object.entries(RECIPES[r].foods).reduce((n,[p,q])=>n+q*FOODS[p].cost,0);}

function workerStep(s,w){if(w.task==='none'&&!w.carry){w.goal=null;return}if(w.task==='waiter'&&!w.carry||w.carry?.kind==='dish'){if(w.carry?.kind==='dish'){if(canceledCarry(s,w)){const order=s.orders.find(o=>o.id===w.carry.order),prep=s.objects.find(o=>o.type==='kitchen'&&objectSpace(o,'dish_'+order.recipe)>0);if(prep){goObject(s,w,prep);returnCanceledDish(s,w);}else w.goal=null;return;}let c=s.customers.find(c=>c.order===w.carry.order);if(!c){w.goal=null;return}let p=customerAccess(s,w,c);if(!p){w.goal=null;return;}go(w,p);if(near(w,c,1))serve(s,w,c);return}if(w.carry)return;{let p=readyPoint(s,w);if(p){go(w,p);if(arrived(w))pickupDish(s,w);return;}
 const waiting=s.customers.filter(c=>c.state==='waiting').sort((a,b)=>(a.experience.limits.service-a.experience.elapsed.service)-(b.experience.limits.service-b.experience.elapsed.service));
 for(const c of waiting){const p=customerAccess(s,w,c);if(!p)continue;go(w,p);if(near(w,c,1))takeOrder(s,w,c);return;}w.goal=null;}return}
 if(w.carry?.kind==='food'){let loc=w.carry.to,o=storageObject(s,loc,w.carry.food,'put',w.carry.quality??0);if(!o){w.goal=null;return}goObject(s,w,o);if(arrived(w)){let q=Math.min(w.carry.n,objectSpace(o,w.carry.food,w.carry.quality??0));putObject(s,o,w.carry.food,q,w.carry.quality??0);w.carry.n-=q;if(!w.carry.n)w.carry=null}return}
 for(const [from,to]of [['storage','kitchen'],['receiving','storage']]){const choice=Object.keys(FOODS).map(food=>({food,chunk:locationChunk(s,from,food)})).find(v=>v.chunk&&storageObject(s,to,v.food,'put',v.chunk.quality));if(!choice)continue;const {food,chunk}=choice;const p=from==='receiving'?{room:'restaurant',x:21,y:12}:closestAccess(s,w,chunk.source);if(!p)continue;go(w,p);if(arrived(w)){const target=storageObject(s,to,food,'put',chunk.quality),n=Math.min(4,chunk.n,objectSpace(target,food,chunk.quality));if(n){takeChunk(s,from,food,chunk,n);w.carry={kind:'food',food,n,to,quality:chunk.quality};}}return;}w.goal=null;}
function finishPeriod(s){s.open=false;s.closing=false;s.cookActive=false;syncService(s);s.message='Restaurante fechado. O turno acompanha o relógio; reabra pela plaquinha enquanto estiver no horário.';}
function simulate(s,dt,rng){patienceStep(s,dt,rng);deliver(s);s.tick=(s.tick+dt)%WALK_TIME;moveActors(s,dt);for(const w of s.workers)workerStep(s,w);kitchenStep(s,dt);for(const o of s.orders)if(!['paid','lost'].includes(o.state))o.age+=dt;for(const c of s.customers){if(c.state==='walk'&&arrived(c)){c.state='waiting';c.goal=null;beginWait(s,c,'service');}if(c.state==='eating'){c.timer-=dt;if(c.timer<=0){let o=s.orders.find(o=>o.id===c.order);o.state='paid';finalizeVisit(s,c,'completed',rng);s.meals.eaten[o.recipe]++;s.dirtyTables[c.seat]=(s.dirtyTables[c.seat]||0)+1;s.cash+=o.price;s.ledger.revenue+=o.price;s.ledger.sales++;c.state='leave';go(c,{room:'restaurant',x:7,y:14});s.message='Pagamento recebido: $'+o.price.toFixed(2);}}if(c.state==='leave'&&arrived(c)){c.done=true;}}s.customers=s.customers.filter(c=>!c.done);if(s.open&&!s.closing){s.arrival+=dt;if(s.arrival>=ARRIVAL_CONFIG.intervalSeconds){s.arrival=0;spawn(s,rng)}}if(s.closing&&!s.customers.length&&!s.cooking&&!s.plating&&!s.ready.length&&!allActors(s).some(a=>a.carry?.kind==='dish'&&!canceledCarry(s,a)))finishPeriod(s);}
function step(s,dt,rng=Math.random){
 if(!Number.isFinite(dt)||dt<=0)return;
 let remaining=dt;
 while(remaining>1e-9){
  const slice=s.clock.ending?remaining:Math.min(remaining,TIME_CONFIG.secondsPerBlock-s.clock.remainder);
  s.time+=slice;advanceClock(s,slice);syncService(s);simulate(s,slice,rng);remaining=Math.max(0,remaining-slice);finishCalendarDay(s);
 }
}
function foodConserved(s){return Object.keys(FOODS).every(raw=>{
 let count=s.inv.receiving[raw]+s.used[raw]+s.deliveries.filter(d=>d.food===raw).reduce((n,d)=>n+d.pending,0);
 for(const loc of allItemLocations(s))for(const p of loc.filter(Boolean))if((ITEMS[p.item]?.raw||p.item)===raw)count+=p.n;
 for(const a of allActors(s))if(a.carry?.kind==='food'&&a.carry.food===raw)count+=a.carry.n;
 return count===s.purchased[raw];});}

function valid(s,inventorySlots=0){try{if(s.singleRoom&&!s.compact)return false;if(s.singleRoom!==undefined&&typeof s.singleRoom!=='boolean')return false;if(s.compact!==undefined&&typeof s.compact!=='boolean')return false;if(!validQuality(s)||!validExperience(s)||!validTimeReputation(s)||!validKitchen(s))return false;for(const o of s.objects.filter(o=>['shelf','cold','fridge','potRack'].includes(o.type))){if(!Array.isArray(o.inventory)||o.inventory.length!==(o.type==='potRack'?3:10)||o.inventory.some(p=>p!==null&&(!accepts(o,p.item)||o.type==='potRack'&&p.n!==1||!Number.isInteger(p.n)||p.n<1||p.n>itemLimit(p.item))))return false;}for(const loc of ['storage','kitchen'])for(const p of Object.keys(FOODS))if(s.inv[loc][p]!==s.objects.filter(o=>o.inventory&&objectLocation(o)===loc).reduce((n,o)=>n+objectCount(o,p),0))return false;if(!Array.isArray(s.inventory)||s.inventory.length!==inventorySlots||!Number.isInteger(s.selectedSlot)||s.selectedSlot<0||s.selectedSlot>=Math.max(1,inventorySlots)||s.inventory.some(slot=>slot!==null&&(!ITEMS[slot.item]||!Number.isInteger(slot.n)||slot.n<1||slot.n>itemLimit(slot.item))))return false;let reservations=new Map();for(const a of allActors(s))for(const p of reserved(a)){let k=a.room+':'+key(p);if(reservations.has(k)&&reservations.get(k)!==a.id)return false;reservations.set(k,a.id)}if(!Number.isInteger(s.serial)||s.serial<1||typeof s.open!=='boolean'||typeof s.closing!=='boolean'||!Number.isFinite(s.tick)||!Number.isFinite(s.arrival)||!s.tools||typeof s.tools.pot!=='boolean'||typeof s.tools.spoon!=='boolean'||!Array.isArray(s.residents)||s.residents.length!==3||!Array.isArray(s.ready)||!Array.isArray(s.reports))return false;for(const v of Object.values(s.ledger))if(!Number.isFinite(v))return false;for(const k of ['lia','beto','nina'])if(!Number.isInteger(s.friends[k])||s.friends[k]<0)return false;for(const w of s.workers)if(!['none','logistics','waiter'].includes(w.task))return false;let orderIds=new Set();for(const o of s.orders){if(!Number.isInteger(o.id)||orderIds.has(o.id)||!RECIPES[o.recipe]||!['ordered','cooking','ready','eating','paid','lost'].includes(o.state)||!Number.isFinite(o.price)||o.price<1||!Number.isFinite(o.age)||o.age<0)return false;orderIds.add(o.id)}if(new Set(s.ready).size!==s.ready.length||s.ready.some(id=>!s.orders.some(o=>o.id===id&&o.state==='ready')))return false;if(s.cooking&&(!RECIPES[s.cooking.recipe]||!s.objects.some(o=>o.id===s.cooking.stove&&o.type==='stove'&&o.pan==='cookingPot')||!Number.isFinite(s.cooking.left)||s.cooking.left<0))return false;for(const c of s.customers)if(!RECIPES[c.recipe]||!['walk','waiting','ordered','eating','leave'].includes(c.state)||!s.objects.some(o=>o.id===c.seat&&o.type==='chair')||c.order!==null&&!s.orders.some(o=>o.id===c.order&&o.customer===c.id))return false;if(s.version!==VERSION||!Number.isFinite(s.cash)||!Number.isInteger(s.day)||s.day<1||![0,1].includes(s.period)||!Number.isFinite(s.time)||!Array.isArray(s.objects)||s.objects.length>180||!Array.isArray(s.orders)||s.orders.length>5000||!Array.isArray(s.customers)||s.customers.length>50||s.workers.length!==(s.singleRoom?1:2))return false;let ids=new Set();for(const o of s.objects){if(!CATALOG[o.type]||!Number.isInteger(o.id)||ids.has(o.id)||!Number.isInteger(o.x)||!Number.isInteger(o.y)||!Number.isInteger(o.rot)||o.rot<0||o.rot>3||o.room!==CATALOG[o.type].room)return false;ids.add(o.id);for(const p of cells(o))if(wall(o.room,p.x,p.y,s)||fixed(o.room,p.x,p.y,s))return false}let occupied=new Set();for(const o of s.objects)for(const p of cells(o)){let k=o.room+':'+key(p);if(occupied.has(k))return false;occupied.add(k)}let persons=new Set();for(const a of allActors(s)){if(!PORTALS[a.room]||!Number.isInteger(a.x)||!Number.isInteger(a.y)||a.x<1||a.x>=W-1||a.y<1||a.y>=H-1||blocked(s,a.room,a.x,a.y,a))return false;if(a.goal&&(!PORTALS[a.goal.room]||!Number.isInteger(a.goal.x)||!Number.isInteger(a.goal.y)||a.goal.x<1||a.goal.x>=W-1||a.goal.y<1||a.goal.y>=H-1))return false;if(a.motion){let m=a.motion;if(!['fromX','fromY','toX','toY','duration','elapsed','x','y'].every(k=>Number.isFinite(m[k]))||m.duration<=0||m.duration>actorWalkTime(a)*3||m.elapsed<0||m.elapsed>=m.duration||!Number.isInteger(m.x)||!Number.isInteger(m.y)||Math.abs(m.x-a.x)>1||Math.abs(m.y-a.y)>1||Math.abs(m.toX-m.x)>.25||Math.abs(m.toY-m.y)>.25||blocked(s,a.room,m.x,m.y,a))return false;}if(a.settled&&!['x','y','px','py'].every(k=>Number.isFinite(a.settled[k])))return false;if(a.goal&&['offsetX','offsetY'].some(k=>a.goal[k]!==undefined&&(!Number.isFinite(a.goal[k])||Math.abs(a.goal[k])>.25)))return false;if(!Number.isFinite(a.hold)||!Number.isFinite(a.wait))return false;if(a.carry&&!['food','dish'].includes(a.carry.kind))return false;if(a.carry?.kind==='dish'&&!s.orders.some(o=>o.id===a.carry.order&&['ready','lost'].includes(o.state)))return false;let k=a.room+':'+key(a);if(persons.has(k))return false;persons.add(k);if(a.carry&&a.carry.kind==='food'&&(!FOODS[a.carry.food]||!Number.isInteger(a.carry.n)||a.carry.n<1))return false;}for(const loc of Object.keys(s.inv))for(const p of Object.keys(FOODS))if(!Number.isInteger(s.inv[loc][p])||s.inv[loc][p]<0||amount(s,loc,p)>capacity(s,loc,p))return false;for(const o of s.deliveries)if(!FOODS[o.food]||!Number.isInteger(o.total)||o.total<1||o.pending<0||o.received<0||o.total!==o.pending+o.received||!Number.isFinite(o.eta))return false;for(const p of Object.keys(FOODS))if(!Number.isInteger(s.purchased[p])||!Number.isInteger(s.used[p])||s.purchased[p]<0||s.used[p]<0)return false;for(const r of Object.keys(RECIPES))if(!Number.isFinite(s.prices[r])||s.prices[r]<1||s.prices[r]>100||typeof s.menu[r]!=='boolean')return false;return foodConserved(s)&&equipmentConserved(s)&&mealsConserved(s);}catch{return false}}
function talk(s,id){if(!['lia','beto','nina'].includes(id))return '';const p=s.residents.find(a=>a.id===id);if(!near(s.player,{room:'street',...p},1))return 'Aproxime-se para conversar.';let k=s.day+':'+id;if(!s.talked[k]){s.friends[id]++;s.talked[k]=true}return {lia:'Lia • agricultora: "Estou testando legumes para os restaurantes do bairro. Prepare sua cozinha antes de abrir!"',beto:'Beto • cozinheiro: "Uma panela e um utensílio já rendem os primeiros pratos. Duas mesas não ajudam quando o fogão é o gargalo."',nina:'Nina • moradora: "Gosto de uma sopa no jantar. Deixe um corredor livre: ninguém quer esbarrar no garçom."'}[id]+' Vínculo: '+s.friends[id]+'. Conversas demonstrativas; desbloqueios e economia social ainda pendentes.';}
function objectNear(s,o,a=s.player){return !!o&&!isMoving(a)&&o.room===a.room&&accessPoints(s,o).some(p=>near(a,p,0));}
function result(s,ok,message){s.message=message;return {ok,error:ok?null:message,message};}



function discardFood(s,id,index){
 const o=s.objects.find(o=>o.id===id);
 if(!['sink','bin'].includes(o?.type)||!objectNear(s,o))return result(s,false,'Aproxime-se da pia ou do lixo.');
 if(s.chopping?.index===index||s.plating?.slot===index)return result(s,false,'A panela está sendo usada no empratamento.');
 const p=s.inventory[index],d=ITEMS[p?.item];
 if(!p||!(p.item.startsWith('pot_')||p.item.startsWith('dish_')))return result(s,false,'Selecione uma panela com comida ou um prato pronto na mochila.');
 const next={inventory:s.inventory.map(p=>p?{...p}:null)};
 removeInventory(next,index,1);
 if(!addInventory(next,d.servings?'pot':'dirtyPlate',1))return result(s,false,'Libere espaço na mochila para devolver a panela ou o prato.');
 s.inventory=next.inventory;s.meals.wasted[d.recipe]+=d.servings||1;
 return result(s,true,'Comida descartada. '+(d.servings?'Panela vazia na mochila.':'Prato sujo na mochila.'));
}
function washPlates(s,id){
 const o=s.objects.find(o=>o.id===id);if(o?.type!=='sink'||!objectNear(s,o))return result(s,false,'Aproxime-se da pia.');
 if(s.player.hand?.item!=='dirtyPlate'||s.chopping||s.plating)return result(s,false,'Traga um prato sujo nas mãos.');
 s.player.hand={item:'plate',n:1};return result(s,true,'Prato limpo nas mãos.');
}

function collectDirty(s,id){
 const table=s.objects.find(o=>o.id===id);if(table?.type!=='table'||!objectNear(s,table))return result(s,false,'Aproxime-se da mesa.');
 if(s.player.hand||s.player.carry||s.chopping||s.plating)return result(s,false,'Libere as mãos para recolher a louça.');
 const chair=s.objects.find(o=>o.type==='chair'&&chairTable(s,o)?.id===id&&s.dirtyTables[o.id]>0);
 if(!chair)return result(s,false,'Não há pratos sujos nesta mesa.');
 s.dirtyTables[chair.id]--;s.player.hand={item:'dirtyPlate',n:1};return result(s,true,'Prato sujo nas mãos. Leve à pia.');
}

function equipmentConserved(s){let sums={pot:0,spoon:0,plate:0};for(const loc of allItemLocations(s))for(const p of loc.filter(Boolean)){if(p.item==='pot'||p.item==='cookingPot'||p.item.startsWith('pot_'))sums.pot+=p.n;else if(p.item==='spoon')sums.spoon+=p.n;else if(['plate','dirtyPlate'].includes(p.item)||p.item.startsWith('dish_'))sums.plate+=p.n;}sums.plate+=allActors(s).filter(a=>a.carry?.kind==='dish').length+s.customers.filter(c=>c.state==='eating').length;for(const [id,n]of Object.entries(s.dirtyTables)){if(!Number.isInteger(n)||n<0||!s.objects.some(o=>o.id===Number(id)&&o.type==='chair'))return false;sums.plate+=n;}return Object.keys(sums).every(k=>Number.isInteger(s.equipment[k])&&s.equipment[k]>=0&&sums[k]===s.equipment[k]);}
function mealsConserved(s){for(const r of Object.keys(RECIPES)){let n=0;for(const loc of allItemLocations(s))for(const p of loc.filter(Boolean))if(ITEMS[p.item]?.recipe===r)n+=p.n*(ITEMS[p.item].servings||1);for(const a of allActors(s))if(a.carry?.kind==='dish'&&s.orders.find(o=>o.id===a.carry.order)?.recipe===r)n++;n+=s.customers.filter(c=>c.state==='eating'&&c.recipe===r).length;for(const name of ['made','eaten','wasted'])if(!Number.isInteger(s.meals[name][r])||s.meals[name][r]<0)return false;if(n+s.meals.eaten[r]+s.meals.wasted[r]!==s.meals.made[r])return false;}const busy=s.objects.flatMap(stationSlots).filter(p=>p?.item==='cookingPot').reduce((n,p)=>n+p.n,0);return busy===(s.cooking?1:0)&&!s.inventory.some(p=>p?.item==='cookingPot');}

// Cozinha 0.13.0: equipamentos possuem encaixes e uma área de retirada,
// nunca um inventário genérico. Todas as transferências são atômicas.
const KITCHEN_CONFIG={batchPortions:1,requiresUtensil:false,cutSeconds:2,platingSeconds:2,readyCapacity:12,plateCapacity:99};
function stationSlots(o){
 if(o.type==='stove')return [...(o.pan?[{item:o.pan,n:1}]:[]),...(o.ingredients||[])];
 if(o.type==='kitchen')return [o.support||null,o.plates?{item:'plate',n:o.plates}:null,o.utensil?{item:'spoon',n:1}:null,...Object.entries(o.dishes||{}).map(([item,n])=>n?{item,n}:null)];
 return o.inventory||[];
}
function allItemLocations(s){return [s.inventory,s.player.hand?[s.player.hand]:[],s.recovery||[],...s.objects.map(stationSlots)];}
function readyCount(o){return Object.values(o.dishes||{}).reduce((a,b)=>a+b,0);}
function consumeItem(s,item,n){
 if(inventoryCount(s,item)<n)return false;
 for(let i=0;i<s.inventory.length&&n;i++){const p=s.inventory[i];if(p?.item===item){const q=Math.min(n,p.n);removeInventory(s,i,q);n-=q;}}
 return true;
}
function kitchenAction(s,id,action,item=null){
 const o=s.objects.find(o=>o.id===id);
 if(!o||!['stove','kitchen','prep'].includes(o.type)||!objectNear(s,o))return result(s,false,'Aproxime-se do equipamento selecionado.');
 if(s.plating?.prep===id)return result(s,false,'Empratamento em andamento. Aguarde ou cancele.');
 if(action==='installPan'&&o.type==='stove'){
  if(o.pan)return result(s,false,'O fogão já tem uma panela.');
  if(!consumeItem(s,'pot',1))return result(s,false,'Falta uma panela vazia na mochila.');
  o.pan='pot';return kitchenFeedback(s,o,'Panela instalada');
 }
 if(action==='takePan'&&['stove','kitchen'].includes(o.type))return takePhysicalPan(s,o);
 if(action==='installPlates'&&o.type==='kitchen'){
  const n=Math.min(inventoryCount(s,'plate'),KITCHEN_CONFIG.plateCapacity-o.plates);
  if(!n)return result(s,false,o.plates>=KITCHEN_CONFIG.plateCapacity?'Encaixe de pratos completo.':'Faltam pratos limpos na mochila.');
  consumeItem(s,'plate',n);o.plates+=n;return kitchenFeedback(s,o,n+' pratos instalados');
 }
 if(action==='installUtensil'&&o.type==='kitchen'){
  if(o.utensil)return result(s,false,'O talher já está instalado.');
  if(!consumeItem(s,'spoon',1))return result(s,false,'Falta um talher (colher) na mochila.');
  o.utensil=true;return kitchenFeedback(s,o,'Talher instalado');
 }
 if(action==='takePlates'&&o.type==='kitchen'){
  const n=Math.min(o.plates,inventorySpace(s,'plate'));
  if(!n)return result(s,false,'Sem pratos limpos disponíveis ou mochila cheia.');
  addInventory(s,'plate',n);o.plates-=n;return kitchenFeedback(s,o,n+' pratos na mochila');
 }
 if(action==='takeUtensil'&&o.type==='kitchen'){
  if(!o.utensil||!addInventory(s,'spoon',1))return result(s,false,'Sem talher instalado ou mochila cheia.');
  o.utensil=false;return kitchenFeedback(s,o,'Talher na mochila');
 }
 if(action==='takeDish'&&o.type==='kitchen'){
  const dish=item||Object.keys(o.dishes).find(k=>o.dishes[k]>0);
  if(!dish?.startsWith('dish_')||!o.dishes[dish])return result(s,false,'Não há esse prato pronto na bancada.');
  const quality=firstDishQuality(o,dish);if(!addInventory(s,dish,1,quality))return result(s,false,'Mochila cheia. O prato continua na bancada.');
  takeObject(s,o,dish,1,quality);return kitchenFeedback(s,o,'Prato pronto na mochila');
 }
 return result(s,false,'Ação indisponível.');
}
function kitchenFeedback(s,o,label){o.feedback={label,until:s.time+.9};return result(s,true,label+'.');}
function cookError(s,o,recipe){
 if(o?.type!=='stove'||!RECIPES[recipe])return 'Complete uma receita na panela.';
 if(s.player.hand||s.player.carry||s.chopping||s.plating)return 'Libere as mãos e conclua o trabalho manual antes de cozinhar.';
 if(s.cooking)return 'Há uma panela cozinhando.';
 if(o.pan!=='pot')return 'Instale uma panela vazia.';
 return recognizedRecipe(o)!==recipe?'A combinação não corresponde à receita.':null;
}
function startCook(s,id,recipe){
 const o=s.objects.find(o=>o.id===id);
 if(!objectNear(s,o))return result(s,false,'Aproxime-se do fogão.');
 const error=cookError(s,o,recipe);if(error)return result(s,false,error);
 let total=0,weighted=0,cost=0;
 for(const p of o.ingredients||[]){const raw=ITEMS[p.item].raw||p.item,q=p.quality||0;total+=p.n;weighted+=p.n*q;cost+=p.n*FOODS[raw].cost*QUALITY_CONFIG.costMultipliers[q];s.used[raw]+=p.n;}
 o.ingredients=[];o.pan='cookingPot';s.cookActive=true;s.ledger.foodCost+=cost;
 s.cooking={stove:id,recipe,servings:KITCHEN_CONFIG.batchPortions,quality:Math.floor(weighted/total),left:RECIPES[recipe].time,total:RECIPES[recipe].time};
 return kitchenFeedback(s,o,'Cozinhando — pode realizar outras tarefas');
}
function kitchenStep(s,dt){
 if(s.cooking){
  const job=s.cooking,o=s.objects.find(o=>o.id===job.stove);
  if(o?.pan==='cookingPot'){
   job.left=Math.max(0,job.left-dt);
   if(job.left<=1e-8){o.pan='pot_'+job.recipe+'_'+(job.servings||4);o.readyBatch={recipe:job.recipe,quality:job.quality??0,doneAt:s.time};s.meals.made[job.recipe]+=(job.servings||4);s.cooking=null;s.cookActive=false;kitchenFeedback(s,o,'Panela pronta — retirar');}
  }
 }
 for(const o of s.objects)if(o.readyBatch&&o.pan?.startsWith('pot_')){const stage=heatState(s,o).stage;if(stage!==o.heatStage){o.heatStage=stage;o.heatEvent=(o.heatEvent||0)+1;if(stage==='burned')o.burned=true;s.message=heatState(s,o).label;}}
 choppingStep(s,dt);platingStep(s,dt);
}
function platingPlan(s,o,recipe){
 if(o?.type!=='kitchen')return {error:'Use a mesa de cozinha.'};
 if(s.player.hand)return {error:'Libere as mãos.'};
 if(!o.plates)return {error:'Instale pratos limpos.'};
 const p=o.support;
 if(!p||!ITEMS[p.item]?.servings||p.burned)return {error:'Apoie uma panela com comida utilizável.'};
 if(readyCount(o)>=KITCHEN_CONFIG.readyCapacity)return {error:'Área de retirada cheia.'};
 return {recipe:ITEMS[p.item].recipe,item:p.item,quality:p.quality||0,portions:ITEMS[p.item].servings,count:1};
}
function plateFood(s,id){
 const o=s.objects.find(o=>o.id===id);
 if(!objectNear(s,o))return result(s,false,'Aproxime-se da mesa de cozinha.');
 if(s.plating||s.chopping)return result(s,false,'Conclua ou cancele o trabalho manual.');
 const plan=platingPlan(s,o);if(plan.error)return result(s,false,plan.error);
 s.plating={prep:id,...plan,left:KITCHEN_CONFIG.platingSeconds,total:KITCHEN_CONFIG.platingSeconds};
 return kitchenFeedback(s,o,'Empratando uma porção');
}
function cancelPlating(s){s.plating=null;return result(s,true,'Empratamento cancelado; itens preservados.');}
function platingStep(s,dt){
 const j=s.plating;if(!j)return;const o=s.objects.find(o=>o.id===j.prep);
 if(!o||o.support?.item!==j.item){cancelPlating(s);return;}
 if(!objectNear(s,o))return;
 j.left=Math.max(0,j.left-dt);if(j.left>1e-8)return;
 if(!o.plates||readyCount(o)>=KITCHEN_CONFIG.readyCapacity)return;
 o.support=j.portions===1?{item:'pot',n:1}:{item:'pot_'+j.recipe+'_'+(j.portions-1),n:1,quality:j.quality};
 o.plates--;putObject(s,o,'dish_'+j.recipe,1,j.quality);s.plating=null;kitchenFeedback(s,o,'Um prato pronto');
}
function recoverItems(s){
 let count=0;
 for(const p of s.recovery||[]){const n=Math.min(p.n,inventorySpace(s,p.item,p.quality??0));if(n){addInventory(s,p.item,n,p.quality??0,!!p.burned);p.n-=n;count+=n;}}
 s.recovery=s.recovery.filter(p=>p.n>0);return result(s,!!count,count?count+' itens preservados recolhidos.':'Libere espaço na mochila.');
}
function migrateKitchen(s){
 s.recovery=s.recovery||[];s.plating=s.plating||null;
 for(const o of s.objects){
  if(!['stove','kitchen'].includes(o.type)||!o.inventory)continue;
  const items=o.inventory.filter(Boolean).map(p=>({...p}));delete o.inventory;
  if(o.type==='stove'){
   const busy=items.find(p=>p.item==='cookingPot'),full=items.find(p=>p.item.startsWith('pot_')),empty=items.find(p=>p.item==='pot');
   const selected=busy||full||empty;o.pan=selected?.item||null;if(selected)selected.n--;
  }else{
   o.plates=0;o.utensil=false;o.dishes={};
   for(const p of items){
    if(p.item==='plate'){const n=Math.min(p.n,99);o.plates=n;p.n-=n;}
    if(p.item==='spoon'&&!o.utensil){o.utensil=true;p.n--;}
    if(p.item.startsWith('dish_')){const n=Math.min(p.n,KITCHEN_CONFIG.readyCapacity-readyCount(o));o.dishes[p.item]=n;p.n-=n;}
   }
  }
  for(const p of items)if(p.n>0)s.recovery.push(p);
 }
 // Try backpack first; excess remains explicitly recoverable, never discarded.
 if(s.recovery.length)recoverItems(s);
 if(s.cooking){delete s.cooking.slot;s.cooking.total=RECIPES[s.cooking.recipe]?.time;}
 syncContainers(s);s.version=VERSION;return s;
}
function migrateCleaning(s){
 for(const o of s.objects){
  if(!['sink','bin'].includes(o.type)||!o.inventory)continue;
  for(const p of o.inventory)if(p)s.recovery.push({...p});
  delete o.inventory;
 }
 if(s.recovery.length)recoverItems(s);
 syncContainers(s);s.version=VERSION;return s;
}
function validKitchen(s){
 const stack=p=>p&&ITEMS[p.item]&&Number.isInteger(p.n)&&p.n>0&&p.n<=itemLimit(p.item);
 if(!Array.isArray(s.recovery)||s.recovery.some(p=>!stack(p)||p.item==='cookingPot'))return false;
 for(const o of s.objects){
  if(['sink','bin'].includes(o.type)&&o.inventory!==undefined)return false;
  if(o.type==='stove'&&(o.inventory!==undefined||!(o.pan===null||o.pan==='pot'||o.pan==='cookingPot'||o.pan?.startsWith('pot_')&&ITEMS[o.pan])))return false;
  if(o.type==='kitchen'&&(o.inventory!==undefined||!Number.isInteger(o.plates)||o.plates<0||o.plates>99||typeof o.utensil!=='boolean'||!o.dishes||Object.entries(o.dishes).some(([k,n])=>!k.startsWith('dish_')||!ITEMS[k]||!Number.isInteger(n)||n<0)||readyCount(o)>KITCHEN_CONFIG.readyCapacity))return false;
 }
 if(s.cooking&&(!Number.isFinite(s.cooking.total)||s.cooking.total<=0||s.cooking.left>s.cooking.total))return false;
 if(!validPhysicalKitchen(s))return false;
 return true;
}


const QUALITY_CONFIG={names:['Comum','Prata','Ouro','Roxa'],costMultipliers:[1,1.25,1.5,2],satisfaction:[.7,.8,.9,1],safeSeconds:8,decayEnd:20,burnSeconds:25};
function receiveQuality(s,food,n,q=0){s.inv.receiving[food]+=n;if(q){s.receivingQuality??={};s.receivingQuality[food]??=[0,0,0,0];s.receivingQuality[food][q]+=n;}}
function receivingCount(s,food,q){const a=s.receivingQuality?.[food]||[0,0,0,0];return q?a[q]:s.inv.receiving[food]-a.slice(1).reduce((x,y)=>x+y,0);}
function objectQualityCount(o,item,q){if(o.type==='kitchen'){const a=o.dishQuality?.[item]||[0,0,0,0];return q?a[q]:objectCount(o,item)-a.slice(1).reduce((x,y)=>x+y,0);}return (o.inventory||[]).reduce((n,p)=>n+(p?.item===item&&(p.quality??0)===q?p.n:0),0);}
function firstDishQuality(o,item){for(let q=0;q<4;q++)if(objectQualityCount(o,item,q)>0)return q;return 0;}
function locationChunk(s,loc,food){if(loc==='receiving'){for(let q=0;q<4;q++){const n=receivingCount(s,food,q);if(n)return {n,quality:q};}return null;}for(const source of s.objects.filter(o=>o.inventory&&objectLocation(o)===loc)){const p=source.inventory.find(p=>p?.item===food);if(p)return {n:p.n,quality:p.quality??0,source};}return null;}
function takeChunk(s,loc,food,chunk,n){if(loc==='receiving')receiveQuality(s,food,-n,chunk.quality);else takeObject(s,chunk.source,food,n,chunk.quality);}
function ingredientPlan(s,recipe){let weighted=0,total=0,cost=0;for(const [food,count]of Object.entries(RECIPES[recipe].foods)){let left=count*4;for(const p of s.inventory){if(p?.item!==food)continue;const n=Math.min(left,p.n),q=p.quality??0;weighted+=n*q;total+=n;cost+=n*FOODS[food].cost*QUALITY_CONFIG.costMultipliers[q];left-=n;if(!left)break;}}return {quality:Math.floor(weighted/Math.max(total,1)+1e-8),cost};}
function batchQuality(s,o){const b=o.readyBatch;if(!b)return 0;const t=Math.max(0,s.time-b.doneAt);return Math.max(0,Math.ceil((b.quality??0)*(1-Math.max(0,t-8)/12)-1e-8));}
function heatState(s,o){const t=Math.max(0,s.time-(o.readyBatch?.doneAt??s.time))+1e-8;if(t>=25||o.burned)return {stage:'burned',label:'✕ Queimado — retirar e descartar',value:1};if(t>=20)return {stage:'danger',label:'⚠ Perto de queimar',value:(t-8)/17};if(t>=8)return {stage:'over',label:'⚠ Passando do ponto',value:(t-8)/17};return {stage:'ready',label:'✓ No ponto — retirar',value:1-t/8};}
function validQuality(s){const qok=q=>q===undefined||Number.isInteger(q)&&q>=0&&q<=3;for(const loc of allItemLocations(s))for(const p of loc.filter(Boolean))if(!qok(p.quality)||p.burned!==undefined&&(typeof p.burned!=='boolean'||!p.item.startsWith('pot_')))return false;for(const a of allActors(s))if(a.carry&&!qok(a.carry.quality))return false;for(const d of s.deliveries)if(!qok(d.quality))return false;for(const [food,a]of Object.entries(s.receivingQuality||{}))if(!FOODS[food]||!Array.isArray(a)||a.length!==4||a.some(n=>!Number.isInteger(n)||n<0)||a.slice(1).reduce((x,y)=>x+y,0)>s.inv.receiving[food])return false;for(const o of s.objects){for(const [dish,a]of Object.entries(o.dishQuality||{}))if(!ITEMS[dish]||!Array.isArray(a)||a.length!==4||a.some(n=>!Number.isInteger(n)||n<0)||a.slice(1).reduce((x,y)=>x+y,0)>(o.dishes[dish]||0))return false;if(o.readyBatch&&(!Number.isFinite(o.readyBatch.doneAt)||o.readyBatch.doneAt>s.time||!qok(o.readyBatch.quality)||!RECIPES[o.readyBatch.recipe]))return false;}return !s.cooking||qok(s.cooking.quality);}

// PHYSICAL_KITCHEN
function recognizedRecipe(o){return Object.keys(RECIPES).find(id=>{
 const need=Object.fromEntries(Object.entries(RECIPES[id].foods).map(([f,n])=>[f==='arroz'?f:f+'_cut',n*KITCHEN_CONFIG.batchPortions]));
 const got={};for(const p of o.ingredients||[])got[p.item]=(got[p.item]||0)+p.n;
 return Object.keys(got).length===Object.keys(need).length&&Object.entries(need).every(([f,n])=>got[f]===n);
})||null;}
function takePhysicalPan(s,o){
 if(s.player.hand||s.player.carry)return result(s,false,'Suas mãos estão ocupadas.');
 if(s.plating?.prep===o.id)return result(s,false,'Cancele o empratamento antes de retirar.');
 if(o.type==='kitchen'){
  if(!o.support)return result(s,false,'Não há panela apoiada.');s.player.hand=o.support;o.support=null;
 }else{
  if(!o.pan||o.pan==='cookingPot')return result(s,false,'Aguarde o cozimento terminar.');
  if(o.ingredients?.length)return result(s,false,'Retire os ingredientes antes de remover a panela.');
  s.player.hand={item:o.pan,n:1,quality:batchQuality(s,o),...(o.burned?{burned:true}:{})};
  o.pan=null;delete o.readyBatch;delete o.burned;delete o.heatStage;
 }
 return kitchenFeedback(s,o,'Panela nas mãos');
}
function removeHandDish(s,a,c,p){s.orders.find(o=>o.id===c.order).state='ready';a.carry={kind:'dish',order:c.order,quality:p.quality||0};}
function handStorage(s,id,action,index){
 const o=s.objects.find(o=>o.id===id),a=s.player;
 if(!o?.inventory||!objectNear(s,o))return result(s,false,'Aproxime-se do armazenamento.');
 if(s.chopping||s.plating||a.carry)return result(s,false,'Conclua a tarefa e libere as mãos.');
 if(action==='take'){
  if(a.hand)return result(s,false,'Suas mãos estão ocupadas. Guarde o item antes de retirar outro.');
  if(!Number.isInteger(index)||index<0||index>=o.inventory.length)return result(s,false,'Espaço inválido.');
  const p=o.inventory[index];if(!p)return result(s,false,'Espaço vazio.');
  a.hand={...p,n:1};removeInventory({inventory:o.inventory},index,1);syncContainers(s);return result(s,true,itemName(a.hand.item)+' nas mãos.');
 }
 if(action==='put'){
  const p=a.hand;if(!p)return result(s,false,'Suas mãos estão vazias.');
  if(!accepts(o,p.item)||(o.type==='potRack'?putObject(s,o,p.item,1,p.quality||0)!==1:!addInventory({inventory:o.inventory},p.item,1,p.quality||0,!!p.burned)))return result(s,false,'Sem espaço compatível; item preservado nas mãos.');
  a.hand=null;syncContainers(s);return result(s,true,'Item guardado.');
 }
 return result(s,false,'Ação inválida.');
}
function recoverHand(s,index){
 if(s.player.hand||s.player.carry||s.chopping||s.plating)return result(s,false,'Libere as mãos.');
 const p=s.recovery[index];if(!p)return result(s,false,'Item preservado ausente.');
 s.player.hand={...p,n:1};p.n--;s.recovery=s.recovery.filter(p=>p.n>0);return result(s,true,'Item antigo recuperado nas mãos.');
}
function physicalAction(s,id,action){
 const o=s.objects.find(o=>o.id===id),a=s.player;
 if(!o||!objectNear(s,o))return result(s,false,'Aproxime-se do objeto.');
 if(action==='cancelCut'){s.chopping=null;return result(s,true,'Corte cancelado; ingrediente permanece nas mãos.');}
 if(action==='cancelPlate')return cancelPlating(s);
 if(s.chopping||s.plating)return result(s,false,'Conclua ou cancele a tarefa manual.');
 if(action==='takePan')return takePhysicalPan(s,o);
 if(action==='chop'){
  const p=a.hand;if(a.carry||o.type!=='prep'||!['legumes','frango'].includes(p?.item))return result(s,false,'Traga frango cru ou legumes inteiros nas mãos.');
  s.chopping={hand:true,table:id,item:p.item,quality:p.quality||0,left:KITCHEN_CONFIG.cutSeconds,total:KITCHEN_CONFIG.cutSeconds};return kitchenFeedback(s,o,'Cortando '+itemName(p.item));
 }
 if(action==='support'){
  if(o.type!=='kitchen'||o.support||!a.hand||!(a.hand.item==='pot'||ITEMS[a.hand.item]?.servings))return result(s,false,'Traga uma panela e libere o apoio.');
  o.support=a.hand;a.hand=null;return kitchenFeedback(s,o,'Panela apoiada');
 }
 if(action==='installPan'){
  if(o.type!=='stove'||o.pan||a.hand?.item!=='pot')return result(s,false,'Traga uma panela vazia para um fogão livre.');
  o.pan='pot';a.hand=null;return kitchenFeedback(s,o,'Panela instalada');
 }
 if(action==='add'){
  if(o.type!=='stove'||o.pan!=='pot')return result(s,false,'Instale uma panela vazia.');
  const p=a.hand;if(!['arroz','legumes_cut','frango_cut'].includes(p?.item))return result(s,false,'Traga arroz, frango cortado ou legumes cortados nas mãos.');
  const next=[...(o.ingredients||[]),{...p,n:1}];
  const possible=Object.values(RECIPES).some(r=>next.every(q=>next.filter(v=>v.item===q.item).reduce((n,v)=>n+v.n,0)<=(r.foods[ITEMS[q.item]?.raw||q.item]||0)*KITCHEN_CONFIG.batchPortions));
  if(!possible)return result(s,false,'Ingrediente incompatível ou excedente; continua nas mãos.');
  a.hand=null;o.ingredients=next;return kitchenFeedback(s,o,recognizedRecipe(o)?'Receita identificada':'Ingrediente adicionado');
 }
 if(action==='removeIngredient'){
  if(a.hand||a.carry||o.type!=='stove'||o.pan!=='pot')return result(s,false,'Libere as mãos; só é possível corrigir antes de cozinhar.');
  const p=o.ingredients?.at(-1);if(!p)return result(s,false,'Não há ingredientes na panela.');
  a.hand=o.ingredients.pop();return kitchenFeedback(s,o,'Ingrediente devolvido às mãos');
 }
 if(action==='cook')return startCook(s,id,recognizedRecipe(o));
 if(action==='plate')return plateFood(s,id);
 if(action==='takeDish'){
  if(a.hand||a.carry)return result(s,false,'Libere as mãos.');
  const dish=Object.keys(o.dishes||{}).find(k=>o.dishes[k]>0);if(!dish)return result(s,false,'Não há prato pronto.');
  const quality=firstDishQuality(o,dish);takeObject(s,o,dish,1,quality);a.hand={item:dish,n:1,quality};return kitchenFeedback(s,o,'Prato nas mãos');
 }
 if(action==='putDish'){
  const p=a.hand;if(o.type!=='kitchen'||!p?.item.startsWith('dish_')||!objectSpace(o,p.item))return result(s,false,'Sem espaço para apoiar o prato.');
  putObject(s,o,p.item,1,p.quality||0);a.hand=null;return kitchenFeedback(s,o,'Prato apoiado');
 }
 if(action==='installPlates'){
  if(o.type!=='kitchen'||a.hand?.item!=='plate'||o.plates>=KITCHEN_CONFIG.plateCapacity)return result(s,false,'Traga um prato limpo; verifique o espaço na mesa.');
  o.plates++;a.hand=null;return kitchenFeedback(s,o,'Prato limpo instalado');
 }
 if(action==='takePlates'||action==='takeUtensil'){
  if(o.type!=='kitchen'||a.hand||a.carry)return result(s,false,'Libere as mãos.');
  if(action==='takePlates'){if(!o.plates)return result(s,false,'Não há pratos limpos.');o.plates--;a.hand={item:'plate',n:1};}
  else {if(!o.utensil)return result(s,false,'Não há talher instalado.');o.utensil=false;a.hand={item:'spoon',n:1};}
  return kitchenFeedback(s,o,'Item nas mãos');
 }
 if(action==='wash')return washPlates(s,id);
 if(action==='discardHand'){
  const p=a.hand,d=ITEMS[p?.item];if(!['sink','bin'].includes(o.type)||!d?.recipe)return result(s,false,'Traga comida pronta para descartar.');
  s.meals.wasted[d.recipe]+=d.servings||1;a.hand={item:d.servings?'pot':'dirtyPlate',n:1};return result(s,true,'Comida descartada; recipiente nas mãos.');
 }
 return result(s,false,'Ação indisponível.');
}
function choppingStep(s,dt){
 const j=s.chopping;if(!j)return;const o=s.objects.find(o=>o.id===j.table),p=s.player.hand;
 if(!o||p?.item!==j.item||(p.quality||0)!==j.quality){s.chopping=null;return;}
 if(!objectNear(s,o))return;
 j.left=Math.max(0,j.left-dt);if(j.left>1e-8)return;
 s.player.hand={item:j.item+'_cut',n:1,quality:j.quality};s.chopping=null;kitchenFeedback(s,o,'Ingrediente cortado nas mãos');
}

function migratePhysicalKitchen(s,sourceVersion){
 if(sourceVersion<10){
  for(const o of s.objects)if(o.type==='prep')o.type='kitchen';
  if(s.plating){/* No consumption has happened yet; cancellation preserves its pan. */s.plating=null;}
  s.chopping=null;
 }
 for(const o of s.objects)if(o.type==='stove')o.ingredients??=[];
 s.version=VERSION;
}
function validPhysicalKitchen(s){
 const stack=p=>p&&ITEMS[p.item]&&Number.isInteger(p.n)&&p.n===1&&Number.isInteger(p.quality??0)&&(p.quality??0)>=0&&(p.quality??0)<=3;
 if(s.player.hand&&(!stack(s.player.hand)||s.player.hand.item==='cookingPot'))return false;
 if(s.player.hand&&s.player.carry)return false;
 for(const o of s.objects){
  if(o.type==='stove'&&(!Array.isArray(o.ingredients)||o.ingredients.some(p=>!stack(p)||!['arroz','legumes_cut','frango_cut'].includes(p.item))||o.ingredients.length&&o.pan!=='pot'))return false;
  if(o.support&&(o.type!=='kitchen'||!stack(o.support)||!(o.support.item==='pot'||ITEMS[o.support.item]?.servings)))return false;
 }
 const j=s.chopping;if(j&&(!s.objects.some(o=>o.id===j.table&&o.type==='prep')||!['frango','legumes'].includes(j.item)||(j.hand?s.player.hand?.item:s.inventory[j.index]?.item)!==j.item||!Number.isFinite(j.left)||j.left<0||j.left>j.total||j.total!==KITCHEN_CONFIG.cutSeconds))return false;
 const p=s.plating;if(p&&(!s.objects.some(o=>o.id===p.prep&&o.type==='kitchen'&&o.support?.item===p.item)||!RECIPES[p.recipe]||p.count!==1||!Number.isFinite(p.left)||p.left<0||p.left>p.total||p.total!==KITCHEN_CONFIG.platingSeconds))return false;
 return true;
}

const api={newServiceHours,validServiceHours,serviceHours,serviceTimeText,newClock,calendarDate,clockText,clampReputation,newReputation,reputationLevel,utilityNear,handStorage,recoverHand,chairTable,recognizedRecipe,physicalAction,advanceTestClock,PLAYER_SPEED,PLAYER_RADIUS,setPlayerInput,playerVelocity,isMoving,takeOrder,serviceHours,serviceTimeText,serviceOpenError,setServiceHours,QUALITY_CONFIG,ingredientPlan,batchQuality,heatState,objectQualityCount,firstDishQuality,receivingCount,ARRIVAL_CONFIG,seatTable,KITCHEN_CONFIG,stationSlots,readyCount,kitchenAction,platingPlan,cancelPlating,recoverItems,TIME_CONFIG,REPUTATION_CONFIG,calendarDate,clockText,reputationLevel,applyVisitReputation,servicePending,CUSTOMER_CONFIG,newExperience,customerIndicator,satisfactionFor,canceledCarry,migrateSave,serve,furnishedTest,clearTestScene,itemLimit,itemName,itemIcon,objectNear,cookError,startCook,plateFood,discardFood,washPlates,collectDirty,equipmentConserved,mealsConserved,objectLocation,accepts,objectCount,objectSpace,syncContainers,putObject,takeObject,transferSlot,ITEMS,inventoryCount,inventorySpace,addInventory,removeInventory,collectReceiving,storageObject,W,H,CELL,VERSION,NAV,WALK_TIME,position,reserved,FOODS,CATALOG,RECIPES,PORTALS,DIRS,key,actor,fresh,rect,cells,hit,wall,fixed,blocked,near,allActors,route,accessPoints,closestAccess,goObject,go,arrived,moveActors,pushAside,place,remove,layoutError,seats,kit,buyTool,capacity,amount,transfer,purchase,deliver,supplyAction,toggleOpen,spawn,interact,pickupDish,atStove,kitchenEnough,step,foodConserved,valid,talk,mealCost};root.Restaurant=api;if(typeof module!=='undefined')module.exports=api;
})(typeof globalThis!=='undefined'?globalThis:this);

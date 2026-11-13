/* Entre Esquinas Restaurante 0.17.0. Parâmetros abaixo são hipóteses de protótipo. */
(function(root){
'use strict';
// Temporary call boundary: gameplay runs these rules in GDScript.
// Node-only regression tests retain the frozen previous engine as their oracle.
let nodeReference;
function nativeRule(name,args){
 if(typeof NativeRule==='function')return JSON.parse(NativeRule(JSON.stringify({name,args})));
 nodeReference??=require('../qa/referencia-migracao/regras-legado.cjs');
 if(name==='setPlayerInput'){nodeReference.setPlayerInput(args[0],args[1],args[2]);return {actor:args[0].player,input:nodeReference.playerVelocity(args[0].player)};}
 if(name==='moveActors'){nodeReference.moveActors(args[0],args[1]);return {...args[0],input:nodeReference.playerVelocity(args[0].player)};}
 if(name==='pushAside'){const s=args[0],actors=nodeReference.allActors(s),locked=new Set(args[3]),seen=new Set(args[4]);const value=nodeReference.pushAside(s,actors.find(a=>a.id===args[1]),actors.find(a=>a.id===args[2]),locked,seen);return {...s,value,locked:[...locked],seen:[...seen]};}
 if(['startMotion','advanceMotion','go'].includes(name)){const value=nodeReference[name](...args);
 if(["place","remove"].includes(name))return {value,state:args[0]};
 if(["chairTable","seatTable"].includes(name))return value?.id??null;
 if(name==="seats")return value.map(o=>o.id);return {value,actor:args[0]};}
 if(name==='goObject'){const value=nodeReference.goObject(...args);return {value,actor:args[1]};}
 if(name==='route')args[5]=new Set(args[5]);
 const value=nodeReference[name](...args);
 if(["place","remove"].includes(name))return {value,state:args[0]};
 if(["chairTable","seatTable"].includes(name))return value?.id??null;
 if(name==="seats")return value.map(o=>o.id);
 if(["recoverItems","migrateKitchen","migrateCleaning","migratePhysicalKitchen","migrateHands"].includes(name))return {value:["recoverItems","migrateHands"].includes(name)?value:null,state:args[0]};
 if(["putObject","takeObject"].includes(name))return {value,object:args[1],inv:args[0].inv};
 if(name==="syncContainers")return {value:null,inv:args[0].inv};
 return ['addInventory','removeInventory'].includes(name)?{value,inventory:args[0].inventory}:value;
}
// Preserve existing references while applying native mutable results.
function syncNative(target,source){
 if(Array.isArray(target))target.length=source.length;
 else for(const key of Object.keys(target))if(!Object.hasOwn(source,key))delete target[key];
 for(const [key,value]of Object.entries(source)){
  if(value&&typeof value==='object'&&target[key]&&typeof target[key]==='object'&&Array.isArray(value)===Array.isArray(target[key]))syncNative(target[key],value);
  else target[key]=value;
 }
}
function migrateNative(name,s,...args){const out=nativeRule(name,[s,...args]);syncNative(s,out.state);return out.value;}
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
function newServiceHours(){return nativeRule("newServiceHours",[]);}
function validServiceHours(hours){return nativeRule("validServiceHours",[hours]);}
function serviceHours(s){return nativeRule("serviceHours",[s]);}
function serviceTimeText(minute){return nativeRule("serviceTimeText",[minute]);}
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

function newClock(){return nativeRule("newClock",[]);}
function calendarDate(day){return nativeRule("calendarDate",[day]);}
function clockText(s){return nativeRule("clockText",[s]);}
function clampReputation(n){return nativeRule("clampReputation",[n]);}
function newReputation(){return nativeRule("newReputation",[]);}
function reputationLevel(score){return nativeRule("reputationLevel",[score]);}
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
  if(!migrateNative("migrateHands",s))return null;
 }
 return valid(s)?s:null;
}catch{return null}}

// Transitional adapter: Godot creates these states in Partida.gd.
// Node regression tests use frozen reference data, not a second implementation.
function nativeInitial(compact,singleRoom,mode){
 const templates=typeof NativePartidas!=='undefined'?NativePartidas:require('../qa/referencia-migracao/partidas.json');
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
function rect(o){return nativeRule("rect",[o]);}
function cells(o){return nativeRule("cells",[o]);}
function hit(o,x,y){return nativeRule("hit",[o,x,y]);}
function wall(room,x,y,s=null){return nativeRule("wall",[room,x,y,s?{compact:s.compact,singleRoom:s.singleRoom}:null]);}
function fixed(room,x,y,s=null){return nativeRule("fixed",[room,x,y,s?{compact:s.compact,singleRoom:s.singleRoom}:null]);}
function blocked(s,room,x,y,a=null,objects=s.objects){if(wall(room,x,y,s)||fixed(room,x,y,s))return true;return objects.some(o=>o.room===room&&hit(o,x,y)&&!(o.type==='chair'&&a&&a.seat===o.id));}
function near(a,p,r=1){return nativeRule("near",[a,p,r]);}
function allActors(s){return [s.player,...s.workers,...s.residents,...s.customers.filter(c=>!c.done)];}
const NAV=DIRS.concat([[1,-1],[1,1],[-1,1],[-1,-1]]),WALK_TIME=.18;
function route(s,room,from,to,a=null,avoid=new Set(),objects=s.objects){return nativeRule('route',[{compact:s.compact,singleRoom:s.singleRoom},room,from,to,a?{seat:a.seat}:null,[...avoid],objects]);}
// Transient input transport; movement decisions execute in Movimento.gd.
const PLAYER_SPEED=3.3,PLAYER_RADIUS=.20,playerInput=new WeakMap();
function playerVelocity(a){return playerInput.get(a)||null;}
function isMoving(a){return nativeRule('isMoving',[a,playerVelocity(a)]);}
function position(a){return nativeRule('position',[a]);}
function reserved(a){return nativeRule('reserved',[a]);}
function actorWalkTime(a){return nativeRule('actorWalkTime',[a]);}
function arrived(a){return nativeRule('arrived',[a]);}
function goalInRoom(a){return nativeRule('goalInRoom',[a]);}
function accessPoints(s,o,objects=s.objects){return nativeRule('accessPoints',[{compact:s.compact,singleRoom:s.singleRoom,objects},o,objects]);}
function closestAccess(s,a,o){return nativeRule('closestAccess',[s,a,o]);}
function occupants(s,a){return new Set(nativeRule('occupants',[s,a]));}
function startMotion(a,to,offsetX=0,offsetY=0){const out=nativeRule('startMotion',[a,to,offsetX,offsetY]);syncNative(a,out.actor);return out.value;}
function advanceMotion(a,dt){const out=nativeRule('advanceMotion',[a,dt]);syncNative(a,out.actor);return out.value;}
function setPlayerInput(s,dx,dy){const out=nativeRule('setPlayerInput',[s,dx,dy,playerVelocity(s.player)]);syncNative(s.player,out.actor);if(out.input)playerInput.set(s.player,out.input);else playerInput.delete(s.player);}
function go(a,p){playerInput.delete(a);const out=nativeRule('go',[a,p]);syncNative(a,out.actor);}
function goObject(s,a,o){const out=nativeRule('goObject',[s,a,o]);syncNative(a,out.actor);if(out.value)playerInput.delete(a);return out.value;}
function applyMovement(s,out){for(const key of ['player','workers','residents','customers'])syncNative(s[key],out[key]);s.flowWaits=out.flowWaits;}
function moveActors(s,dt=WALK_TIME){const out=nativeRule('moveActors',[s,dt,playerVelocity(s.player)]);applyMovement(s,out);if(out.input)playerInput.set(s.player,out.input);else playerInput.delete(s.player);}
function pushAside(s,b,requester,locked,seen=new Set()){const out=nativeRule('pushAside',[s,b.id,requester.id,[...locked],[...seen]]);applyMovement(s,out);locked.clear();for(const k of out.locked)locked.add(k);seen.clear();for(const k of out.seen)seen.add(k);return out.value;}
// Native construction rules; adapters retain object identity for game callers.
function editError(s){return nativeRule('editError',[s]);}
function layoutError(s,objects){return nativeRule('layoutError',[s,objects]);}
function longSideSeat(chair,table){return nativeRule('longSideSeat',[chair,table]);}
function chairTable(s,chair,objects=s.objects){const id=nativeRule('chairTable',[s,chair||null,objects]);return objects.find(o=>o.id===id);}
function seatTable(s,chair,objects=s.objects){const id=nativeRule('seatTable',[s,chair||null,objects]);return objects.find(o=>o.id===id);}
function chairLayoutError(s,chair,objects){return nativeRule('chairLayoutError',[s,chair,objects]);}
function seats(s){const ids=new Set(nativeRule('seats',[s]));return s.objects.filter(o=>ids.has(o.id));}
function kit(s){return nativeRule('kit',[s]);}
function applyConstruction(s,out,prior,moving=null){
 if(!out.value.ok)return out.value;
 s.objects=out.state.objects.map(source=>{const old=prior.find(o=>o.id===source.id&&o.id!==moving);if(old){syncNative(old,source);return old;}return source;});
 s.cash=out.state.cash;s.serial=out.state.serial;syncNative(s.ledger,out.state.ledger);syncNative(s.inv,out.state.inv);
 if(out.value.object)out.value.object=s.objects.find(o=>o.id===out.value.object.id);
 return out.value;
}
function place(s,type,x,y,rot=0,moving=null){const prior=s.objects;return applyConstruction(s,nativeRule('place',[s,type,x,y,rot,moving]),prior,moving);}
function remove(s,id){const prior=s.objects;return applyConstruction(s,nativeRule('remove',[s,id]),prior);}
const ITEMS={legumes_cut:{name:'Legumes cortados',raw:'legumes'},frango_cut:{name:'Frango cortado',raw:'frango'},...FOODS,pot:{name:'Panela'},spoon:{name:'Colher / utensílio'},plate:{name:'Prato limpo'},dirtyPlate:{name:'Prato sujo'},cookingPot:{name:'Panela em preparo',limit:1}};
for(const [r,d]of Object.entries(RECIPES)){ITEMS['dish_'+r]={name:'Prato de '+d.name,recipe:r};for(let n=1;n<=4;n++)ITEMS['pot_'+r+'_'+n]={name:'Panela: '+d.name+' ('+n+'/4 porções)',recipe:r,servings:n,limit:1};}
function itemLimit(item){return nativeRule("itemLimit",[item]);}
function itemName(item){return ITEMS[item]?.name||'Item desconhecido';}
function itemIcon(item){return FOODS[item]?{arroz:'🌾',legumes:'🥕',frango:'🍗'}[item]:item==='spoon'?'🥄':item==='plate'?'🍽️':item==='dirtyPlate'?'🧽':item.startsWith('dish_')?'🍛':item==='pot'?'🥘':'🍲';}
function inventoryCount(s,item){return nativeRule("inventoryCount",[{inventory:s.inventory},item]);}
function inventorySpace(s,item,quality=0){return nativeRule("inventorySpace",[{inventory:s.inventory},item,quality]);}
function addInventory(s,item,n,quality=0,burned=false){const out=nativeRule("addInventory",[{inventory:s.inventory},item,n,quality,burned]);s.inventory.splice(0,s.inventory.length,...out.inventory);return out.value;}
function removeInventory(s,index,n){const out=nativeRule("removeInventory",[{inventory:s.inventory},index,n]);s.inventory.splice(0,s.inventory.length,...out.inventory);return out.value;}
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

function objectLocation(o){return nativeRule("objectLocation",[o]);}
function accepts(o,item){return nativeRule("accepts",[o,item]);}
function objectCount(o,item){return nativeRule("objectCount",[o,item]);}
function objectSpace(o,item,quality=0){return nativeRule("objectSpace",[o,item,quality]);}
function syncContainers(s){const out=nativeRule("syncContainers",[{objects:s.objects,inv:s.inv}]);syncNative(s.inv,out.inv);}
function putObject(s,o,item,n,quality=0){const out=nativeRule("putObject",[{objects:s.objects,inv:s.inv},o,item,n,quality]);syncNative(o,out.object);syncNative(s.inv,out.inv);return out.value;}
function takeObject(s,o,item,n,quality=null){const out=nativeRule("takeObject",[{objects:s.objects,inv:s.inv},o,item,n,quality]);syncNative(o,out.object);syncNative(s.inv,out.inv);return out.value;}
function changeLocation(s,loc,food,n){if(loc==='receiving'){s.inv.receiving[food]+=n;return Math.abs(n);}let left=Math.abs(n);for(const o of s.objects.filter(o=>o.inventory&&objectLocation(o)===loc)){let q=n>0?putObject(s,o,food,left):takeObject(s,o,food,left);left-=q;if(!left)break;}return Math.abs(n)-left;}
function capacity(s,loc,food){return nativeRule("capacity",[{objects:s.objects,inv:s.inv},loc,food]);}
function amount(s,loc,food){return nativeRule("amount",[{objects:s.objects,inv:s.inv},loc,food]);}
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
function foodConserved(s){return nativeRule("foodConserved",[s]);}

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

function equipmentConserved(s){return nativeRule("equipmentConserved",[s]);}
function mealsConserved(s){return nativeRule("mealsConserved",[s]);}

// Cozinha 0.13.0: equipamentos possuem encaixes e uma área de retirada,
// nunca um inventário genérico. Todas as transferências são atômicas.
const KITCHEN_CONFIG={batchPortions:1,requiresUtensil:false,cutSeconds:2,platingSeconds:2,readyCapacity:12,plateCapacity:99};
function stationSlots(o){return nativeRule("stationSlots",[o]);}
function allItemLocations(s){return [s.inventory,s.player.hand?[s.player.hand]:[],s.recovery||[],...s.objects.map(stationSlots)];}
function readyCount(o){return nativeRule("readyCount",[o]);}
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
function recoverItems(s){return migrateNative("recoverItems",s);}
function migrateKitchen(s){migrateNative("migrateKitchen",s);return s;}
function migrateCleaning(s){migrateNative("migrateCleaning",s);return s;}
function validKitchen(s){return nativeRule("validKitchen",[s]);}

const QUALITY_CONFIG={names:['Comum','Prata','Ouro','Roxa'],costMultipliers:[1,1.25,1.5,2],satisfaction:[.7,.8,.9,1],safeSeconds:8,decayEnd:20,burnSeconds:25};
function receiveQuality(s,food,n,q=0){s.inv.receiving[food]+=n;if(q){s.receivingQuality??={};s.receivingQuality[food]??=[0,0,0,0];s.receivingQuality[food][q]+=n;}}
function receivingCount(s,food,q){const a=s.receivingQuality?.[food]||[0,0,0,0];return q?a[q]:s.inv.receiving[food]-a.slice(1).reduce((x,y)=>x+y,0);}
function objectQualityCount(o,item,q){return nativeRule("objectQualityCount",[o,item,q]);}
function firstDishQuality(o,item){return nativeRule("firstDishQuality",[o,item]);}
function locationChunk(s,loc,food){if(loc==='receiving'){for(let q=0;q<4;q++){const n=receivingCount(s,food,q);if(n)return {n,quality:q};}return null;}for(const source of s.objects.filter(o=>o.inventory&&objectLocation(o)===loc)){const p=source.inventory.find(p=>p?.item===food);if(p)return {n:p.n,quality:p.quality??0,source};}return null;}
function takeChunk(s,loc,food,chunk,n){if(loc==='receiving')receiveQuality(s,food,-n,chunk.quality);else takeObject(s,chunk.source,food,n,chunk.quality);}
function ingredientPlan(s,recipe){return nativeRule("ingredientPlan",[s,recipe]);}
function batchQuality(s,o){return nativeRule("batchQuality",[s,o]);}
function heatState(s,o){return nativeRule("heatState",[s,o]);}
function validQuality(s){return nativeRule("validQuality",[s]);}

// PHYSICAL_KITCHEN
function recognizedRecipe(o){return nativeRule("recognizedRecipe",[o]);}
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

function migratePhysicalKitchen(s,sourceVersion){migrateNative("migratePhysicalKitchen",s,sourceVersion);}
function validPhysicalKitchen(s){return nativeRule("validPhysicalKitchen",[s]);}

const api={utilityNear,handStorage,recoverHand,chairTable,recognizedRecipe,physicalAction,advanceTestClock,PLAYER_SPEED,PLAYER_RADIUS,setPlayerInput,playerVelocity,isMoving,takeOrder,serviceHours,serviceTimeText,serviceOpenError,setServiceHours,QUALITY_CONFIG,ingredientPlan,batchQuality,heatState,objectQualityCount,firstDishQuality,receivingCount,ARRIVAL_CONFIG,seatTable,KITCHEN_CONFIG,stationSlots,readyCount,kitchenAction,platingPlan,cancelPlating,recoverItems,TIME_CONFIG,REPUTATION_CONFIG,calendarDate,clockText,reputationLevel,applyVisitReputation,servicePending,CUSTOMER_CONFIG,newExperience,customerIndicator,satisfactionFor,canceledCarry,migrateSave,serve,furnishedTest,clearTestScene,itemLimit,itemName,itemIcon,objectNear,cookError,startCook,plateFood,discardFood,washPlates,collectDirty,equipmentConserved,mealsConserved,objectLocation,accepts,objectCount,objectSpace,syncContainers,putObject,takeObject,transferSlot,ITEMS,inventoryCount,inventorySpace,addInventory,removeInventory,collectReceiving,storageObject,W,H,CELL,VERSION,NAV,WALK_TIME,position,reserved,FOODS,CATALOG,RECIPES,PORTALS,DIRS,key,actor,fresh,rect,cells,hit,wall,fixed,blocked,near,allActors,route,accessPoints,closestAccess,goObject,go,arrived,moveActors,pushAside,place,remove,layoutError,seats,kit,buyTool,capacity,amount,transfer,purchase,deliver,supplyAction,toggleOpen,spawn,interact,pickupDish,atStove,kitchenEnough,step,foodConserved,valid,talk,mealCost};root.Restaurant=api;if(typeof module!=='undefined')module.exports=api;
})(typeof globalThis!=='undefined'?globalThis:this);

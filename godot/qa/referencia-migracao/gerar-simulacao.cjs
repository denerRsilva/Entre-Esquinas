const fs=require('fs'),path=require('path'),R=require('./regras-legado.cjs');
const clone=x=>JSON.parse(JSON.stringify(x));const base=R.furnishedTest(true,true),cases=[];
function diff(a,b,p=[]){if(JSON.stringify(a)===JSON.stringify(b))return [];if(a&&b&&!Array.isArray(a)&&!Array.isArray(b)&&typeof a==='object'&&typeof b==='object')return [...new Set([...Object.keys(a),...Object.keys(b)])].flatMap(k=>!(k in b)?[{path:[...p,k],remove:true}]:!(k in a)?[{path:[...p,k],value:b[k]}]:diff(a[k],b[k],[...p,k]));return [{path:p,value:b}];}
function add(system,op,s,params,velocity=null){let input=clone(s),draws=0;const rng=()=>[.1,.8,.2,.9,.5][draws++%5];if(velocity)R.setPlayerInput(s,velocity.x,velocity.y);input=clone(s);const initialVelocity=clone(R.playerVelocity(s.player));let value=R[op](s,...params,rng);cases.push({system,operation:op,input:diff(base,input),params:params.map(p=>p&&p.id?p.id:p),velocity:initialVelocity,draws,expected:{value:value??null,patch:diff(base,s),velocity:clone(R.playerVelocity(s.player))}});}
for(const compact of [false,true])for(const single of [false,true]){
 if(single&&!compact)continue;
 for(const dt of [.01,.1,7,200,1680]){let s=R.furnishedTest(compact,single);add('simulacao','step',s,[dt]);}
 for(const task of ['none','waiter','logistics'])for(const dt of [1,40,150]){
 const s=R.furnishedTest(compact,single);s.workers.forEach(w=>w.task=task);s.serviceHours=[{start:360,end:900},{start:1080,end:1320}];s.open=true;R.receiveQuality(s,'frango',8,3);R.receiveQuality(s,'legumes',5,2);add('simulacao','step',s,[dt]);
 }
}
for(const hand of [null,{item:'arroz',n:1,quality:2}])for(const x of [0,1,-1]){const s=clone(base);s.player.hand=hand;add('simulacao','step',s,[2],{x,y:1});}
for(const scenario of ['normal','ending','noMenu','occupiedEntrance','dirty','full']){let s=clone(base);if(scenario==='ending')s.clock.ending=true;if(scenario==='noMenu')Object.keys(s.menu).forEach(k=>s.menu[k]=false);if(scenario==='occupiedEntrance')Object.assign(s.player,{x:7,y:13});if(scenario==='dirty')s.objects.filter(o=>o.type==='chair').forEach(o=>s.dirtyTables[o.id]=1);if(scenario==='full')s.objects.filter(o=>o.type==='chair').forEach((o,i)=>s.customers.push({id:'test'+i,seat:o.id,done:false}));add('simulacao','spawn',s,[]);}
for(const from of ['receiving','storage','kitchen'])for(const to of ['receiving','storage','kitchen'])for(const food of Object.keys(R.FOODS))for(const n of [0,1,10,99]){const s=R.furnishedTest(false,false);R.receiveQuality(s,food,8,2);add('logistica','transfer',s,[from,to,food,n]);}
for(const loc of ['receiving','storage','kitchen'])for(const food of Object.keys(R.FOODS))for(const n of [-10,0,1,5]){const s=clone(base);add('logistica','changeLocation',s,[loc,food,n]);}
for(const moving of [false,true])for(const occupied of [false,true]){const s=clone(base);s.objects.push({id:99,type:'receiving',x:20,y:12,rot:0,room:'restaurant'});Object.assign(s.player,{x:20,y:11,hand:occupied?{item:'pot',n:1}:null});R.receiveQuality(s,'frango',8,2);add('logistica','collectReceiving',s,[],moving?{x:1,y:0}:null);}
fs.writeFileSync(path.join(__dirname,'simulacao.json'),JSON.stringify({base,cases}));console.log(cases.length);

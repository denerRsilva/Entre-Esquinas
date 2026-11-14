const fs=require('fs'),R=require('./regras-legado.cjs');
const clone=x=>JSON.parse(JSON.stringify(x));const base=R.furnishedTest(true,true);const cases=[];
function diff(a,b,path=[]){if(JSON.stringify(a)===JSON.stringify(b))return [];if(a&&b&&!Array.isArray(a)&&!Array.isArray(b)&&typeof a==='object'&&typeof b==='object'){return [...new Set([...Object.keys(a),...Object.keys(b)])].flatMap(k=>!(k in b)?[{path:[...path,k],remove:true}]:!(k in a)?[{path:[...path,k],value:b[k]}]:diff(a[k],b[k],[...path,k]));}return [{path,value:b}];}
function add(op,s,params){let input=clone(s),value=R[op](s,...params);cases.push({operation:op,input:diff(base,input),params,expected:{value:value??null,patch:diff(base,s)}});}
for(const type of ['stove','prep','kitchen','sink','bin','fridge','potRack','table']){
 for(const hand of [null,{item:'pot',n:1},{item:'legumes',n:1,quality:2},{item:'legumes_cut',n:1,quality:1},{item:'frango_cut',n:1,quality:3},{item:'arroz',n:1,quality:0},{item:'plate',n:1},{item:'dirtyPlate',n:1},{item:'pot_sopa_1',n:1,quality:2},{item:'dish_sopa',n:1,quality:3}]){
 for(const action of ['chop','cancelCut','cancelPlate','support','installPan','add','removeIngredient','cook','plate','takePan','takeDish','putDish','installPlates','takePlates','takeUtensil','wash','discardHand','unknown']){
 const s=clone(base),o=s.objects.find(o=>o.type===type),p=R.accessPoints(s,o)[0];Object.assign(s.player,p,{hand:clone(hand)});add('physicalAction',s,[o.id,action]);
 }
 }
}
for(const type of ['fridge','potRack'])for(const action of ['take','put','unknown'])for(const index of [-1,0,1,8,null]){
 const s=clone(base),o=s.objects.find(o=>o.type===type);Object.assign(s.player,R.accessPoints(s,o)[0]);add('handStorage',s,[o.id,action,index]);
}
for(const recipe of Object.keys(R.RECIPES))for(const q of [0,1,2,3]){
 let s=clone(base),o=s.objects.find(o=>o.type==='stove');Object.assign(s.player,R.accessPoints(s,o)[0]);o.ingredients=Object.entries(R.RECIPES[recipe].foods).map(([food,n])=>({item:food==='arroz'?food:food+'_cut',n,quality:q}));add('startCook',clone(s),[o.id,recipe]);R.startCook(s,o.id,recipe);
 for(const dt of [.1,R.RECIPES[recipe].time,100]){const t=clone(s);t.time+=dt;add('kitchenStep',t,[dt]);}
 for(const time of [0,5,15,50,100,1000]){const t=clone(s);R.kitchenStep(t,100);t.time+=time;add('kitchenStep',t,[0]);}
}
for(const item of ['legumes','frango'])for(const dt of [.5,2,4])for(const move of [false,true]){const s=clone(base),o=s.objects.find(o=>o.type==='prep');Object.assign(s.player,R.accessPoints(s,o)[0],{hand:{item,n:1,quality:2}});R.physicalAction(s,o.id,'chop');if(move)s.player.x=7;add('choppingStep',s,[dt]);}
for(const portion of [1,2,4])for(const dt of [.5,2,4])for(const cancel of [false,true]){const s=clone(base),o=s.objects.find(o=>o.type==='kitchen');Object.assign(s.player,R.accessPoints(s,o)[0]);o.support={item:'pot_sopa_'+portion,n:1,quality:3};R.plateFood(s,o.id);if(cancel)o.support=null;add('platingStep',s,[dt]);}
fs.writeFileSync(require('path').join(__dirname,'cozinha.json'),JSON.stringify({base,cases}));console.log(cases.length);

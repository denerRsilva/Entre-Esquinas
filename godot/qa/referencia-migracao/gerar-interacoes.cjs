const {vm,R,source,pointerSource}=require('./interacoes-legado.cjs'),fs=require('fs'),path=require('path');
const clone=x=>JSON.parse(JSON.stringify(x)),base=R.furnishedTest(true,true),cases=[];
function diff(a,b,p=[]){if(JSON.stringify(a)===JSON.stringify(b))return [];if(a&&b&&!Array.isArray(a)&&!Array.isArray(b)&&typeof a==='object'&&typeof b==='object')return [...new Set([...Object.keys(a),...Object.keys(b)])].flatMap(k=>!(k in b)?[{path:[...p,k],remove:true}]:!(k in a)?[{path:[...p,k],value:b[k]}]:diff(a[k],b[k],[...p,k]));return [{path:p,value:b}];}
function add(operation,s,params,configuration={}){
 const effects=[],inputContext={pending:configuration.pending||null,current:configuration.current!==false,selected:configuration.selected??null,building:!!configuration.building,moving:!!configuration.moving};
 if(inputContext.moving){R.setPlayerInput(s,1,0);R.moveActors(s,.05);}
 inputContext.moving=!!R.playerVelocity(s.player)?.moving;
 const input=clone(s),velocity=clone(R.playerVelocity(s.player));
 const context={R,state:s,building:inputContext.building?{}:null,selectedObject:inputContext.selected,effects};
 context.pendingInteraction=inputContext.pending?{...clone(inputContext.pending),state:inputContext.current?s:{}}:null;
 context.tell=(message,bad=false)=>{s.message=message;effects.push({kind:'tell',message,bad})};
 context.openDialog=mode=>effects.push({kind:'dialog',mode});context.openObjectInventory=id=>effects.push({kind:'inventory',id});
 vm.createContext(context);vm.runInContext(source,context);
 let args=params;if(['primaryObjectAction','queuePhysical'].includes(operation))args=[s.objects.find(o=>o.id===params[0]),...params.slice(1)];
 if(operation==='approachCustomer')args=[s.customers.find(c=>c.id===params[0])];
 let value;
 if(operation==='pointerDown'){
  const pointer=params[0];context.prepOptionsId=null;context.prepChoice=null;context.constructionMode=pointer.construction;context.building=clone(pointer.building);context.buildPointer=null;
  context.releaseKeyboard=()=>R.setPlayerInput(s,0,0);
  context.worldPointer=()=>pointer.world;
  context.canvas={getBoundingClientRect:()=>({left:0,top:60,width:960,height:640}),setPointerCapture:pointerId=>effects.push({kind:'capture',x:context.buildPointer.x,y:context.buildPointer.y,pointerId})};
  context.beginBuild=(type,moving)=>effects.push({kind:'beginBuild',type,moving});
  context.updatePreview=()=>effects.push({kind:'preview',x:context.hover.x,y:context.hover.y});
  context.refresh=()=>effects.push({kind:'refresh'});
  vm.runInContext(pointerSource,context);value=context.canvas.onpointerdown(pointer);
 }else value=context[operation](...args);
 const job=context.pendingInteraction;
 const pending=job?Object.fromEntries(Object.entries(job).filter(([k])=>k!=='state')):null;
 cases.push({operation,input:diff(base,input),params,context:inputContext,velocity,expected:{value:value??null,patch:diff(base,s),pending,current:job?job.state===s:inputContext.current,selected:context.selectedObject,effects,velocity:clone(R.playerVelocity(s.player))}});
}
const hands=[null,...['pot','plate','dirtyPlate','arroz','legumes','frango','legumes_cut','pot_sopa_1','dish_sopa'].map(item=>({item,n:1,quality:2}))];
for(const type of ['stove','prep','kitchen','fridge','potRack','sink','bin','table','chair'])for(const hand of hands)for(const nearby of [false,true]){
 const s=clone(base),o=s.objects.find(o=>o.type===type);s.player.hand=clone(hand);if(nearby)Object.assign(s.player,R.accessPoints(s,o)[0]);add('primaryObjectAction',s,[o.id]);
}
for(const pan of [null,'pot','cookingPot','pot_sopa_1'])for(const hand of hands)for(const ingredients of [[],[{item:'legumes_cut',n:2,quality:2}]]){
 const s=clone(base),o=s.objects.find(o=>o.type==='stove');o.pan=pan;o.ingredients=clone(ingredients);s.player.hand=clone(hand);Object.assign(s.player,R.accessPoints(s,o)[0]);add('primaryObjectAction',s,[o.id],{moving:true});
}
for(const phase of ['waiting','ordered','eat','leaving'])for(const hand of [null,{item:'dish_sopa',n:1,quality:2}])for(const direct of [false,true]){
 const s=clone(base);s.customers=[{...clone(s.player),id:'clientTest',room:'restaurant',x:9,y:9,seat:4,state:phase,recipe:'sopa',order:'order1',timer:0,experience:R.newExperience(()=>.5)}];s.orders=[{id:'order1',recipe:'sopa',state:'waiting',client:'clientTest',price:12}];s.player.hand=hand;if(direct)Object.assign(s.player,{x:8,y:9});add('primaryObjectAction',s,[1]);add('queueInteraction',clone(s),['customer','clientTest']);
}
for(const kind of ['physical','storage','utility','wash','clean','customer','computer','receiving','serviceSign'])for(const status of ['near','far','expired','stale','building','moving','missing','changed']){
 const s=clone(base);s.objects.push({id:99,type:'computer',room:'restaurant',x:20,y:12,rot:0});let type=({physical:'prep',storage:'fridge',utility:'computer',wash:'sink',clean:'table'})[kind]||'table',o=s.objects.find(o=>o.type===type);s.player.hand={item:kind==='wash'?'dirtyPlate':'legumes',n:1,quality:2};
 const job={kind,target:o.id,action:'chop',index:0,phase:'waiting',until:30,wasOpen:s.open,period:s.period};
 if(kind==='customer'){s.customers=[{...clone(s.player),id:'clientTest',state:status==='changed'?'ordered':'waiting',room:'restaurant',x:9,y:9,seat:4,recipe:'sopa',order:null,experience:R.newExperience(()=>.5)}];job.target='clientTest';Object.assign(s.player,{x:8,y:9});}
 else if(kind==='computer'||kind==='receiving')Object.assign(s.player,{x:kind==='computer'?16:21,y:12});
 else if(kind==='serviceSign')Object.assign(s.player,{x:7,y:13});else Object.assign(s.player,R.accessPoints(s,o)[0]);
 if(status==='far')s.player.x=22;if(status==='expired')s.time=31;if(status==='missing')job.target=9999;if(status==='changed')job.wasOpen=!s.open;
 add('processInteraction',s,[],{pending:job,current:status!=='stale',building:status==='building',moving:status==='moving'});
}
for(const kind of ['physical','storage','customer','clean'])add('queueInteraction',clone(base),[kind,99999]);
for(const [compact,single]of [[false,false],[true,false],[true,true]])for(let y=0;y<16;y++)for(let x=0;x<24;x++){
 const s=R.furnishedTest(compact,single);add('pointerDown',s,[{world:{x:x+.25,y:y+.75},clientX:100,clientY:200,pointerId:1,construction:false,building:null}]);
}
for(const building of [null,{type:'chair',rot:0,moving:null,locked:false}])for(const world of [{x:9.5,y:8.5},{x:19.5,y:10.5},{x:-1,y:20}])add('pointerDown',clone(base),[{world,clientX:90,clientY:120,pointerId:1,construction:true,building}],{building:building!=null});
for(const room of ['street','stock'])for(const world of [{x:5.5,y:10.5},{x:18.5,y:8.5},{x:17.5,y:12.5},{x:12.5,y:5.5},{x:21.5,y:14.5},{x:12.5,y:6.5},{x:0,y:0},{x:-1,y:20}]){
 const s=clone(base);Object.assign(s.player,{room,x:12,y:10});add('pointerDown',s,[{world,clientX:80,clientY:100,pointerId:1,construction:false,building:null}]);
}
for(const phase of ['waiting','ordered'])for(const hand of [null,{item:'dish_sopa',n:1,quality:2}]){
 const s=clone(base);s.customers=[{...clone(s.player),id:'clientTest',room:'restaurant',x:9,y:9,seat:4,state:phase,recipe:'sopa',order:'order1',timer:0,experience:R.newExperience(()=>.5)}];s.orders=[{id:'order1',recipe:'sopa',state:'ordered',client:'clientTest',price:12}];Object.assign(s.player,{x:8,y:9,hand});add('pointerDown',s,[{world:{x:9.5,y:9.5},clientX:80,clientY:100,pointerId:1,construction:false,building:null}]);
}
fs.writeFileSync(path.join(__dirname,'interacoes.json'),JSON.stringify({base,cases}));console.log(cases.length);

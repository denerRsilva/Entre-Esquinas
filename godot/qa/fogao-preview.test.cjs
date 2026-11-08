const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const dir=path.join(__dirname,'../simulacao'),context=vm.createContext({assert,console});
vm.runInContext('const InterfaceBase='+fs.readFileSync(path.join(dir,'interface-base.json'),'utf8'),context);
for(const name of ['apresentacao','restaurant-core','comidas','cenografia','acoes','sessao'])vm.runInContext(fs.readFileSync(path.join(dir,name+'.js'),'utf8'),context,{filename:name});
vm.runInContext(`(()=>{
 state=R.furnishedTest();$('welcome').close();enterConstruction();
 const before=JSON.stringify([state.cash,state.objects]);
 for(const type of Object.keys(R.CATALOG))for(let rot=0;rot<4;rot++){
  beginBuild(type);building.rot=rot;hover={x:18,y:3};
  const packet=JSON.parse(snapshot(0,[]));assert(packet.construction);assert(packet.ui.build);
  const cancel=[...Host.widgets].find(([,w])=>w.id==='cancelBuild');assert(cancel);
  JSON.parse(snapshot(0,[{kind:'widget',path:cancel[0]}]));assert.equal(building,null);
 }
 const stove=state.objects.find(o=>o.type==='stove');
 for(let i=0;i<10;i++){
  beginBuild('stove',stove.id);hover={x:18,y:3};JSON.parse(snapshot(0,[]));
  const rotate=[...Host.widgets].find(([,w])=>w.id==='rotateBtn');assert(rotate);
  JSON.parse(snapshot(0,[{kind:'widget',path:rotate[0]}]));assert.equal(building.rot,1);
  const cancel=[...Host.widgets].find(([,w])=>w.id==='cancelBuild');JSON.parse(snapshot(0,[{kind:'widget',path:cancel[0]}]));
  assert.equal(building,null);assert.equal(JSON.stringify([state.cash,state.objects]),before);
 }
 assert(R.valid(state));exitConstruction();assert(!constructionMode);
})()`,context);
console.log('PASSOU: prévias dos dez móveis nas quatro rotações e dez ciclos de mover/girar/cancelar fogão, sem perda de conteúdo ou caixa.');

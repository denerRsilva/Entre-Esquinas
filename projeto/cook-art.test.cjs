const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const calls=[];
const context=new Proxy({drawImage:(...args)=>calls.push(args)}, {get:(o,k)=>o[k]||(()=>{})});
const sandbox={
 Image:class{constructor(){this.complete=true;this.naturalWidth=1254;this.naturalHeight=1254;}addEventListener(){}},
 document:{createElement:()=>({getContext:()=>context})},
};
vm.createContext(sandbox);
const source=fs.readFileSync(__dirname+'/dist/restaurant-art.js','utf8');
vm.runInContext(source.replace('root.RestaurantArt={','root.testActor=actor;root.RestaurantArt={'),sandbox);
assert.equal(calls.length,16);
for(let i=0;i<16;i++)assert.deepEqual(calls[i].slice(5),[i%4*64,Math.floor(i/4)*64,64,64]);
const R={position:()=>({x:2,y:3})};
const player={id:'player'};
for(const [row,dx,dy]of [[0,0,1],[1,-1,0],[2,1,0],[3,0,-1]]){
 for(let column=0;column<4;column++){
  calls.length=0;
  player.motion={fromX:0,fromY:0,toX:dx,toY:dy};
  sandbox.testActor(context,R,{time:column/8,orders:[]},player,null,true);
  assert.deepEqual(calls[0].slice(1,5),[column*64,row*64,64,64]);
  assert.deepEqual(calls[0].slice(7),[64,64]);
 }
 player.motion=null;calls.length=0;
 sandbox.testActor(context,R,{time:10,orders:[]},player,null,true);
 assert.deepEqual(calls[0].slice(1,5),[64,row*64,64,64]);
}
console.log('16 quadros de caminhada, quatro direções e parada com direção mantida: OK');

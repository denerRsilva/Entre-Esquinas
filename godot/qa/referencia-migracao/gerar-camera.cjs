const {vm,R,source}=require('./camera-legado.cjs'),fs=require('fs'),path=require('path');const tests=[];
const clone=x=>JSON.parse(JSON.stringify(x));
for(const [compact,singleRoom]of [[false,false],[true,false],[true,true]])for(const room of ['restaurant','street','stock'])for(const size of [[960,640],[960,1280],[1920,640]])for(const cameraLevel of [.7,1,1.3,2])for(const constructionMode of [false,true])for(const prior of [null,'build']){
 const state={compact,singleRoom,player:{id:'player',room,x:18,y:11,settled:null,motion:{fromX:17,fromY:11,toX:18,toY:11,elapsed:.25,duration:1}}};
 const viewport={width:size[0],height:size[1]},camera={zoom:1,x:-999,y:999,mode:prior},rect={left:37,top:60,width:1280,height:720};
 const context={R,state,viewport,camera:clone(camera),cameraLevel,constructionMode,canvas:{getBoundingClientRect:()=>rect}};vm.createContext(context);vm.runInContext(source,context);context.updateCamera();
 tests.push({args:['update',state,camera,viewport,cameraLevel,constructionMode],expected:clone(context.camera)});
 for(const [x,y]of [[0,0],[20.25,60.5],[1280,720]]){
  const screen=context.screenPoint(x,y),point={clientX:screen.x,clientY:screen.y};
  tests.push({args:['screenPoint',x,y,rect,viewport,context.camera],expected:screen});
  tests.push({args:['worldPointer',point,rect,viewport,context.camera],expected:context.worldPointer(point)});
 }
 const button={style:{}},management=false,welcome=false;context.$=id=>id==='openBtn'?button:{open:false};context.positionDoorSign();tests.push({args:['door',state,context.camera,viewport,rect,constructionMode,management,welcome],expected:{hidden:!!button.hidden,left:parseFloat(button.style.left),top:parseFloat(button.style.top)}});
}
for(const value of [-1,.65,.7,.75,.85,1,1.25,1.95,2,4])tests.push({args:['level',value],expected:Math.round(Math.max(.7,Math.min(2,value))*10)/10});
for(const [args,expected]of [
 [['resize',960,700,60,1],{viewport:{width:960,height:640},pixels:{width:960,height:640},height:640}],
 [['resize',1280,800,0,3],{viewport:{width:960,height:600},pixels:{width:2560,height:1600},height:800}],
 [['resize',1024,60,60,1.5],{viewport:{width:960,height:.9375},pixels:{width:1536,height:2},height:1}]
])tests.push({args,expected});
fs.writeFileSync(path.join(__dirname,'camera.json'),JSON.stringify(tests));console.log(tests.length);

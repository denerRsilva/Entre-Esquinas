/* One deterministic host tick. Map input is expressed in the game's 960 × 700
   logical viewport; the Godot viewport handles physical window scaling. */
function summary(n) {
 if(typeof n==='string')return n;
 return n.attrs['aria-hidden']==='true'?'':n.nodes.map(summary).join(' ')||n.attrs['aria-label']||'';
}
function firstArtwork(n) {
 if(typeof n==='string')return null;
 if(n.tag==='canvas')return n.getContext().commands;
 if(n.svg)return [['svg',n.svg]];
 for(const child of n.children){const found=firstArtwork(child);if(found)return found}
 return null;
}
function pack(n,path){
 if(typeof n==='string')return n.trim()?{tag:'text',text:n.trim()}:null;
 if(n.hidden||n.attrs['aria-hidden']==='true')return null;
 const v={tag:n.tag,cls:n.className,id:n.id};
 if(n.tag==='button'||n.tag==='input'||n.tag==='select'||n.tag==='a'){
  Host.widgets.set(path,n);Object.assign(v,{path,disabled:!!n.disabled,label:n.attrs['aria-label']||n.title||'',text:n.tag==='button'?summary(n).trim():'',value:n.value,type:n.type||'',checked:!!n.checked,min:n.min,max:n.max,step:n.step});
  if(n.className.includes('inventorySlot'))v.text=n.children.slice(-1)[0]?.textContent||'—';
  if(n.tag==='select')v.options=n.options.map(x=>[x.textContent,x.value]);
  const art=firstArtwork(n);if(art)v.art=art;
 }else if(n.tag==='canvas'){v.art=n.getContext().commands;v.label=n.attrs['aria-label']}
 else if(n.tag==='progress'){v.value=n.value;v.max=n.max}
 else if(n.svg){v.art=[['svg',n.svg]];v.label=n.attrs['aria-label']}
 else{v.children=n.nodes.map((c,i)=>pack(c,path+'/'+i)).filter(Boolean)}
 return v;
}
function section(id){return pack($(id),id)}
function input(e){
 if(e.kind==='widget'){
  const w=Host.widgets.get(e.path);if(!w||w.disabled)return;
  if(w.tag==='button')w.click();
  else{w.value=e.value;w.checked=e.value;w.onchange?.()}
 }else if(e.kind==='pointer'&&!$('welcome').open&&!$('management').open){
  canvas['onpointer'+e.phase]?.({clientX:e.x,clientY:e.y,buttons:e.drag?1:0,pointerId:1,pointerType:'mouse'});
 }else if(e.kind==='key'){
  if(e.key==='escape'&&e.down&&$('management').open){$('management').close();return}
  document.emit(e.down?'keydown':'keyup',{key:e.key,repeat:false,preventDefault(){}});
 }else if(e.kind==='blur')releaseKeyboard();
}
function snapshot(dt,events) {
 for(const e of events)input(e);
 Host.clock+=dt*1000;frame(Host.clock);
 const painter=new Painter();
 RestaurantArt.draw(painter,R,state,{selectedObject,building,hover,previewError,constructionMode});
 const modal=$('welcome').open?'welcome':$('management').open?'management':'';
 Host.widgets.clear();
 const ui={};
 if(modal){ui.modal=section(modal)}
 else if(constructionMode){
  ui.catalog=section('constructionControls');ui.drawer=section('constructionDrawer');ui.build=section('buildBar');
 }else{
  for(const id of ['hud','dock','actions','context','ordersHud','kitchenStatus','openBtn','hint'])ui[id]=section(id);
  ui.notice=$('notice').style.opacity==='1'?section('notice'):null;
 }
 const writes=Host.writes;Host.writes={};
 return JSON.stringify({room:state.player.room,camera:[camera.x,camera.y,camera.zoom],scene:painter.commands,ui,modal,construction:constructionMode,door:[parseFloat($('openBtn').style.left)||0,parseFloat($('openBtn').style.top)||0],writes,sounds:Host.sound.splice(0)});
}
kitchenAudio={state:'running',currentTime:0,createOscillator(){const tone={frequency:{value:0},connect(){},start(){Host.sound.push(tone.frequency.value)},stop(){}};return tone},createGain(){return {gain:{setValueAtTime(){},exponentialRampToValueAtTime(){}},connect(){}}}};

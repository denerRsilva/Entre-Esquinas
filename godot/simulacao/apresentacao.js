/* Model of the existing menus. Godot owns the window, input, painting and widgets.
   Control paths are stable across rebuilds; callbacks always resolve the current tree. */
const Host = { clock:0, values:{}, writes:{}, sound:[], keys:{}, widgets:new Map(), width:960,height:700,top:60 };
const performance = {now:()=>Host.clock};
const innerWidth=960, innerHeight=700, devicePixelRatio=1;
const localStorage = {
 getItem:k=>Host.values[k]??null,
 setItem(k,v){Host.values[k]=Host.writes[k]=String(v)}
};
const getComputedStyle=()=>({getPropertyValue:()=>String(Host.top)});
const requestAnimationFrame=()=>{};
class Bitmap {
 constructor(){this.complete=true;this.naturalWidth=1254;this.naturalHeight=1254}
 set src(v){this.file=v.split('/').pop();if(this.onload)this.onload()}
}
const Image=Bitmap;
class Painter {
 constructor(){this.commands=[];this.s={x:0,y:0,sx:1,sy:1};this.stack=[];this.globalAlpha=1;this.font='12px';this.path=[]}
 save(){this.stack.push([Object.assign({},this.s),this.globalAlpha,this.font,this.fillStyle,this.strokeStyle,this.textAlign,this.lineWidth])}
 restore(){[this.s,this.globalAlpha,this.font,this.fillStyle,this.strokeStyle,this.textAlign,this.lineWidth]=this.stack.pop()}
 translate(x,y){this.s.x+=x*this.s.sx;this.s.y+=y*this.s.sy}
 scale(x,y){this.s.sx*=x;this.s.sy*=y}
 point(x,y){return [Math.round(this.s.x+x*this.s.sx),Math.round(this.s.y+y*this.s.sy)]}
 fillRect(x,y,w,h){this.commands.push(['rect',...this.point(x,y),w,h,this.fillStyle,this.globalAlpha])}
 strokeRect(x,y,w,h){this.commands.push(['line',...this.point(x,y),w,h,this.strokeStyle,this.lineWidth||1])}
 measureText(t){return {width:String(t).length*parseInt(this.font.match(/\d+/)?.[0]||12)*.60}}
 fillText(t,x,y){this.commands.push(['text',...this.point(x,y),String(t),parseInt(this.font.match(/\d+/)?.[0]||12),this.fillStyle,this.textAlign||'left'])}
 drawImage(img,...p){if(img.file)this.commands.push(['img',img.file,...p.slice(0,4),...this.point(p[4],p[5]),p[6]*this.s.sx,p[7]*this.s.sy,this.globalAlpha]);else this.commands.push(...img.getContext().commands)}
 clearRect(){this.commands=[]}
 beginPath(){this.path=[]}
 moveTo(x,y){this.path.push([x,y])}
 lineTo(x,y){this.path.push([x,y])}
 closePath(){}
 fill(){if(this.path.length>=3)this.commands.push(['poly',this.path,this.fillStyle])}
 stroke(){}
 actor(x,y,dir,moving){this.commands.push(['cook',x,y,dir,moving])}
 furniture(o,x,y,w,h,preview){this.commands.push(['furniture',o.type,x,y,w,h,o.rot,preview])}
}
class Widget {
 constructor(tag,id=''){this.tag=tag;this.id=id;this.nodes=[];this.attrs={};this.style={};this.className='';this.events={};this.value='';this.classList={add:k=>this.className+=' '+k,remove:k=>this.className=this.className.split(' ').filter(x=>x!==k).join(' '),toggle:(k,b)=>{this.classList.remove(k);if(b)this.classList.add(k)}}}
 get children(){return this.nodes.filter(v=>typeof v==='object')}
 set textContent(t){this.nodes=[String(t)]}
 get textContent(){return this.nodes.map(n=>typeof n==='string'?n:n.textContent).join('')}
 set innerHTML(html){if(html.includes('<svg')){this.nodes=[];this.svg=html;return}this.textContent=html.replace(/<\/(?:li|p|div|span)>/g,'  ').replace(/<[^>]+>/g,'').trim()}
 append(...nodes){this.nodes.push(...nodes)}
 add(n){this.append(n);if(this.options.length===1)this.value=n.value}
 get options(){return this.children}
 replaceChildren(...n){this.nodes=n}
 setAttribute(k,v){this.attrs[k]=v}
 addEventListener(k,fn){(this.events[k]??=[]).push(fn)}
 emit(k,e){for(const fn of this.events[k]||[])fn(e)}
 click(){if(!this.disabled)this.onclick?.()}
 close(){this.open=false;this.emit('close',{})}
 showModal(){this.open=true}
 getContext(){return this.painter??=new Painter()}
 getBoundingClientRect(){if(this.id==='world')return {left:0,top:Host.top,width:960,height:640,right:960,bottom:700};return {left:0,top:0,width:0,height:0}}
 child(tag){const n=new Widget(tag);this.append(n);return n}
 createTHead(){return this.child('thead')}
 createTBody(){return this.child('tbody')}
 insertRow(){return this.child('tr')}
 insertCell(){return this.child('td')}
 querySelector(selector){
   const descendants=w=>w.children.flatMap(n=>[n,...descendants(n)]);
   const list=descendants(this);
   if(selector==='.prepPanel')return list.find(n=>n.className.includes('prepPanel'));
   const cls=selector.match(/^\.(\w+)/)?.[1];
   if(cls==='prepPrimary')return list.find(n=>n.className.includes(cls))?.querySelector('button:not(:disabled)');
   return list.find(n=>n.tag==='button'&&!n.disabled&&(!cls||n.className.includes(cls)));
 }
}
class Option extends Widget {constructor(t,v){super('option');this.textContent=t;this.value=v}}
const window=new Widget('window'),document=new Widget('document');
document.documentElement=new Widget('html');
document.createElement=t=>new Widget(t);
document.createTextNode=t=>String(t);
const elements={};
document.getElementById=id=>elements[id];
function readLayout(node){
 if(typeof node==='string')return node;
 const [tag,attrs,children]=node,n=new Widget(tag,attrs.id||'');
 n.attrs=attrs;n.className=attrs.class||'';n.hidden='hidden' in attrs;
 if(n.id)elements[n.id]=n;
 n.nodes=children.map(readLayout);return n;
}
readLayout(InterfaceBase);

/* Identidade visual única dos alimentos, compartilhada entre DOM e cenário. */
(function(root){
'use strict';
const atlas=typeof Image!=='undefined'?new Image():null;
const crops=[[154,44,310,306],[594,35,344,323],[1054,103,361,244],[83,714,440,280],[588,714,350,280],[1004,714,448,280],[586,425,361,212],[1067,428,327,208]];
const keys=["arroz","legumes","frango","arrozLegumes","sopa","frangoArroz","legumes_cut","frango_cut"];
const names=["Arroz","Legumes","Frango","Arroz com legumes","Sopa de legumes","Frango com arroz","Legumes cortados","Frango cortado"];
const pending=[];
if(atlas){atlas.onload=()=>{for(const fn of pending.splice(0))fn()};atlas.src='assets/taverna/alimentos.png';}
function key(item){if(keys.includes(item))return item;if(item?.startsWith('dish_'))return item.slice(5);if(item?.startsWith('pot_'))return item.split('_')[1];return null;}
function draw(c,item,x,y,w=32,h=32){const id=keys.indexOf(key(item));if(id<0||!atlas?.complete||!atlas.naturalWidth)return false;const r=crops[id],scale=Math.min(w/r[2],h/r[3]),dw=r[2]*scale,dh=r[3]*scale;c.save();c.imageSmoothingEnabled=false;c.drawImage(atlas,...r,Math.round(x+(w-dw)/2),Math.round(y+(h-dh)/2),Math.round(dw),Math.round(dh));c.restore();return true;}
function icon(item,quality=0){const id=keys.indexOf(key(item)),el=document.createElement('canvas');el.className='foodArt';el.width=64;el.height=64;el.setAttribute('role','img');el.setAttribute('aria-label',names[id]||'Comida');const paint=()=>{const c=el.getContext('2d');draw(c,item,0,0,64,64);if(!item.startsWith('pot_'))star(c,quality,44,44,18);};el.setAttribute('aria-label',(names[id]||'Comida')+' • '+['Comum','Prata','Ouro','Roxa'][quality]);if(atlas?.complete&&atlas.naturalWidth)paint();else pending.push(paint);return el;}
const lookup=Object.fromEntries(names.map((n,i)=>[n.toLowerCase(),keys[i]]));
const pattern=/(?<![\p{L}])(?:arroz com legumes|sopa de legumes|frango com arroz|arroz|legumes|frango)(?![\p{L}])/giu;
function parts(text){const out=[];let at=0;for(const m of text.matchAll(pattern)){if(m.index>at)out.push(text.slice(at,m.index));out.push({food:lookup[m[0].toLowerCase()]});at=m.index+m[0].length;}if(at<text.length)out.push(text.slice(at));return out;}
function decorate(element){
 if(element.className==='recipeBook')return;
 if(!element||element.tag==='canvas'||element.tag==='option'||element.svg)return;
 for(const node of element.children)decorate(node);
 element.nodes=element.nodes.flatMap(node=>{
  if(typeof node!=='string')return [node];
  return parts(node).map(part=>typeof part==='string'?part:icon(part.food));
 });
}
function star(c,quality,x,y,size=10){if(!quality)return;c.save();c.fillStyle=['','#c5c9cc','#ffd14c','#c286ff'][quality];c.strokeStyle='#352c38';c.lineWidth=1;c.beginPath();for(let i=0;i<10;i++){const a=-Math.PI/2+i*Math.PI/5,r=size*(i%2?.22:.5),px=x+size/2+Math.cos(a)*r,py=y+size/2+Math.sin(a)*r;if(!i)c.moveTo(px,py);else c.lineTo(px,py);}c.closePath();c.fill();c.stroke();c.restore();}
root.FoodArt={key,draw,icon,parts,decorate,star};
})(typeof globalThis!=='undefined'?globalThis:this);

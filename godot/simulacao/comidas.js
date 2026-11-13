/* Identidade visual única dos alimentos, compartilhada entre DOM e cenário. */
(function(root){
'use strict';
const keys=["arroz","legumes","frango","arrozLegumes","sopa","frangoArroz","legumes_cut","frango_cut"];
const names=["Arroz","Legumes","Frango","Arroz com legumes","Sopa de legumes","Frango com arroz","Legumes cortados","Frango cortado"];
function key(item){if(keys.includes(item))return item;if(item?.startsWith('dish_'))return item.slice(5);if(item?.startsWith('pot_'))return item.split('_')[1];return null;}
function draw(c,item,x,y,w=32,h=32){if(!keys.includes(key(item)))return false;c.commands.push(['food',item,x,y,w,h,c.s.sx,c.s.sy,c.s.x,c.s.y,c.globalAlpha]);return true;}
function icon(item,quality=0){const id=keys.indexOf(key(item)),el=document.createElement('canvas');el.className='foodArt';el.width=64;el.height=64;el.setAttribute('role','img');el.setAttribute('aria-label',names[id]||'Comida');const paint=()=>{const c=el.getContext('2d');draw(c,item,0,0,64,64);if(!item.startsWith('pot_'))star(c,quality,44,44,18);};el.setAttribute('aria-label',(names[id]||'Comida')+' • '+['Comum','Prata','Ouro','Roxa'][quality]);paint();return el;}
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

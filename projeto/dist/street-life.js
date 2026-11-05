/* Circulação da rua independente do expediente e da fila de compras. */
let pedestrians=[],pedestrianClock=0,pedestrianId=0;
function newPedestrian(x){const id=pedestrianId++,right=id%2===0;return {id,pos:[x===undefined?(right?-30:830):x,right?342:350],right,speed:48+(id%3)*8}}
pedestrians=[newPedestrian(180),newPedestrian(590),newPedestrian(350)];
function stepStreet(dt){pedestrianClock+=dt;for(const p of pedestrians)p.pos[0]+=(p.right?1:-1)*p.speed*dt;pedestrians=pedestrians.filter(p=>p.pos[0]>-45&&p.pos[0]<845);if(pedestrianClock>=3&&pedestrians.length<4){pedestrianClock=0;pedestrians.push(newPedestrian())}}
const streetStep=step;step=function(dt){streetStep(dt);stepStreet(dt)};
const streetDraw=draw;draw=function(){streetDraw();if(s.room!=='street')return;for(const p of pedestrians)person(p.pos,['#b480a0','#7895b1','#c8955c','#6b9776'][p.id%4],'Pedestre',false)};

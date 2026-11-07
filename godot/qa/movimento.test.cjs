const assert=require('node:assert/strict'),R=require('../simulacao/restaurant-core.js');
let count=0;
function test(name,fn){fn();count++;console.log('OK '+name)}
function scene(x=5,y=5){const s=R.fresh();Object.assign(s.player,{x,y});return s;}
function move(s,dx,dy,time,dt=1/60){R.setPlayerInput(s,dx,dy);for(let left=time;left>1e-9;){const slice=Math.min(dt,left);R.moveActors(s,slice);left-=slice;}return R.position(s.player);}
function near(a,b){assert(Math.abs(a-b)<1e-5,`${a} / ${b}`)}
test('Posição subcélula e parada imediata sem encaixe na grade',()=>{
 const s=scene();const p=move(s,1,0,.1);near(p.x,5+.1*R.PLAYER_SPEED);
 assert(!Number.isInteger(p.x));R.setPlayerInput(s,0,0);R.moveActors(s,.5);near(R.position(s.player).x,p.x);
 assert(!R.isMoving(s.player));assert(R.valid(s));
});
test('Velocidade constante a 15, 30, 60 e 144 quadros/s',()=>{
 for(const fps of [15,30,60,144]){const p=move(scene(),1,0,.4,1/fps);near(p.x,5+.4*R.PLAYER_SPEED);}
});
test('Diagonal normalizada, sem bônus de velocidade',()=>{
 const p=move(scene(),1,1,.3);near(Math.hypot(p.x-5,p.y-5),.3*R.PLAYER_SPEED);
});
test('Inversão imediata de direção no meio do movimento',()=>{
 const s=scene();move(s,1,0,.07);const before=R.position(s.player);const p=move(s,-1,0,.01);near(p.x,before.x-.01*R.PLAYER_SPEED);
});
test('Parede: parar no contato e sair imediatamente ao inverter',()=>{
 const s=scene(1,5),p=move(s,-1,0,1);near(p.x,.5+R.PLAYER_RADIUS);
 const next=move(s,1,0,.01);assert(next.x>p.x);assert(R.valid(s));
});
test('Diagonal contra parede desliza pelo eixo livre',()=>{
 const s=scene(1,5);move(s,-1,0,.3);const p=move(s,-1,1,.3);
 near(p.x,.5+R.PLAYER_RADIUS);assert(p.y>5.8);assert(R.valid(s));
});
test('Canto: sem penetração e sem prender ao se afastar',()=>{
 const s=scene(1,1);let p=move(s,-1,-1,2);near(p.x,.5+R.PLAYER_RADIUS);near(p.y,.5+R.PLAYER_RADIUS);
 p=move(s,1,1,.1);assert(p.x>.9&&p.y>.9);assert(R.valid(s));
});
test('Quadro lento não atravessa a parede divisória',()=>{
 const s=scene(12,5);const p=move(s,1,0,2,2);near(p.x,13.5-R.PLAYER_RADIUS);assert(R.valid(s));
});
test('Passagem de uma célula entre salão e cozinha',()=>{
 const s=scene(12,7);const p=move(s,1,0,.9);assert(p.x>15);near(p.y,7);assert(R.valid(s));
});
test('Móvel impede entrada, mas permite deslizar e recuar',()=>{
 const s=scene(3,6);assert(R.place(s,'table',5,5).ok);
 let p=move(s,1,-1,.6);assert(!R.blocked(s,'restaurant',s.player.x,s.player.y,s.player));
 const previous=p; p=move(s,-1,1,.2);assert(p.x<previous.x);assert(R.valid(s));
});
test('Reservas dos outros personagens e conservação do save',()=>{
 const s=scene(16,12);move(s,1,0,1);assert(R.position(s.player).x<17.5);assert(R.valid(s));
 R.setPlayerInput(s,0,0);const saved=R.migrateSave(JSON.parse(JSON.stringify(s)));assert(saved);
 const p=R.position(saved.player);R.moveActors(saved,.3);near(R.position(saved.player).x,p.x);
});
test('Teclado interrompe clique sem completar a célula pendente',()=>{
 const s=scene();R.go(s.player,{room:'restaurant',x:10,y:5});R.moveActors(s,.04);
 const before=R.position(s.player);const p=move(s,-1,0,.02);assert(p.x<before.x);assert.equal(s.player.goal,null);
});
test('Clique volta a navegar após parar numa posição fracionária',()=>{
 const s=scene();move(s,1,0,.07);R.setPlayerInput(s,0,0);R.go(s.player,{room:'restaurant',x:10,y:5});
 for(let i=0;i<120;i++)R.moveActors(s,1/60);
 near(R.position(s.player).x,10);near(R.position(s.player).y,5);assert(R.valid(s));
});
console.log(count+' cenários de movimento livre passaram.');

/* Computador físico: pedidos e preços acessíveis somente junto ao terminal. */
const COMPUTER={bounds:[60,295,160,55],point:[140,390]};
obstacles.stock.push(COMPUTER.bounds);
function atComputer(){return s.room==='stock'&&Math.hypot(s.player[0]-COMPUTER.point[0],s.player[1]-COMPUTER.point[1])<60}
function computerSession(){return atComputer()&&$('management').open&&managementSection==='computer'}
$('useComputer').onclick=()=>openManagement('computer');
const walkBeforeComputer=canvas.onpointerdown;
canvas.onpointerdown=e=>{
 const r=canvas.getBoundingClientRect(),x=(e.clientX-r.left)*800/r.width,y=(e.clientY-r.top)*460/r.height;
 const [a,b,w,h]=COMPUTER.bounds;
 if(s.room!=='stock'||x<a-10||x>a+w+10||y<b-25||y>b+h+10)return walkBeforeComputer(e);
 const path=route('stock',s.player,COMPUTER.point);
 if(!path)return say('Caminho até o computador bloqueado.',true);
 playerPath=path;target=[...COMPUTER.point];doorTarget=null;
};
function renderComputerOrders(){
 const received=s.orders.reduce((n,o)=>n+o.received,0),pending=s.orders.reduce((n,o)=>n+o.pending,0);
 $('ordersSummary').textContent=s.orders.length?`${s.orders.length} pedido(s) • ${received} unidades recebidas • ${pending} aguardando espaço.`:'Nenhum pedido realizado. Use Compras e preços para encomendar mercadoria.';
 const rows=s.orders.map((o,i)=>`<tr><td>#${i+1}</td><td>${GOODS[o.product].name}</td><td>${o.total}</td><td>${o.received}</td><td>${o.pending}</td><td>$${(o.total*GOODS[o.product].cost).toFixed(2)}</td></tr>`).join('');
 if($('ordersRows').innerHTML!==rows)$('ordersRows').innerHTML=rows;
}
const buyAtComputer=$('buy').onclick,priceAtComputer=$('price').oninput;
$('buy').onclick=()=>computerSession()?buyAtComputer():say('Faça o pedido pelo computador no estoque.',true);
$('price').oninput=()=>{if(computerSession())return priceAtComputer();$('price').value=s.prices[selected];say('Ajuste os preços pelo computador no estoque.',true)};
const updateBeforeComputer=update;
update=function(){updateBeforeComputer();$('useComputer').hidden=!atComputer();if(atComputer())$('contextHint').textContent='Computador • pedidos ao fornecedor, entregas e preços.';if($('management').open&&managementSection==='computer')renderComputerOrders()};
const drawBeforeComputer=draw;
draw=function(){drawBeforeComputer();if(s.room!=='stock')return;
 rect(65,303,160,55,'#0003');rect(60,295,160,55,'#72563c');rect(60,295,160,9,'#c4a377');
 rect(98,267,76,44,'#203c40');rect(105,273,62,30,'#8fc5b0');rect(111,279,49,3,'#315f57');rect(111,286,34,3,'#315f57');rect(111,293,42,3,'#315f57');
 rect(131,310,10,8,'#203c40');rect(115,317,43,5,'#203c40');rect(100,328,73,12,'#c6c3aa');rect(182,326,12,16,'#c6c3aa');
 tag('Computador',140,249,14);if(atComputer())tag('Usar computador',140,365,13);
};
function moveOutOfComputer(){
 const [a,b,w,h]=COMPUTER.bounds;
 for(const actor of [{room:s.room,pos:s.player},{room:s.workerRoom,pos:s.worker},s.worker2])if(actor.room==='stock'&&actor.pos[0]>a-15&&actor.pos[0]<a+w+15&&actor.pos[1]>b-16&&actor.pos[1]<b+h+16){actor.pos[0]=COMPUTER.point[0];actor.pos[1]=COMPUTER.point[1]}
}
const restoreBeforeComputer=$('restore').onclick;
$('restore').onclick=()=>{restoreBeforeComputer();moveOutOfComputer();update()};
moveOutOfComputer();update();

/* Descarga FIFO automática: estoque recebido permanece no recebimento físico. */
function unloadAutomatically(){let delivered=0;for(const order of s.orders){const amount=Math.min(order.pending,cap('receiving')-s.stock.receiving);if(amount<=0)continue;order.pending-=amount;order.received+=amount;s.stock.receiving+=amount;delivered+=amount}return delivered}
const automaticBuy=$('buy').onclick;$('buy').onclick=()=>{const before=s.purchased;automaticBuy();if(s.purchased>before){const delivered=unloadAutomatically();say(`Pedido confirmado. ${delivered} caixa(s) descarregadas automaticamente; ${pending()} aguardam espaço no recebimento.`);contextualUI()}};
const automaticStep=step;step=function(dt){unloadAutomatically();automaticStep(dt);if(unloadAutomatically()) {update();contextualUI()}};
const automaticRestore=$('restore').onclick;$('restore').onclick=()=>{automaticRestore();unloadAutomatically();update();contextualUI()};
$('unload').hidden=true;

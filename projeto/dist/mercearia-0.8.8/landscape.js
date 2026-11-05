/* Canvas com proporção preservada; movimento continua baseado no seu retângulo real. */
function canvasLayout(width,height){const scale=Math.max(0,Math.min(width/800,height/460));return {width:800*scale,height:460*scale}}
function sizeLandscapeCanvas(){let viewport=$('sceneViewport'),size=canvasLayout(viewport.clientWidth,viewport.clientHeight);canvas.style.width=size.width+'px';canvas.style.height=size.height+'px';const k=Math.max(1,Math.min(3,Math.round(size.width*(window.devicePixelRatio||1)/800)));if(canvas.width!==800*k){canvas.width=800*k;canvas.height=460*k}}
function setGameMenu(open){$('gameMenu').hidden=!open;$('menuToggle').setAttribute('aria-expanded',String(open));$('menuToggle').textContent=open?'✕ Fechar menu':'☰ Menu'}
$('menuToggle').onclick=()=>setGameMenu($('gameMenu').hidden);
$('closeGameMenu').onclick=()=>{setGameMenu(false);$('menuToggle').focus()};
const enterManagement=$('manage').onclick;$('manage').onclick=()=>{setGameMenu(false);enterManagement()};
for(const b of document.querySelectorAll('[data-open-panel]'))b.onclick=()=>{$('manage').onclick();document.querySelector('[data-panel="'+b.dataset.openPanel+'"]').click()};
const pointToWalk=canvas.onpointerdown;canvas.onpointerdown=e=>{setGameMenu(false);pointToWalk(e)};
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!$('management').open&&!$('dialog').open&&!$('gameMenu').hidden){setGameMenu(false);$('menuToggle').focus()}});
$('fullscreenToggle').onclick=async()=>{try{if(document.fullscreenElement){await document.exitFullscreen();$('fullscreenNotice').textContent='Tela cheia desativada.';return}if(!document.documentElement.requestFullscreen){$('fullscreenNotice').textContent='Tela cheia indisponível aqui. Gire o celular para horizontal.';return}await document.documentElement.requestFullscreen();try{if(screen.orientation?.lock)await screen.orientation.lock('landscape')}catch{}$('fullscreenNotice').textContent='Tela cheia ativada. Se necessário, gire o celular para horizontal.'}catch{$('fullscreenNotice').textContent='Não foi possível ativar tela cheia. Gire o celular para horizontal.'}finally{sizeLandscapeCanvas()}};
window.addEventListener('resize',sizeLandscapeCanvas);document.addEventListener('fullscreenchange',sizeLandscapeCanvas);window.visualViewport?.addEventListener('resize',sizeLandscapeCanvas);
sizeLandscapeCanvas();setGameMenu(false);
$('management').addEventListener('close',()=>$('menuToggle').focus());

// Atalho sempre visível acima das ações, usando o mesmo fluxo de tela cheia.
$('quickFullscreen').onclick=async()=>{await $('fullscreenToggle').onclick();say($('fullscreenNotice').textContent)};
function updateFullscreenShortcut(){const active=!!document.fullscreenElement;$('quickFullscreen').textContent=active?'⛶ Sair do fullscreen':'⛶ Fullscreen';$('quickFullscreen').setAttribute('aria-label',active?'Sair da tela cheia':'Ativar tela cheia')}
document.addEventListener('fullscreenchange',updateFullscreenShortcut);
updateFullscreenShortcut();

/* 0.8.5 — apresentação: nitidez, HUD, atalhos na tela, avisos e seletores de produto. Não altera regras. */
const drawScene=draw;draw=function(){const k=canvas.width/800;ctx.setTransform(k,0,0,k,0,0);drawScene()};
$('quickLoad').appendChild($('load'));
let noteTimer=0;const sayBase=say;say=function(t,bad=false){sayBase(t,bad);const n=$('note');n.dataset.status=bad?'error':'info';n.classList.remove('fade');clearTimeout(noteTimer);noteTimer=setTimeout(()=>n.classList.add('fade'),bad?7000:5000)};
function chipify(id){const sel=$(id),box=document.createElement('div');box.className='chips';box.setAttribute('role','group');box.setAttribute('aria-label','Produto');for(const o of sel.options){const b=document.createElement('button');b.type='button';b.textContent=o.textContent;b.dataset.value=o.value;b.onclick=()=>{sel.value=o.value;sel.dispatchEvent(new Event('change',{bubbles:true}));sel.dispatchEvent(new Event('input',{bubbles:true}));syncUI()};box.appendChild(b)}sel.classList.add('sr');sel.after(box);return box}
const chipBoxes=[chipify('product'),chipify('quickProduct')];
function renderHud(){const state=s.closing?'Fechando':s.open?'Aberta':'Fechada';$('hud').innerHTML=`<span class="chip">Dia ${s.day}</span><span class="chip state ${s.open?'open':''}">${state}</span><span class="chip cash">$${s.cash.toFixed(2)}</span>`}
function syncUI(){renderHud();$('dockShop').textContent=$('shop').textContent;$('dockShop').dataset.open=String(!!s.open);$('dockShop').disabled=$('shop').disabled;$('quick').dataset.room=s.room||'street';$('load').hidden=/\| 0\//.test($('load').textContent);for(const box of chipBoxes){const sel=box.previousElementSibling;for(const b of box.children){const on=b.dataset.value===sel.value;b.setAttribute('aria-pressed',String(on))}}}
const updateBase=update;update=function(){updateBase();syncUI()};
$('dockManage').onclick=()=>$('manage').click();$('dockShop').onclick=()=>$('shop').click();
setInterval(syncUI,150);syncUI();

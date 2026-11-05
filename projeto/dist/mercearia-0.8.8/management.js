let managementSection='general';
const generalPanels=['logistics','upgrades','evaluation','progress'];
const computerPanels=['goods','orders'];
function showManagementPanel(id){
 const allowed=managementSection==='computer'?computerPanels:generalPanels;
 if(!allowed.includes(id))return;
 for(const p of document.querySelectorAll('.panel')){p.hidden=p.id!==id;p.classList.toggle('active',p.id===id)}
 for(const b of document.querySelectorAll('[data-panel]')){b.hidden=!allowed.includes(b.dataset.panel);b.setAttribute('aria-selected',String(b.dataset.panel===id))}
}
function openManagement(section='general'){
 if(section==='computer'&&!atComputer())return say('Aproxime-se do computador no estoque.',true);
 managementSection=section;
 $('managementTitle').textContent=section==='computer'?'Computador • fornecedor e preços':'Gestão da mercearia';
 $('menuNotice').textContent='';
 showManagementPanel(section==='computer'?'goods':'logistics');
 $('management').showModal();update();
}
$('manage').onclick=()=>openManagement();
$('closeManagement').onclick=()=>$('management').close();
for(const b of document.querySelectorAll('[data-panel]'))b.onclick=()=>showManagementPanel(b.dataset.panel);
$('quickProduct').onchange=()=>selectTransportProduct($('quickProduct').value);

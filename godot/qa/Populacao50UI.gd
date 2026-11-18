extends "res://qa/PlaytestDoZeroUI.gd"
const REF = preload("res://simulacao/nativa/Refugio.gd")
const HIRE = preload("res://simulacao/nativa/Contratacao.gd")
const BAL = preload("res://simulacao/nativa/Equilibrio.gd")
func roundtrip(s: Dictionary) -> Variant:
 var raw = g.session.SAVE.serialize(s)
 return g.session.SAVE.new().load_value(JSON.parse_string(raw)) if raw is String else null
func run():
 root.size=Vector2i(1280,720);g=load("res://mundo/Restaurante.tscn").instantiate();root.add_child(g);g.set_process(false);await layout()
 check(await choose("Novo jogo"),"Novo jogo real pela interface")
 var s: Dictionary = g.session.state
 check(s.refuge.residents.size()==50 and s.refuge.initialPopulation==50,"Campanha nova começa com cinquenta moradores reais")
 check(s.workers.is_empty() and s.cash==200 and s.equipment=={"pot":2,"plate":8,"spoon":0},"População não concede funcionário, dinheiro ou equipamentos extras")
 check(s.refuge.stats=={"food":65.0,"energy":70.0,"morale":65.0} and s.refuge.nextHorde==3,"Status e primeira horda preservados")
 check(BAL.interval(s)==28 and HIRE.HIRE_COST==100 and HIRE.MIN_POPULATION==4,"Mesmas regras de intervalo e contratação")
 var ids := {};var names := {}
 for person in s.refuge.residents:
  ids[person.id]=true;names[person.name]=true
  check(person.skin>=12 and person.skin<=14,"Moradores reutilizam sprites existentes")
 check(ids.size()==50 and names.size()==50 and s.refuge.residents[0].name=="Lia" and s.refuge.residents[49].name=="Morador 50","Identidades únicas e fundadores preservados")
 var saved_initial = roundtrip(s)
 check(saved_initial!=null and equivalent(saved_initial.refuge.residents,s.refuge.residents),"Cinquenta identidades persistem sem perder conteúdo")
 var initial: Dictionary = s.duplicate(true)
 var nutrition: Dictionary = initial.duplicate(true);BAL.meal(nutrition,"caldoBatata",85)
 check(is_equal_approx(nutrition.refuge.stats.food-65,8.0/50),"Contribuição alimentar mantém fórmula original, agora dividida por cinquenta")
 check(await choose("Gestão") and await choose("Cidade"),"Cidade abre pelo menu existente")
 check(JSON.stringify(g.frame_data.ui.modal).contains("População: 50"),"Menu mostra cinquenta moradores")
 await choose("Equipe");check(await choose("Procurar contratação"),"Regra de quatro moradores libera busca naturalmente")
 check(HIRE.candidates(s).size()==47,"Os três fundadores continuam reservados às suas funções")
 check(await choose("Contratar Morador 50"),"Último morador pode ser escolhido na lista rolável")
 check(s.workers.size()==1 and s.workers[0].refugeResident==50 and s.cash==100,"Contratação de ID alto mantém custo e limite de vaga")
 var hired = roundtrip(s)
 check(hired!=null and hired.workers[0].refugeResident==50,"Contratação além do sexto morador pode ser salva/carregada")
 # Exercise a real arrival and click-to-note at the end of the population list.
 await choose("Voltar ao jogo")
 g.session.load_state(initial.duplicate(true));s=g.session.state
 s.clock.minute=660;s.open=true;s.arrival=BAL.interval(s);s.refuge.visits=[]
 for id in range(1,50):s.refuge.visits.append(REF.visit_key(s,id))
 g.session.rng=func():return 0.5
 for i in 600:
  g.tick(0.05)
  if not s.customers.is_empty() and s.customers[0].state=="waiting":break
 check(s.customers.size()==1 and s.customers[0].refugeResident==50,"Quinquagésimo morador chega sem indexar nomes/sprites fora do atlas")
 if not s.customers.is_empty():
  var c: Dictionary = s.customers[0]
  await world(Vector2(c.x*40+20,c.y*40-12))
  check(s.player.has("noteJob"),"Clique no morador50 inicia anotação")
  advance(1.3)
  check(s.orders.any(func(o):return o.customer==c.id),"Pedido do morador50 usa atendimento normal")
  check(roundtrip(s)!=null,"Visita e pedido de ID alto persistem")
 # Two meal periods may record one hundred visits; old twelve-entry cap is gone.
 var visits: Dictionary = initial.duplicate(true)
 for period in 2:
  visits.period=period
  for person in visits.refuge.residents:visits.refuge.visits.append(REF.visit_key(visits,person.id))
 visits.period=0
 check(visits.refuge.visits.size()==100 and roundtrip(visits)!=null,"Cem registros dos dois turnos cabem no save")
 var old: Dictionary = initial.duplicate(true);old.refuge.erase("initialPopulation");old.refuge.residents=old.refuge.residents.slice(0,3)
 var restored = roundtrip(old)
 check(restored!=null and restored.refuge.residents.size()==3 and not restored.refuge.has("initialPopulation"),"Save anterior mantém três moradores sem expansão automática")
 # Preserve +1 per first victory and the existing cap of three reconstruction levels.
 for base in [initial,old]:
  var growth: Dictionary = base.duplicate(true);var count: int = growth.refuge.residents.size()
  for win in 4:
   growth.day=growth.refuge.nextHorde;growth.clock={"minute":1080,"remainder":0,"ending":false};growth.refuge.phase="day";growth.refuge.visits=[];growth.refuge.closed=[]
   preload("res://simulacao/nativa/Mercado.gd").restock(growth)
   for key in REF.STATS:growth.refuge.stats[key]=95
   REF.begin_attack(growth);REF.battle_step(growth,8)
   check(growth.refuge.residents.size()==count+mini(3,win+1) and roundtrip(growth)!=null,"Crescimento e salvamento preservados para base "+str(count))
 for kind in ["base","duplicate","missingBase","visit"]:
  var corrupt: Dictionary = initial.duplicate(true)
  if kind=="base":corrupt.refuge.initialPopulation=49
  elif kind=="duplicate":corrupt.refuge.residents[49].id=1
  elif kind=="missingBase":corrupt.refuge.erase("initialPopulation")
  else:corrupt.refuge.visits=["1:0:99"]
  check(g.session.SAVE.serialize(corrupt)==null,"Rejeita população/identidade inválida: "+kind)
 await finish()

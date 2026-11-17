extends RefCounted
## First playable refuge. Optional state keeps existing restaurants compatible.
const STATS = ["food","energy","morale"]
const BATTLE_SECONDS := 8.0
const INTERVALS = [4,5,3]
static func active(s: Dictionary) -> bool:return s.get("refuge") is Dictionary
static func resident(id: int) -> Dictionary:
	return {"id":id,"name":["Lia","Beto","Nina","Íris","Rui","Cora"][id-1],"skin":12+(id-1)%3,"food":65.0,"energy":70.0,"morale":65.0}
static func start(s: Dictionary) -> void:
	s.refuge={"version":1,"residents":[resident(1),resident(2),resident(3)],"nextHorde":3,"wave":0,"defeats":0,"defense":65.0,"level":0,"phase":"day","battle":null,"visits":[],"closed":[],"lastAttack":0}
	s.clock={"minute":600,"remainder":0,"ending":false}
static func blocked(s: Dictionary) -> bool:return active(s) and s.refuge.phase!="day"
static func attack_day(s: Dictionary) -> bool:return active(s) and (s.day>=s.refuge.nextHorde or s.refuge.lastAttack==s.day)
static func dinner_blocked(s: Dictionary) -> bool:return attack_day(s) and s.clock.minute>=s.serviceHours[1].start
static func cut_time(s: Dictionary) -> float:return 1.6 if active(s) and s.refuge.level>=1 else 2.0
static func find_resident(s: Dictionary,id: Variant) -> Variant:
	if not active(s):return null
	for person in s.refuge.residents:
		if person.id==id:return person
	return null
static func visit_key(s: Dictionary,id: int) -> String:return str(int(s.day))+":"+str(int(s.period))+":"+str(id)
static func next_resident(s: Dictionary) -> Variant:
	if not active(s):return null
	var best: Variant = null
	for person in s.refuge.residents:
		if visit_key(s,person.id) in s.refuge.visits:continue
		if best==null or person.food<best.food:best=person
	return best
static func bind_visit(s: Dictionary,c: Dictionary,person: Dictionary) -> void:
	c.refugeResident=person.id;c.skin=person.skin
	s.refuge.visits.append(visit_key(s,person.id))
static func completed(s: Dictionary,c: Dictionary,outcome: String) -> void:
	var person = find_resident(s,c.get("refugeResident"))
	if person==null:return
	if outcome=="completed":
		person.food=minf(100,person.food+26)
		var satisfaction = c.experience.get("satisfaction")
		person.morale=minf(100,person.morale+2+6*(float(satisfaction.score)/100 if satisfaction!=null else 0.5))
	else:person.morale=maxf(0,person.morale-3)
static func end_shift(s: Dictionary,period: int) -> void:
	if not active(s):return
	var key := str(int(s.day))+":"+str(period)
	if key in s.refuge.closed:return
	s.refuge.closed.append(key)
	# A canceled horde dinner never consumes food, energy or morale.
	if period==1 and attack_day(s):return
	for person in s.refuge.residents:
		person.food=maxf(0,person.food-8);person.energy=maxf(0,person.energy-6);person.morale=maxf(0,person.morale-2)
static func dawn(s: Dictionary) -> void:
	if not active(s):return
	for person in s.refuge.residents:
		person.energy=minf(100,person.energy+(16 if person.food>=40 else 8))
	s.refuge.visits=[];s.refuge.closed=[]
static func averages(s: Dictionary) -> Dictionary:
	var result := {"food":0.0,"energy":0.0,"morale":0.0}
	if not active(s):return result
	for person in s.refuge.residents:
		for key in STATS:result[key]+=person[key]/s.refuge.residents.size()
	return result
static func due(s: Dictionary) -> bool:return active(s) and s.refuge.phase=="day" and s.day>=s.refuge.nextHorde and s.clock.minute>=s.serviceHours[1].start
static func begin_attack(s: Dictionary) -> void:
	var r: Dictionary = s.refuge
	end_shift(s,0);end_shift(s,1)
	var stats := averages(s)
	# Deterministic, visible preparation decides the outcome. No hidden roll.
	var readiness: float = stats.food*0.35+stats.energy*0.25+stats.morale*0.25+r.defense*0.15
	var strength: float = minf(72,50+r.wave*4)
	var result := "calm" if readiness>=strength+18 else "held" if readiness>=strength else "retreat" if r.defeats==0 else "fallen"
	r.phase="battle";r.lastAttack=s.day
	r.battle={"day":s.day,"population":r.residents.size(),"elapsed":0.0,"result":result,"readiness":readiness,"strength":strength,"stats":stats,"defense":r.defense,"applied":false}
	s.open=false;s.closing=false
static func battle_step(s: Dictionary,dt: float) -> void:
	if not active(s) or s.refuge.phase!="battle":return
	s.refuge.battle.elapsed=minf(BATTLE_SECONDS,s.refuge.battle.elapsed+maxf(0,dt))
	if s.refuge.battle.elapsed>=BATTLE_SECONDS:resolve(s)
static func resolve(s: Dictionary) -> void:
	var r: Dictionary = s.refuge;var b: Dictionary = r.battle
	if b.applied:return
	b.applied=true;r.wave+=1
	if b.result in ["retreat","fallen"]:
		r.defeats+=1;r.defense=maxf(25,r.defense-20)
		for person in r.residents:person.morale=maxf(0,person.morale-8)
	else:
		r.defense=minf(100,r.defense+8)
		for person in r.residents:person.morale=minf(100,person.morale+8)
		# First reconstruction reward: a better cutting kit; then new residents.
		r.level=mini(3,r.level+1)
		if r.residents.size()<6:r.residents.append(resident(r.residents.size()+1))
	for person in r.residents:person.energy=maxf(0,person.energy-12)
	r.nextHorde=s.day+INTERVALS[(r.wave-1)%INTERVALS.size()]
	r.phase="gameover" if r.defeats>=2 else "aftermath"
static func continue_day(s: Dictionary) -> bool:
	if not active(s) or s.refuge.phase!="aftermath":return false
	s.refuge.phase="day";s.clock={"minute":1560,"remainder":0,"ending":true}
	return true
static func view(s: Dictionary) -> Variant:
	if not active(s):return null
	var r: Dictionary = s.refuge
	return {"phase":r.phase,"stats":averages(s),"residents":r.residents,"population":r.residents.size(),"days":maxi(0,int(r.nextHorde-s.day)),"defeats":r.defeats,"defense":r.defense,"level":r.level,"battle":r.battle,"day":s.day}
static func number(v: Variant) -> bool:return (v is int or v is float) and is_finite(v)
static func integer(v: Variant) -> bool:return number(v) and v==floor(v)
static func percent(v: Variant) -> bool:return number(v) and v>=0 and v<=100
static func valid(s: Dictionary) -> bool:
	if not s.has("refuge"):return true
	var r = s.refuge
	if not r is Dictionary or r.get("version")!=1:return false
	for key in ["nextHorde","wave","defeats","level","lastAttack"]:
		if not integer(r.get(key)) or r[key]<0:return false
	if r.nextHorde<1 or r.defeats>2 or r.level>3 or r.defeats>r.wave or r.level!=mini(3,r.wave-r.defeats) or r.lastAttack>s.day or r.wave>10000 or not percent(r.get("defense")):return false
	if r.get("phase") not in ["day","battle","aftermath","gameover"]:return false
	if not r.get("residents") is Array or r.residents.size()!=3+r.level:return false
	var ids := {}
	for person in r.residents:
		if not person is Dictionary or not integer(person.get("id")) or person.id<1 or person.id>6 or ids.has(person.id) or not person.get("name") is String or person.name.length()>32:return false
		if not integer(person.get("skin")) or person.skin<12 or person.skin>14:return false
		for key in STATS:
			if not percent(person.get(key)):return false
		ids[person.id]=true
	for key in ["visits","closed"]:
		if not r.get(key) is Array or r[key].size()>12:return false
		var seen := {}
		for entry in r[key]:
			if not entry is String or entry.length()>40 or seen.has(entry):return false
			var parts: PackedStringArray = entry.split(":")
			if parts.size()!=(3 if key=="visits" else 2) or parts[0]!=str(int(s.day)) or parts[1] not in ["0","1"]:return false
			if key=="visits" and (not parts[2].is_valid_int() or not ids.has(int(parts[2]))):return false
			seen[entry]=true
	for c in s.customers:
		if not ids.has(c.get("refugeResident")) or c.get("skin")!=find_resident(s,c.refugeResident).skin:return false
	if r.phase!="day" and (s.open or s.closing or not s.customers.is_empty()):return false
	if (r.phase=="gameover")!=(r.defeats==2):return false
	var b = r.get("battle")
	if b==null:return r.phase=="day" and r.wave==0 and r.defeats==0
	if not b is Dictionary or not integer(b.get("population")) or b.population<3 or b.population>r.residents.size() or not integer(b.get("day")) or b.day<1 or b.day>s.day or b.day!=r.lastAttack:return false
	if b.get("result") not in ["calm","held","retreat","fallen"] or not number(b.get("elapsed")) or b.elapsed<0 or b.elapsed>BATTLE_SECONDS or not b.get("applied") is bool:return false
	if not percent(b.get("readiness")) or not number(b.get("strength")) or b.strength<50 or b.strength>72 or not percent(b.get("defense")):return false
	if not b.get("stats") is Dictionary:return false
	for key in STATS:
		if not percent(b.stats.get(key)):return false
	var expected: float = b.stats.food*0.35+b.stats.energy*0.25+b.stats.morale*0.25+b.defense*0.15
	if not is_equal_approx(expected,b.readiness):return false
	var lost: bool = b.result in ["retreat","fallen"]
	var past_defeats: int = r.defeats-(1 if b.applied and lost else 0)
	var wave: int = r.wave-(1 if b.applied else 0)
	if wave<0 or b.strength!=minf(72,50+wave*4):return false
	var expected_result := "calm" if b.readiness>=b.strength+18 else "held" if b.readiness>=b.strength else "retreat" if past_defeats==0 else "fallen"
	if b.result!=expected_result:return false
	if r.phase=="battle":return not b.applied and b.elapsed<BATTLE_SECONDS and b.day==s.day
	return b.applied and b.elapsed==BATTLE_SECONDS

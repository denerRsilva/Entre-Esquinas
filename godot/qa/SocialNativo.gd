extends "res://qa/BaseNativa.gd"
func run():
	var state := preload("res://simulacao/nativa/Partida.gd").fresh(true,true)
	var social = preload("res://simulacao/nativa/Social.gd")
	state.player.room="street";state.player.x=5;state.player.y=10
	check(social.talk(state,"lia").contains("Lia") and state.friends.lia==1,"Conversa aumenta vínculo")
	social.talk(state,"lia");check(state.friends.lia==1,"Uma vez por dia")
	state.day+=1;social.talk(state,"lia");check(state.friends.lia==2,"Novo dia permite conversar")
	state.player.x=12;check(social.talk(state,"lia")=="Aproxime-se para conversar." and state.friends.lia==2,"Distância preserva vínculo")
	check(social.talk(state,"unknown")=="","Morador inexistente")
	print("FALHAS: ",failures);quit(1 if failures else 0)

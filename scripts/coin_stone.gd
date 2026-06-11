extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if "total_coin" in body:
		body.total_coin += 100
		
		print("Dapat 100 koin!")
		print("Total koin saat ini: " + str(body.total_coin))
		
		queue_free()

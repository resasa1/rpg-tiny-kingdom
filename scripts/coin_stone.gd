extends Area2D

# Mengambil node Sprite dan Collision untuk dianimasikan & dimatikan
@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D
@onready var coin_sound = $"../coin_hit"

func _on_body_entered(body: Node2D) -> void:
	if "total_coin" in body:
		# 1. Matikan collision seketika agar koin tidak bisa disentuh dua kali
		collision.set_deferred("disabled", true)
		
		# 2. Tambah skor koin pada player
		body.total_coin += 100
		print("Dapat 100 koin!")
		print("Total koin saat ini: " + str(body.total_coin))
		
		# 3. Putar suara koin (suara aman karena node koin tidak langsung dihapus)
		coin_sound.play()
		
		# 4. Mulai animasi menghilangkan koin perlahan
		animate_and_remove()

func animate_and_remove():
	var tween = create_tween().set_parallel(true)
	
	# Menggunakan 'self' (Area2D itu sendiri) jika node sprite bermasalah
	# Ini akan memudarkan seluruh koin beserta isinya
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	
	# Menggerakkan posisi seluruh node koin ke atas sejauh 30 pixel
	tween.tween_property(self, "position:y", position.y - 30, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Hapus dari game setelah selesai
	tween.chain().finished.connect(queue_free)

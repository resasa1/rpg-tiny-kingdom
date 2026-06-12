extends CharacterBody2D

const SPEED = 100.0
const RUN_SPEED = 180.0
const BULLET_SCENE = preload("res://scenes/bullet.tscn")
const MAX_CAM_DISTANCE = 300.0 # Batas maksimal kamera boleh menjauh dari player (pixel)
const CAM_SMOOTH_SPEED = 10.0  # Kecepatan kembalinya kamera ke player

@onready var animated_sprite = $AnimatedSprite2D
var is_attacking: bool = false
var is_guard: bool = false
var total_coin: int = 0
var audio_tween: Tween
var is_panning: bool = false
var camera_offset: Vector2 = Vector2.ZERO

@onready var run_sound = $run_sound
@onready var attack_sound = $attack_sound
@onready var shoot_sound = $shoot_sound
@onready var camera = $Camera2D
@onready var coin_modal = $CoinModal
@onready var coin_label = $CoinModal/CoinLabel
@onready var muzzle = $muzzle

func _physics_process(delta: float) -> void:
	# Menampilkan / menyembunyikan modal koin saat menekan tombol TAB
	if Input.is_action_pressed("show_tab"):
		coin_label.text = "Total Coin: " + str(total_coin)
		coin_modal.visible = true
	else:
		coin_modal.visible = false
		
	if Input.is_action_pressed("input_guard"):
		if not is_guard: 
			start_guard()
		velocity = Vector2.ZERO
		move_and_slide()
		return
	elif is_guard:
		# Jika tombol guard dilepas secara manual sebelum animasi selesai
		is_guard = false
		
	# Jika sedang menyerang, hentikan pergerakan karakter
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	# Deteksi input serangan
	if Input.is_action_just_pressed("input_attack"):
		start_attack()
		return
	
	if Input.is_action_just_pressed("input_special"):
		start_shoot()
		shoot_sound.play()
		return
		
	# Mengambil input arah pergerakan (Up, Down, Left, Right)
	var direction_x := Input.get_axis("input_left", "input_right")
	var direction_y := Input.get_axis("input_up", "input_down")
	var direction := Vector2(direction_x, direction_y)
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		
		# Cek apakah tombol Shift ditekan bersamaan dengan arah mana pun
		if Input.is_action_pressed("input_run"):
			velocity = direction * RUN_SPEED # Menggunakan kecepatan lari
			
			# Putar animasi lari jika ada di AnimatedSprite2D Anda
			if animated_sprite.sprite_frames.has_animation("run"):
				animated_sprite.play("run")
			else:
				animated_sprite.play("walk")
		else:
			velocity = direction * SPEED # Kecepatan jalan normal
			animated_sprite.play("walk")
			
		# Mengatur suara langkah kaki saat bergerak
		if not run_sound.playing:
			run_sound.play()
		if audio_tween and audio_tween.is_valid():
			audio_tween.kill() 
		run_sound.volume_db = 0.0
	else:
		# Jika tidak ada tombol arah yang ditekan
		velocity = Vector2.ZERO
		animated_sprite.play("idle")
		
		# Efek memudarkan suara langkah kaki sampai berhenti (Fade-out)
		if run_sound.playing and (audio_tween == null or not audio_tween.is_valid()):
			fade_out_run_sound()
			
	move_and_slide()
	
	# Mengatur arah hadap sprite berdasarkan pergerakan horizontal
	if direction_x > 0:
		animated_sprite.flip_h = false
	elif direction_x < 0:
		animated_sprite.flip_h = true
	
	#camera handled
	if is_panning:
		# Jika sedang klik-seret, geser kamera ke posisi target offset secara instan
		camera.position = camera_offset
	else:
		# Jika Klik Kiri dilepas, kembalikan kamera ke tubuh player secara perlahan (smooth)
		camera_offset = camera_offset.lerp(Vector2.ZERO, CAM_SMOOTH_SPEED * delta)
		camera.position = camera_offset

func fade_out_run_sound() -> void:
	audio_tween = create_tween()
	# Perbaikan struktur chaining agar tidak memicu error null instance di Godot 4
	audio_tween.tween_property(run_sound, "volume_db", -40.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	audio_tween.tween_callback(run_sound.stop)

func start_attack() -> void:
	is_attacking = true
	animated_sprite.play("attack")
	
	if audio_tween and audio_tween.is_valid():
		audio_tween.kill()
		
	run_sound.stop()
	attack_sound.play()
	
	# Menghubungkan sinyal selesainya animasi attack agar karakter bisa bergerak lagi
	if not animated_sprite.animation_finished.is_connected(_on_attack_animation_finished):
		animated_sprite.animation_finished.connect(_on_attack_animation_finished)

func start_guard() -> void:
	is_guard = true
	is_attacking = false
	animated_sprite.play("guard")
	
	if not animated_sprite.animation_finished.is_connected(_on_guard_animation_finished):
		animated_sprite.animation_finished.connect(_on_guard_animation_finished)

func start_shoot() -> void:
	is_attacking = true
	animated_sprite.play("attack2")
	if run_sound.playing:
		run_sound.stop()
		
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ambil arah hadap karakter saat ini dari input pergerakan
	var dir_x := Input.get_axis("input_left", "input_right")
	var dir_y := Input.get_axis("input_up", "input_down")
	var shoot_dir := Vector2(dir_x, dir_y)
	
	# Jika player menembak sambil diam, tentukan arah default berdasarkan flip_h
	if shoot_dir == Vector2.ZERO:
		if animated_sprite.flip_h:
			shoot_dir = Vector2.LEFT
		else:
			shoot_dir = Vector2.RIGHT
	else:
		shoot_dir = shoot_dir.normalized()
		
	# Kirim data arah pergerakan asli ke objek peluru
	bullet_instance.direction = shoot_dir
	
	# Atur rotasi gambar peluru agar menghadap ke arah terbangnya secara otomatis
	bullet_instance.global_rotation = shoot_dir.angle()
	
	# --- SOLUSI TOTAL 8 ARAH (KIRI, KANAN, ATAS, BAWAH, DIAGONAL) ---
	# Kita hitung jarak absolut (radius) titik muzzle dari pusat badan player
	var radius = muzzle.position.length()
	
	# Tempatkan posisi awal peluru secara melingkar sempurna mengikuti arah tembakan Anda
	# Ditambahkan Vector2(0, -16) atau sesuaikan tinggi dada/tengah karakter agar peluru berputar di poros tengah badan
	var player_center = global_position + Vector2(0, -16) 
	bullet_instance.global_position = player_center + (shoot_dir * radius)
		
	# Tambahkan ke root scene utama
	get_tree().root.add_child(bullet_instance)
	
	if not animated_sprite.animation_finished.is_connected(_on_attack_animation_finished):
		animated_sprite.animation_finished.connect(_on_attack_animation_finished)

func _on_attack_animation_finished() -> void:
	if animated_sprite.animation == "attack" or animated_sprite.animation == "attack2":
		is_attacking = false

func _on_guard_animation_finished() -> void:
	if animated_sprite.animation == "guard":
		is_guard = false

#camera mouse panning
func _unhandled_input(event: InputEvent) -> void:
	# Cek jika Klik Kiri ditekan atau dilepas
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_panning = event.pressed
		
	# Cek jika mouse digeser SAAT Klik Kiri sedang ditahan
	if event is InputEventMouseMotion and is_panning:
		# Tambahkan offset kamera berdasarkan seberapa jauh mouse digeser
		# Nilai dikurangi (-) agar arah seret terasa natural (seperti menarik peta)
		camera_offset -= event.relative
		
		# Batasi agar kamera tidak bisa digeser terlalu jauh tanpa batas
		camera_offset = camera_offset.limit_length(MAX_CAM_DISTANCE)

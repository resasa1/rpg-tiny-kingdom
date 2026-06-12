extends Area2D

const BULLET_SPEED = 100.0
var direction := Vector2.RIGHT # Default terbang ke kanan
const BULLET_AMMO = 10

@onready var sprite_terbang = $DuckBullet
@onready var sprite_ledakan = $Exploison
@onready var collision = $CollisionShape2D
@onready var explode_sound = $hit_shoot_sound

var is_exploded := false

func _ready() -> void:
	# Hubungkan sinyal lewat kode agar 100% pasti terdeteksi saat menabrak
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		
	# Mulai memutar animasi peluru terbang
	sprite_terbang.visible = true
	sprite_terbang.play("default") 
	sprite_ledakan.visible = false 
	
	# Jika dalam 3 detik peluru tidak menabrak apapun, hapus secara diam-diam
	var lifetime_timer = get_tree().create_timer(3.0)
	lifetime_timer.timeout.connect(destroy_bullet_silently)

func _physics_process(delta: float) -> void:
	# Jika sudah meledak, peluru berhenti bergerak
	if is_exploded:
		return
		
	# Peluru terbang lurus sesuai arah hadap karakter
	position += direction * BULLET_SPEED * delta

# Terpicu saat peluru mengenai objek (TileMap, Musuh, Dinding, dll)
func _on_body_entered(body: Node2D) -> void:
	# PENGAMAN UTAMA: Abaikan jika yang tertabrak adalah Player itu sendiri
	if body.name == "Player" or body.is_in_group("Player") or "total_coin" in body: 
		return
		
	# Perbaikan: Menghapus baris pemanggilan ganda yang salah ketik kemarin
	explode()

func explode() -> void:
	if is_exploded: return # Pengaman tambahan agar fungsi tidak berjalan berkali-kali
	is_exploded = true
	
	collision.set_deferred("disabled", true) # Matikan deteksi tabrakan
	sprite_terbang.visible = false           # Sembunyikan peluru terbang
	sprite_ledakan.visible = true            # Munculkan animasi ledakan
	
	sprite_ledakan.frame = 0
	sprite_ledakan.play("explode") 
	explode_sound.play()
	
	# Memaksa peluru terhapus dari memory 0.4 detik setelah meledak
	var kill_timer = get_tree().create_timer(0.4)
	kill_timer.timeout.connect(queue_free)

# FUNGSI BARU: Menghapus peluru di ujung map tanpa memunculkan efek ledakan
func destroy_bullet_silently() -> void:
	if not is_exploded:
		queue_free()

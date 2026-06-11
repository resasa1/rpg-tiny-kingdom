extends CharacterBody2D

const SPEED = 200.0

@onready var animated_sprite = $AnimatedSprite2D

var is_attacking: bool = false
var total_coin: int = 0

@onready var coin_modal = $CoinModal
@onready var coin_label = $CoinModal/CoinLabel

func _physics_process(delta: float) -> void:
	
	if Input.is_action_pressed("show_tab"):
		coin_label.text = "Total Coin: " + str(total_coin)
		coin_modal.visible = true
	else:
		coin_modal.visible = false
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if Input.is_action_just_pressed("attack"):
		start_attack()
		return 

	var direction_x := Input.get_axis("left", "right")
	var direction_y := Input.get_axis("up", "down")
	var direction := Vector2(direction_x, direction_y)
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * SPEED
		
		animated_sprite.play("run") 
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("idle") 

	move_and_slide()
	
	if direction_x > 0:
		animated_sprite.flip_h = false  
	elif direction_x < 0:
		animated_sprite.flip_h = true   

func start_attack() -> void:
	is_attacking = true
	animated_sprite.play("attack")
	
	if not animated_sprite.animation_finished.is_connected(_on_attack_animation_finished):
		animated_sprite.animation_finished.connect(_on_attack_animation_finished)

func _on_attack_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false

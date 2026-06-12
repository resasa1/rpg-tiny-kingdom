extends Node

const GAME_BGM = preload("res://assets/Visual Novel Audio Pack Vol. 1/2. Pieces/ogg/Relax.ogg") # Sesuaikan path file Anda


var bgm_player: AudioStreamPlayer

func _ready() -> void:
	# 1. Buat node AudioStreamPlayer secara otomatis lewat kode
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	
	# 2. Masukkan file musik ke dalam player
	bgm_player.stream = GAME_BGM
	
	# 3. Set agar musik otomatis memutar ulang jika habis (Looping) di Godot 4
	bgm_player.stream.loop = true
	
	# 4. Atur volume jika terlalu keras (opsional, nilai minus berarti lebih pelan)
	bgm_player.volume_db = -10.0 
	
	# 5. Mulai putar musik saat game pertama kali dibuka
	play_bgm()

func play_bgm() -> void:
	if bgm_player and not bgm_player.playing:
		bgm_player.play()

func stop_bgm() -> void:
	if bgm_player and bgm_player.playing:
		bgm_player.stop()

extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")

var player: CharacterBody3D
var spawn_timer: Timer
var hud: Label
var message: Label
var score := 0
var wave := 1
var game_over := false

func _ready() -> void:
	_build_arena()
	_build_lighting()
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(0, 1, 0)
	add_child(player)
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	_build_hud()
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 2.0
	spawn_timer.timeout.connect(_spawn_enemy)
	add_child(spawn_timer)
	spawn_timer.start()
	_spawn_enemy()

func _build_arena() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "ArenaFloor"
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(32, 32)
	floor_mesh.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.12, 0.16, 0.20)
	floor_material.roughness = 0.9
	floor_mesh.material_override = floor_material
	floor_body.add_child(floor_mesh)
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(32, 0.2, 32)
	floor_collision.shape = floor_shape
	floor_collision.position.y = -0.1
	floor_body.add_child(floor_collision)
	add_child(floor_body)
	for i in range(4):
		var wall := StaticBody3D.new()
		var wall_mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(32, 3, 0.5) if i < 2 else Vector3(0.5, 3, 32)
		wall_mesh.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.20, 0.25, 0.30)
		wall_mesh.material_override = mat
		wall.add_child(wall_mesh)
		var wall_collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = box.size
		wall_collision.shape = shape
		wall.add_child(wall_collision)
		if i == 0: wall.position = Vector3(0, 1.5, -16)
		elif i == 1: wall.position = Vector3(0, 1.5, 16)
		elif i == 2: wall.position = Vector3(-16, 1.5, 0)
		else: wall.position = Vector3(16, 1.5, 0)
		add_child(wall)

func _build_lighting() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 1.2
	add_child(light)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.44, 0.55)
	env.ambient_light_energy = 0.65
	environment.environment = env
	add_child(environment)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(20, 18)
	hud.add_theme_font_size_override("font_size", 22)
	hud.text = "Health: 100   Score: 0   Wave: 1"
	layer.add_child(hud)
	var help := Label.new()
	help.position = Vector2(20, 54)
	help.text = "WASD move  •  Mouse aim  •  Left click shoot  •  Esc free mouse"
	layer.add_child(help)
	message = Label.new()
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 36)
	layer.add_child(message)
	_update_hud()

func _spawn_enemy() -> void:
	if game_over:
		return
	var enemy := ENEMY_SCENE.instantiate()
	var angle := randf() * TAU
	var radius := randf_range(10.0, 13.0)
	enemy.position = Vector3(cos(angle) * radius, 1, sin(angle) * radius)
	enemy.target = player
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)
	if score > 0 and score % 10 == 0:
		wave = 1 + score / 10
	_update_hud()

func _on_enemy_died() -> void:
	score += 1
	_update_hud()

func _on_health_changed(value: int) -> void:
	_update_hud(value)

func _on_player_died() -> void:
	game_over = true
	spawn_timer.stop()
	message.text = "GAME OVER\nScore: %d\nPress Enter to restart" % score
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _update_hud(health: int = -1) -> void:
	if hud == null:
		return
	if health < 0 and is_instance_valid(player):
		health = int(player.health)
	hud.text = "Health: %d   Score: %d   Wave: %d" % [health, score, wave]

func _unhandled_input(event: InputEvent) -> void:
	if game_over and event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		get_tree().reload_current_scene()

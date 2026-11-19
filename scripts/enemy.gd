extends CharacterBody3D

signal died

@export var move_speed := 2.8
@export var max_health := 100
var health := 100
var target: CharacterBody3D
var attack_cooldown := 0.0
var mesh_instance: MeshInstance3D

func _ready() -> void:
	health = max_health
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	mesh_instance = MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.48
	mesh.height = 1.8
	mesh_instance.mesh = mesh
	mesh_instance.position.y = 0.9
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.82, 0.16, 0.12)
	mesh_instance.material_override = material
	add_child(mesh_instance)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var toward := target.global_position - global_position
	toward.y = 0
	if toward.length() > 1.35:
		var direction := toward.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = 0
		velocity.z = 0
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			attack_cooldown = 0.8
			target.take_damage(10)
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	if health <= 0:
		died.emit()
		queue_free()

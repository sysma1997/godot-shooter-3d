extends CharacterBody3D

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera
@onready var weapon_controller: WeaponController = $Head/WeaponVisual

@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var jump_velocity := 4.5
@export var mouse_sensivity := 0.002
@export var acceleration := 10.0
@export var air_control := 0.3

var speed: float
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensivity)
		head.rotate_x(-event.relative.y * mouse_sensivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event.is_action_pressed("fire"):
		weapon_controller.fire()
	if event.is_action_pressed("reload"):
		weapon_controller.reload()

func _process(delta: float) -> void:
	if weapon_controller and weapon_controller.current_weapon:
		if weapon_controller.current_weapon.is_automatic:
			if Input.is_action_pressed("fire"):
				weapon_controller.fire()
				# Disparo continuo sin esperar al timer visual
				while weapon_controller.fire_timer <= 0 and Input.is_action_pressed("fire"):
					if weapon_controller.current_magazine_ammo > 0:
						weapon_controller.fire()
					else:
						break
					# Pequeña pausa entre disparos automaticos
					await get_tree().create_timer(weapon_controller.current_weapon.fire_rate * 0.5).timeout
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_velocity := direction * speed
	var control_factor := 1.0 if is_on_floor() else air_control
	
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * control_factor * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * control_factor * delta)
	
	move_and_slide()

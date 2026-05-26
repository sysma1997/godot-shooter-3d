class_name WeaponController extends Node3D
# Señales
signal weapon_fired(weapon_data: WeaponData)
signal ammo_changed(magazine: int, total: int)
signal reload_started(reload_time: float)
signal reload_finished()
# Referencia al arma actual
@export var current_weapon: WeaponData
@onready var muzzle: Marker3D = $Muzzle
@onready var muzzle_flash: GPUParticles3D = $MuzzleFlash
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Estados internos
var current_magazine_ammo: int
var current_total_ammo: int
var can_fire: bool = true
var is_reloading: bool = false
var fire_timer: float = 0.0

func _ready() -> void:
	if current_weapon:
		initialize_weapon(current_weapon)

func _process(delta: float) -> void:
	if fire_timer > 0:
		fire_timer -= delta

func initialize_weapon(weapon: WeaponData) -> void:
	current_weapon = weapon
	current_magazine_ammo = weapon.magazine_size
	current_total_ammo = weapon.total_ammo
	can_fire = true
	is_reloading = false
	ammo_changed.emit(current_magazine_ammo, current_total_ammo)

func fire() -> void:
	# Verificaciones
	if not can_fire: return
	if is_reloading: return
	if fire_timer > 0: return
	if current_magazine_ammo <= 0:
		reload()
		return
	
	current_magazine_ammo -= 1
	fire_timer = current_weapon.fire_rate
	ammo_changed.emit(current_magazine_ammo, current_total_ammo)
	# Efectos visuales
	_show_muzzle_flash()
	# Realizar el disparo
	_perform_raycast()
	# Recoil visual
	_apply_recoil()
	
	# Señal de disparo
	weapon_fired.emit(current_weapon)
	
	# Auto-recarga si esta vacio
	if current_magazine_ammo <= 0 and current_total_ammo > 0:
		reload()

func _perform_raycast() -> void:
	var space_state = get_world_3d().direct_space_state
	var camera = get_viewport().get_camera_3d()
	# Calcular direccion con dispersion
	var direction = -camera.global_transform.basis.z # Hacia adelante
	var spread = deg_to_rad(current_weapon.spread_angle)
	direction = direction.rotated(Vector3.RIGHT, randf_range(-spread, spread))
	direction = direction.rotated(Vector3.UP, randf_range(-spread, spread))
	# Configuracion del RayCast
	var query = PhysicsRayQueryParameters3D.create(
		camera.global_position, 
		camera.global_position + direction * current_weapon.max_range
	)
	var result = space_state.intersect_ray(query)
	
	if result:
		# Impacto algo
		var hit_point = result.position
		var hit_normal = result.normal
		var hit_object = result.collider
		print("Impacto en: ", hit_object.name, " a ", hit_point)
		# Efecto impacto
		# _spawn_impact_effect(hit_point, hit_normal)
func reload() -> void:
	if is_reloading: return
	if current_magazine_ammo >= current_weapon.magazine_size: return
	if current_total_ammo <= 0: return
	
	is_reloading = true
	can_fire = false
	reload_started.emit(current_weapon.reload_time)
	# Simular tiempo de carga
	await get_tree().create_timer(current_weapon.reload_time).timeout
	# Calcular cuantas balas necesitamos
	var needed = current_weapon.magazine_size - current_magazine_ammo
	var to_reload = min(needed, current_total_ammo)
	
	current_magazine_ammo += to_reload
	current_total_ammo -= to_reload
	
	is_reloading = false
	can_fire = true
	ammo_changed.emit(current_magazine_ammo, current_total_ammo)
	reload_finished.emit()

func _show_muzzle_flash() -> void:
	if muzzle_flash:
		muzzle_flash.restart()
		muzzle_flash.emitting = true
		await get_tree().create_timer(0.05).timeout
		muzzle_flash.emitting = false
func _apply_recoil() -> void:
	# Rotacion ligera hacia arriba
	var recoil_rot = Vector3(
		-current_weapon.recoil_vertical * 0.01, 
		randf_range(-current_weapon.recoil_horizontal, current_weapon.recoil_horizontal) * 0.01, 
		0
	)
	rotation += recoil_rot
	
	var tween = create_tween()
	tween.tween_property(self, "rotation", Vector3.ZERO, 0.1)

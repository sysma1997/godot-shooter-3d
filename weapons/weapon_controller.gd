class_name WeaponController extends Node3D
# Señales
signal weapon_fired(weapon_data: WeaponData)
signal ammo_changed(magazine: int, total: int)
signal reload_started(reload_time: float)
signal reload_finished()
# Referencia al arma actual
@export var current_weapon: WeaponData
@onready var muzzle: Marker3D = $Muzzle
@onready var muzzle_flash_light: OmniLight3D = $MuzzleFashLight
@onready var mesh_flash: MeshInstance3D = $MeshFlash
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Estados internos
var current_magazine_ammo: int
var current_total_ammo: int
var can_fire: bool = true
var is_reloading: bool = false
var fire_timer: float = 0.0

var current_recoil_x: float = 0.0
var current_recoil_y: float = 0.0
var recoil_recovery_speed: float = 5.0
var is_firing: bool = false

func _ready() -> void:
	if current_weapon:
		initialize_weapon(current_weapon)
	
	if muzzle_flash_light:
		muzzle_flash_light.light_energy = 0.0
	if mesh_flash:
		mesh_flash.visible = false

func _process(delta: float) -> void:
	if fire_timer > 0:
		fire_timer -= delta
	
	if not is_firing and not is_reloading:
		_recover_recoil(delta)

func initialize_weapon(weapon: WeaponData) -> void:
	current_weapon = weapon
	current_magazine_ammo = weapon.magazine_size
	current_total_ammo = weapon.total_ammo
	can_fire = true
	is_reloading = false
	ammo_changed.emit(current_magazine_ammo, current_total_ammo)

func fire() -> void:
	# Verificaciones
	if not can_fire or is_reloading: return
	if fire_timer > 0: return
	if current_magazine_ammo <= 0:
		reload()
		return
	
	is_firing = true
	
	current_magazine_ammo -= 1
	fire_timer = current_weapon.fire_rate
	ammo_changed.emit(current_magazine_ammo, current_total_ammo)
	# Efectos visuales
	_show_muzzle_flash()
	_apply_recoil()
	_apply_weapon_kickback()
	# Realizar el raycast
	_perform_raycast()
	
	# Señal de disparo
	weapon_fired.emit(current_weapon)
	
	# Auto-recarga si esta vacio
	if current_magazine_ammo <= 0 and current_total_ammo > 0:
		# Pequeño delay para que no recargue instantaneamente
		get_tree().create_timer(0.2).timeout.connect(reload)
	
	# Resetea is_firing despues de un momento
	if not current_weapon.is_automatic:
		await get_tree().create_timer(0.1).timeout
		is_firing = false

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
	if muzzle_flash_light:
		muzzle_flash_light.light_energy = 10.0
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_EXPO)
		tween.tween_property(muzzle_flash_light, "light_energy", 0.0, 0.08)
	if mesh_flash:
		mesh_flash.visible = true
		mesh_flash.scale = Vector3(1.8, 1.8, 1.8)
		mesh_flash.global_position = muzzle.global_position
		mesh_flash.global_rotation = muzzle.global_rotation
		mesh_flash.rotate_z(randf_range(0, TAU))
		
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(mesh_flash, "scale", Vector3(0.1, 0.1, 0.1), 0.05)
		tween.tween_callback(func(): mesh_flash.visible = false)
func _apply_recoil() -> void:
	# Recoil mas notorio
	var camera = get_viewport().get_camera_3d()
	if not camera: return
	
	# Acumular retroceso
	# Cada disparo suma mas retroceso
	var recoil_vertical = current_weapon.recoil_vertical * 0.08
	var recoil_horizontal = current_weapon.recoil_horizontal * 0.08
	# Si es automatica y se mantiene precionado, el retroceso crece mas
	if current_weapon.is_automatic:
		# Cuando mas dispara, mas sube
		var spray_factor = 1.0 + (current_recoil_x * 0.5)
		recoil_vertical *= spray_factor
		recoil_horizontal *= spray_factor * 1.2 # Mas dispersion lateral con el tiempo
	# Acumular en los acumuladores
	current_recoil_x += recoil_vertical
	current_recoil_y += randf_range(-recoil_horizontal, recoil_horizontal)
	# Limitar el maximo para que no sea injugable
	current_recoil_x = clamp(current_recoil_x, 0.0, 8.0)
	current_recoil_y = clamp(current_recoil_y, -5.0, 5.0)
	# Aplicar rotacion instantanea a la camara
	camera.rotation.x += deg_to_rad(recoil_vertical * 3.0)
	camera.rotation.y += deg_to_rad(randf_range(-recoil_horizontal, recoil_horizontal) * 3.0)
func _apply_weapon_kickback() -> void:
	var kick_direction = Vector3(randf_range(-0.01, 0.01), 0.015, 0.04)
	position += kick_direction
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position", position - kick_direction, 0.12)
func _recover_recoil(delta: float) -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera: return
	# Reducir acumuladores gradualmente
	current_recoil_x = move_toward(current_recoil_x, 0.0, recoil_recovery_speed * delta)
	current_recoil_y = move_toward(current_recoil_y, 0.0, recoil_recovery_speed * delta)
	# Recuperar rotacion de camara suave
	camera.rotation.x = move_toward(camera.rotation.x, 0.0, 3.0 * delta)
	camera.rotation.y = move_toward(camera.rotation.y, 0.0, 3.0 * delta)

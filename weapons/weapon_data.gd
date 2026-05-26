class_name WeaponData extends Resource
# Identidad
@export var name: String = "Unnamed Weapon"
@export var icon: Texture2D
# Disparo
@export var fire_rate: float = 0.1          # Tiempo de disparos (segundos)
@export var is_automatic: bool = false      # Disparo continuo al mantener el click
@export var damage: float = 10.0            # Daño de cada disparo
@export var max_range: float = 100.0        # Alcance maximo en metros
# Municion
@export var magazine_size: int = 30         # Balas por cargador
@export var total_ammo: int = 120           # Municion total Disponible
@export var reload_time: float = 1.5        # Tiempo de recarga (segundos)
# Disparo / Recoil
@export var spread_angle: float = 0.5       # Angulo de dispersion en grados
@export var recoil_vertical: float = 0.2    # Cuanto sube el arma al disparar
@export var recoil_horizontal: float = 0.1  # Cuanto se mueve lateral
# Visual y sonido
@export var muzzle_flash_scene: PackedScene
@export var fire_sound: AudioStream
@export var impact_effect: PackedScene

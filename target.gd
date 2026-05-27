extends StaticBody3D

@export var health: float = 100.0
var original_color: Color

func _ready() -> void:
	if $MeshInstance3D.mesh is BoxMesh:
		original_color = Color.RED

func take_damage(amount: float) -> void:
	health -= amount
	
	var mesh = $MeshInstance3D
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	mesh.material_override = material
	
	await get_tree().create_timer(0.05).timeout
	mesh.material_override = null
	
	if health <= 0:
		queue_free()
		print("Target destruido")

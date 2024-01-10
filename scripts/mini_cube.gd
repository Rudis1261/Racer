extends MeshInstance3D

func _ready() -> void:
	await get_tree().create_timer(60).timeout
	queue_free()

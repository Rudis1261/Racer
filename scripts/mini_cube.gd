extends MeshInstance3D

@onready var animation: AnimationPlayer = %animation

func _ready() -> void:
	await get_tree().create_timer(60).timeout
	animation.play("fade_out")

func _on_animation_animation_finished(anim_name: StringName) -> void:
	queue_free()

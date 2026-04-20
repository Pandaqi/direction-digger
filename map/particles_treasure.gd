extends CPUParticles2D
class_name ParticlesTreasure

func _ready() -> void:
	set_emitting(true)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

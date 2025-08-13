class_name Goblin extends Mob


@export var goblin_mob_resource: MobResource
@onready var mob_body: MobBody = $MobBody


func _ready() -> void:
	mob_body.set_sprite(goblin_mob_resource.animated_sprite)

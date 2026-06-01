class_name DamageAuthority
extends RefCounted


static func apply_damage(target: Node, amount: float, source: String = "") -> void:
	if amount <= 0.0 or target == null:
		return
	if target is Player:
		SurvivalAuthority.apply_damage(target as Player, amount, source)
	elif target is BaseEntity:
		(target as BaseEntity).take_damage(int(ceil(amount)))

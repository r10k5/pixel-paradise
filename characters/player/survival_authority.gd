class_name SurvivalAuthority
extends RefCounted


static func apply_damage(player: Player, amount: float, source: String = "") -> void:
	if player == null or amount <= 0.0:
		return
	var stats := _stats(player)
	if stats == null:
		return
	stats.apply_damage(amount)
	if source == "bomb" and stats.hp <= 0.0:
		pass


static func heal(player: Player, amount: float) -> void:
	var stats := _stats(player)
	if stats != null:
		stats.heal(amount)


static func restore_hunger(player: Player, amount: float) -> void:
	var stats := _stats(player)
	if stats != null:
		stats.restore_hunger(amount)


static func restore_stamina(player: Player, amount: float) -> void:
	var stats := _stats(player)
	if stats != null:
		stats.restore_stamina(amount)


static func spend_stamina(player: Player, amount: float, allow_partial: bool = false) -> bool:
	var stats := _stats(player)
	if stats == null:
		return false
	if allow_partial:
		stats.spend_stamina_flat(amount)
		return true
	return stats.spend_stamina(amount)


static func _stats(player: Player) -> SurvivalStats:
	if player == null:
		return null
	return player.get_node_or_null("SurvivalStats") as SurvivalStats

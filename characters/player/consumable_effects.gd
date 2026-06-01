class_name ConsumableEffects
extends RefCounted


static func try_use_selected(player: Player) -> bool:
	if player == null:
		return false
	var inv := player.inventory
	var slot_item := inv.get_item(player.selected_hotbar_slot)
	if slot_item == null or slot_item.is_empty():
		return false
	var item := slot_item.item
	if item == null:
		return false
	var hunger_restore := 0.0
	var stamina_restore := 0.0
	var hp_restore := 0.0
	if item is PickupItem:
		var pickup := item as PickupItem
		hunger_restore = pickup.hunger_restore
		stamina_restore = pickup.stamina_restore
		hp_restore = pickup.hp_restore
	if hunger_restore <= 0.0 and stamina_restore <= 0.0 and hp_restore <= 0.0:
		return false
	if not inv.consume_one_by_item_id(str(item.id)):
		return false
	if hunger_restore > 0.0:
		SurvivalAuthority.restore_hunger(player, hunger_restore)
	if stamina_restore > 0.0:
		SurvivalAuthority.restore_stamina(player, stamina_restore)
	if hp_restore > 0.0:
		SurvivalAuthority.heal(player, hp_restore)
	return true

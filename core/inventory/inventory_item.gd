class_name InventoryItem

var id: int
var item: BaseEntity
var count: int = 1

func is_empty() -> bool:
	return item == null

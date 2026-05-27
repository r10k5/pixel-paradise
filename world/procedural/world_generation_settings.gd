class_name WorldGenerationSettings
extends Resource

@export_group("Основное")
@export var seed: int = 0
@export var map_scale: float = 1.5
@export var chunk_size: int = 32

@export_group("Параметры высот")
@export var height_frequency: float = 0.035
@export var height_octaves: int = 4
@export var water_level: float = -0.22
@export var puddle_level: float = -0.16

@export_group("Вода: реки/озёра/лужи")
@export var river_frequency: float = 0.006
@export var river_width: float = 0.045
@export var lake_frequency: float = 0.01
@export var lake_threshold: float = 0.2
@export var lake_height_bias: float = 0.04
@export var puddle_frequency: float = 0.08
@export var puddle_threshold: float = 0.86
@export var puddle_spawn_chance: float = 0.2

@export_group("Биомы")
@export var enable_biomes: bool = true
@export var biome_precompute_radius: int = 64
## Чем меньше — тем крупнее пятна биомов (шум влажности/температуры).
@export var moisture_frequency: float = 0.004
@export var temperature_frequency: float = 0.0035

@export_group("Дороги")
@export var path_density: float = 0.065
@export var path_thickness: float = 0.028

@export_group("Декорации")
@export var enable_decorations: bool = true
@export var global_decoration_multiplier: float = 1.0
@export var decoration_spacing_tiles: int = 2

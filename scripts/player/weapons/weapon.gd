extends Node2D
class_name Weapon
@export var data: WeaponData
@export_group("Sprite")
@export var sprite_top_left: Texture2D
@export var sprite_top_right: Texture2D
@export var sprite_bottom_left: Texture2D
@export var sprite_bottom_right: Texture2D
@export var sprite_scale_mult: float = 7.0
@export var sprite_offset: float = 20.0  ## distancia do centro do player ate a arma
@export var sprite_z_index: int = 1  ## acima do player (z_index 0 por padrao)
@export var sprite_rotation_mult: float = 0.1  ## 1.0 = giro total (+-45), 0.0 = sem giro

@export_group("Muzzle")
## Ponto da ponta do cano em pixels, relativo ao CENTRO de cada textura
## (Sprite2D e centered por padrao, entao (0,0) = centro da imagem).
@export var muzzle_point_top_left: Vector2 = Vector2.ZERO
@export var muzzle_point_top_right: Vector2 = Vector2.ZERO
@export var muzzle_point_bottom_left: Vector2 = Vector2.ZERO
@export var muzzle_point_bottom_right: Vector2 = Vector2.ZERO

@export_group("Screen Dirt")
## 1.0 = um carregador cheio enche a tela em 100%.
## 0.5 = precisa de 2 carregadores pra encher. 0.33 = precisa de 3. etc.
@export var dirtiness_scale: float = 0.25

const ProjectileScene := preload("res://scenes/combat/projectile.tscn")

enum FacingDir { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }

@onready var _sprite: Sprite2D = $Sprite2D

var upgrades: UpgradeSystem
var runtime: WeaponData
var _cooldown: float = 0.0
var _pierce: int = 0
var _has_sprites: bool = false
var _facing: FacingDir = FacingDir.BOTTOM_RIGHT

func _ready() -> void:
	if data == null:
		data = preload("res://resources/weapons/basic_ink.tres")
	runtime = data.duplicate() as WeaponData
	GameEvents.upgrades_changed.connect(recompute)
	recompute()
	_setup_sprite()

func _setup_sprite() -> void:
	_has_sprites = sprite_top_left != null and sprite_top_right != null \
		and sprite_bottom_left != null and sprite_bottom_right != null
	if not _has_sprites:
		_sprite.visible = false
		return
	_sprite.visible = true
	_sprite.texture = sprite_bottom_right
	_sprite.scale = Vector2.ONE * _sprite_base_scale(sprite_bottom_right) * sprite_scale_mult
	_sprite.z_index = sprite_z_index
	_sprite.z_as_relative = true

func _sprite_base_scale(tex: Texture2D) -> float:
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return 1.0
	return sprite_offset / max(tex_size.x, tex_size.y)

func recompute() -> void:
	if runtime == null:
		return
	const S := UpgradeEffect.Stat
	if upgrades == null:
		_pierce = 0
		return
	runtime.projectile_damage = upgrades.value(S.DAMAGE, data.projectile_damage)
	runtime.fire_rate = upgrades.value(S.FIRE_RATE, data.fire_rate)
	runtime.ink_cost = upgrades.value(S.INK_COST, data.ink_cost)
	runtime.projectiles_per_shot = maxi(1, roundi(upgrades.value(S.PROJECTILES, data.projectiles_per_shot)))
	runtime.splat_size = upgrades.value(S.SPLAT_SIZE, data.splat_size)
	runtime.splat_dirtiness = upgrades.value(S.SPLAT_DIRTINESS, data.splat_dirtiness)
	if runtime.projectiles_per_shot > data.projectiles_per_shot:
		runtime.spread_deg = maxf(data.spread_deg, 5.0 * runtime.projectiles_per_shot)
	_pierce = maxi(0, roundi(upgrades.value(S.PIERCE, 0.0)))

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	_update_facing_sprite()

func _update_facing_sprite() -> void:
	if not _has_sprites:
		return
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() <= 0.001:
		return
	var mouse_angle := to_mouse.angle()
	var is_top := to_mouse.y < 0.0
	var is_right := to_mouse.x >= 0.0

	var new_facing: FacingDir
	var center_angle: float
	if is_top and is_right:
		new_facing = FacingDir.TOP_RIGHT
		center_angle = -PI / 4.0
	elif is_top and not is_right:
		new_facing = FacingDir.TOP_LEFT
		center_angle = -3.0 * PI / 4.0
	elif not is_top and is_right:
		new_facing = FacingDir.BOTTOM_RIGHT
		center_angle = PI / 4.0
	else:
		new_facing = FacingDir.BOTTOM_LEFT
		center_angle = 3.0 * PI / 4.0

	if new_facing != _facing:
		_facing = new_facing
		var tex: Texture2D
		match _facing:
			FacingDir.TOP_LEFT:
				tex = sprite_top_left
			FacingDir.TOP_RIGHT:
				tex = sprite_top_right
			FacingDir.BOTTOM_LEFT:
				tex = sprite_bottom_left
			FacingDir.BOTTOM_RIGHT:
				tex = sprite_bottom_right
		_sprite.texture = tex
		_sprite.scale = Vector2.ONE * _sprite_base_scale(tex) * sprite_scale_mult

	_sprite.rotation = wrapf(mouse_angle - center_angle, -PI, PI) * sprite_rotation_mult

func _current_muzzle_point() -> Vector2:
	match _facing:
		FacingDir.TOP_LEFT:
			return muzzle_point_top_left
		FacingDir.TOP_RIGHT:
			return muzzle_point_top_right
		FacingDir.BOTTOM_LEFT:
			return muzzle_point_bottom_left
		FacingDir.BOTTOM_RIGHT:
			return muzzle_point_bottom_right
	return Vector2.ZERO

func _muzzle_world_position(origin: Vector2) -> Vector2:
	if _has_sprites:
		return _sprite.to_global(_current_muzzle_point())
	return origin

func try_fire(origin: Vector2, direction: Vector2, ink: InkSystem) -> bool:
	if runtime == null or _cooldown > 0.0:
		return false
	if not ink.consume(runtime.ink_cost):
		GameEvents.ink_depleted.emit()
		return false
	_cooldown = 1.0 / maxf(0.01, runtime.fire_rate)
	# base: fracao real de tinta gasta nesse tiro (ink_cost / max_ink).
	# dirtiness_scale reduz isso, entao precisa de mais de um carregador
	# pra encher a tela em 100% (0.5 = 2 carregadores, 0.33 = 3, etc).
	var base_dirtiness := runtime.ink_cost / maxf(0.01, ink.effective_max())
	runtime.splat_dirtiness = base_dirtiness * dirtiness_scale
	_spawn(origin, direction)
	GameEvents.shot_fired.emit(direction, runtime)
	return true

func _spawn(origin: Vector2, direction: Vector2) -> void:
	var entities := get_tree().get_first_node_in_group("entities")
	if entities == null:
		entities = get_tree().current_scene
	var base_ang := direction.angle()
	var n := maxi(1, runtime.projectiles_per_shot)
	var spread := deg_to_rad(runtime.spread_deg)
	var muzzle_pos := _muzzle_world_position(origin)
	for i in n:
		var off := 0.0
		if n > 1:
			off = lerpf(-spread, spread, float(i) / float(n - 1))
		else:
			off = randf_range(-spread, spread) * 0.5
		var dir := Vector2.RIGHT.rotated(base_ang + off)
		var p := ProjectileScene.instantiate()
		entities.add_child(p)
		p.global_position = muzzle_pos
		p.setup(dir, runtime.projectile_speed, runtime.projectile_damage,
			runtime.projectile_lifetime, runtime.projectile_color, _pierce)

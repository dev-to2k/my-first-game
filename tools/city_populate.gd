@tool
extends Node3D
## SAO Starting City population: semi-circular radial housing & anime foliage trees via MultiMesh.

const SEED := 20261004
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = SEED
	if Engine.is_editor_hint():
		if _has_instances():
			return
	var total := populate_city()
	print("POPULATE kit_instances=", total)

func _has_instances() -> bool:
	for c in get_children():
		if c is MultiMeshInstance3D and (c as MultiMeshInstance3D).multimesh:
			var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
			if mm.instance_count > 0:
				return true
	return false

func _count_all_instances() -> int:
	var count := 0
	for c in get_children():
		if c is MultiMeshInstance3D and (c as MultiMeshInstance3D).multimesh:
			count += (c as MultiMeshInstance3D).multimesh.instance_count
	return count

func _fill(mm_name: String, xf: Array) -> int:
	var mmi: MultiMeshInstance3D = get_node_or_null(mm_name) as MultiMeshInstance3D
	if mmi == null or mmi.multimesh == null:
		return 0
	var mm: MultiMesh = mmi.multimesh
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
		if mm.use_colors:
			mm.set_instance_color(i, Color.WHITE)
	return xf.size()

func _is_in_clearance(px: float, pz: float) -> bool:
	# Central boulevard corridor clearance (24m road + curbs)
	if abs(px) < 14.0 and pz > -100.0 and pz <= 185.0:
		return true
	# Rectangular water park clearance (60m x 30m)
	if abs(px) < 19.0 and pz >= 62.0 and pz <= 128.0:
		return true
	# Circular Teleport Plaza clearance (80m diameter = 40m radius)
	var dist_plaza := Vector2(px, pz - 15.0).length()
	if dist_plaza < 44.0:
		return true
	# Black Iron Palace fortress clearance at north end
	if abs(px) < 80.0 and pz < -80.0:
		return true
	# Outer perimeter wall clearance (R > 185m)
	if dist_plaza >= 185.0 or dist_plaza < 46.0:
		return true
	return false

func _dist_to_radial_avenues(px: float, pz: float) -> float:
	var dx := px
	var dz := pz - 15.0
	var ang := atan2(dx, dz)
	if abs(ang) > 1.45:
		return 999.0
	var min_d := 999.0
	var num_avenues := 12
	for j in num_avenues:
		var ray_ang: float = -1.30 + float(j) * (2.60 / float(num_avenues - 1))
		var diff := abs(wrapf(ang - ray_ang, -PI, PI))
		var d := diff * Vector2(dx, dz).length()
		if d < min_d:
			min_d = d
	return min_d

func populate_city() -> int:
	_rng.seed = SEED
	var bags := {
		"house_s": [],
		"house_m": [],
		"house_l": [],
		"corner": [],
		"tower_small": [],
		"tree_oak": [],
		"tree_small": [],
		"HouseTerracotta": [],
		"HouseSlate": [],
		"UrbanTrees": []
	}
	var total := 0

	# 1. Main Boulevard & Water Park Trees
	var z_cur: float = -75.0
	while z_cur <= 175.0:
		var in_park: bool = (z_cur >= 62.0 and z_cur <= 128.0)
		var x_dist: float = 18.5 if in_park else 13.5
		for side in [-1.0, 1.0]:
			var px: float = side * x_dist + _rng.randf_range(-0.3, 0.3)
			var pz: float = z_cur + _rng.randf_range(-0.5, 0.5)
			var rot := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
			var scl: float = _rng.randf_range(0.9, 1.2)
			var xf := Transform3D(rot * Basis.from_scale(Vector3(scl, scl, scl)), Vector3(px, 0.0, pz))
			var key: String = "tree_oak" if _rng.randf() < 0.6 else "tree_small"
			(bags[key] as Array).append(xf)
			(bags["UrbanTrees"] as Array).append(xf)
			total += 1
		z_cur += 10.5

	# 2. Teleport Plaza Outer Colonnade Trees
	var plaza_trees := 28
	for i in plaza_trees:
		var a: float = TAU * float(i) / float(plaza_trees)
		var r_pos: float = 40.0 + _rng.randf_range(2.5, 4.5)
		var px: float = cos(a) * r_pos
		var pz: float = 15.0 + sin(a) * r_pos
		if not _is_in_clearance(px, pz) and abs(px) > 13.0:
			var rot := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
			var scl: float = _rng.randf_range(0.95, 1.25)
			var xf := Transform3D(rot * Basis.from_scale(Vector3(scl, scl, scl)), Vector3(px, 0.0, pz))
			var key: String = "tree_oak" if _rng.randf() < 0.7 else "tree_small"
			(bags[key] as Array).append(xf)
			(bags["UrbanTrees"] as Array).append(xf)
			total += 1

	# 3. 8 Concentric Rings x 12 Radial Avenues Residential Housing
	var r_min: float = 52.0
	var r_max: float = 178.0
	var num_rings: int = 8
	var ring_spacing: float = (r_max - r_min) / float(num_rings - 1)

	for ring_idx in num_rings:
		var r_road: float = r_min + float(ring_idx) * ring_spacing
		var row_offsets: Array[float] = [-5.2, 5.2]
		for ro in row_offsets:
			var r_row: float = r_road + ro
			if r_row < 46.0 or r_row > 185.0:
				continue

			var arc_len: float = r_row * 2.80
			var house_w: float = 7.6
			var num_houses: int = int(arc_len / house_w)

			for h_idx in num_houses:
				var t: float = (float(h_idx) + 0.5) / float(num_houses)
				var ang: float = -1.40 + t * 2.80

				var px: float = sin(ang) * (r_row + _rng.randf_range(-0.35, 0.35))
				var pz: float = 15.0 + cos(ang) * (r_row + _rng.randf_range(-0.35, 0.35))

				if _is_in_clearance(px, pz):
					continue
				if _dist_to_radial_avenues(px, pz) < 4.2:
					continue

				var yaw: float = -ang + (0.0 if ro > 0.0 else PI)
				yaw += _rng.randf_range(-0.06, 0.06)

				var scl_x: float = _rng.randf_range(0.92, 1.08)
				var scl_y: float = _rng.randf_range(0.95, 1.35)
				var scl_z: float = _rng.randf_range(0.92, 1.08)
				var rot := Basis(Vector3.UP, yaw)
				var scale_basis := Basis.from_scale(Vector3(scl_x, scl_y, scl_z))
				var xf := Transform3D(rot * scale_basis, Vector3(px, 0.0, pz))

				var roll: float = _rng.randf()
				var is_terracotta: bool = roll < 0.65
				var group_key: String = "HouseTerracotta" if is_terracotta else "HouseSlate"
				(bags[group_key] as Array).append(xf)

				# Map to modular kit keys for fallback
				var pick: float = _rng.randf()
				var kit_key: String = "house_s"
				if pick < 0.40:
					kit_key = "house_s"
				elif pick < 0.70:
					kit_key = "house_m"
				elif pick < 0.85:
					kit_key = "house_l"
				elif pick < 0.95:
					kit_key = "corner"
				else:
					kit_key = "tower_small"
				(bags[kit_key] as Array).append(xf)
				total += 1

				# Courtyard trees in interior gardens
				if _rng.randf() < 0.14:
					var tr_r: float = r_row + (-ro * 0.6) + _rng.randf_range(-1.0, 1.0)
					var tr_ang: float = ang + _rng.randf_range(-0.02, 0.02)
					var tx: float = sin(tr_ang) * tr_r
					var tz: float = 15.0 + cos(tr_ang) * tr_r
					if not _is_in_clearance(tx, tz):
						var t_rot := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
						var t_scl: float = _rng.randf_range(0.85, 1.15)
						var t_xf := Transform3D(t_rot * Basis.from_scale(Vector3(t_scl, t_scl, t_scl)), Vector3(tx, 0.0, tz))
						var t_key: String = "tree_oak" if _rng.randf() < 0.55 else "tree_small"
						(bags[t_key] as Array).append(t_xf)
						(bags["UrbanTrees"] as Array).append(t_xf)
						total += 1

	for k in bags:
		_fill(k, bags[k])

	print("POPULATE: Total instances baked: ", total)
	return total

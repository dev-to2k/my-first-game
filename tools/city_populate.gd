@tool
extends Node3D
## Kit city population: modular buildings & anime foliage trees via MultiMesh.

const SEED := 20261004
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = SEED
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
		push_warning("city_populate: missing " + mm_name)
		return 0
	var mm: MultiMesh = mmi.multimesh
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
		if mm.use_colors:
			mm.set_instance_color(i, Color.WHITE)
	return xf.size()

func _road_dist(x: float, z: float) -> float:
	var px := x
	var pz := z - 28.0
	var d := 1e9
	var dirs := [Vector2(1, 0), Vector2(0.7071, 0.7071), Vector2(0.7071, -0.7071)]
	for dv in dirs:
		var along: float = px * dv.x + pz * dv.y
		if along > -40.0:
			d = min(d, abs(px * dv.y - pz * dv.x))
	return d

func _keep(x: float, z: float) -> bool:
	# Main avenue & gate corridor clearance: 22m wide corridor all the way to city gate
	if abs(x) < 11.0 and z > -22.0 and z <= 185.0:
		return false
	# City wall perimeter: wall is at z=180 (thickness 4m). Keep houses inside fortress (z < 173)
	if z >= 173.0:
		return false
	if _road_dist(x, z) < 4.5:
		return false  # 8 m roads + safety margin
	if abs(x) < 45.0 and z > 62.0 and z < 128.0:
		return false  # lake + shore margin
	if Vector2(x, z - 28.0).length() < 38.0:
		return false  # central plaza disc
	if abs(x) < 22.0 and z > -18.0 and z < 14.0:
		return false  # church
	return true

func populate_city() -> int:
	_rng.seed = SEED
	var bags := {
		"house_s": [],
		"house_m": [],
		"house_l": [],
		"corner": [],
		"tower_small": [],
		"tree_oak": [],
		"tree_small": []
	}
	var total := 0

	# 1. Avenue Anime Trees (Lining AvenueGrassL and AvenueGrassR)
	for x_side: float in [-11.5, 11.5]:
		# Segment 1: from south near church to north before lake
		var z_cur: float = -15.0
		while z_cur <= 58.0:
			var px: float = x_side + _rng.randf_range(-0.4, 0.4)
			var pz: float = z_cur + _rng.randf_range(-0.6, 0.6)
			var rot := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
			var scl: float = _rng.randf_range(0.9, 1.15)
			var xf := Transform3D(rot * Basis.from_scale(Vector3(scl, scl, scl)), Vector3(px, 0.0, pz))
			var key: String = "tree_oak" if _rng.randf() < 0.6 else "tree_small"
			(bags[key] as Array).append(xf)
			total += 1
			z_cur += 11.0

		# Segment 2: north of lake towards city wall
		z_cur = 132.0
		while z_cur <= 168.0:
			var px: float = x_side + _rng.randf_range(-0.4, 0.4)
			var pz: float = z_cur + _rng.randf_range(-0.6, 0.6)
			var rot := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
			var scl: float = _rng.randf_range(0.9, 1.15)
			var xf := Transform3D(rot * Basis.from_scale(Vector3(scl, scl, scl)), Vector3(px, 0.0, pz))
			var key: String = "tree_oak" if _rng.randf() < 0.6 else "tree_small"
			(bags[key] as Array).append(xf)
			total += 1
			z_cur += 11.0

	# 2. Plaza Outer Perimeter Trees (Shading the colonnade walk)
	var plaza_trees: int = 24
	for i in plaza_trees:
		var a: float = TAU * float(i) / float(plaza_trees)
		var r_dist: float = _rng.randf_range(36.0, 40.0)
		var px: float = cos(a) * r_dist
		var pz: float = 28.0 + sin(a) * r_dist
		# Ensure not on road or avenue
		if _road_dist(px, pz) > 4.5 and abs(px) > 10.0:
			var rot := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
			var scl: float = _rng.randf_range(0.95, 1.2)
			var xf := Transform3D(rot * Basis.from_scale(Vector3(scl, scl, scl)), Vector3(px, 0.0, pz))
			var key: String = "tree_oak" if _rng.randf() < 0.7 else "tree_small"
			(bags[key] as Array).append(xf)
			total += 1

	# 3. Lake Park Shoreline Trees
	for x_side: float in [-32.0, 32.0]:
		var z_cur: float = 72.0
		while z_cur <= 118.0:
			var px: float = x_side + _rng.randf_range(-1.5, 1.5)
			var pz: float = z_cur + _rng.randf_range(-1.5, 1.5)
			var rot := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
			var scl: float = _rng.randf_range(0.9, 1.25)
			var xf := Transform3D(rot * Basis.from_scale(Vector3(scl, scl, scl)), Vector3(px, 0.0, pz))
			var key: String = "tree_oak" if _rng.randf() < 0.75 else "tree_small"
			(bags[key] as Array).append(xf)
			total += 1
			z_cur += 9.0

	# 4. Urban Grid: Houses and Residential Green Courtyards
	var g: float = 4.0
	var gx: float = -256.0
	while gx <= 256.0:
		var gz: float = -256.0
		while gz <= 256.0:
			var px: float = gx + _rng.randf_range(-1.0, 1.0)
			var pz: float = gz + _rng.randf_range(-1.0, 1.0)
			var r0: float = Vector2(px, pz - 20.0).length()
			if r0 >= 40.0 and r0 <= 250.0 and _keep(px, pz):
				var dense: bool = r0 < 90.0
				var pass_p: float = 0.35 if dense else 0.12
				var roll: float = _rng.randf()
				if roll < pass_p:
					# House instance
					var ang: float = atan2(px, pz - 28.0)
					var yaw: float = round(ang / (PI / 4.0)) * (PI / 4.0) + _rng.randf_range(-0.05, 0.05)
					var rot := Basis(Vector3.UP, yaw)
					var scl: float = 1.0 if dense else 0.8
					var pick: float = _rng.randf()
					var key: String = "house_s"
					if pick < 0.40:
						key = "house_s"
					elif pick < 0.70:
						key = "house_m"
					elif pick < 0.85:
						key = "house_l"
					elif pick < 0.95:
						key = "corner"
					else:
						key = "tower_small"
					var xf := Transform3D(rot * Basis.from_scale(Vector3(scl, scl, scl)), Vector3(px, 0.0, pz))
					(bags[key] as Array).append(xf)
					total += 1
				elif roll < pass_p + 0.06:
					# Green courtyard / garden tree
					var rot := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
					var scl: float = _rng.randf_range(0.85, 1.1)
					var key: String = "tree_oak" if _rng.randf() < 0.5 else "tree_small"
					var xf := Transform3D(rot * Basis.from_scale(Vector3(scl, scl, scl)), Vector3(px, 0.0, pz))
					(bags[key] as Array).append(xf)
					total += 1
			gz += g
		gx += g

	for k in bags:
		_fill(k, bags[k])
	return total


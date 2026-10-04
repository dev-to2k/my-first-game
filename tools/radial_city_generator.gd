@tool
extends Node3D
class_name RadialCityGenerator
## SAO Starting City (Aincrad Floor 1) - Procedural Semi-Circular Radial Layout Generator
## Implements:
## 1. Central Boulevard (24m wide) connecting Main Gate to Black Iron Palace
## 2. Rectangular Water Park (60m x 30m) with turquoise water & promenade trees
## 3. Circular Teleport Plaza (80m diameter) with colonnade & teleport crystal
## 4. 8 Concentric Circular Road Rings & 12 Radial Avenues
## 5. High-density residential housing plots via MultiMeshInstance3D (terracotta & slate roofs)
## 6. Lush anime trees lining sidewalks and courtyard gardens

const SEED := 20261004

@export_category("City Geometry")
@export var boulevard_width: float = 24.0
@export var water_park_length: float = 60.0
@export var water_park_width: float = 30.0
@export var water_park_center_z: float = 95.0
@export var plaza_diameter: float = 80.0
@export var plaza_center_z: float = 15.0
@export var gate_z: float = 180.0
@export var palace_z: float = -115.0
@export var city_wall_radius: float = 195.0
@export var concentric_rings: int = 8
@export var radial_avenues: int = 12

@export_category("Housing MultiMesh")
@export var house_density: float = 1.0
@export var terracotta_ratio: float = 0.65 # 65% terracotta orange, 35% slate stone gray

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = SEED
	if Engine.is_editor_hint():
		if _has_active_multimeshes():
			return
	populate_radial_city()

func _has_active_multimeshes() -> bool:
	for c in get_children():
		if c is MultiMeshInstance3D and (c as MultiMeshInstance3D).multimesh:
			var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
			if mm.instance_count > 0:
				return true
	return false

## Checks clearance against boulevard, water park, plaza, palace, and city wall
func is_in_clearance(px: float, pz: float) -> bool:
	# Central boulevard corridor clearance (24m road + curbs)
	if abs(px) < (boulevard_width * 0.5 + 1.5) and pz > (palace_z + 20.0) and pz <= (gate_z + 5.0):
		return true
	
	# Rectangular water park clearance (60m x 30m)
	if abs(px) < (water_park_width * 0.5 + 4.0) and abs(pz - water_park_center_z) < (water_park_length * 0.5 + 4.0):
		return true
		
	# Circular Teleport Plaza clearance (80m diameter = 40m radius)
	var dist_plaza := Vector2(px, pz - plaza_center_z).length()
	if dist_plaza < (plaza_diameter * 0.5 + 4.0):
		return true
		
	# Black Iron Palace fortress terrace clearance
	if abs(px) < 85.0 and pz < (palace_z + 35.0):
		return true
		
	# Outside city wall or moat
	var dist_center := Vector2(px, pz - plaza_center_z).length()
	if dist_center >= (city_wall_radius - 6.0) or dist_center < 42.0:
		return true
		
	return false

## Distance to nearest radial avenue
func distance_to_radial_avenue(px: float, pz: float) -> float:
	var dx := px
	var dz := pz - plaza_center_z
	var ang := atan2(dx, dz) # Angle relative to South axis (+Z)
	
	# Check if within semi-circular fan (-1.40 rad to +1.40 rad)
	if abs(ang) > 1.45:
		return 999.0
		
	var min_dist := 999.0
	for j in radial_avenues:
		var ray_ang: float = -1.30 + float(j) * (2.60 / float(radial_avenues - 1))
		var diff := abs(wrapf(ang - ray_ang, -PI, PI))
		var d := diff * Vector2(dx, dz).length()
		if d < min_dist:
			min_dist = d
	return min_dist

## Main procedural generator for semi-circular radial housing & trees
func populate_radial_city() -> int:
	_rng.seed = SEED
	
	var terracotta_xforms: Array[Transform3D] = []
	var slate_xforms: Array[Transform3D] = []
	var tree_xforms: Array[Transform3D] = []
	
	# 1. Generate trees along Main Boulevard sidewalks
	var z_cur: float = palace_z + 40.0
	while z_cur <= gate_z - 5.0:
		# Skip water park interior, but plant trees along park sidewalks
		var in_park: bool = abs(z_cur - water_park_center_z) < (water_park_length * 0.5 + 2.0)
		var x_dist: float = (water_park_width * 0.5 + 2.5) if in_park else (boulevard_width * 0.5 + 1.2)
		for side in [-1.0, 1.0]:
			var tx: float = side * x_dist + _rng.randf_range(-0.3, 0.3)
			var tz: float = z_cur + _rng.randf_range(-0.5, 0.5)
			var rot := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
			var scl: float = _rng.randf_range(0.9, 1.25)
			var xf := Transform3D(rot * Basis.from_scale(Vector3(scl, scl, scl)), Vector3(tx, 0.0, tz))
			tree_xforms.append(xf)
		z_cur += 10.5

	# 2. Generate trees along outer colonnade walkway of Teleport Plaza
	var plaza_colonnade_trees := 28
	for i in plaza_colonnade_trees:
		var a: float = TAU * float(i) / float(plaza_colonnade_trees)
		var r_pos: float = plaza_diameter * 0.5 + _rng.randf_range(2.0, 4.5)
		var tx: float = cos(a) * r_pos
		var tz: float = plaza_center_z + sin(a) * r_pos
		if not is_in_clearance(tx, tz) and abs(tx) > 13.0:
			var rot := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
			var scl: float = _rng.randf_range(0.95, 1.3)
			var xf := Transform3D(rot * Basis.from_scale(Vector3(scl, scl, scl)), Vector3(tx, 0.0, tz))
			tree_xforms.append(xf)

	# 3. Generate 8 Concentric Road Rings and Residential Plots
	# Ring radii from inner ring (~52m) to outer ring (~178m)
	var r_min: float = 52.0
	var r_max: float = 178.0
	var ring_spacing: float = (r_max - r_min) / float(concentric_rings - 1)
	
	for ring_idx in concentric_rings:
		var r_road: float = r_min + float(ring_idx) * ring_spacing
		
		# In each plot band between rings, place houses facing the roads:
		# - Inner row offset inward towards inner street
		# - Outer row offset outward towards outer street
		var row_offsets: Array[float] = [-5.2, 5.2]
		for ro in row_offsets:
			var r_row: float = r_road + ro
			if r_row < 46.0 or r_row > 185.0:
				continue
				
			# Calculate circumference arc length in semi-circle fan (approx 160 deg = 2.8 rad)
			var arc_span: float = 2.80
			var arc_len: float = r_row * arc_span
			var house_width: float = 7.6 # ~6x8m house foot-print + narrow medieval gap
			var num_houses: int = int(arc_len / house_width)
			
			for h_idx in num_houses:
				var t: float = (float(h_idx) + 0.5) / float(num_houses)
				var ang: float = -1.40 + t * 2.80 # Radiating around South axis
				
				# Jiggle position slightly for natural organic medieval feel
				var px: float = sin(ang) * (r_row + _rng.randf_range(-0.4, 0.4))
				var pz: float = plaza_center_z + cos(ang) * (r_row + _rng.randf_range(-0.4, 0.4))
				
				# Clearance checks
				if is_in_clearance(px, pz):
					continue
				if distance_to_radial_avenue(px, pz) < 4.2:
					continue
					
				# House orientation: facing tangent to the circular road
				# Facing angle points along circle tangent
				var road_tangent_yaw: float = -ang + (0.0 if ro > 0.0 else PI)
				road_tangent_yaw += _rng.randf_range(-0.06, 0.06)
				
				# Varied height (2 to 3 stories high)
				var scl_x: float = _rng.randf_range(0.92, 1.08)
				var scl_y: float = _rng.randf_range(0.95, 1.35) # 2-3 stories!
				var scl_z: float = _rng.randf_range(0.92, 1.08)
				var rot := Basis(Vector3.UP, road_tangent_yaw)
				var scale_basis := Basis.from_scale(Vector3(scl_x, scl_y, scl_z))
				var xf := Transform3D(rot * scale_basis, Vector3(px, 0.0, pz))
				
				# Palette distribution: ~65% terracotta orange, ~35% slate gray
				if _rng.randf() < terracotta_ratio:
					terracotta_xforms.append(xf)
				else:
					slate_xforms.append(xf)
					
				# Occasional courtyard tree in back gardens
				if _rng.randf() < 0.14:
					var tree_r: float = r_row + (-ro * 0.6) + _rng.randf_range(-1.0, 1.0)
					var tree_ang: float = ang + _rng.randf_range(-0.02, 0.02)
					var tree_x: float = sin(tree_ang) * tree_r
					var tree_z: float = plaza_center_z + cos(tree_ang) * tree_r
					if not is_in_clearance(tree_x, tree_z):
						var t_rot := Basis(Vector3.UP, _rng.randf_range(0.0, TAU))
						var t_scl: float = _rng.randf_range(0.85, 1.15)
						var t_xf := Transform3D(t_rot * Basis.from_scale(Vector3(t_scl, t_scl, t_scl)), Vector3(tree_x, 0.0, tree_z))
						tree_xforms.append(t_xf)

	# 4. Apply transforms to MultiMeshInstance3D nodes
	var total_inst := 0
	total_inst += _fill_mmi("HouseTerracotta", terracotta_xforms, Color(0.95, 0.50, 0.30))
	total_inst += _fill_mmi("HouseSlate", slate_xforms, Color(0.40, 0.55, 0.85))
	total_inst += _fill_mmi("UrbanTrees", tree_xforms, Color.WHITE)
	
	print("RADIAL_CITY_GENERATOR: populated %d instances (%d terracotta, %d slate, %d trees)" % [
		total_inst, terracotta_xforms.size(), slate_xforms.size(), tree_xforms.size()
	])
	return total_inst

func _fill_mmi(node_name: String, xforms: Array[Transform3D], default_color: Color) -> int:
	var mmi: MultiMeshInstance3D = get_node_or_null(node_name) as MultiMeshInstance3D
	if mmi == null or mmi.multimesh == null:
		return 0
	var mm: MultiMesh = mmi.multimesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, default_color)
	return xforms.size()

func clear_city() -> void:
	for k in ["HouseTerracotta", "HouseSlate", "UrbanTrees"]:
		var mmi: MultiMeshInstance3D = get_node_or_null(k) as MultiMeshInstance3D
		if mmi and mmi.multimesh:
			mmi.multimesh.instance_count = 0
	print("RADIAL_CITY_GENERATOR: cleared all instances")

func generate_city() -> void:
	populate_radial_city()

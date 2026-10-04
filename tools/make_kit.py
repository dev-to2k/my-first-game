import struct, json, math, os

OUT = r"C:\Users\Admin\Documents\my-first-game\assets\kit"
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------
# SAO Anime Color Palette
# ---------------------------------------------------------
BASE_STONE   = (0.54, 0.51, 0.46, 1.0)   # Rubble stone base #8A8175
BASE_TRIM    = (0.42, 0.39, 0.35, 1.0)   # Foundation edge trim
WALL_PLASTER = (0.93, 0.91, 0.87, 1.0)   # Off-white lime plaster #ECE8DF
TIMBER       = (0.24, 0.15, 0.10, 1.0)   # Dark walnut timber framing #3D261A
TIMBER_LIGHT = (0.32, 0.22, 0.15, 1.0)   # Sills and bargeboards
ROOF_ORANGE  = (0.76, 0.39, 0.20, 1.0)   # Terracotta orange tiles #C26433
ROOF_RIDGE   = (0.62, 0.30, 0.14, 1.0)   # Ridge / under-eaves
ROOF_SLATE   = (0.35, 0.42, 0.50, 1.0)   # Slate gray-blue #596B80
DOOR_WOOD    = (0.19, 0.12, 0.08, 1.0)   # Recessed wooden door
WINDOW_GLASS = (0.16, 0.20, 0.25, 1.0)   # Tinted dark window pane
WINDOW_FRAME = (0.26, 0.18, 0.12, 1.0)   # Timber window frame
CHIMNEY      = (0.48, 0.45, 0.41, 1.0)   # Stone chimney masonry
CHIMNEY_CAP  = (0.34, 0.31, 0.28, 1.0)   # Chimney flue cap

# Anime Foliage
TRUNK_BARK   = (0.34, 0.23, 0.15, 1.0)   # Warm stylized bark #573B26
TRUNK_DARK   = (0.24, 0.16, 0.10, 1.0)   # Root flares / crevices
LEAF_TOP     = (0.43, 0.79, 0.30, 1.0)   # Sunlit canopy highlights #6EC94D
LEAF_MID     = (0.28, 0.65, 0.24, 1.0)   # Vibrant anime green #47A63D
LEAF_BOT     = (0.17, 0.45, 0.17, 1.0)   # Under-canopy shadow green #2C732C


def face_normal(a, b, c):
    ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
    vx, vy, vz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
    nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
    l = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
    return (nx / l, ny / l, nz / l)


def lerp_color(c1, c2, t):
    t = max(0.0, min(1.0, t))
    return (
        c1[0] + (c2[0] - c1[0]) * t,
        c1[1] + (c2[1] - c1[1]) * t,
        c1[2] + (c2[2] - c1[2]) * t,
        1.0
    )


class Buf:
    def __init__(self):
        self.pos = []   # list of (x,y,z)
        self.nor = []   # list of (nx,ny,nz)
        self.col = []   # list of (r,g,b,a)

    def tri(self, a, b, c, color, n=None):
        if n is None:
            n = face_normal(a, b, c)
        for v in (a, b, c):
            self.pos.append(v)
            self.nor.append(n)
            self.col.append(color)

    def tri_vn(self, v1, n1, c1, v2, n2, c2, v3, n3, c3):
        self.pos.extend([v1, v2, v3])
        self.nor.extend([n1, n2, n3])
        self.col.extend([c1, c2, c3])

    def quad(self, a, b, c, d, color, n=None):
        if n is None:
            n = face_normal(a, b, c)
        self.tri(a, b, c, color, n)
        self.tri(a, c, d, color, n)

    def box_minmax(self, x0, y0, z0, x1, y1, z1, color):
        # 6 faces with proper outward normals
        # +Z
        self.quad((x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1), color, (0, 0, 1))
        # -Z
        self.quad((x1, y0, z0), (x0, y0, z0), (x0, y1, z0), (x1, y1, z0), color, (0, 0, -1))
        # +Y
        self.quad((x0, y1, z1), (x1, y1, z1), (x1, y1, z0), (x0, y1, z0), color, (0, 1, 0))
        # -Y
        self.quad((x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1), color, (0, -1, 0))
        # -X
        self.quad((x0, y0, z0), (x0, y0, z1), (x0, y1, z1), (x0, y1, z0), color, (-1, 0, 0))
        # +X
        self.quad((x1, y0, z1), (x1, y0, z0), (x1, y1, z0), (x1, y1, z1), color, (1, 0, 0))

    def box_center(self, cx, cz, y0, w, h, d, color):
        hw, hd = w * 0.5, d * 0.5
        self.box_minmax(cx - hw, y0, cz - hd, cx + hw, y0 + h, cz + hd, color)

    def cylinder(self, cx, cz, y0, h, r_bot, r_top, segs, color):
        top_pts = []
        bot_pts = []
        for i in range(segs):
            a = math.tau * i / segs
            ca, sa = math.cos(a), math.sin(a)
            bot_pts.append((cx + ca * r_bot, y0, cz + sa * r_bot))
            top_pts.append((cx + ca * r_top, y0 + h, cz + sa * r_top))
        for i in range(segs):
            i_next = (i + 1) % segs
            b0, b1 = bot_pts[i], bot_pts[i_next]
            t0, t1 = top_pts[i], top_pts[i_next]
            self.quad(b0, t0, t1, b1, color)

    def cone(self, cx, cz, y0, h, r_bot, segs, color):
        apex = (cx, y0 + h, cz)
        pts = []
        for i in range(segs):
            a = math.tau * i / segs
            pts.append((cx + math.cos(a) * r_bot, y0, cz + math.sin(a) * r_bot))
        for i in range(segs):
            i_next = (i + 1) % segs
            self.tri(pts[i], apex, pts[i_next], color)

    def gable_roof(self, w_walls, d_walls, y_eaves, roof_h, overhang, color, ridge_color=ROOF_RIDGE):
        x_eave = (w_walls * 0.5) + overhang
        z_eave = (d_walls * 0.5) + overhang
        y_ridge = y_eaves + roof_h
        r_back  = (0.0, y_ridge, -z_eave)
        r_front = (0.0, y_ridge, z_eave)
        l_back  = (-x_eave, y_eaves, -z_eave)
        l_front = (-x_eave, y_eaves, z_eave)
        rr_back = (x_eave, y_eaves, -z_eave)
        rr_front= (x_eave, y_eaves, z_eave)

        # Left slope
        self.quad(l_back, l_front, r_front, r_back, color)
        # Right slope
        self.quad(rr_front, rr_back, r_back, r_front, color)

        # Front gable triangle (with wall offset)
        xw, zw = w_walls * 0.5, d_walls * 0.5
        self.tri((-xw, y_eaves, zw), (xw, y_eaves, zw), (0.0, y_ridge - 0.1, zw), WALL_PLASTER, (0, 0, 1))
        # Front timber verge boards / gable trim
        self.quad((-x_eave, y_eaves - 0.1, z_eave), (0.0, y_ridge, z_eave), (0.0, y_ridge + 0.1, z_eave), (-x_eave, y_eaves, z_eave), TIMBER, (0, 0, 1))
        self.quad((0.0, y_ridge, z_eave), (x_eave, y_eaves - 0.1, z_eave), (x_eave, y_eaves, z_eave), (0.0, y_ridge + 0.1, z_eave), TIMBER, (0, 0, 1))

        # Back gable triangle
        self.tri((xw, y_eaves, -zw), (-xw, y_eaves, -zw), (0.0, y_ridge - 0.1, -zw), WALL_PLASTER, (0, 0, -1))
        # Back timber verge boards
        self.quad((x_eave, y_eaves - 0.1, -z_eave), (0.0, y_ridge, -z_eave), (0.0, y_ridge + 0.1, -z_eave), (x_eave, y_eaves, -z_eave), TIMBER, (0, 0, -1))
        self.quad((0.0, y_ridge, -z_eave), (-x_eave, y_eaves - 0.1, -z_eave), (-x_eave, y_eaves, -z_eave), (0.0, y_ridge + 0.1, -z_eave), TIMBER, (0, 0, -1))

        # Ridge cap beam
        self.box_center(0.0, 0.0, y_ridge - 0.05, 0.3, 0.18, (z_eave * 2.0) + 0.1, ridge_color)

    def timber_posts(self, w, d, y0, h, post_w=0.22):
        hw, hd = w * 0.5, d * 0.5
        # 4 corners
        for cx in [-hw + post_w * 0.5, hw - post_w * 0.5]:
            for cz in [-hd + post_w * 0.5, hd - post_w * 0.5]:
                self.box_center(cx, cz, y0, post_w, h, post_w, TIMBER)
        # horizontal floor plate & sill plate
        self.box_center(0.0, -hd, y0, w, 0.15, post_w * 0.8, TIMBER)
        self.box_center(0.0, hd, y0, w, 0.15, post_w * 0.8, TIMBER)
        self.box_center(0.0, -hd, y0 + h - 0.15, w, 0.15, post_w * 0.8, TIMBER)
        self.box_center(0.0, hd, y0 + h - 0.15, w, 0.15, post_w * 0.8, TIMBER)

    def door_and_windows(self, w, d, y_door, door_w=1.0, door_h=1.9):
        hd = d * 0.5
        # Inset front door
        self.box_center(0.0, hd + 0.02, y_door, door_w + 0.2, door_h + 0.15, 0.12, TIMBER)
        self.box_center(0.0, hd + 0.04, y_door, door_w, door_h, 0.1, DOOR_WOOD)
        # Front windows (flanking door if wide enough)
        if w >= 5.0:
            for wx in [-w * 0.28, w * 0.28]:
                self.box_center(wx, hd + 0.02, y_door + 0.6, 0.9, 1.1, 0.12, WINDOW_FRAME)
                self.box_center(wx, hd + 0.04, y_door + 0.65, 0.7, 0.9, 0.08, WINDOW_GLASS)
        else:
            # Side window
            self.box_center(w * 0.5 + 0.02, 0.0, y_door + 0.6, 0.12, 1.0, 0.8, WINDOW_FRAME)
            self.box_center(w * 0.5 + 0.04, 0.0, y_door + 0.65, 0.08, 0.8, 0.6, WINDOW_GLASS)

    def chimney(self, cx, cz, y0, h, w=0.65, d=0.65):
        self.box_center(cx, cz, y0, w, h, d, CHIMNEY)
        self.box_center(cx, cz, y0 + h, w + 0.15, 0.15, d + 0.15, CHIMNEY_CAP)
        self.box_center(cx, cz, y0 + h + 0.15, w * 0.5, 0.25, d * 0.5, CHIMNEY_CAP)

    def cloud_puff(self, cx, cy, cz, rx, ry, rz, segs_u=8, segs_v=6):
        """Spherical normal transferred cloud puff for anime cel-shading"""
        grid_v = []
        grid_n = []
        grid_c = []
        for iv in range(segs_v + 1):
            theta = math.pi * iv / segs_v
            v_row = []
            n_row = []
            c_row = []
            t_col = (math.cos(theta) + 1.0) * 0.5
            col = lerp_color(LEAF_BOT, LEAF_MID, t_col * 1.5) if t_col < 0.6 else lerp_color(LEAF_MID, LEAF_TOP, (t_col - 0.6) / 0.4)
            for iu in range(segs_u):
                phi = math.tau * iu / segs_u
                # Ellipsoid vertex
                dx = rx * math.sin(theta) * math.cos(phi)
                dy = ry * math.cos(theta)
                dz = rz * math.sin(theta) * math.sin(phi)
                vx, vy, vz = cx + dx, cy + dy, cz + dz
                # Spherical outward normal from cluster center
                nl = math.sqrt(dx * dx + dy * dy + dz * dz) or 1.0
                nx, ny, nz = dx / nl, dy / nl, dz / nl
                v_row.append((vx, vy, vz))
                n_row.append((nx, ny, nz))
                c_row.append(col)
            grid_v.append(v_row)
            grid_n.append(n_row)
            grid_c.append(c_row)

        for iv in range(segs_v):
            for iu in range(segs_u):
                next_u = (iu + 1) % segs_u
                v00, n00, c00 = grid_v[iv][iu], grid_n[iv][iu], grid_c[iv][iu]
                v01, n01, c01 = grid_v[iv][next_u], grid_n[iv][next_u], grid_c[iv][next_u]
                v10, n10, c10 = grid_v[iv + 1][iu], grid_n[iv + 1][iu], grid_c[iv + 1][iu]
                v11, n11, c11 = grid_v[iv + 1][next_u], grid_n[iv + 1][next_u], grid_c[iv + 1][next_u]

                if iv == 0:
                    self.tri_vn(v00, n00, c00, v11, n11, c11, v10, n10, c10)
                elif iv == segs_v - 1:
                    self.tri_vn(v00, n00, c00, v01, n01, c01, v10, n10, c10)
                else:
                    self.tri_vn(v00, n00, c00, v11, n11, c11, v10, n10, c10)
                    self.tri_vn(v00, n00, c00, v01, n01, c01, v11, n11, c11)


# ---------------------------------------------------------
# Building Generators
# ---------------------------------------------------------
def make_house_s():
    b = Buf()
    w, d = 4.0, 4.0
    # Foundation
    b.box_center(0.0, 0.0, 0.0, w + 0.3, 0.7, d + 0.3, BASE_STONE)
    b.box_center(0.0, 0.0, 0.65, w + 0.4, 0.1, d + 0.4, BASE_TRIM)
    # Walls
    b.box_center(0.0, 0.0, 0.7, w, 2.6, d, WALL_PLASTER)
    b.timber_posts(w, d, 0.7, 2.6)
    b.door_and_windows(w, d, 0.7, door_w=0.9, door_h=1.8)
    # Jettying bracket beam at roofline
    b.box_center(0.0, 0.0, 3.25, w + 0.3, 0.15, d + 0.3, TIMBER)
    # Gable roof & chimney
    b.gable_roof(w, d, 3.3, 2.0, overhang=0.4, color=ROOF_ORANGE)
    b.chimney(1.5, 0.0, 2.0, 3.7)
    return b


def make_house_m():
    b = Buf()
    w, d = 6.0, 6.0
    # Foundation
    b.box_center(0.0, 0.0, 0.0, w + 0.4, 0.8, d + 0.4, BASE_STONE)
    b.box_center(0.0, 0.0, 0.75, w + 0.5, 0.1, d + 0.5, BASE_TRIM)
    # First floor
    b.box_center(0.0, 0.0, 0.8, w, 2.7, d, WALL_PLASTER)
    b.timber_posts(w, d, 0.8, 2.7)
    b.door_and_windows(w, d, 0.8, door_w=1.1, door_h=2.0)
    # Jettying cantilevered second floor (+0.3m overhang)
    w2, d2 = w + 0.4, d + 0.4
    b.box_center(0.0, 0.0, 3.5, w2 + 0.1, 0.2, d2 + 0.1, TIMBER)
    b.box_center(0.0, 0.0, 3.7, w2, 2.6, d2, WALL_PLASTER)
    b.timber_posts(w2, d2, 3.7, 2.6)
    # 2nd floor windows on front and sides
    hd2 = d2 * 0.5
    for wx in [-1.8, 0.0, 1.8]:
        b.box_center(wx, hd2 + 0.02, 4.4, 0.8, 1.0, 0.12, WINDOW_FRAME)
        b.box_center(wx, hd2 + 0.04, 4.45, 0.65, 0.8, 0.08, WINDOW_GLASS)
    # Roof & chimney
    b.gable_roof(w2, d2, 6.3, 2.5, overhang=0.45, color=ROOF_ORANGE)
    b.chimney(2.3, -0.8, 4.0, 5.2)
    return b


def make_house_l():
    b = Buf()
    w, d = 8.0, 8.0
    # Heavy stone base
    b.box_center(0.0, 0.0, 0.0, w + 0.5, 0.9, d + 0.5, BASE_STONE)
    b.box_center(0.0, 0.0, 0.85, w + 0.6, 0.12, d + 0.6, BASE_TRIM)
    # Ground floor
    b.box_center(0.0, 0.0, 0.9, w, 3.0, d, WALL_PLASTER)
    b.timber_posts(w, d, 0.9, 3.0, post_w=0.28)
    b.door_and_windows(w, d, 0.9, door_w=1.4, door_h=2.2)
    # First jettying (floor 2)
    w2, d2 = w + 0.4, d + 0.4
    b.box_center(0.0, 0.0, 3.9, w2 + 0.15, 0.25, d2 + 0.15, TIMBER)
    b.box_center(0.0, 0.0, 4.15, w2, 2.8, d2, WALL_PLASTER)
    b.timber_posts(w2, d2, 4.15, 2.8, post_w=0.25)
    # 2nd floor windows
    hd2 = d2 * 0.5
    for wx in [-2.5, -0.8, 0.8, 2.5]:
        b.box_center(wx, hd2 + 0.02, 4.9, 0.85, 1.1, 0.12, WINDOW_FRAME)
        b.box_center(wx, hd2 + 0.04, 4.95, 0.7, 0.9, 0.08, WINDOW_GLASS)
    # Roof with dormer accent
    b.gable_roof(w2, d2, 6.95, 3.2, overhang=0.5, color=ROOF_ORANGE)
    # Dual stone chimneys
    b.chimney(3.0, -1.5, 5.0, 5.8)
    b.chimney(-3.0, 1.5, 5.0, 5.8)
    return b


def make_corner():
    b = Buf()
    w, d = 4.5, 4.5
    # 3-story tall corner house
    b.box_center(0.0, 0.0, 0.0, w + 0.3, 0.8, d + 0.3, BASE_STONE)
    # Floor 1
    b.box_center(0.0, 0.0, 0.8, w, 3.0, d, WALL_PLASTER)
    b.timber_posts(w, d, 0.8, 3.0)
    b.door_and_windows(w, d, 0.8, door_w=1.0, door_h=2.0)
    # Floor 2 jettying
    w2, d2 = w + 0.3, d + 0.3
    b.box_center(0.0, 0.0, 3.8, w2 + 0.15, 0.2, d2 + 0.15, TIMBER)
    b.box_center(0.0, 0.0, 4.0, w2, 3.0, d2, WALL_PLASTER)
    b.timber_posts(w2, d2, 4.0, 3.0)
    # Floor 3 jettying
    w3, d3 = w2 + 0.3, d2 + 0.3
    b.box_center(0.0, 0.0, 7.0, w3 + 0.15, 0.2, d3 + 0.15, TIMBER)
    b.box_center(0.0, 0.0, 7.2, w3, 2.8, d3, WALL_PLASTER)
    b.timber_posts(w3, d3, 7.2, 2.8)
    # Tall steep pavilion/pyramid roof
    hw3, hd3 = (w3 + 0.6) * 0.5, (d3 + 0.6) * 0.5
    apex = (0.0, 13.0, 0.0)
    v0 = (-hw3, 10.0, -hd3)
    v1 = (hw3, 10.0, -hd3)
    v2 = (hw3, 10.0, hd3)
    v3 = (-hw3, 10.0, hd3)
    b.tri(v0, apex, v1, ROOF_SLATE)
    b.tri(v1, apex, v2, ROOF_SLATE)
    b.tri(v2, apex, v3, ROOF_SLATE)
    b.tri(v3, apex, v0, ROOF_SLATE)
    # Spire finial
    b.box_center(0.0, 0.0, 13.0, 0.2, 1.0, 0.2, TIMBER)
    return b


def make_tower_small():
    b = Buf()
    # Cylindrical stone watchtower
    b.cylinder(0.0, 0.0, 0.0, 1.2, 2.4, 2.1, 14, BASE_STONE)
    b.cylinder(0.0, 0.0, 1.2, 10.0, 2.1, 2.0, 14, WALL_PLASTER)
    # Arrow slits
    for a in [0.0, math.pi * 0.5, math.pi, math.pi * 1.5]:
        ca, sa = math.cos(a), math.sin(a)
        b.box_center(ca * 2.02, sa * 2.02, 5.0, 0.18, 0.9, 0.18, DOOR_WOOD)
        b.box_center(ca * 2.02, sa * 2.02, 8.5, 0.18, 0.9, 0.18, DOOR_WOOD)
    # Corbel overhang & battlement
    b.cylinder(0.0, 0.0, 11.2, 0.8, 2.0, 2.5, 14, BASE_STONE)
    # Conical roof
    b.cone(0.0, 0.0, 12.0, 3.8, 2.6, 14, ROOF_ORANGE)
    b.box_center(0.0, 0.0, 15.8, 0.15, 0.8, 0.15, TIMBER)
    return b


# ---------------------------------------------------------
# Anime Foliage Generators (Cloud / Puff Foliage)
# ---------------------------------------------------------
def make_tree_oak():
    b = Buf()
    # Stylized organic trunk
    b.cylinder(0.0, 0.0, 0.0, 1.5, 0.65, 0.45, 10, TRUNK_BARK)
    b.cylinder(0.0, 0.0, 1.5, 2.5, 0.45, 0.35, 10, TRUNK_BARK)
    # Root flares
    for i in range(4):
        a = math.tau * i / 4.0
        ca, sa = math.cos(a), math.sin(a)
        perp_x, perp_z = -sa * 0.08, ca * 0.08
        pa = (ca * 0.6 + perp_x, 0.0, sa * 0.6 + perp_z)
        pb = (ca * 0.6 - perp_x, 0.0, sa * 0.6 - perp_z)
        pt = (ca * 0.45, 0.8, sa * 0.45)
        tip = (ca * 1.1, 0.0, sa * 1.1)
        b.tri(pa, pt, tip, TRUNK_DARK)
        b.tri(tip, pt, pb, TRUNK_DARK)
        b.tri(pa, tip, pb, TRUNK_DARK)
    # Stylized branch reach
    b.cylinder(0.5, 0.2, 3.6, 1.2, 0.25, 0.18, 8, TRUNK_BARK)
    b.cylinder(-0.4, -0.3, 3.5, 1.0, 0.22, 0.16, 8, TRUNK_BARK)

    # Cloud puff canopy with Spherical Normals
    # Central top crown
    b.cloud_puff(0.0, 6.2, 0.0, 2.4, 1.9, 2.4, segs_u=10, segs_v=7)
    # Surrounding organic puffy lobes
    b.cloud_puff(1.5, 5.1, 0.8, 1.9, 1.6, 1.8, segs_u=9, segs_v=6)
    b.cloud_puff(-1.4, 4.8, -0.9, 1.8, 1.5, 1.7, segs_u=9, segs_v=6)
    b.cloud_puff(0.3, 5.3, -1.5, 1.7, 1.4, 1.6, segs_u=8, segs_v=6)
    b.cloud_puff(-1.1, 4.3, 1.1, 1.5, 1.3, 1.5, segs_u=8, segs_v=6)
    return b


def make_tree_small():
    b = Buf()
    # Slender ornamental tree
    b.cylinder(0.0, 0.0, 0.0, 1.0, 0.35, 0.24, 8, TRUNK_BARK)
    b.cylinder(0.0, 0.0, 1.0, 1.8, 0.24, 0.18, 8, TRUNK_BARK)
    # Root flares
    for i in range(3):
        a = math.tau * i / 3.0
        ca, sa = math.cos(a), math.sin(a)
        perp_x, perp_z = -sa * 0.05, ca * 0.05
        pa = (ca * 0.3 + perp_x, 0.0, sa * 0.3 + perp_z)
        pb = (ca * 0.3 - perp_x, 0.0, sa * 0.3 - perp_z)
        pt = (ca * 0.22, 0.5, sa * 0.22)
        tip = (ca * 0.65, 0.0, sa * 0.65)
        b.tri(pa, pt, tip, TRUNK_DARK)
        b.tri(tip, pt, pb, TRUNK_DARK)
        b.tri(pa, tip, pb, TRUNK_DARK)
    # Cloud puff canopy
    b.cloud_puff(0.0, 4.1, 0.0, 1.5, 1.3, 1.5, segs_u=8, segs_v=6)
    b.cloud_puff(0.8, 3.2, 0.4, 1.2, 1.0, 1.1, segs_u=7, segs_v=5)
    b.cloud_puff(-0.7, 3.1, -0.4, 1.1, 1.0, 1.1, segs_u=7, segs_v=5)
    return b


# ---------------------------------------------------------
# glTF 2.0 Binary (GLB) Exporter
# ---------------------------------------------------------
def pack(b):
    stride = 10 * 4
    out = bytearray()
    pos_min = [1e9] * 3
    pos_max = [-1e9] * 3
    for i in range(len(b.pos)):
        p, n, c = b.pos[i], b.nor[i], b.col[i]
        for k in range(3):
            pos_min[k] = min(pos_min[k], p[k])
            pos_max[k] = max(pos_max[k], p[k])
        out += struct.pack('<3f3f4f', p[0], p[1], p[2], n[0], n[1], n[2], c[0], c[1], c[2], c[3])
    return bytes(out), pos_min, pos_max, len(b.pos)


def write_glb(path, b):
    data, pmin, pmax, nverts = pack(b)
    stride = 40
    acc0 = {"bufferView": 0, "byteOffset": 0, "componentType": 5126, "count": nverts, "type": "VEC3", "min": pmin, "max": pmax}
    acc1 = {"bufferView": 0, "byteOffset": 12, "componentType": 5126, "count": nverts, "type": "VEC3"}
    acc2 = {"bufferView": 0, "byteOffset": 24, "componentType": 5126, "count": nverts, "type": "VEC4"}
    gltf = {
        "asset": {"version": "2.0", "generator": "SAO_KitGen_v2"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0}],
        "meshes": [{"primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "COLOR_0": 2}, "material": 0}]}],
        "materials": [{"pbrMetallicRoughness": {"baseColorFactor": [1, 1, 1, 1], "metallicFactor": 0.0, "roughnessFactor": 0.85}}],
        "accessors": [acc0, acc1, acc2],
        "bufferViews": [{"buffer": 0, "byteOffset": 0, "byteLength": nverts * stride, "byteStride": stride}],
        "buffers": [{"byteLength": len(data)}],
    }
    js = json.dumps(gltf, separators=(',', ':')).encode()
    js += b' ' * ((4 - len(js) % 4) % 4)
    bin_ = data
    bin_ += b'\x00' * ((4 - len(bin_) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(bin_)
    with open(path, 'wb') as f:
        f.write(struct.pack('<III', 0x46546C67, 2, total))
        f.write(struct.pack('<II', len(js), 0x4E4F534A))
        f.write(js)
        f.write(struct.pack('<II', len(bin_), 0x004E4942))
        f.write(bin_)


specs = {
    "house_s.glb": make_house_s(),
    "house_m.glb": make_house_m(),
    "house_l.glb": make_house_l(),
    "corner.glb": make_corner(),
    "tower_small.glb": make_tower_small(),
    "tree_oak.glb": make_tree_oak(),
    "tree_small.glb": make_tree_small(),
}

for name, b in specs.items():
    write_glb(os.path.join(OUT, name), b)
    print("wrote", name, len(b.pos), "verts")
print("KIT_DONE")


# Lộ Trình Nâng Cấp Đồ Họa Cảnh "Thành Khởi Đầu" (Starting City - SAO Aincrad Floor 1)
**Nền tảng**: Godot Engine 4.x (Forward+ / RenderingDevice)  
**Phong cách mục tiêu**: Anime Stylized / Cel-shaded (Sword Art Online: Aincrad Arc)  
**Vai trò**: 3D Technical Artist & Senior Godot 4 Graphics Engineer  

---

## 1. Quy Hoạch Asset & Modular Workflow

### 1.1. Khảo Sát Phong Cách Kiến Trúc SAO Aincrad (Town of Beginnings)
Thành Khởi Đầu trong Sword Art Online là một đại đô thị hình bán nguyệt dựa lưng vào vách vành đai ngoài của tầng 1 Aincrad:
- **Đặc trưng kiến trúc**: Phong cách Trung cổ Tây Âu (Medieval / Tudor / Half-timbered) hòa quyện cùng kỳ ảo (Fantasy).
  - **Tầng trệt**: Khối đá sa thạch thô (rubble stone / ashlar), màu xám ngà `#D2CCC0` hoặc nâu xám ấm `#8A8175`.
  - **Tầng trên (tầng 1 & 2)**: Khung xà gỗ chịu lực lộ thiên (timber frames) sơn nâu óc chó sẫm `#422B1D`, vách trát vữa thạch cao phẳng màu trắng kem `#F5F2EB`. Kết cấu nhô ra ngoài (jettying) tạo độ sâu bóng đổ đường phố.
  - **Mái nhà**: Mái dốc nhọn (steep pitched gables / dormers) 45°-60° lợp ngói vảy đất nung cam đất `#C46A3A` hoặc xanh ngói đá phiến slate `#4A607A`.
  - **Chi tiết ngoại thất**: Ban công gỗ console, ống khói đá, đèn lồng treo tường nghệ thuật, bảng hiệu tiệm rèn/quán ăn uốn sắt.
- **Khu vực Trung tâm (Central Plaza & Colonnades)**:
  - Quảng trường tròn khổng lồ bán kính ~35-50m nơi người chơi xuất hiện và nghe thông báo sinh tử của Kayaba Akihiko.
  - Hàng cột thức cổ điển cách điệu (Stylized Tuscan/Doric colonnades), đá cẩm thạch trắng ngà.
  - Đài phun nước đá đa tầng ở tâm quảng trường.
- **Hệ thống Tường thành & Cổng vòm (City Walls & Gates)**:
  - Tường thành cao 15-20m, có đường tuần tra (rampart/battlement) và lỗ châu mai (crenelations).
  - Tháp canh hình trụ hoặc bát giác (Watchtowers) có chóp nón vuốt nhọn.
- **Cây cối & Thảm thực vật Anime (Stylized Anime Foliage)**:
  - Không dùng lá card PBR chi tiết li ti gây nhiễu thị giác (visual noise).
  - Sử dụng phương pháp **Cloud/Puff Foliage**: Các cụm tán lá tạo hình khối tròn bồng bềnh như đám mây.
  - Kỹ thuật **Normal Transfer (Foliage Normal Editing)**: Toàn bộ vector normal của các face lá được nắn lại hướng tỏa đều từ tâm cụm khối cầu ra ngoài (trong Blender dùng Normal Edit Modifier hoặc Transfer Normal từ Sphere), giúp bóng đổ cel-shading trên tán cây mượt mà, phân mảng sáng tối rõ rệt như tranh vẽ anime 2D.

### 1.2. Danh Mục Bộ Kit Modular (Metrics & Snapping)
Thiết lập Grid Snapping trong Godot/Blender chuẩn hệ mét: **1m, 2m, 4m**:

| Mã Kit | Tên Thành Phần | Kích Thước (W x H x D) | Mô Tả Kỹ Thuật |
| :--- | :--- | :--- | :--- |
| `MOD_WALL_10M` | Tường thành thẳng | 10.0m x 15.0m x 4.0m | Có rampart phía trên, chân tường dốc (batter) |
| `MOD_WALL_TOWER` | Tháp canh tròn | R: 4.5m x H: 24.0m | Mái nón dốc 60°, cửa tò vò canh gác |
| `MOD_GATE_ARCH` | Cổng thành vòm đá | 16.0m x 18.0m x 6.0m | Cửa gỗ bọc sắt và cơ cấu tời kéo |
| `MOD_HOUSE_BASE_A` | Khối nhà trệt đá | 8.0m x 4.0m x 10.0m | Đá hộc, cửa chính vòm gỗ, 2 cửa sổ nhỏ |
| `MOD_HOUSE_MID_A` | Tầng lầu khung gỗ | 8.4m x 3.8m x 10.4m | Nhô ra hơn tầng trệt 0.2m mỗi bên (jettying) |
| `MOD_ROOF_GABLE_A` | Mái ngói chữ A | 9.0m x 4.5m x 11.0m | Ngói đất nung cam, có cửa sổ mái dormer |
| `MOD_COLONNADE_ARC` | Đoạn hành lang cong | 6.0m x 7.0m x 3.0m | Bán kính uốn cong 35m bao quanh quảng trường |
| `MOD_TREE_OAK_STYL`| Cây sồi anime | R: 5.0m x H: 9.0m | 3 cụm mesh tán lá mây + thân cây stylized |

### 1.3. Quản Lý Số Lượng Đối Tượng Lớn & Tối Ưu Hóa Hiệu Năng (Large-Scale Performance)
Bản đồ Thành Khởi Đầu có đường kính ~700m - 1200m với hàng nghìn căn nhà, tháp và cây xanh. Để duy trì 60 - 120 FPS trên PC và thiết bị tầm trung:

1. **MultiMeshInstance3D (GPU Instancing)**:
   - Gom toàn bộ các đối tượng lặp lại (hàng ngàn cây xanh, cột đèn, băng ghế, thùng gỗ, ngói nóc, cụm nhà modular) thành các node `MultiMeshInstance3D`.
   - Mỗi loại đối tượng chỉ tốn **1 Draw Call duy nhất**.
   - Dữ liệu ma trận transform (Position, Rotation, Scale) và màu sắc (Color) được lưu trữ trực tiếp trong VRAM GPU buffer.
2. **GridMap vs MultiMesh trong quy trình**:
   - Sử dụng `GridMap` trong giai đoạn thiết kế màn chơi (Level Design / Blockout) để lắp ghép nhanh bằng lưới snap.
   - Khi chuyển sang bản đồ hoàn thiện (Production), chuyển đổi các chunk tĩnh sang `MultiMeshInstance3D` hoặc gộp mesh bằng `SurfaceTool` / `MeshMerger` để tối ưu hóa triệt để Draw Calls.
3. **Godot 4 Visibility Range & Phân Cấp LOD (HLOD)**:
   - Sử dụng hệ thống `Visibility Range` tích hợp sẵn trong Godot 4 cho từng cấp LOD:
     - **LOD 0 (0m - 40m)**: Mô hình chi tiết đầy đủ, bật Inverted Hull Outline Pass, Vertex Shader đón gió cho tán lá.
     - **LOD 1 (40m - 150m)**: Mô hình giảm 70% polycount, tắt Outline pass, vật liệu gộp (texture atlas).
     - **LOD 2 / Distant Impostors (150m - 800m)**: Dùng cụm Mesh khối đơn giản (Block/Silhouette low-poly) hoặc Octahedral Impostors, dùng unlit shader hoặc flat diffuse.
   - Bật `Fade Mode = Self` với `Visibility Range Hysteresis = 5.0m` để triệt tiêu hoàn toàn hiện tượng pop-in giật cục khi camera di chuyển.
4. **Occlusion Culling (Bake Occluder3D)**:
   - Thêm `OccluderInstance3D` dạng `QuadOccluder3D` và `BoxOccluder3D` đặt bên trong các khối tường thành dày và các dãy nhà lớn.
   - GPU sẽ loại bỏ (cull) toàn bộ nội thất và các dãy phố bị che khuất phía sau bức tường trước khi đưa vào pipeline render.

---

## 2. Kỹ Thuật Shaders & Vật Liệu (Anime / Cel-Shading)

### 2.1. Toon Shader với Banded Lighting & Anime Specular
- Đóng gói tại [**`shaders/toon_cel_shading.gdshader`**](file:///c:/Users/Admin/Documents/my-first-game/shaders/toon_cel_shading.gdshader).
- **Cơ chế hoạt động**:
  - **Banded Diffuse**: Thay vì shading Lambert mượt mà của thực tế, chia dải sáng làm 2 - 3 bậc rõ rệt (`core_shadow`, `mid_shadow`).
  - **Bảo toàn năng lượng ánh sáng**: Tránh hiện tượng rò rỉ ánh sáng (light leakage) hoặc phát sáng tự thân trong bóng tối bằng cách nhân trực tiếp với `core_shadow` và `ATTENUATION`. Vùng tối hoàn toàn không nhận ánh sáng trực tiếp mà nhận ánh sáng môi trường mát dịu từ Sky/Environment.
  - **Specular Highlight Anime**: Vết sáng bóng tròn gắt (sharp cut Blinn-Phong), ngắt ngưỡng bằng hàm `smoothstep` với độ mờ cực nhỏ (`specular_softness`), được kiểm soát bởi shadow attenuation để không lóe sáng qua vật chắn.
  - **Anime Rim Light (Viền sáng ngược)**: Tạo dải sáng viền quanh mép đối tượng khi nhìn ngược hướng ánh sáng (`backlight = max(dot(-VIEW, LIGHT), 0.0)`), có điều biến `ATTENUATION` để triệt tiêu lỗi viền phát sáng xuyên qua tường thành.

### 2.2. Viền Nét Bề Mặt (Inverted Hull / Backface Extrusion Outline)
- Đóng gói tại [**`shaders/inverted_hull_outline.gdshader`**](file:///c:/Users/Admin/Documents/my-first-game/shaders/inverted_hull_outline.gdshader).
- **Phương pháp thực hiện chuẩn mực**:
  - Gán vào khe `next_pass` của `ShaderMaterial` hoặc `StandardMaterial3D`.
  - Khai báo `render_mode cull_front, unshaded, depth_draw_opaque`.
  - **Triệt tiêu lỗi tỉ lệ**: Biến đổi Normal và Vertex sang View Space (`MODELVIEW_MATRIX`), sau đó bù trừ chiều sâu phối cảnh `-view_pos.z`. Kỹ thuật này giúp độ dày viền nét trên màn hình hoàn toàn không bị ảnh hưởng bởi tỉ lệ co giãn cục bộ (`Scale`) của Node hay khoảng cách xa gần.

### 2.3. Shader Mặt Nước Hồ Cảnh Quan (Stylized Water)
- Đóng gói tại [**`shaders/stylized_water.gdshader`**](file:///c:/Users/Admin/Documents/my-first-game/shaders/stylized_water.gdshader).
- **Cơ chế hoạt động**:
  - **Beer-Lambert Depth Gradient**: Tái tạo tọa độ View-Space Depth từ `hint_depth_texture` để tính toán độ sâu thực của nước `water_depth = max(linear_depth - (-VERTEX.z), 0.0)`. Màu chuyển mềm mại từ ngọc bích ven bờ (`#38C7D1`) sang xanh thẳm đáy hồ (`#144794`).
  - **Dynamic Shore Foam (Bọt mép bờ)**: Đo khoảng cách tiếp xúc giữa mặt nước và đáy hồ để sinh bọt nước cuộn theo sóng noise, không bị artifact biên tại mép nước.
  - **Stylized Wave Glints & Refraction**: Phản xạ ánh nắng mặt trời tạo các đốm lấp lánh cel-cut trên mặt hồ kết hợp khúc xạ nhẹ mặt đáy thông qua `hint_screen_texture`.

### 2.4. Đường Lát Đá Quảng Trường & Lối Đi (Stylized Cobblestone)
- Đóng gói tại [**`shaders/stylized_cobblestone.gdshader`**](file:///c:/Users/Admin/Documents/my-first-game/shaders/stylized_cobblestone.gdshader).
- **Cơ chế hoạt động**:
  - Sử dụng cơ chế **Triplanar Mapping** để chiếu vân đá lên mặt đất và thềm bậc tam cấp mà không bị kéo giãn UV (UV stretching).
  - Sử dụng ma trận chuẩn xác `MODEL_NORMAL_MATRIX` để bảo toàn hướng vector pháp tuyến khi địa hình bị co giãn không đồng trục.
  - Cel-shading phân mảng gờ đá kết hợp specular cel-cut sắc bén, hoàn toàn đồng bộ với hệ thống ánh sáng chung.

---

## 3. Thiết Lập Ánh Sáng & Môi Trường (WorldEnvironment)

### 3.1. Cấu Hình DirectionalLight3D (Ánh Nắng Ban Ngày Aincrad)
Tái hiện bầu không khí tươi sáng, ấm áp của tập 1 SAO với các thông số chuẩn xác cho Godot 4:

```gdscript
# Thông số chuẩn cho node Sun (DirectionalLight3D):
transform.basis = Basis.from_euler(Vector3(deg_to_rad(-48.0), deg_to_rad(135.0), 0.0)) # Góc chiếu xiên đẹp
light_color = Color(1.0, 0.96, 0.88)       # Vàng nắng ấm nhẹ anime
light_energy = 1.35                         # Cường độ nắng chính
light_indirect_energy = 1.0                # Hỗ trợ chiếu sáng gián tiếp anime
shadow_enabled = true
shadow_bias = 0.03                         # Ngăn ngừa sọc bóng shadow acne
shadow_normal_bias = 1.8                   # Triệt tiêu hiện tượng tách bóng chân tường (peter-panning)
shadow_blur = 1.6                          # Giữ bóng sắc nét cel-shade nhưng không vỡ hạt
directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
directional_shadow_split_1 = 0.08          # ~15m (vùng cận cảnh người chơi)
directional_shadow_split_2 = 0.22          # ~45m (khu vực dãy phố lân cận)
directional_shadow_split_3 = 0.50          # ~120m (tường thành và tháp chuông)
directional_shadow_max_distance = 350.0    # Giới hạn bóng đổ tiết kiệm VRAM
directional_shadow_blend_splits = true     # Hòa trộn mượt mà giữa các vùng cascade
```

### 3.2. Cấu Hình WorldEnvironment (Anime Aesthetic)
```gdscript
# Thiết lập node WorldEnvironment:
environment.background_mode = Environment.BG_SKY

# 1. Bầu Trời Anime (Sky):
# Dùng ProceduralSkyMaterial hoặc Shader Sky Anime với 3 tầng dải màu pastel:
# Sky Top Color: Color(0.24, 0.52, 0.88) - Xanh thiên thanh
# Sky Horizon Color: Color(0.72, 0.88, 0.96) - Xanh lơ phấn nhạt
# Ground Bottom Color: Color(0.48, 0.46, 0.42) - Xám đất ấm
# Ground Horizon Color: Color(0.76, 0.80, 0.82) - Nhuộm màu đường chân trời

# 2. Ánh Sáng Môi Trường (Ambient Light):
environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
environment.ambient_light_color = Color(0.68, 0.74, 0.85) # Ánh sáng môi trường hơi lam nhẹ
environment.ambient_light_sky_contribution = 0.75
environment.ambient_light_energy = 0.85

# 3. Tonemapping (Quan trọng nhất cho Anime Look):
# Trong Godot 4: TONE_MAPPER_FILMIC = 2 hoặc TONE_MAPPER_ACES = 3
environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
environment.tonemap_exposure = 1.1          # Nâng sáng tổng thể tạo cảm giác anime rực rỡ
environment.tonemap_white = 1.05

# 4. Glow (Bloom mềm mại):
environment.glow_enabled = true
environment.glow_intensity = 0.5
environment.glow_strength = 0.95
environment.glow_bloom = 0.12               # Tỏa sáng nhẹ ở các điểm phản chiếu mặt nước/kính
environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

# 5. SSAO (Screen Space Ambient Occlusion):
environment.ssao_enabled = true
environment.ssao_radius = 1.2
environment.ssao_intensity = 1.8            # Nhấn đậm các góc khuất, chân cột, gờ mái như nét mực
environment.ssao_power = 1.5
environment.ssao_detail = 0.5

# 6. Global Illumination (SDFGI vs VoxelGI):
# Với Starting City quy mô rộng lớn (>500m), SDFGI là giải pháp tối ưu vượt trội:
# Không cần nướng bake trước dung lượng VRAM lớn, tự động phủ toàn bộ không gian mở.
environment.sdfgi_enabled = true
environment.sdfgi_cascades = 4
environment.sdfgi_min_cell_size = 0.4
environment.sdfgi_energy = 0.8

# 7. Sương Mù Khí Quyển (Aerial Perspective Fog):
# Tạo chiều sâu thăm thẳm như tranh background vẽ tay của Studio A-1 Pictures:
environment.fog_enabled = true
environment.fog_light_color = Color(0.80, 0.88, 0.96) # Màu xanh lơ pastel đồng điệu với chân trời
environment.fog_density = 0.0014
environment.fog_aerial_perspective = 0.85  # Tăng mạnh sắc thái không khí cho các vật thể ở xa
environment.fog_sky_affect = 0.35
```

---

## 4. Quy Trình Triển Khai Thực Tế (Step-by-Step Checklist)

```markdown
- [ ] GIAI ĐOẠN 1: MÔ HÌNH HÓA VÀ THAY THẾ BLOCKOUT (DCC & Modular Setup)
  - [x] Bước 1.1: Tạo và kiểm thử các shader cốt lõi (.gdshader) cho pipeline anime cel-shading.
  - [ ] Bước 1.2: Mô hình hóa bộ kit modular trong DCC (Blender) với lưới snapping chuẩn hệ mét 1m/2m/4m.
  - [ ] Bước 1.3: Nắn chỉnh Normal cho tán lá cây anime (Normal Transfer modifier từ hình cầu) để tạo khối puff cloud.
  - [ ] Bước 1.4: Xuất GLTF/GLB kèm Vertex Color (lưu sẵn Ambient Occlusion rãnh tường đá).
  - [ ] Bước 1.5: Thay thế các Primitive Mesh trong `sao_starting_city.tscn` bằng các scene modular kit hoàn chỉnh.

- [ ] GIAI ĐOẠN 2: THIẾT LẬP VẬT LIỆU CEL-SHADING & OUTLINE
  - [ ] Bước 2.1: Tạo các ShaderMaterial kế thừa từ `shaders/toon_cel_shading.gdshader` cho tường đá, khung gỗ, mái ngói.
  - [ ] Bước 2.2: Thiết lập `next_pass` với `shaders/inverted_hull_outline.gdshader` trên các mesh chính để bật viền nét anime.
  - [ ] Bước 2.3: Gán `shaders/stylized_water.gdshader` cho mặt nước hồ cảnh quan và tinh chỉnh độ sâu `depth_distance`.
  - [ ] Bước 2.4: Gán `shaders/stylized_cobblestone.gdshader` cho quảng trường trung tâm và trục đường chính.

- [ ] GIAI ĐOẠN 3: ÁNH SÁNG & HẬU KỲ WORLDENVIRONMENT
  - [ ] Bước 3.1: Đặt góc xoay `Sun` (DirectionalLight3D) tại `(-48°, 135°, 0°)` với màu vàng ấm `Color(1.0, 0.96, 0.88)`.
  - [ ] Bước 3.2: Bật PSSM 4 Splits và tinh chỉnh Bias (0.03) + Normal Bias (1.8).
  - [ ] Bước 3.3: Bật `Filmic Tonemap`, đẩy nhẹ `exposure = 1.1`.
  - [ ] Bước 3.4: Bật `Fog` với `aerial_perspective = 0.85` để nhuộm sắc xanh lam cho các ngọn tháp và tường thành ở xa.
  - [ ] Bước 3.5: Kích hoạt `SSAO` và `SDFGI` để có ánh sáng nảy gián tiếp trong các con hẻm cổ điển.

- [ ] GIAI ĐOẠN 4: HỆ THỐNG INSTANCING & TỐI ƯU HÓA HIỆU NĂNG
  - [ ] Bước 4.1: Chuyển đổi các ngôi nhà lặp lại và toàn bộ cây cối sang `MultiMeshInstance3D` thông qua tool script.
  - [ ] Bước 4.2: Cấu hình `Visibility Range` (LOD 0: 0-40m, LOD 1: 40-150m, Impostor: 150m+).
  - [ ] Bước 4.3: Đặt các tấm `OccluderInstance3D` dọc theo các dãy tường thành lớn.
  - [ ] Bước 4.4: Bật Godot Monitors (Draw Calls, Primitive Count, Frame Time) để thẩm định FPS đạt chuẩn 60+ FPS ổn định.
```

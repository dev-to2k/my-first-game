# Tài Liệu Thiết Kế Phân Vùng Kỹ Thuật (Technical Level Design Specification)
# Bản Đồ Bán Mở Tầng 1 Aincrad (Sword Art Online) - Quy Mô 2x2 km
**Dự án**: Aincrad Floor 1 Reconstruction  
**Engine**: Godot Engine 4.x (Forward+ Renderer / Jolt Physics)  
**Vai trò**: Senior Technical Level Designer  
**Quy mô**: $2000\text{ m} \times 2000\text{ m}$ ($4\text{ km}^2$), Semi-Open World  
**Phiên bản tài liệu**: 1.0.0-PROD  

---

## 1. Tổng Quan Không Gian & Hệ Trục Tọa Độ (World Scale & Coordinate System)

### 1.1. Thang Đo Thế Giới & Hệ Thống Tọa Độ Godot 4
- **Đơn vị chuẩn**: $1\text{ unit} = 1.0\text{ mét}$ thực tế.
- **Quy mô không gian (Bounding Box)**:
  - Trục ngang (X): $[-1000.0\text{ m}, +1000.0\text{ m}]$ (Tây $\leftrightarrow$ Đông).
  - Trục dọc (Z): $[-1000.0\text{ m}, +1000.0\text{ m}]$ (Bắc $\leftrightarrow$ Nam).
  - Trục cao độ (Y): $[0.0\text{ m}, +320.0\text{ m}]$.
- **Điểm gốc (Origin `Vector3(0, 0, 0)`)**:
  - Tọa lạc tại **Đài Phun Nước / Tâm Vòng Tròn Dịch Chuyển (Central Teleport Gate Plaza)** của Thị trấn Khởi đầu. Mọi vector định vị, cân bằng khoảng cách và điểm mốc sơ cấp đều lấy gốc này làm tham chiếu tuyệt đối.
- **Trần vòm thế giới (Floor 2 Bottom Plate)**:
  - Ở cao độ $Y = +350.0\text{ m}$ là đáy kim loại - đá của Tầng 2 Aincrad với các đường gân hoa văn ánh kim rực rỡ, đóng vai trò như một "bầu trời cơ khí kỳ ảo" bao bọc toàn bộ bán cầu thế giới.

```
                     [ CỰC BẮC: Z = -1000m ]
             =======================================
             |         THÁP MÊ CUNG TẦNG 1         |
             |        (Labyrinth Tower: 320m)      |
             =======================================
                            ▲
                            │ (Dốc hẻm núi hiểm trở)
                            │
       [ TÂY: X = -1000m ]  │   [ ĐÔNG: X = +1000m ]
       ┌────────────────────┼──────────────────────┐
       │                    │  RỪNG MÊ CUNG        │
       │ BÌNH NGUYÊN        │  & VÙNG ĐỒI TOLBANA  │
       │ THẢO NGUYÊN        │  (Tolbana Foothills  │
       │ (West Plains)      │   & Dense Forest)    │
       │                    │                      │
       │ Cụm Cối Xay Gió    │  Thị trấn Tolbana    │
       │ Đồi thoai thoải    │  Hang động đá ngầm   │
       │ Bầy Frenzy Boar    │  Rừng rậm tán dày    │
       └────────────────────┼──────────────────────┘
                            │
             =======================================
             |       THỊ TRẤN KHỞI ĐẦU              |
             |     (Town of Beginnings)            |
             |   Origin (0,0,0) - Cổng Dịch Chuyển |
             |   Cung điện Hắc Thiết & Tường Bán Nguyệt
             =======================================
                     [ CỰC NAM: Z = +1000m ]
```

### 1.2. Phân Chia Lưới Chunking & Cơ Chế World Partition trong Godot 4
Do quy mô bản đồ $2000\text{ m} \times 2000\text{ m}$, việc nạp toàn bộ scene vào bộ nhớ sẽ tiêu tốn $\approx 6\text{ GB}$ VRAM và kéo tụt FPS. Giải pháp kỹ thuật được chuẩn hóa:
1. **Lưới Phân Vùng 16 Macro-Chunks ($4 \times 4$)**:
   - Mỗi macro-chunk có kích thước $500\text{ m} \times 500\text{ m}$.
   - Tên định danh theo tọa độ ma trận: `Chunk_X[0..3]_Z[0..3]`.
2. **Khu Vực Kích Hoạt Động (Active Streaming Radius)**:
   - **Bán kính nạp đầy đủ (LOD 0)**: $r = 150\text{ m}$ quanh người chơi (Geometry, Collision, NavMesh, dynamic NPCs).
   - **Bán kính nạp trung gian (LOD 1 / HLOD)**: $r = 150\text{ m} - 450\text{ m}$ (Simplified mesh, không collision, không dynamic actor update).
   - **Bán kính cảnh quan xa (LOD 2 / Skybox Impostors)**: $r > 450\text{ m}$ (Chỉ hiển thị các Landmark lớn như Tháp Mê Cung, Tường Thành, Cối Xay Gió).
3. **Cơ chế nạp không giật khung hình (Asynchronous Background Threading)**:
   - Sử dụng `ResourceLoader.load_threaded_request()` kết hợp `VisibleOnScreenNotifier3D` và vùng đệm kích hoạt (Trigger Volumes).

---

## 2. Thiết Kế Chi Tiết 4 Khu Vực Cốt Lõi (Zone Breakdown & Spatial Design)

---

### Khu Vực 1: Thị Trấn Khởi Đầu (Town of Beginnings)
- **Tọa độ trung tâm**: $X \in [-450, +450]$, $Z \in [+300, +950]$, $Y \in [0, +40]$.
- **Diện tích**: $\approx 0.65\text{ km}^2$.
- **Bản chất Gameplay**: Safe Zone tuyệt đối, Hub giao thương, trung tâm cốt truyện, vùng chuẩn bị trang bị và nhận quest.

```
       [CỔNG BẮC RA THẢO NGUYÊN]
                  │
        ┌─────────┴─────────┐
       /   DÃY PHỐ THƯƠNG MẠI \
      /      (Market Street)   \
     │                          │
     │   QUẢNG TRƯỜNG TRUNG TÂM  │  <-- [Origin (0,0,0): Teleport Gate & Fountain]
     │    (Central Plaza R=45m) │
      \                        /
       \   KHU DÂN CƯ CỔ KÍNH  /
        └─────────┬───────────┘
                  │
       [CUNG ĐIỆN HẮC THIẾT (Black Iron Palace)]
       =========================================
       [TƯỜNG THÀNH BÁN NGUYỆT CAO 22M (Outer Wall)]
```

#### Các Công Trình Cốt Lõi:
1. **Quảng Trường Dịch Chuyển Trung Tâm (Central Teleport Gate Plaza)**:
   - **Quy mô**: Vòng tròn bán kính $R = 45\text{ m}$. Lát đá phiến xám ngà theo họa tiết nan hoa mặt trời (`stylized_cobblestone.gdshader`).
   - **Tâm điểm**: 
     - **Cổng Dịch Chuyển (Teleport Gate Monument)**: Kiến trúc vòng cung đá cẩm thạch trắng cao $12\text{ m}$ bao quanh khối tinh thể pha lê lơ lửng màu lam ngọc phát sáng hạt ánh sáng (GPUParticles3D).
     - **Đài Phun Nước Đa Tầng**: Nằm ngay cạnh cổng dịch chuyển, sử dụng `stylized_water.gdshader`.
   - **Hàng Cột Cổ Điển Bao Quanh (Colonnades)**: Dãy hành lang có mái vòm uốn cong $35\text{ m}$, tạo ranh giới tự nhiên giữa quảng trường trung tâm và các nhánh phố tỏa ra ngoài.
2. **Cung Điện Hắc Thiết (Black Iron Palace - Kurogane Palace)**:
   - **Tọa độ**: $X \in [-120, +120]$, $Z \in [+750, +920]$, $Y \in [+5, +85]$.
   - **Quy mô**: Kiến trúc đồ sộ kiểu Brutalist / Dark Fantasy Gothic. Mặt tiền rộng $180\text{ m}$, tháp trung tâm cao $80\text{ m}$.
   - **Vật liệu**: Toàn bộ khối đá hắc thạch đen tuyền có ánh phản quang cel-specular tím than `#1C1924`.
   - **Không gian chức năng**:
     - *Đại Sảnh Tưởng Niệm (Monument of Life Room)*: Nơi đặt bia đá khổng lồ khắc tên 10.000 người chơi, tự động gạch ngang tên người đã tử nạn.
     - *Cổng Dẫn Xuống Ngục Tối Bí Mật (Dungeon Entrance)*: Cửa sắt rèn kiên cố khóa chặt dẫn xuống ngục tối dưới lòng thành (nội dung khám phá cấp cao).
3. **Tường Thành Bán Nguyệt (Semi-circular Bastion Walls)**:
   - **Quy mô**: Bán kính uốn cong $R = 480\text{ m}$ che chắn trọn vẹn nửa phía Nam thị trấn và áp sát vành đai ngoài của Tầng 1.
   - **Thông số kỹ thuật**: Tường thành cao $22\text{ m}$, mặt đường tuần tra trên tường rộng $6\text{ m}$ (cho phép người chơi đi bộ ngắm toàn cảnh đồng bằng từ trên cao).
   - **Tháp Canh Phân Bổ (Defensive Bastions)**: 7 tháp tròn đường kính $9\text{ m}$, cao $32\text{ m}$ phân bố đều mỗi $120\text{ m}$ tường thành.
   - **Hệ Thống Cổng Xuất Thành**:
     - *Cổng Bắc (Main North Gate)*: Rộng $16\text{ m}$, cao $18\text{ m}$, vòm đá kép, dẫn thẳng ra Bình nguyên Thảo nguyên.
     - *Cổng Đông Bắc (East Postern Gate)*: Cổng phụ bí mật hẹp $5\text{ m}$ dẫn tắt đến bìa rừng Tolbana.

---

### Khu Vực 2: Bình Nguyên Thảo Nguyên (Starting Plains / West-Central Meadows)
- **Tọa độ trung tâm**: $X \in [-900, +100]$, $Z \in [-250, +300]$, $Y \in [+5, +95]$.
- **Diện tích**: $\approx 1.25\text{ km}^2$.
- **Bản chất Gameplay**: Vùng luyện cấp nhập môn (Tutorial / Early-Game Grind), không gian mở thoáng đãng tạo cảm giác tự do giải tỏa sau khi bước ra khỏi bức tường thành ngột ngạt.

```
  [Phía Tây: Vách Núi Vành Đai]                    [Phía Đông: Bìa Rừng Tolbana]
       │                                                         │
   [ĐỒI THOAI THOẢI 8°-14°]      [ĐỒNG CỎ LỘNG GIÓ]      [DÒNG SUỐI XANH]
   (Bầy Frenzy Boar Lv.1-2)    (Little Nepents Lv.3-4)   (Cầu Đá & Bến Nước)
       │                                                         │
       └────────────── [CỤM 5 CỐI XAY GIÓ CỔ KÍNH] ─────────────┘
                       (Windmill Ridge: Cao độ +85m)
```

#### Các Thành Phần Cốt Lõi:
1. **Địa Hình Đồi Thoai Thoải & Lòng Chảo Thảo Nguyên**:
   - Biên độ dốc nhẹ từ $6^\circ$ đến $14^\circ$, giúp người chơi dễ dàng bao quát tầm nhìn 360 độ mà không bị che chắn.
   - Thảm thực vật: Cỏ xanh anime hai sắc độ chuyển tiếp mượt mà, điểm xuyết các vạt hoa dại vàng cam (`#F4A261`).
2. **Cụm Cối Xay Gió Lộng Gió (The Windmill Ridge)**:
   - **Vị trí**: Đặt trên dải đồi cao phía Tây Bắc ($X = -450, Z = +50, Y = +85$).
   - **Quy mô**: 5 cối xay gió khổng lồ phong cách Medieval Tudor, cánh quạt dài $16\text{ m}$ xoay chậm rãi theo trục gió thổi từ Tây sang Đông.
   - **Ý đồ Level Design**:
     - Hoạt cảnh cánh quạt chuyển động liên tục tạo ra **Visual Kinetic Anchor** (Điểm mốc động lực thị giác). Khi người chơi ở bất kỳ đâu trên bình nguyên, chỉ cần nhìn thấy hướng xoay của cối xay gió là xác định được ngay hướng Tây và vị trí độ cao của sườn đồi.
     - Dưới chân cối xay gió lớn nhất bố trí điểm nghỉ ngơi an toàn (Rest Campfire) và NPC người bán dạo đồ hồi phục.
3. **Cụm Quái Vật Khởi Đầu (Mob Ecosystem)**:
   - *Vùng Thấp Trảng Cỏ (Cạnh Cổng Thành)*: Bầy Lợn Rừng Cuồng Nộ (**Frenzy Boar - Cấp 1-2**). Mật độ thưa: 1 con / $120\text{ m}^2$, hành vi thụ động, tầm aggro $8\text{ m}$.
   - *Vùng Trũng Ven Suối & Rặng Cây Lẻ*: Cây Ăn Thịt Bé (**Little Nepent - Cấp 3-4**). Nằm ẩn dưới các hốc đất ẩm ướt, hoa phát sáng màu tím cảnh báo nguy hiểm.

---

### Khu Vực 3: Vùng Đồi Chân Núi & Rừng Mê Cung (Tolbana Foothills & Dense Forest)
- **Tọa độ trung tâm**: $X \in [+150, +950]$, $Z \in [-650, +150]$, $Y \in [+45, +180]$.
- **Diện tích**: $\approx 1.1\text{ km}^2$.
- **Bản chất Gameplay**: Vùng chuyển tiếp gia tăng độ khó (Mid-Game Transition), thắt chặt tầm nhìn (Visual Choke), mê cung định hướng bằng âm thanh và ánh sáng.

```
       [CHÂN THÁP MÊ CUNG BẮC]
                  ▲
                  │  (Hẻm núi dốc 25°)
        ┌─────────┴─────────┐
       /   RỪNG MÊ CUNG RẬM   \
      /  (Canopy Density 75%)  \
     │  Ánh sáng God Rays anime │
     │  Hang Động Quặng Ngầm    │
     │  (Hidden Crystal Grotto) │
      \                        /
       \   THỊ TRẤN TOLBANA   /
        └─────────┬──────────┘
                  │  (Đường mòn ven suối)
       [BÌNH NGUYÊN THẢO NGUYÊN]
```

#### Các Thành Phần Cốt Lõi:
1. **Rừng Mê Cung Tán Dày (Canopy & Fog System)**:
   - **Mật độ tán cây (Foliage Density)**: $70\% - 85\%$. Sử dụng kỹ thuật Cloud Foliage Normal Transfer với các cây đại thụ thân cao $18\text{ m} - 28\text{ m}$.
   - **Ánh Sáng & Khí Quyển**:
     - Tận dụng `VolumetricFog` trong Godot 4 kết hợp `FogVolume` cục bộ để tạo ra các dải sương mây là là mặt đất.
     - Ánh nắng mặt trời xuyên qua kẽ lá tạo thành các vệt sáng xiên (Anime God Rays / Light Shafts), vừa tạo vẻ đẹp huyền bí vừa là "đèn rọi" định hướng cho các lối mòn trong rừng.
2. **Thị Trấn Tiền Đồn Tolbana (Tolbana Foothills Town)**:
   - **Vị trí**: Nằm áp sát vách đá sườn núi phía Đông Bắc ($X = +520, Z = -280, Y = +110$).
   - **Cấu trúc Không gian**: Thị trấn xây dựng theo mô hình bậc thang đá bám vào vách núi (Amphitheater stepped architecture).
   - **Quảng trường Hội thảo Boss (Boss Raid Briefing Amphitheater)**: Đấu trường tròn bằng đá ngoài trời nơi người chơi tham gia cuộc họp lập đội diệt Boss của hiệp sĩ Diabel.
3. **Hang Động Đá Ẩn (Hidden Grottos & Resource Nodes)**:
   - *Hang Tinh Thể Xanh (Azure Grotto)*: Cửa hang bị rễ cây cổ thụ và dây leo che khuất $60\%$. Bên trong là hồ nước ngầm phát quang sinh học (bioluminescent flora) và quặng sắt/tinh thể dùng để rèn cường hóa trang bị.
   - *Hầm Phục Kích Kobold (Kobold Scout Den)*: Hang cụt chứa bầy quái Kobold Trinh Sát canh giữ rương báu (Treasure Chest).

---

### Khu Vực 4: Tháp Mê Cung Tầng 1 (Labyrinth Tower of Floor 1)
- **Tọa độ trung tâm**: $X \in [-300, +300]$, $Z \in [-1000, -650]$, $Y \in [+120, +320]$.
- **Diện tích mặt bằng**: Chân tháp $\approx 0.25\text{ km}^2$; chiều cao thẳng đứng $+200\text{ m}$.
- **Bản chất Gameplay**: Dungeon cao trào cuối tầng (End-of-Floor Climax), áp lực sống còn cực đại, cấu trúc đa tầng thẳng đứng.

```
       [ĐỈNH THÁP: CAO ĐỘ +300m]
      ┌─────────────────────────┐
      │  PHÒNG BOSS TẦNG 1      │
      │  (Illfang the Kobold    │  <-- [Cửa vòm sắt chạm khắc, Đấu trường 75x75m]
      │   Lord & 3 Hộ Vệ Sent.) │
      └────────────▲────────────┘
                   │ (Cầu thang xoắn ốc & Cầu đá hẹp qua vực sâu)
      ┌────────────┴────────────┐
      │  TẦNG MÊ CUNG HUYẾT CHIẾN│
      │  (Kobold Sentinels)     │  <-- [Cạm bẫy gai, Hành lang đá cổ, Cửa khóa]
      └────────────▲────────────┘
                   │
      ┌────────────┴────────────┐
      │  TIỀN SẢNH AN TOÀN       │
      │  (Safe Hub Antechamber) │  <-- [Pha lê dịch chuyển khẩn cấp, Cửa vào tháp]
      └────────────▲────────────┘
                   │
         [HẺM NÚI TỬ THẦN]
```

#### Các Thành Phần Cốt Lõi:
1. **Kiến Trúc Ngoại Thất Chân Tháp**:
   - Trụ tháp đá xám đen vân rune cổ có đường kính chân tháp $160\text{ m}$, sừng sững đâm thẳng từ mặt đất lên tiếp giáp với vòm Tầng 2.
   - Chân tháp được bao bọc bởi hẻm vực dốc đứng (chênh lệch độ cao $45\text{ m}$), chỉ có duy nhất một cây cầu đá nguyên khối bắc qua, buộc người chơi phải đi qua điểm thắt nút này.
2. **Tiền Sảnh Chân Tháp (Antechamber / Forward Safe Zone)**:
   - Nằm ngay sau cổng chính của tháp. Đây là vùng cấm combat cuối cùng trước khi leo tháp, trang bị đài dịch chuyển mini một chiều về Thị trấn Khởi đầu và các băng ghế đá hồi phục thể lực.
3. **Cấu Trúc Labyrinth Xoắn Ốc (Vertical Dungeon Levels)**:
   - Gồm 3 tầng nội vi kết nối bằng các đoạn dốc thoải và cầu thang đá vòng:
     - *Tầng Labyrinth 1*: Mạng lưới hành lang vuông vức, tường đá ẩm ướt rêu phong, quái vật tuần tra theo cặp.
     - *Tầng Labyrinth 2*: Khu vực cầu đá không có lan can vắt qua vực sâu hun hút, thử thách phản xạ tránh đòn đẩy ngã của quái vật.
     - *Tầng Labyrinth 3 (Hành lang Tiền Boss)*: Dãy đuốc lửa đỏ rực bốc cháy hai bên tường, không khí rung chuyển bởi tiếng gầm của Boss từ phía sau cánh cửa khổng lồ.
4. **Đại Điện Boss Tầng 1 (Floor 1 Boss Arena)**:
   - **Quy mô**: Phòng tròn đường kính $75\text{ m}$, trần vòm cao $35\text{ m}$.
   - **Kẻ Thù Thống Lĩnh**: **Illfang the Kobold Lord** (Thanh kiếm cong Talwar + Khiên chắn sừng, giai đoạn 2 chuyển sang thanh đại đao Nodachi) cùng 3 hộ vệ **Ruin Kobold Sentinels**.
   - **Cơ chế môi trường**: 4 cây cột đá chịu lực bố trí quanh phòng thi đấu. Người chơi có thể lợi dụng góc khuất của cột để che chắn các đòn quét diện rộng (AoE cleave) của Boss.

---

## 3. Tỉ Lệ Không Gian, Vận Tốc & Luồng Di Chuyển (Pacing & Navigation)

### 3.1. Thang Đo Di Chuyển (Locomotion Metrics)
Để cân bằng cảm giác quy mô thế giới mở mà không gây nhàm chán khi di chuyển, thông số vận tốc người chơi được thiết lập:

| Trạng Thái Di Chuyển | Vận Tốc ($m/s$) | Vận Tốc ($km/h$) | Tiêu Hao Thể Lực (Stamina) |
| :--- | :--- | :--- | :--- |
| **Đi bộ khám phá (Walk)** | $3.5\text{ m/s}$ | $12.6\text{ km/h}$ | $0\text{ pts/s}$ (Hồi phục thể lực) |
| **Chạy việt dã (Jog / Run)** | $6.0\text{ m/s}$ | $21.6\text{ km/h}$ | $0\text{ pts/s}$ (Vận tốc di chuyển mặc định) |
| **Nước rút (Sprint / Dash)** | $9.0\text{ m/s}$ | $32.4\text{ km/h}$ | $-15\text{ pts/s}$ (Duy trì tối đa 12 giây) |
| **Chiến đấu cơ động (Combat Pace)**| $4.8\text{ m/s}$ | $17.3\text{ km/h}$ | Tùy biến theo động tác vung kiếm/lướt |

### 3.2. Ma Trận Thời Gian Di Chuyển Giữa Các Khu Vực (Traversal Times)
*Giả định người chơi chạy việt dã liên tục ($6.0\text{ m/s}$) theo đường mòn thực tế (uốn lượn tỉ lệ $1.3\times$ đường chim bay):*

```
[Thị Trấn Khởi Đầu] ──(2.8 phút / 800m)──► [Cụm Cối Xay Gió]
        │                                         │
 (4.2 phút / 1200m)                        (3.5 phút / 1000m)
        │                                         │
        ▼                                         ▼
[Thị Trấn Tolbana]   ──(3.8 phút / 1100m)──► [Chân Tháp Mê Cung]
```

- **Xuyên suốt toàn bản đồ (Town of Beginnings $\rightarrow$ Labyrinth Tower)**:
  - Khoảng cách đường bộ quanh đồi và xuyên rừng: $\approx 2200\text{ m}$.
  - Thời gian chạy không dừng: **$\approx 6.1\text{ phút}$**.
  - Thời gian chơi thực tế (kết hợp combat, nhặt tài nguyên, nghỉ chân): **$22 - 35\text{ phút}$**.
  - Đây là "tỉ lệ vàng" cho trải nghiệm semi-open world: vừa đủ rộng để mang lại cảm giác hành trình sử thi (epic expedition), vừa đủ gọn để không làm loãng nhịp độ chơi game.

### 3.3. Nhịp Độ Trải Nghiệm (Pacing Loops)

```
[AN TOÀN TUYỆT ĐỐI]      [HỌC TẬP & THƯ THÁI]     [CĂNG THẲNG GIA TĂNG]     [ĐIỂM DỪNG CHÂN]     [CĂNG THẲNG CỰC ĐỘ]
  Thị trấn Khởi đầu   ──►    Bình nguyên cỏ    ──►     Rừng Mê Cung     ──► Thị trấn Tolbana ──►  Tháp Mê Cung & Boss
  (Safe Trading Hub)      (Mở rộng tầm nhìn)       (Tầm nhìn hẹp, quái đông)  (Chuẩn bị trang bị)   (Sinh tử nghẹt thở)
```

1. **Macro Loop (Hành trình xuyên Tầng 1)**:
   - **Nhịp thở 1 (Thư giãn / Khởi đầu)**: Thị trấn rực rỡ nắng vàng, âm nhạc êm dịu, không có nguy cơ sát thương.
   - **Nhịp thở 2 (Mở rộng / Háo hức)**: Bước qua cổng thành, chân trời bao la mở ra, đồi cỏ dập dờn theo gió, người chơi tự do thử nghiệm các đòn đánh cơ bản lên bầy lợn rừng.
   - **Nhịp thở 3 (Căng thẳng / Phòng thủ)**: Bước vào rừng Tolbana, cây cối che khuất bầu trời, âm thanh chim chóc nhường chỗ cho tiếng gầm gừ, quái vật tấn công bất ngờ.
   - **Nhịp thở 4 (Giải tỏa / Tập hợp)**: Đến Tolbana, gặp gỡ đồng đội, mua bình máu, cường hóa vũ khí.
   - **Nhịp thở 5 (Cao trào / Khắc nghiệt)**: Đột phá Tháp Mê Cung, đối đầu Illfang trong trận chiến nghẹt thở.

2. **Micro Loop (Vòng lặp 45 - 90 giây trên đường đi)**:
   - **Quan Sát (Spot)**: Người chơi đứng trên mỏm đồi nhìn thấy một tảng đá kỳ lạ hoặc đám hoa phát sáng cách đó $150\text{ m}$.
   - **Tiếp Cận & Đụng Độ (Engage)**: Di chuyển tới nơi thì gặp 1-2 quái vật canh giữ; kích hoạt trận đánh hành động ngắn.
   - **Chiến Lợi Phẩm (Reward)**: Hạ quái, thu thập thảo dược quý hoặc mở rương gỗ nhỏ.
   - **Tái Định Hướng (Reorient)**: Từ vị trí mới, ngước nhìn lên lại thấy cánh quạt cối xay gió hoặc đỉnh Tháp Mê Cung để chọn hướng đi tiếp theo.

### 3.4. Tuyến Đường Chính (Golden Path) & Các Tuyến Đường Phụ (Secondary Loops)
- **Tuyến đường huyết mạch (Golden Path)**:
  - Tuyến đường lát đá dăm và vệt mòn bánh xe rộng $4\text{ m}$ kết nối: *Cổng Bắc Thị Trấn $\rightarrow$ Cầu Suối Bình Nguyên $\rightarrow$ Cổng Phía Tây Rừng Tolbana $\rightarrow$ Đèo Đá Tolbana $\rightarrow$ Cầu Đá Chân Tháp Mê Cung*.
  - Dọc theo tuyến đường này luôn có các cọc tiêu đá gắn đèn tinh thể và mật độ quái vật được kiểm soát ở mức thấp để người chơi chạy nhiệm vụ chính tuyến không bị quấy rối liên tục.
- **Tuyến đường tắt & Vùng thưởng (Secondary Loops & Shortcuts)**:
  - *Lối mòn vách đá thảo nguyên*: Đi dọc theo vách núi phía Tây qua cụm Cối Xay Gió, đường đi gồ ghề hơn nhưng nhặt được nhiều rương báu và quặng rèn.
  - *Hẻm suối ngầm rừng Tolbana*: Lội dọc theo lòng suối cạn cắt thẳng qua khu rừng rậm, tránh được $70\%$ bầy quái Kobold nhưng phải vượt qua vách đá trơn trượt dốc $28^\circ$.

---

## 4. Độ Dốc Địa Hình & Quy Hoạch Điểm Mốc Không Phụ Thuộc Minimap (Landmarks & Sightlines)

### 4.1. Tiêu Chuẩn Kỹ Thuật Độ Dốc Địa Hình (Terrain Slope Matrix in Godot 4)

Trong Godot 4, module `NavigationServer3D` và hệ thống Physics CharacterBody3D yêu cầu thiết lập góc dốc nghiêm ngặt để đảm bảo nhân vật di chuyển tự nhiên và ngăn chặn bug kẹt va chạm:

| Góc Dốc Địa Hình | Phân Cấp Kỹ Thuật | Tác Động Vận Tốc & Gameplay | Cấu Hình Godot 4 (CharacterBody3D & NavMesh) |
| :--- | :--- | :--- | :--- |
| **$0^\circ - 15^\circ$** | **Thoải mái (Gentle / Flat)** | 100% tốc độ di chuyển; không gian chiến đấu tối ưu; khu vực dựng lều, chợ búa, tụ điểm NPC. | `floor_max_angle = deg_to_rad(45.0)`<br>`NavMesh.agent_max_slope = 45.0` |
| **$16^\circ - 28^\circ$** | **Dốc Đồi (Moderate Slope)** | Vận tốc chạy lên dốc giảm $20\%$, chạy xuống dốc tăng $10\%$. Không phù hợp để dàn trận đông quái vật. | Tự động kích hoạt blend animation chạy dốc người hơi ngả về trước. |
| **$29^\circ - 42^\circ$** | **Dốc Khó / Bậc Đá (Steep Scramble)** | Không thể chạy thẳng; nhân vật chuyển sang trạng thái leo chậm chạp hoặc trượt dần xuống chân dốc. Dùng cho lối tắt một chiều (One-way drops). | `NavMesh` vẫn bake được nếu có bậc đá ngắt nhịp (`agent_max_climb = 0.45m`). |
| **$> 42^\circ$** | **Vách Đá Đứng (Sheer Cliff / Impassable)** | **Rào cản tự nhiên tuyệt đối (Natural Soft Wall)**. Ngăn người chơi ra khỏi biên giới bản đồ mà không cần dùng tường vô hình (Invisible walls). | `NavMesh` tự động loại bỏ (không thể đi lại). Đóng vai trò làm vật che chắn GPU Occlusion Culling. |

```
    [ĐỘ DỐC ĐỊA HÌNH & TÁC ĐỘNG KHÔNG GIAN]

    90° ┼                                        │ VÁCH NÚI ĐỨNG (> 42°)
        │                                        │ Rào cản tự nhiên, Occlusion Box
    45° ┼────────────────────────────────────────┼ Ranh giới NavMesh cực hạn (45°)
        │                        ┌───────────────┤ DỐC TRƯỢT MỘT CHIỀU (29° - 42°)
    28° ┼────────────────────────┘               │ DỐC ĐỒI LEO NÚI (16° - 28°)
        │            ┌───────────────────────────┤
    15° ┼────────────┘                           │ MẶT PHẲNG CHIẾN ĐẤU & ĐƯỜNG MÒN (0° - 15°)
     0° ┴────────────────────────────────────────┴─────────────────────────────────►
```

### 4.2. Hệ Thống Điểm Mốc 3 Cấp Độ (Hierarchical Landmark System)

Để người chơi đắm chìm trong thế giới mà không phải dán mắt vào bản đồ góc màn hình (Minimap), hệ thống điểm mốc được quy hoạch theo 3 phân cấp tầm nhìn:

```
[CẤP 1: SƠ CẤP - TOÀN CỤC] ──► THÁP MÊ CUNG (+320m) & BẦU TRỜ TẦNG 2 (+350m)
                               (Luôn hiện diện trên đường chân trời, xác định Cực Bắc)
                                     │
[CẤP 2: THỨ CẤP - VÙNG]   ──► CỐI XAY GIÓ (Tây) | CUNG ĐIỆN HẮC THIẾT (Nam) | ĐỈNH TOLBANA (Đông)
                               (Nhận diện ngay phân vùng hiện tại chỉ bằng 1 cái xoay camera)
                                     │
[CẤP 3: CỤC BỘ - ĐIỂM ĐẾN]──► ĐÈN LỒNG CỔNG THÀNH | ĐÀI TẾ ĐÁ PHÁT SÁNG | CÂY CỔ THỤ MẸ
                               (Dẫn dắt trực tiếp từng ngã rẽ và lối vào hang động)
```

#### 1. Điểm Mốc Cấp 1 (Primary / Global Landmarks):
- **Tháp Mê Cung Khổng Lồ (Labyrinth Tower)**:
  - **Cao độ**: Đỉnh tháp chạm $+320\text{ m}$.
  - **Chức năng định hướng**: Luôn hiển thị trên đường chân trời bất kể người chơi đang ở đâu trên bản đồ (nhờ cấu hình `visibility_range_end = 0.0` - không bao giờ bị cull).
  - **Nguyên lý La Bàn Thị Giác**: Khi nhìn thấy Tháp Mê Cung ở trước mặt $\rightarrow$ Đang hướng về Cực Bắc; quay lưng lại với tháp $\rightarrow$ Đang hướng về Thị trấn Khởi đầu (Cực Nam).
- **Vòm Đáy Tầng 2 (Floor 2 Ceiling Plate)**:
  - Có dải hoa văn kim loại màu vàng phát quang xoay quanh trục thẳng đứng, ánh sáng phản chiếu xuống mặt hồ và đồng cỏ, cung cấp nguồn sáng thứ cấp dịu nhẹ.

#### 2. Điểm Mốc Cấp 2 (Secondary / Regional Landmarks):
- **Cung Điện Hắc Thiết (Black Iron Palace)**:
  - Kiến trúc đen tuyền khối hộp sừng sững cao $85\text{ m}$ tại Cực Nam, phân biệt rõ ràng với phong cách tự nhiên của rừng và đồi.
- **Dãy Cối Xay Gió Đồi Cao (Windmill Ridge)**:
  - 5 cối xay gió cao $45\text{ m}$ với cánh quạt xoay trên cao độ $+85\text{ m}$ phía Tây. Khi người chơi lạc trong rừng rậm hoặc lòng chảo, chỉ cần trèo lên gờ đá nhìn thấy cánh quạt là định vị ngay được sườn Tây.
- **Vách Núi Bậc Thang Tolbana (Tolbana Amphitheater Escarpment)**:
  - Vách đá sa thạch đỏ vàng cao $65\text{ m}$ phản chiếu ánh hoàng hôn rực rỡ, đánh dấu ranh giới phía Đông bản đồ.

#### 3. Điểm Mốc Cấp 3 (Tertiary / Local Landmarks):
- **Cột Mốc Chỉ Hướng Bằng Đá Tinh Thể (Aether Guide Monoliths)**:
  - Các trụ đá cổ khắc chữ Runes phát ánh sáng lam ngọc, đặt chính xác tại các ngã ba đường mòn xuyên rừng.
- **Cây Sồi Khổng Lồ Nghìn Năm (Elder Oak of the Glade)**:
  - Nằm ở trung tâm Rừng Mê Cung, tán xòe rộng $60\text{ m}$, là điểm mốc then chốt giúp người chơi biết mình đã vào đến lõi rừng chứ không bị lạc vòng quanh.

### 4.3. Kỹ Thuật Định Hướng & Dẫn Dắt Tầm Nhìn (Sightlines & Framing Principles)

1. **Nguyên lý "Weenie" của Walt Disney**:
   - Tháp Mê Cung được thiết kế đóng vai trò như "Tòa lâu đài Lọ Lem" - luôn có một phần kiến trúc vươn cao trên ngọn cây hoặc lọt qua khe giữa hai sườn đồi, tạo động lực vô thức thôi thúc người chơi tiến về phía trước.
2. **Kỹ thuật "Pinch and Reveal" (Thắt Nút và Mở Rộng Không Gian)**:
   - *Ứng dụng từ Cổng Thành ra Bình Nguyên*: Khi chạy trong đường hẻm thị trấn, hai bên là nhà cao tầng che khuất tầm nhìn (Pinch). Đến khi bước qua vòm Cổng Bắc hẹp, camera lập tức mở toang đường chân trời rộng ngút ngàn với đồng cỏ và dãy cối xay gió xa xa (Reveal), tạo cảm xúc choáng ngợp giải phóng thị giác.
   - *Ứng dụng từ Rừng Mê Cung đến Chân Tháp*: Đường đi trong rừng dày đặc cây cối u ám bỗng thắt lại tại một khe hẻm đá hẹp dốc $20^\circ$. Khi vượt qua khe đá, toàn bộ thân Tháp Mê Cung sừng sững chiếm trọn $80\%$ khung hình màn hình.
3. **Đường Dẫn Hướng Thị Giác Tự Nhiên (Leading Lines)**:
   - Dòng suối uốn lượn từ sườn núi phía Đông chảy dài về phía hồ nước phía Nam. Người chơi bị lạc trong sương mù chỉ cần đi xuôi theo dòng nước là sẽ tìm thấy lối về bến nước ven thành phố.
   - Các dải hoa dại màu cam đất mọc tự nhiên dọc theo rìa vệt mòn bánh xe, dẫn dắt ánh mắt người chơi một cách tự nhiên theo hướng đi an toàn.

---

## 5. Kiến Trúc Kỹ Thuật Godot 4 & Tối Ưu Hóa (Engine Architecture & Budgets)

### 5.1. Cấu Hình Terrain & Vật Liệu Đa Lớp (Heightmap & Splatmapping)
- **Độ phân giải Heightmap**: $2048 \times 2048\text{ pixels}$ (tương ứng tỉ lệ $1\text{ pixel} \approx 0.976\text{ mét}$ trên thực địa $2\times 2\text{ km}$).
- **Định dạng độ cao**: 16-bit Grayscale RAW/PNG (đảm bảo chuyển dịch độ cao mịn màng, không bị hiện tượng giật nấc thang bậc tam cấp).
- **Vật liệu địa hình 4 lớp (Splatmap Texture Array)**:
  1. *Layer 0 (Base)*: Cỏ Thảo Nguyên Xanh Anime (`res://assets/terrain/grass_albedo.png`).
  2. *Layer 1 (Paths)*: Đất Đỏ Nâu Đường Mòn (`res://assets/terrain/dirt_albedo.png`).
  3. *Layer 2 (Cliffs)*: Đá Núi Xám Đứng Triplanar (`res://assets/terrain/rock_cliff_albedo.png`).
  4. *Layer 3 (Urban)*: Đá Lát Quảng Trường Thị Trấn (`res://assets/terrain/cobble_albedo.png`).
- Tự động hòa trộn bằng độ dốc (Slope Auto-blending): Mọi bề mặt có góc dốc $> 30^\circ$ tự động chuyển sang *Layer 2 (Đá Núi)* bằng hàm chiếu `world_normal.y` trong shader địa hình.

### 5.2. Cấu Hình NavigationServer3D & Baking NavMesh
Bản đồ $4\text{ km}^2$ không thể bake trên một NavigationRegion3D đơn lẻ vì sẽ làm tràn RAM trình biên dịch.
- **Chia nhỏ NavMesh theo Chunk**: Mỗi Macro-Chunk ($500\text{ m} \times 500\text{ m}$) sở hữu một `NavigationRegion3D` riêng biệt.
- **Thông số Baking chuẩn hóa**:
  ```gdscript
  var nav_mesh: NavigationMesh = NavigationMesh.new()
  nav_mesh.cell_size = 0.3        # Độ mịn mắt lưới 30cm
  nav_mesh.cell_height = 0.2      # Bước nhảy cao độ 20cm
  nav_mesh.agent_radius = 0.45    # Bán kính va chạm nhân vật
  nav_mesh.agent_height = 1.8     # Chiều cao người chơi
  nav_mesh.agent_max_climb = 0.4  # Bước bậc tam cấp tối đa
  nav_mesh.agent_max_slope = 42.0 # Độ dốc leo tối đa 42 độ
  nav_mesh.filter_baking_use_geometry = NavigationMesh.PARSING_GEOMETRY_BOTH
  nav_mesh.filter_collision_mask = 1 # Chỉ bake với StaticBody3D địa hình và tường
  ```
- **Tự động khâu mép (Edge Stitching)**: Các `NavigationRegion3D` cạnh nhau tự động kết nối thông qua tính năng `edge_connection_margin = 0.5m` của Godot 4, cho phép AI quái vật rượt đuổi người chơi xuyên biên giới các chunk mà không bị đứng khựng lại.

### 5.3. Ngân Sách Hiệu Năng & Mục Tiêu Kỹ Thuật (Performance Budget)
Để đảm bảo trải nghiệm 60+ FPS ổn định trên cấu hình phần cứng phổ thông (NVIDIA GeForce GTX 1650 / RTX 3050):

| Tiêu Chí Kỹ Thuật | Ngân Sách Tối Đa (Budget) | Giải Pháp Thực Thi Trong Godot 4 |
| :--- | :--- | :--- |
| **Draw Calls (Số lệnh vẽ)** | $\le 750\text{ calls / frame}$ | MultiMeshInstance3D cho cây xanh, đá cuội, hàng rào; Texture Atlasing; Visibility Range. |
| **Tổng số Tam Giác (Triangles)** | $\le 1.800.000\text{ tris}$ | Mesh LOD tự động sinh bởi Godot khi import glTF; Inverted Hull Outline chỉ bật ở LOD 0 ($< 40\text{ m}$). |
| **Dung Lượng Bộ Nhớ VRAM** | $\le 3.5\text{ GB}$ VRAM | Nén texture dạng VRAM Compressed (BC7 trên Windows Desktop); Chia sẻ Material/Shader cache. |
| **Băng Thông Physics Engine** | $\le 60\text{ bodies hoạt động}$ | Godot Jolt Physics; Tắt physics process của quái vật ngoài bán kính $80\text{ m}$ bằng `VisibleOnScreenNotifier3D`. |
| **Occlusion Culling** | $40\% - 65\%$ số mesh bị cull | Bake `BoxOccluder3D` dày bên trong vách tường thành thị trấn và các dãy núi ngăn cách. |

---

## 6. Lộ Trình Triển Khai Thực Thi Cho Technical Level Designer

```
GIAI ĐOẠN 1: BLOCKOUT              GIAI ĐOẠN 2: STREAMING & NAV        GIAI ĐOẠN 3: ART & POLISH
[Tuần 1 - 2]                       [Tuần 3 - 4]                        [Tuần 5 - 6]
- Dựng Graybox địa hình 2x2km      - Cấu hình 16 Macro-Chunks          - Đắp chi tiết Foliage Anime
- Cắm cọc 4 Landmark chính         - Bake NavMesh từng chunk           - Thêm hiệu ứng sương mù Fog
- Test vận tốc & thời gian chạy    - Tích hợp Jolt Physics             - Tối ưu Draw Call & Occlusion
```

1. **Bước 1 (Blockout & Graybox Geometry)**: Dựng mô hình địa hình khối xám low-poly quy mô $2\times 2\text{ km}$. Đặt các hình khối lập phương/hình trụ tượng trưng cho Tháp Mê Cung, Cung Điện Hắc Thiết và Cối Xay Gió. Cho nhân vật chạy thử để đo chính xác thời gian và độ dốc.
2. **Bước 2 (Splines & Navigation Baking)**: Vẽ các đường cong Spline định hình Golden Path và các đường mòn. Phân chia 16 chunk và kiểm tra đường khâu NavigationRegion3D.
3. **Bước 3 (Asset Population & MultiMesh Pass)**: Rải thảm thực vật bằng MultiMeshInstance3D, phủ shader Anime Cel-shading và Inverted Hull Outline.
4. **Bước 4 (Lighting, Sightline Framing & Occlusion Bake)**: Đặt DirectionalLight3D mặt trời, tinh chỉnh Volumetric Fog và bake Occlusion Culling trên tường thành và thung lũng.
5. **Bước 5 (Stress Test & Gameplay Balancing)**: Đưa bầy quái Frenzy Boar và Kobold vào vị trí, kiểm tra hành vi truy đuổi qua các địa hình dốc và tối ưu hóa hiệu năng duy trì trên 60 FPS.

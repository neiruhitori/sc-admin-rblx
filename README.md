# Mount Skuy Admin Script + Violence District

Admin script untuk Roblox dengan fitur lengkap + Violence District module optional.

## 📦 Struktur File

```
📁 Mount Skuy/
├── LoaderScript.lua          # ⚙️ WAJIB - Admin commands
├── vd.lua                     # ⚡ OPTIONAL - Violence District features  
├── EXECUTOR_TEMPLATE.lua      # 📋 Template untuk executor
└── README.md                  # 📖 File ini
```

## 🚀 Cara Pakai

### Opsi 1: Load Keduanya (Recommended) ✅

```lua
-- Load admin commands (WAJIB)
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/LoaderScript.lua"))()

-- Load Violence District (OPTIONAL)
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/vd.lua"))()
```

### Opsi 2: Load Hanya Admin Commands

```lua
-- Hanya load admin commands, skip Violence District
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/LoaderScript.lua"))()
```

### Opsi 3: Gunakan Template

1. Buka `EXECUTOR_TEMPLATE.lua`
2. Ganti URL dengan GitHub kamu
3. Comment/uncomment sesuai kebutuhan
4. Copy semua code
5. Paste di executor dan execute

## ⚙️ Fitur LoaderScript.lua

Admin commands dengan UI panel:

- ✈️ **Fly** - `;fly` - Terbang dengan WASD + Space + Shift
- 🏃 **Speed** - `;speed [number]` - Ubah kecepatan jalan (default 16)
- 🦘 **Jump Power** - `;jp [number]` - Ubah tinggi lompat
- ∞ **Infinite Jump** - `;infinitejump` - Hold SPACE untuk terbang
- 🛡️ **God Mode** - `;god` - True invincibility (no damage)
- 📍 **Goto Player** - `;goto` - Teleport ke player (pilih di UI)
- 🔄 **Respawn** - `;respawn` - Reset character
- ⏰ **Anti-AFK** - `;antiafk` - Aktif 24/7, no auto-kick
- 🥔 **Potato Mode** - `UI Button` - FPS boost (click ON/OFF di panel)

**UI Features:**
- Tombol ⚙️ floating di layar
- Toggle buttons dengan status ON/OFF
- Player selection dropdown
- Draggable panel

**Potato Mode Details (UI Button - TOGGLE):**
- 🥔 **LoaderScript.lua**: Click button di admin panel (Utility tab)
- 🥔 **vd.lua**: Press N key (keyboard shortcut)
- 🟢 **ON**: Optimize parts, clear water, disable effects, continuous FPS boost
- 🔴 **OFF**: Stop water clearing loop (materials/shadows stay until respawn)
- 🥔 Optimize semua parts: SmoothPlastic material, no shadows
- 💧 Clear terrain water: Continuous clearing setiap frame (while ON)
- 💡 Disable lighting: Flat appearance, no shadows
- ✨ Disable particles: No smoke, fire, sparkles
- 🌊 Hide water parts: Transparency 100%, no collision
- 📊 **Best for**: Low-end PC, boost FPS 2-3x
- ⚠️ **Different controls**: LoaderScript=UI button, vd.lua=N key

## ⚡ Fitur Violence District (vd.lua)

Module terpisah dengan advanced features:

| Fitur | Shortcut | Deskripsi |
|-------|----------|-----------|
| 🖱️ Cursor Unlock | `K` | Unlock mouse cursor |
| 👁️ ESP Wallhack | `J` | See players through walls + name tags |
| 🪤 Pallet ESP | `J` | Highlight trap pallets (orange) |
| 🎯 Crosshair | `H` | Range marks: 30m/60m/90m+ |
| 📷 Camera Zoom | `G` | Free scroll zoom + look around |
| ⚡ Speed Boost | `L` | Speed 20 + Auto hold Shift |
| 🥔 Potato Mode | `N` | FPS boost (keyboard only, no UI) |
**UI Features:**
- Tombol ⚡ floating di layar (biru)
- Feature cards dengan status ON/OFF
- Keyboard shortcuts untuk quick toggle
- Draggable panel dan icon

## 🔧 Setup GitHub

1. **Upload files ke GitHub:**
   ```
   LoaderScript.lua  ← WAJIB
   vd.lua            ← OPTIONAL
   EXECUTOR_TEMPLATE.lua
   ```

2. **Dapatkan Raw URL:**
   - Buka file di GitHub
   - Klik tombol "Raw" (pojok kanan atas)
   - Copy URL dari browser

3. **Format URL yang BENAR:**
   ```
   ✅ https://raw.githubusercontent.com/username/repo/main/LoaderScript.lua
   ❌ https://github.com/username/repo/blob/main/LoaderScript.lua
   ```

4. **Ganti URL di EXECUTOR_TEMPLATE.lua** dengan URL kamu

## ⚠️ PENTING - Urutan Loading

**Violence District HARUS di-load SETELAH LoaderScript.lua!**

✅ **BENAR:**
```lua
loadstring(game:HttpGet("URL/LoaderScript.lua"))()
loadstring(game:HttpGet("URL/vd.lua"))()  -- Load setelah LoaderScript
```

❌ **SALAH:**
```lua
loadstring(game:HttpGet("URL/vd.lua"))()  -- ERROR! AdminGUI belum ada
loadstring(game:HttpGet("URL/LoaderScript.lua"))()
```

**Kenapa?**
- `vd.lua` butuh `_G.AdminGUI` dari LoaderScript untuk notifications
- LoaderScript export `_G.AdminGUI` yang dipakai vd.lua

## 🎮 Cara Pakai di Game

### Admin Commands:
1. Execute LoaderScript.lua
2. Akan muncul tombol ⚙️ di layar
3. Klik untuk buka panel
4. Atau ketik command di chat: `;fly`, `;speed 100`, dll

### Violence District:
1. Execute vd.lua (setelah LoaderScript)
2. Akan muncul tombol ⚡ di layar
3. Klik untuk buka panel VD
4. Atau tekan keyboard shortcuts: K, J, H, G, L

### Tips:
- Drag floating buttons untuk reposition
- Drag title bar untuk move panel
- Semua feature bisa di-toggle ON/OFF
- Status tersimpan selama session

## 🐛 Troubleshooting

**Script error/crash:**
- Pastikan URL adalah raw.githubusercontent.com
- Jangan pakai URL dengan `/blob/`
- Load LoaderScript.lua dulu sebelum vd.lua

**Violence District tidak muncul:**
- Cek apakah LoaderScript sudah di-load dulu
- Pastikan vd.lua di-load setelahnya
- Cek console untuk error message

**ESP tidak work:**
- Toggle OFF lalu ON lagi (tekan J 2x)
- Cek apakah ada players/objects di map
- Pallet ESP butuh object bernama "pallet" di workspace

**Features tidak work after respawn:**
- Auto-reapply: Fly, Speed, Camera Zoom
- Manual toggle lagi: ESP, Crosshair
- Anti-AFK tetap aktif selamanya

## 📝 Changelog

### v4.7 - Potato Mode UI Control
- ✅ LoaderScript: Potato Mode sekarang UI button (bukan keyboard N)
- ✅ Click button "Potato Mode" di Utility tab untuk toggle ON/OFF
- ✅ Status indicator: ON (hijau) / OFF (abu-abu)
- ✅ Removed keyboard N binding dari LoaderScript (conflict prevention)
- ✅ vd.lua: Tetap pakai N key (no change, keyboard only)
- ✅ Different controls: Admin=UI button, VD=N key
- ✅ PlayerStatuses tracking untuk potato mode state
- ✅ Visual feedback: Button color changes based on status

### v4.6 - Potato Mode Toggle & VD Integration
- ✅ Potato Mode sekarang TOGGLE ON/OFF (bukan one-time activation)
- ✅ Press N: Toggle potato mode (ON = optimize, OFF = stop water loop)
- ✅ Potato Mode tersedia di VD (vd.lua) - SAME implementation
- ✅ Both LoaderScript & vd.lua dapat toggle potato mode independently
- ✅ DisablePotato function: Stop water clearing loop saat OFF
- ✅ Visual feedback: "POTATO MODE ON" atau "POTATO MODE OFF"
- ✅ Documentation updated: EXECUTOR_TEMPLATE.lua & README.md

### v4.5 - Potato Mode Fix & Admin Panel Fix
- ✅ FIXED: Admin command buttons tidak bisa diklik (Modal property removed)
- ✅ FIXED: Potato Mode (N key) tidak terdokumentasi - sekarang tercantum
- ✅ Potato Mode features: Parts optimization, water clearing, lighting disable
- ✅ ZIndex hierarchy adjusted: mainFrame(10), dropdown(100), buttons(101)
- ✅ Improved notification message for Potato Mode activation
- ✅ Full documentation added for N key feature in template & README

### v4.4 - Dropdown Player Selection Fix
- ✅ Fixed click detection issue: Modal=true untuk prevent click-through
- ✅ Active=true untuk proper input handling
- ✅ ZIndex increased: 200→250 (container), 201→251 (buttons)
- ✅ Added debounce (0.1s) untuk prevent rapid clicking conflicts
- ✅ Visual feedback: Flash green saat berhasil select player
- ✅ BorderSizePixel: 1→2 untuk area click yang lebih besar
- ✅ ScrollBar lebih visible (thickness 6→8, colored blue)
- ✅ Dropdown sekarang responsive dan reliable!

### v4.3 - Notification UI Improvements
- ✅ Notification text size increased: 14 → 18 (lebih mudah dibaca)
- ✅ Font upgraded: Gotham → GothamBold (lebih tebal dan jelas)
- ✅ Success color: hijau neon (0,255,0) → hijau soft (46,204,113)
- ✅ Error color: merah terang (255,0,0) → merah soft (231,76,60)
- ✅ Added text stroke (outline hitam) untuk kontras maksimal
- ✅ Text sekarang sangat jelas dibaca di background apapun

### v4.2 - Violence District Separated
- ✅ Violence District dijadikan module terpisah (vd.lua)
- ✅ LoaderScript.lua fokus admin commands
- ✅ EXECUTOR_TEMPLATE.lua dengan penjelasan jelas
- ✅ Optional loading untuk flexibility

### v4.1 - Player List Fix
- ✅ Player list position adjusted (15px gap)
- ✅ Max height 300px untuk dropdown
- ✅ Better UI spacing

### v4.0 - Initial Release
- ✅ All admin commands
- ✅ Violence District features
- ✅ Modern UI design

## 👨‍💻 Credits

**By:** NB - Nobody Comunity  
**Discord:** https://discord.gg/xHrJaSgy  
**Version:** v4.7 - Potato UI Control

## 📜 License

Public access - Free to use!  
No admin check required, anyone can use all features.

---

**⚠️ Disclaimer:** Use at your own risk. This is for educational purposes.

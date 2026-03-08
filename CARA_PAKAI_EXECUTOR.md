# 🚀 Cara Menggunakan Script Admin di Game Lain

## 📋 Langkah-Langkah

### 1. Upload ke GitHub

1. **Buat Repository Baru di GitHub**
   - Pergi ke https://github.com
   - Login ke akun kamu
   - Klik tombol "New" atau "New repository"
   - Beri nama (contoh: `roblox-admin-script`)
   - Pilih "Public" (harus public agar bisa diakses)
   - Klik "Create repository"

2. **Upload File LoaderScript.lua**
   - Di repository yang baru dibuat, klik "Add file" > "Upload files"
   - Drag and drop file `LoaderScript.lua` atau klik "choose your files"
   - Klik "Commit changes"

3. **Dapatkan Raw URL**
   - Buka file `LoaderScript.lua` di GitHub
   - Klik tombol "Raw" (pojok kanan atas)
   - Copy URL dari browser (contoh: `https://raw.githubusercontent.com/username/repo/main/LoaderScript.lua`)

### 2. Edit Username Admin

Sebelum upload ke GitHub, **PENTING**:

1. Buka file `LoaderScript.lua`
2. Cari bagian ini (sekitar baris 18-20):
   ```lua
   AdminConfig.Admins = {
       "Danielle_0021", -- Ganti dengan username Roblox kamu
   }
   ```
3. **Ganti `"Danielle_0021"` dengan username Roblox kamu!**
4. Kamu bisa tambahkan lebih banyak admin:
   ```lua
   AdminConfig.Admins = {
       "UsernameKamu",
       "TemanKamu",
       [1234567890] = true, -- Atau gunakan UserId
   }
   ```

### 3. Cara Pakai di Executor

1. Buka Roblox game apapun yang kamu mau
2. Buka executor kamu (Synapse, KRNL, Fluxus, dll)
3. Paste code ini di executor:
   ```lua
   loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/REPO/main/LoaderScript.lua"))()
   ```
   **Ganti URL dengan Raw URL kamu dari langkah 1!**

4. Klik Execute/Inject
5. Done! ✅

## 🎮 Cara Menggunakan Admin Panel

### Membuka Panel

- Klik tombol **⚙️** (floating button) di layar
- Atau ketik command di chat dengan prefix `;`

### Fitur yang Tersedia (Client-Side)

#### ⚡ Character Mods
- **Speed** - Ubah kecepatan jalan
- **Jump Power** - Ubah power lompat  
- **God Mode** - Tidak bisa mati
- **Ungod** - Matikan god mode
- **Invisible** - Jadi tidak terlihat
- **Visible** - Jadi terlihat lagi

#### ✈️ Flying
- **Enable Fly** - Terbang dengan WASD, Space (naik), Shift (turun)
- **Disable Fly** - Matikan fly mode

#### 🔧 Other
- **Reset Character** - Reset ke normal (speed 16, jp 50, dll)
- **Respawn** - Respawn character kamu
- **Anti-AFK** - Tidak akan di-kick karena AFK

### Command di Chat

Ketik di chat dengan prefix `;`:

```
;fly              - Enable flying
;unfly            - Disable flying
;speed 100        - Set speed ke 100
;jp 100           - Set jump power ke 100
;god              - Enable god mode
;ungod            - Disable god mode
;invis            - Invisible
;vis              - Visible
;reset            - Reset character
;respawn          - Respawn
;antiafk          - Toggle anti-AFK
```

## ⚠️ PENTING - Keterbatasan Client-Side

Script ini **CLIENT-SIDE ONLY**, artinya:

✅ **Yang Bisa:**
- Fly (hanya kamu yang lihat)
- Speed boost (hanya kamu yang lihat)
- Jump power (hanya kamu yang lihat)
- God mode (hanya di client kamu)
- Invisible (hanya di device kamu)
- Anti-AFK

❌ **Yang Tidak Bisa:**
- Kill player lain
- Kick player
- Teleport ke player lain (tergantung game)
- Bring player
- Commands yang mempengaruhi player lain

**Kenapa?** Karena ini client-side script, tidak ada server-side backend. Jadi hanya mempengaruhi client kamu saja.

## 🔧 Tips & Troubleshooting

### Script Tidak Jalan?

1. **Pastikan URL benar**
   - Harus raw.githubusercontent.com
   - Harus public repository

2. **Pastikan username admin benar**
   - Cek lagi di `AdminConfig.Admins`
   - Case sensitive! `Username` ≠ `username`

3. **Executor tidak support?**
   - Coba executor lain
   - Pastikan game support executor (bukan mobile-only game)

### Cara Update Script

1. Edit file di GitHub langsung
2. Klik "Edit" (icon pensil)
3. Edit code
4. Klik "Commit changes"
5. Execute ulang di executor (akan load versi terbaru)

## 🎯 Contoh Lengkap

Misalnya username Roblox kamu: **SkuyGaming123**

1. Edit `LoaderScript.lua`:
   ```lua
   AdminConfig.Admins = {
       "SkuyGaming123",
   }
   ```

2. Upload ke GitHub repo: `my-roblox-admin`

3. Raw URL jadi: 
   ```
   https://raw.githubusercontent.com/namagithubmu/my-roblox-admin/main/LoaderScript.lua
   ```

4. Di executor:
   ```lua
   loadstring(game:HttpGet("https://raw.githubusercontent.com/namagithubmu/my-roblox-admin/main/LoaderScript.lua"))()
   ```

## 📝 Catatan

- Script ini aman digunakan (tidak ada backdoor)
- Script ini gratis dan open source
- Gunakan dengan bijak!
- Jangan spam di game orang lain
- Kalo ada bug, edit code di GitHub dan commit

## 💡 Fitur Tambahan

- **Draggable UI** - Bisa di-drag floating button dan main panel
- **Modern Design** - UI dark theme yang nyaman
- **Smooth Animations** - Animasi yang smooth
- **Input Dialog** - Dialog untuk input nilai (speed, jp)
- **Notifications** - Notifikasi untuk setiap action

---

**Happy Gaming! 🎮**

*Script by: Mount Skuy Admin System*

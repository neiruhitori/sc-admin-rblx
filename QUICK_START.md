# ⚡ Quick Start - Admin Script Executor

## 🎯 3 Langkah Mudah

### 1️⃣ Edit Username (WAJIB!)
Buka `LoaderScript.lua`, cari baris ini:
```lua
AdminConfig.Admins = {
    "Danielle_0021", -- GANTI INI!
}
```
**Ganti dengan username Roblox kamu!**

### 2️⃣ Upload ke GitHub
1. Buat repository public di GitHub
2. Upload file `LoaderScript.lua`
3. Klik file > Klik "Raw" > Copy URL

### 3️⃣ Execute di Game
Di executor, paste:
```lua
loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()
```

## 📌 Contoh URL yang Benar
```
https://raw.githubusercontent.com/username/repo/main/LoaderScript.lua
```
**Harus: **
- ✅ `raw.githubusercontent.com` (bukan github.com biasa)
- ✅ Repository public
- ✅ Path file benar

## 🎮 Setelah Execute

1. Klik tombol **⚙️** yang muncul di layar
2. Pilih command yang mau dipakai
3. Atau ketik di chat: `;fly`, `;speed 100`, dll

## ⚠️ Catatan Penting

- ✅ Berfungsi di **semua game** (client-side)
- ✅ Fitur: Fly, Speed, JP, God Mode, Invisible, Anti-AFK
- ❌ Tidak bisa: Kill/Kick player lain (butuh server-side)
- ⚡ Script sangat ringan dan cepat

## 🔧 Commands Cepat

```
;fly         - Terbang (WASD untuk gerak)
;speed 100   - Kecepatan 100
;jp 100      - Jump power 100
;god         - God mode ON
;invis       - Invisible
;reset       - Reset ke normal
;antiafk     - Anti-AFK toggle
```

---

**Need help?** Baca `CARA_PAKAI_EXECUTOR.md` untuk panduan lengkap!

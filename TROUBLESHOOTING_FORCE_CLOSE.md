# 🔴 TROUBLESHOOTING: Roblox Force Close / Crash

## ⚠️ Masalah Utama: URL SALAH!

### ❌ Yang Kamu Pakai (SALAH):
```
https://github.com/neiruhitori/sc-admin-rblx/blob/main/LoaderScript.lua
```

### ✅ Yang Harus Dipakai (BENAR):
```
https://raw.githubusercontent.com/neiruhitori/sc-admin-rblx/main/LoaderScript.lua
```

---

## 🤔 Kenapa Crash/Force Close?

Ketika kamu pakai URL GitHub biasa (yang ada `/blob/`):

1. **URL GitHub biasa** → Halaman HTML (bukan file Lua)
2. **game:HttpGet()** → Download HTML
3. **loadstring()** → Coba parse HTML sebagai Lua
4. **ERROR** → Syntax error / parsing failed
5. **CRASH** → Roblox force close! 💥

### Visual Perbedaan:

```
URL BIASA (Ada /blob/):
https://github.com/user/repo/blob/main/file.lua
└─ Ini halaman WEB dengan button, navbar, dll (HTML)

RAW URL (Tidak ada /blob/):
https://raw.githubusercontent.com/user/repo/main/file.lua
└─ Ini ISI FILE langsung (pure Lua code)
```

---

## ✅ Cara Dapat RAW URL yang Benar

### Method 1: Klik Tombol Raw (RECOMMENDED)
1. Buka file di GitHub (LoaderScript.lua)
2. Lihat pojok kanan atas
3. Klik tombol **"Raw"**
4. Browser akan redirect ke URL raw
5. **Copy URL dari address bar**
6. Done! ✅

### Method 2: Manual Edit URL
Kalau udah terlanjur copy URL biasa, tinggal edit:

**From:**
```
https://github.com/neiruhitori/sc-admin-rblx/blob/main/LoaderScript.lua
```

**To:**
1. Ganti `github.com` → `raw.githubusercontent.com`
2. Hapus `/blob/`

```
https://raw.githubusercontent.com/neiruhitori/sc-admin-rblx/main/LoaderScript.lua
```

---

## 🎯 Cara Pakai (Step by Step)

### Di GitHub:
1. Buka repository kamu: `https://github.com/neiruhitori/sc-admin-rblx`
2. Klik file: `LoaderScript.lua`
3. Klik tombol: **"Raw"** (pojok kanan atas, di samping Edit)
4. Copy URL dari browser (HARUS: `raw.githubusercontent.com`)

### Di Executor:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/neiruhitori/sc-admin-rblx/main/LoaderScript.lua"))()
```

### Hasilnya:
- ⚙️ Muncul tombol floating di layar
- ✅ Print message di console: "Admin Script Loaded!"
- 🎮 Klik tombol untuk buka panel

---

## 🔍 Cara Check URL Kamu Benar atau Salah

### Ciri-ciri URL BENAR ✅:
- ✅ Ada kata `raw.githubusercontent.com`
- ✅ TIDAK ADA kata `/blob/`
- ✅ Format: `https://raw.githubusercontent.com/USER/REPO/BRANCH/FILE.lua`

### Ciri-ciri URL SALAH ❌:
- ❌ Ada kata `github.com` (tanpa raw)
- ❌ Ada kata `/blob/`
- ❌ Format: `https://github.com/USER/REPO/blob/BRANCH/FILE.lua`

---

## 🛠️ Troubleshooting Lainnya

### Masih Crash Setelah Pakai Raw URL?

1. **Check Username Admin**
   - Buka file `LoaderScript.lua` di GitHub
   - Edit baris 20-22, pastikan username Roblox kamu ada di list
   - Commit changes
   - Execute ulang (akan load versi terbaru)

2. **Check Executor**
   - Coba executor lain (Synapse, KRNL, Fluxus, dll)
   - Beberapa game punya anti-cheat yang block executor
   - Coba di game lain dulu untuk test

3. **Check Internet**
   - Pastikan internet stabil
   - Coba reload game
   - Coba execute ulang

### Error "HTTP 404" atau "Failed to load"?

- Repository kamu harus **PUBLIC**, bukan private
- Cek nama file, harus exact match: `LoaderScript.lua`
- Cek nama branch, biasanya `main` atau `master`

### Script Load Tapi Tidak Ada Tombol?

- Kamu bukan admin! Check username di `AdminConfig.Admins`
- Check output console (F9) untuk error message

---

## 📝 Checklist Sebelum Execute

- [ ] URL pakai `raw.githubusercontent.com`
- [ ] URL TIDAK ADA `/blob/`
- [ ] Repository public
- [ ] Username admin sudah di-set di file
- [ ] File bernama `LoaderScript.lua` (exact, case-sensitive)
- [ ] Internet stabil

---

## 💡 Contoh Lengkap (Your Case)

### Repository Info:
- Username: `neiruhitori`
- Repo: `sc-admin-rblx`
- Branch: `main`
- File: `LoaderScript.lua`

### URL yang Benar:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/neiruhitori/sc-admin-rblx/main/LoaderScript.lua"))()
```

### Link Test (Buka di Browser):
Buka ini di browser: https://raw.githubusercontent.com/neiruhitori/sc-admin-rblx/main/LoaderScript.lua

**Harusnya:**
- Browser langsung download/show Lua code
- Lihat baris pertama: `--[[ ... ADMIN SCRIPT LOADER ...`

**Kalau malah:**
- Show error 404 → Check repo public atau tidak
- Show HTML page → URL salah, bukan raw URL

---

## ⚡ Quick Fix untuk Kamu

Copy paste ini langsung ke executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/neiruhitori/sc-admin-rblx/main/LoaderScript.lua"))()
```

Kalau masih crash/error, DM saya atau create issue di GitHub dengan:
1. Screenshot error (kalau ada)
2. Executor yang dipakai
3. Game yang di-test
4. Output console (F9)

---

**Good luck! 🚀**

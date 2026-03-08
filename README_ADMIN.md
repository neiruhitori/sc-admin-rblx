# Admin Script untuk Roblox

Script admin lengkap yang bisa digunakan di map manapun!

## 🚀 Cara Menggunakan

### 1. Setup Admin
Buka file `src/shared/AdminConfig.luau` dan tambahkan username Roblox kamu ke daftar admin:

```lua
AdminConfig.Admins = {
    "UsernameKamu", -- Ganti dengan username Roblox kamu
    "TemanKamu",
    -- Tambahkan admin lain di sini
}
```

### 2. Publish ke Roblox
1. Buka Roblox Studio
2. Install Rojo (jika belum): https://rojo.space/
3. Run command: `rojo serve`
4. Di Roblox Studio, klik "Connect" di plugin Rojo
5. Script akan otomatis sync ke game kamu

### 3. Testing
### 3. Menggunakan Admin Panel
1. Klik "Play" di Roblox Studio
2. **Klik icon floating button ⚙️** (di kanan layar) untuk membuka Admin Panel
3. Pilih target player dari dropdown (atau pilih "Me (Self)")
4. **Klik button command** yang ingin digunakan
5. Untuk command yang perlu input (speed, jp, announce), akan muncul dialog input

### 4. Kontrol Icon Button
- **Klik icon** untuk membuka/tutup panel
- **Drag icon** untuk memindahkan posisinya ke mana saja di layar

## 📋 Daftar Commands

**⚠️ Tidak perlu ketik manual lagi! Semua command tersedia sebagai BUTTON di dalam panel.**

Cara pakai:
1. Klik icon ⚙️ untuk buka panel
2. Pilih target player
3. Klik button command yang diinginkan

### 👥 Player Control
- **💀 Kill** - Matikan player
- **🚪 Kick** - Kick player dari game (akan muncul dialog untuk reason)
- **🔄 Respawn** - Respawn player
- **🧊 Freeze** - Freeze player (tidak bisa bergerak)
- **🔥 Unfreeze** - Unfreeze player

### 🌐 Teleportation
- **📍 TP to Player** - Teleport ke player yang dipilih
- **🎯 Bring Player** - Bawa player ke posisi kamu

### ⚡ Character Modifications
- **🏃 Speed** - Ubah kecepatan jalan (akan muncul dialog input)
- **🦘 Jump Power** - Ubah jump power (akan muncul dialog input)
- **🛡️ God Mode** - Aktifkan god mode (invincible)
- **❌ Ungod** - Matikan god mode
- **👻 Invisible** - Buat player invisible
- **👁️ Visible** - Buat player visible kembali

### ✈️ Flying
- **🚀 Enable Fly** - Aktifkan fly mode (WASD + Space/Shift)
- **🪂 Disable Fly** - Matikan fly mode

### 🔄 Reset & Other
- **♻️ Reset to Normal** - Reset semua ke normal (speed, jump, health, visibility, fly)
- **📣 Announce** - Kirim announcement ke semua player (akan muncul dialog input)

## ⌨️ Kontrol

### Icon & Panel:
- **Klik Icon ⚙️** - Buka/tutup admin panel
- **Drag Icon** - Pindahkan icon ke posisi lain
- **Drag Title Bar** - Pindahkan panel ke posisi lain
- **Klik Button** - Execute command otomatis

### Fly Mode Controls (saat fly aktif):
- **W** - Terbang ke depan
- **S** - Terbang ke belakang
- **A** - Terbang ke kiri
- **D** - Terbang ke kanan
- **Space** - Terbang ke atas
- **Shift** - Terbang ke bawah

## 🎨 Features

✅ **Modern Button UI** - Tidak perlu ketik command manual
✅ **Floating Draggable Icon** - Icon button yang bisa dipindah ke mana saja
✅ **Tab Menu System** - Admin tab & Settings tab terpisah
✅ **Status Badges** - Indikator visual untuk status yang aktif (God, Fly, Invisible, Freeze)
✅ **Anti-AFK Protection** - Otomatis prevent kick saat idle
✅ **Anti-Staff Detection** - Auto-hide GUI saat staff/admin join server
✅ **Player Selector** - Dropdown untuk pilih target player dengan mudah
✅ **Category System** - Commands dikelompokkan berdasarkan kategori
✅ **Input Dialogs** - Dialog otomatis untuk input tambahan (speed, jp, etc)
✅ Universal - Bekerja di map manapun
✅ Fly Mode - Terbang bebas dengan WASD + Space/Shift
✅ Reset Command - Kembalikan semua ke normal dengan 1 klik
✅ Drag & Drop - Panel dan icon bisa dipindah-pindah
✅ Notifikasi - Feedback langsung untuk setiap command
✅ Secure - Validasi admin di server-side
✅ Modern UI - Dark theme dengan animasi smooth dan hover effects

## ⚙️ Settings Tab (BARU!)

Klik tab **"Settings"** di atas panel untuk mengakses fitur-fitur proteksi:

### ⏰ Anti-AFK
- **Fungsi**: Mencegah auto-kick saat idle/AFK
- **Cara kerja**: Mensimulasikan activity otomatis
- **Toggle**: Klik button untuk ON/OFF
- **Status**: Hijau = ON, Abu-abu = OFF

### 🛡️ Anti-Staff
- **Fungsi**: Auto-hide admin GUI saat staff/admin join
- **Cara kerja**: Deteksi player dengan nama "admin", "mod", "staff", "owner"
- **Toggle**: Klik button untuk ON/OFF
- **Status**: Hijau = ON, Abu-abu = OFF
- **Keamanan**: Membantu menghindari deteksi saat menggunakan script

### 🟢 Status Badges (BARU!)
Setiap button command menampilkan **badge hijau** jika fitur sedang aktif:
- **God Mode**: Badge muncul saat god mode ON
- **Flying**: Badge muncul saat fly mode ON
- **Invisible**: Badge muncul saat invisible ON
- **Frozen**: Badge muncul saat player frozen

Status badge otomatis update setiap 2 detik!

## 📑 Tab Menu

### 👑 Admin Tab
Berisi semua command untuk kontrol player:
- Player Control (kill, kick, respawn, freeze, etc)
- Teleportation (tp, bring)
- Character Modifications (speed, jp, god, invis, etc)
- Flying controls
- Reset & other commands

### ⚙️ Settings Tab
Berisi pengaturan proteksi dan utilitas:
- Anti-AFK toggle
- Anti-Staff toggle
- (Bisa ditambah fitur lain di masa depan)

## 🔧 Menambah Command Baru

Buka `src/server/AdminCommands.luau` dan tambahkan command baru:

```lua
-- Contoh: command untuk memberi player Robux (jika memungkinkan)
AdminCommands.Commands.example = function(executor: Player, args: {string})
    if #args < 1 then
        notify(executor, "Usage: ;example <player>", "error")
        return
    end
    
    local target = findPlayer(args[1])
    if not target then
        notify(executor, "Player not found!", "error")
        return
    end
    
    -- Lakukan sesuatu dengan target player
    notify(executor, "Example command executed!", "success")
end
```

Kemudian tambahkan button di `src/client/AdminGUI.luau` di kategori yang sesuai.

## 🛡️ Security

- ✅ Semua commands divalidasi di server-side
- ✅ Hanya admin yang bisa execute commands
- ✅ Client tidak bisa bypass admin check
- ✅ Protected dari exploiters

## 📝 Notes

- Script ini menggunakan Luau (Roblox's Lua)
- Kompatibel dengan Rojo untuk development workflow
- Bisa di-extend dengan commands custom sesuai kebutuhan game kamu
- GUI otomatis hanya muncul untuk admin

## 🐛 Troubleshooting

**Icon tidak muncul?**
- Pastikan username kamu sudah ditambahkan di `AdminConfig.luau`
- Cek console untuk error messages
- Pastikan semua file tersync dengan benar

**Button tidak berfungsi?**
- Cek apakah sudah pilih target player (untuk command yang memerlukan target)
- Lihat notification di kanan atas untuk feedback
- Cek console untuk error messages

**Panel tidak bisa dibuka?**
- Coba klik icon floating button lagi
- Restart game jika perlu

**Player tidak ditemukan?**
- Klik button "🔄 Refresh" untuk update daftar player
- Pastikan player target masih ada di server

## 📞 Support

Jika ada bug atau ingin menambah fitur, silahkan modify script sesuai kebutuhan!

Happy coding! 🎮

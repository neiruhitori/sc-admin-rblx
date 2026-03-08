# 🔄 Admin Script - Update Log

## v2.0 - Major Update: Tab System & Protection Features (Latest)

### 🆕 Fitur Baru

#### 1. **Tab Menu System**
- ✅ Menu tab di bagian atas panel (Admin & Settings)
- ✅ Tab Admin: Berisi semua command untuk kontrol player
- ✅ Tab Settings: Berisi fitur proteksi dan utilitas
- ✅ Smooth tab switching dengan visual feedback
- ✅ Player selector otomatis hide saat di Settings tab

#### 2. **Status Badge System** 🟢
- ✅ Badge hijau indikator pada setiap command button
- ✅ Badge muncul otomatis saat fitur aktif (God, Fly, Invisible, Freeze)
- ✅ Auto-refresh status setiap 2 detik
- ✅ Visual feedback real-time untuk status player

#### 3. **Anti-AFK Protection** ⏰
- ✅ Mencegah auto-kick dari server saat idle
- ✅ Simulasi activity otomatis menggunakan VirtualUser
- ✅ Toggle ON/OFF dengan 1 klik
- ✅ Status indicator (Hijau = ON, Abu = OFF)
- ✅ Module: `src/client/AntiAFK.luau`

#### 4. **Anti-Staff Detection** 🛡️
- ✅ Auto-hide admin GUI saat staff/admin join server
- ✅ Deteksi player dengan nama: admin, mod, staff, owner
- ✅ Auto-show GUI saat staff leave
- ✅ Toggle ON/OFF dengan 1 klik
- ✅ Membantu menghindari deteksi saat menggunakan script
- ✅ Module: `src/client/AntiStaff.luau`

### 🐛 Bug Fixes

#### Jump Power Bug
- ❌ **Problem**: Command `jp` tidak bekerja
- ✅ **Fixed**: Menangani Humanoid.UseJumpPower flag
  - Jika `UseJumpPower = false`, gunakan `JumpHeight`
  - Jika `UseJumpPower = true`, gunakan `JumpPower`
- 📍 **File**: `src/server/AdminCommands.luau`

#### Visible Command Bug
- ❌ **Problem**: Command `vis` tidak mengembalikan visibility dengan benar
- ✅ **Fixed**: Iterasi through semua descendants accessories
  - Handle `Decal` transparency
  - Handle `Texture` transparency
  - Handle `BasePart` transparency & LocalTransparencyModifier
- 📍 **File**: `src/server/AdminCommands.luau`

### 🔧 Improvements

#### Server-Side Status Tracking
- ✅ Tambah `PlayerStatus` table di server
- ✅ Track status: GodMode, Flying, Invisible, Frozen
- ✅ RemoteFunction `GetStatus` untuk query status dari client
- ✅ Update otomatis saat command executed

#### GUI Enhancements
- ✅ Settings container dengan ScrollingFrame
- ✅ Toggle setting buttons dengan visual ON/OFF
- ✅ Deskripsi lengkap untuk setiap setting
- ✅ Icon visual untuk setiap setting
- ✅ Module integration (AntiAFK & AntiStaff)

### 📁 File Changes

#### New Files:
- `src/client/AntiAFK.luau` - Anti-AFK module
- `src/client/AntiStaff.luau` - Anti-Staff detection module
- `UPDATE_LOG.md` - This file

#### Modified Files:
- `src/client/AdminGUI.luau` - Tab system, status badges, settings integration
- `src/server/AdminCommands.luau` - Bug fixes, status tracking
- `src/shared/AdminRemote.luau` - Added GetStatus RemoteFunction
- `README_ADMIN.md` - Updated documentation

### 🎯 Usage Guide

#### Menggunakan Tab Menu:
1. Klik icon ⚙️ untuk buka admin panel
2. Klik tab **"Admin"** untuk command controls
3. Klik tab **"Settings"** untuk proteksi features

#### Menggunakan Status Badges:
- Badge hijau akan muncul otomatis di button saat fitur aktif
- Contoh: Jika player dalam god mode, badge hijau muncul di button "God Mode"
- Status refresh otomatis setiap 2 detik

#### Menggunakan Anti-AFK:
1. Buka Settings tab
2. Klik toggle button "Anti-AFK"
3. Button akan berubah hijau (ON) atau abu-abu (OFF)
4. Saat ON: Auto prevent kick dari idle

#### Menggunakan Anti-Staff:
1. Buka Settings tab
2. Klik toggle button "Anti-Staff"
3. Button akan berubah hijau (ON) atau abu-abu (OFF)
4. Saat ON: GUI auto-hide jika staff join server

### ⚙️ Technical Details

#### Status Badge Refresh System:
```lua
-- Refresh interval: 2 seconds
-- Uses RunService.Heartbeat
-- Queries server status via RemoteFunction
-- Updates badge visibility based on PlayerStatus table
```

#### Tab Switching Logic:
```lua
-- Switches between commandsContainer and settingsContainer
-- Hides player selector in Settings tab
-- Visual feedback via tab button colors
```

#### Anti-Staff Detection:
```lua
-- Checks player names for: admin, mod, staff, owner
-- Monitors PlayerAdded and PlayerRemoving events
-- Hides/shows GUI mainFrame visibility
```

---

## v1.0 - Initial Release

### Features:
- Basic admin command system (18+ commands)
- Modern button-based UI
- Floating draggable icon
- Player selector dropdown
- Fly controller with WASD controls
- Category system for commands
- Notification system
- Input dialogs for commands
- Server-side validation
- Dark theme UI with animations

---

**Last Updated**: December 2024
**Version**: 2.0
**Status**: ✅ Fully Functional

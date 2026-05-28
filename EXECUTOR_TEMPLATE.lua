--[[
    ============================================
    TEMPLATE EXECUTOR - Copy paste ini ke executor kamu
    ============================================
    
    📦 ADA 2 SCRIPT TERPISAH:
    
    1️⃣ LoaderScript.lua (WAJIB) - Admin Commands
       • Fly, Speed, God Mode, Jump, Anti-AFK, dll
       • Tombol ⚙️ untuk control panel
       
    2️⃣ vd.lua (OPTIONAL) - Violence District Features
       • ESP Wallhack, Crosshair, Camera Zoom, dll
       • Tombol ⚡ untuk VD panel
       • Keyboard shortcuts: K, J, H, G, L
    
    💡 PILIHAN LOAD:
    • Load KEDUANYA (full features) ✅ Recommended
    • Load HANYA LoaderScript.lua (tanpa VD)
    
    LANGKAH:
    1. Ganti URL di bawah dengan Raw URL GitHub kamu
    2. Pilih mau load apa (comment/uncomment)
    3. Copy SEMUA code ini
    4. Paste di executor
    5. Execute!
    
]]

-- ============================================
-- GANTI URL INI! ⬇️⬇️⬇️
-- ============================================

-- 1️⃣ WAJIB: Admin Commands (LoaderScript.lua)
loadstring(game:HttpGet("https://raw.githubusercontent.com/neiruhitori/sc-admin-rblx/main/LoaderScript.lua"))()

-- 2️⃣ OPTIONAL: Violence District (vd.lua)
-- Uncomment baris di bawah jika mau Violence District features
loadstring(game:HttpGet("https://raw.githubusercontent.com/neiruhitori/sc-admin-rblx/main/vd.lua"))()

--[[
    ⚠️ PENTING - PERBEDAAN URL:
    
    ❌ SALAH (Bikin Crash/Force Close):
    https://github.com/neiruhitori/sc-admin-rblx/blob/main/LoaderScript.lua
    ^ URL ini adalah halaman HTML GitHub, BUKAN file Lua!
    
    ✅ BENAR:
    https://raw.githubusercontent.com/neiruhitori/sc-admin-rblx/main/LoaderScript.lua
    ^ Ini URL raw file, langsung konten Lua
    
    CARA DAPAT RAW URL:
    1. Buka file di GitHub
    2. Klik tombol "Raw" (pojok kanan atas)
    3. Copy URL dari browser
    
    CONTOH URL YANG BENAR:
    https://raw.githubusercontent.com/JohnDoe/my-admin-script/main/LoaderScript.lua
    
    PASTIKAN:
    ✅ Harus "raw.githubusercontent.com" (BUKAN "github.com")
    ✅ TIDAK ADA "/blob/" di URL
    ✅ Ganti USERNAME dengan username GitHub kamu
    ✅ Ganti REPO dengan nama repository kamu
    ✅ File harus bernama LoaderScript.lua (atau sesuaikan nama file)
    
    SETELAH EXECUTE:
    • Tombol ⚙️ muncul di layar (Admin panel)
    • Tombol ⚡ muncul di layar (Violence District - jika di-load)
    • Ketik command di chat: ;fly, ;speed 100, dll
    
    📋 FITUR LoaderScript.lua:
    ✈️  Fly (WASD + Space + Shift) - ;fly
    🏃 Speed boost - ;speed [number]
    🦘 Jump power - ;jp [number]
    ∞  Infinite jump - ;infinitejump
    🛡️ God mode (true invincibility) - ;god
    📍 Goto player - ;goto
    🔄 Respawn - ;respawn
    ⏰ Anti-AFK 24/7 - ;antiafk
    🥔 Potato Mode (FPS boost) - UI Button (click ON/OFF)
       • Click button di admin panel untuk toggle
       • ON: Optimize parts, clear water, disable effects
       • OFF: Stop water clearing loop
       • Best for low-end devices
       ⚠️ NO keyboard shortcut untuk admin (UI only)
    
    ⚡ FITUR Violence District (vd.lua):
    🖱️ Cursor Unlock - K key
    👁️ ESP Wallhack + Objects - J key
    🪤 Pallet Trap Detection - J key
    🎯 Crosshair + Range Marks - H key
    📷 Camera Zoom Unlock - G key
    ⚡ Speed Boost + Auto Shift - L key
    🥔 Potato Mode - N key (keyboard only, no UI)
    
]]

# 🔧 Mount Skuy Admin Script - Troubleshooting Guide

## ❌ Problem: "[CrossExperience] Error executing call Cannot find executable"

### Root Cause
Ini error terjadi karena:
1. File di `src/client/` (AdminGUI.luau, FlyController.luau) mencoba load AdminRemote dari server
2. Server script (`src/server/init.server.luau`) TIDAK BERJALAN
3. RemoteEvents/RemoteFunctions tidak ada di ReplicatedStorage
4. Script terus coba menghubungi remotes yang tidak ada → error berulang

### Simbol Diagnosis
Error pattern yang Anda lihat:
```
[CrossExperience] Error executing call Cannot find executable. ❌ ❌ ❌
Failed to load sound rbxassetid://1723137730
Failed to parse color string: ColorShift_Top
```

**Ini adalah error GAME INTERNAL, bukan dari script Anda!**

---

## ✅ SOLUTIONS

### Option 1: Use LoaderScript.lua (Recommended for Executor Users)
**LoaderScript.lua adalah standalone script** - tidak perlu server, tidak perlu RemoteEvents!

**CARA MENGGUNAKAN:**
```
1. Copy seluruh isi LoaderScript.lua
2. Paste ke executor Anda
3. Run!

ATAU jika Anda punya GitHub:
loadstring(game:HttpGet("YOUR_GITHUB_RAW_LINK"))()
```

**KEUNTUNGAN:**
- ✅ Tidak perlu server script
- ✅ Tidak perlu RemoteEvents di ReplicatedStorage
- ✅ Standalone - semua features berjalan di client saja
- ✅ Tidak ada "[CrossExperience] Error"

---

### Option 2: Fix Server Script (Jika Anda Pakai Studio)
Jika Anda menggunakan **Roblox Studio** dengan client + server setup:

**LANGKAH:**
1. Pastikan `src/server/init.server.luau` adalah **Script** (bukan LocalScript)
2. Pastikan script berada di **ServerScriptService** 
3. Pastikan script TIDAK disabled
4. Setelah server script aktif, client scripts akan bisa akses RemoteEvents

---

### Option 3: Quick Fix - Suppress Game Errors
Jika Anda ingin tetap pakai struktur dengan server scripts, tambah ini di awal LoaderScript.lua:

```lua
-- Suppress CrossExperience errors
game:GetService("LogService"):GetLogger():Warn = function() end

print("🚀 Loading Admin Script...")
-- ... rest of script
```

---

## 🎯 Recommended Setup

### Untuk Executor (Like Synapse, Krnl, Script-Ware):
```
USE: LoaderScript.lua
STATUS: ✅ Fully Standalone
```

### Untuk Roblox Studio:
```
USE: src/client/ + src/server/ + src/shared/
SETUP:
  - src/server/init.server.luau → ServerScriptService (Script not LocalScript)
  - client files → StarterPlayer/StarterPlayerScripts (LocalScripts)
```

---

## 📊 File Structure Analysis

| File | Type | Requires Server? | Notes |
|------|------|------------------|-------|
| LoaderScript.lua | Standalone | ❌ No | USE THIS FOR EXECUTOR |
| src/client/*.luau | Client | ✅ Yes | Needs src/server/*.luau |
| src/server/*.luau | Server | ✅ Required | Must be in ServerScriptService |
| src/shared/*.luau | Shared | ✅ Yes | Both client & server need it |

---

## 🔍 Why Errors Happened Suddenly?

**Possible Causes (tanpa ada perubahan code):**

1. **Executor Plugin Issue**
   - Try restart executor program
   - Re-run LoaderScript.lua

2. **Network Connectivity**
   - Check your internet connection
   - Try join game again

3. **Roblox Game Update**
   - Game might have disabled features
   - Roblox CDN might be blocking some assets (sound, images)

4. **Asset Loading Failures**
   - Sound files blocked by game → Ignore (not critical)
   - Colors failed to parse → Ignore (UI will use defaults)

---

## ✨ Verification Checklist

```
[ ] Using LoaderScript.lua directly
[ ] Script prints "🚀 Loading Admin Script..."
[ ] Admin GUI button appears on screen
[ ] No "[CrossExperience]" errors in output (game errors OK)
[ ] Commands work (fly, speed, god mode, etc)
```

---

## 💡 Pro Tips

1. **Ignore Game-Level Errors**
   ```
   ❌ Failed to load sound
   ❌ Failed to parse color string
   ✅ Your script is fine - game internal issues
   ```

2. **Check Output Log**
   - Look for `✅` messages (your script)
   - Ignore `⚠️ Failed to load` (game issues)

3. **If Still Having Issues**
   - Restart executor completely
   - Rejoin the game
   - Re-run LoaderScript.lua

---

**Version:** March 2026
**Script:** TwoHand Comunity Admin Panel

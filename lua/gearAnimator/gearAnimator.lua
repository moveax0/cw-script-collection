{$lua}

[ENABLE]

-- set your folder path and file names here
local patternFolder = [[C:\your\folder\]]  -- include trailing slash
local filenames = {
  left   = "cannotBeEmpty.txt",
  right  = "cannotBeEmpty.txt",
  chest  = "cannotBeEmpty.txt",
  shoulder = "cannotBeEmpty.txt"
}

_G.gearAnimator_enabled = {
  left   = false,
  right  = false,
  chest  = false,
  shoulder = false
}

local intervals = {
  left   = 1000,
  right  = 1000,
  chest  = 1000,
  shoulder = 1000
}

-- hide lua console
getLuaEngine().cbShowOnPrint.Checked = false
getLuaEngine().hide()

-- check if file exists
local function fileExists(path)
  local f = io.open(path, "r")
  if not f then return false end
  f:close()
  return true
end

-- parse multi-line hex file into pattern lists
local function loadPatterns(path)
  assert(fileExists(path), "❌ File not found: " .. path)
  local t = {}
  for line in io.lines(path) do
    if line:match("%S") then
      local bytes = {}
      for hex in line:gmatch("%x%x") do
        table.insert(bytes, tonumber(hex, 16))
      end
      assert(#bytes == 280,
        string.format("Each pattern must be 280 bytes (%d) in %s", #bytes, path))
      table.insert(t, bytes)
    end
  end
  return t
end

-- check folder and load patterns
local folderOK = fileExists(patternFolder) or os.rename(patternFolder,patternFolder)
assert(folderOK, "❌ Folder not found: " .. patternFolder)

local leftWeaponList  = loadPatterns(patternFolder .. filenames.left)
local rightWeaponList = loadPatterns(patternFolder .. filenames.right)
local chestList       = loadPatterns(patternFolder .. filenames.chest)
local shoulderList    = loadPatterns(patternFolder .. filenames.shoulder)

-- existing pointer + timers setup
local baseSpec = "[Cube.exe+0036B1C8]"
local firstOffset = 0x39C
local baseAddr = getAddress(baseSpec)
assert(baseAddr and baseAddr ~= 0, "❌ Could not resolve base pointer: " .. baseSpec)
local playerBasePtr = readPointer(baseAddr + firstOffset)
assert(playerBasePtr and playerBasePtr ~= 0, "❌ Failed to dereference base offset")

-- store addresses globally for disable section
_G.gearAnimator_addrs = {
  leftWeaponAddr  = playerBasePtr + 0x990,
  rightWeaponAddr = playerBasePtr + 0xAA8,
  chestAddr       = playerBasePtr + 0x530,
  shoulderAddr    = playerBasePtr + 0x878
}

-- store original bytes for restoration
_G.originalBytes = {
  left   = readBytes(_G.gearAnimator_addrs.leftWeaponAddr, 280, true),
  right  = readBytes(_G.gearAnimator_addrs.rightWeaponAddr, 280, true),
  chest  = readBytes(_G.gearAnimator_addrs.chestAddr, 280, true),
  shoulder = readBytes(_G.gearAnimator_addrs.shoulderAddr, 280, true)
}

local function setupWriter(name, addr, list, interval, enabledFlag)
  local timer = createTimer(nil, false)
  timer.Interval = interval
  local idx = 1
  timer.OnTimer = function()
    if not enabledFlag or #list == 0 then return end
    if idx > #list then idx = 1 end
    local b = list[idx]
    writeBytes(addr, b)
    idx = idx + 1
  end
  timer.Enabled = true
  return timer
end

_G.LeftTimer  = setupWriter("Left",  _G.gearAnimator_addrs.leftWeaponAddr,  leftWeaponList,  intervals.left,   _G.gearAnimator_enabled.left)
_G.RightTimer = setupWriter("Right", _G.gearAnimator_addrs.rightWeaponAddr, rightWeaponList, intervals.right,  _G.gearAnimator_enabled.right)
_G.ChestTimer = setupWriter("Chest", _G.gearAnimator_addrs.chestAddr,       chestList,       intervals.chest,  _G.gearAnimator_enabled.chest)
_G.ShoulderTimer = setupWriter("Shoulder", _G.gearAnimator_addrs.shoulderAddr, shoulderList, intervals.shoulder, _G.gearAnimator_enabled.shoulder)

print("✅ Loaded patterns from folder. Set enabled flags to 'true' to start writing.")

[DISABLE]

-- stop all timers
if _G.LeftTimer then
  _G.LeftTimer.Enabled = false
  _G.LeftTimer.destroy()
  _G.LeftTimer = nil
end

if _G.RightTimer then
  _G.RightTimer.Enabled = false
  _G.RightTimer.destroy()
  _G.RightTimer = nil
end

if _G.ChestTimer then
  _G.ChestTimer.Enabled = false
  _G.ChestTimer.destroy()
  _G.ChestTimer = nil
end

if _G.ShoulderTimer then
  _G.ShoulderTimer.Enabled = false
  _G.ShoulderTimer.destroy()
  _G.ShoulderTimer = nil
end

-- restore only gear that's enabled
if _G.originalBytes and _G.gearAnimator_addrs and _G.gearAnimator_enabled then
  if _G.gearAnimator_enabled.left and _G.originalBytes.left then
    writeBytes(_G.gearAnimator_addrs.leftWeaponAddr, _G.originalBytes.left)
  end
  if _G.gearAnimator_enabled.right and _G.originalBytes.right then
    writeBytes(_G.gearAnimator_addrs.rightWeaponAddr, _G.originalBytes.right)
  end
  if _G.gearAnimator_enabled.chest and _G.originalBytes.chest then
    writeBytes(_G.gearAnimator_addrs.chestAddr, _G.originalBytes.chest)
  end
  if _G.gearAnimator_enabled.shoulder and _G.originalBytes.shoulder then
    writeBytes(_G.gearAnimator_addrs.shoulderAddr, _G.originalBytes.shoulder)
  end
  
  _G.originalBytes = nil
  _G.gearAnimator_addrs = nil
  _G.gearAnimator_enabled = nil
end

print("🛑 Script disabled. Restored original gear for enabled parts only.")

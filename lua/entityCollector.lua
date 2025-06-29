{$lua}

if syntaxcheck then return "" end  -- prevents side-effects during syntax-check

[ENABLE]

-- suppress console popup
local le = getLuaEngine()
le.cbShowOnPrint.Checked = false
le.hide()

-- CONFIG
local bpAddr    = getAddress("Cube.exe+219D51")
local seenESI   = {}
local seenNames = {}  -- track seen names for header pruning

debugProcess()
debug_setBreakpoint(bpAddr)
print(string.format("🔍 Scan started; breakpoint at 0x%08X", bpAddr))

local al = getAddressList()

-- ensure top-level entityList header exists
local entityHdr = al.getMemoryRecordByDescription("entityList")
if not entityHdr then
  entityHdr = al.createMemoryRecord()
  entityHdr.IsGroupHeader = true
  entityHdr.Description   = "entityList"
  entityHdr.Options       = "[moHideChildren]"
  entityHdr.Collapsed     = true
  print("✅ Created entityList header")
else
  print("➡️ Using existing entityList header")
end

-- get clean 16-byte name at ESI+0x1168
local function getName(esi)
  return (readString(esi + 0x1168, 16) or "")
           :gsub("%z.*", "")
           :gsub("\r?\n", "")
end

-- find or create player header under entityList
local function getOrMakePlayerHeader(name)
  for i = 0, entityHdr.Count - 1 do
    local mr = entityHdr.getChild(i)
    if mr.IsGroupHeader and mr.Description == name then
      return mr
    end
  end
  local hdr = al.createMemoryRecord()
  hdr.IsGroupHeader = true
  hdr.Description   = name
  hdr.Options       = "[moHideChildren]"
  hdr.Collapsed     = true
  hdr.appendToEntry(entityHdr)
  return hdr
end

-- create all player sections
local function setupPlayerSections(parentHdr, baseAddr)
  -- create attributes group header
  local attrHdr = al.createMemoryRecord()
  attrHdr.IsGroupHeader = true
  attrHdr.Description   = "attributes"
  attrHdr.Options       = "[moHideChildren]"
  attrHdr.Collapsed     = true
  attrHdr.appendToEntry(parentHdr)

  -- attribute definitions [name, offset, type]
  local attributes = {
    {"level",           0x190,  vtDword},
    {"experience",      0x194,  vtDword},
    {"class",           0x140,  vtByte},
    {"sub-class",       0x141,  vtByte},
    {"money",           0x1304, vtDword},
    {"platinum coins",  0x1308, vtDword}
  }

  -- create attribute records
  for _, attr in ipairs(attributes) do
    local mr = al.createMemoryRecord()
    mr.Description = attr[1]
    mr.Address     = baseAddr + attr[2]
    mr.Type        = attr[3]
    mr.appendToEntry(attrHdr)
  end

  -- create resources group header
  local resHdr = al.createMemoryRecord()
  resHdr.IsGroupHeader = true
  resHdr.Description   = "resources"
  resHdr.Options       = "[moHideChildren]"
  resHdr.Collapsed     = true
  resHdr.appendToEntry(parentHdr)

  -- resource definitions [name, offset, type]
  local resources = {
    {"health",        0x16C,  vtSingle},
    {"mana",          0x170,  vtSingle},
    {"stamina",       0x1194, vtSingle},
    {"stealth",       0x1190, vtSingle},
    {"block power",   0x174,  vtSingle}
  }

  -- create resource records
  for _, res in ipairs(resources) do
    local mr = al.createMemoryRecord()
    mr.Description = res[1]
    mr.Address     = baseAddr + res[2]
    mr.Type        = res[3]
    mr.appendToEntry(resHdr)
  end

  -- create coordinates group header
  local coordHdr = al.createMemoryRecord()
  coordHdr.IsGroupHeader = true
  coordHdr.Description   = "coordinates"
  coordHdr.Options       = "[moHideChildren]"
  coordHdr.Collapsed     = true
  coordHdr.appendToEntry(parentHdr)

  -- coordinate definitions [name, offset, type]
  local coordinates = {
    {"x", 0x10, vtSingle},
    {"y", 0x18, vtSingle},
    {"z", 0x20, vtSingle}
  }

  -- create coordinate records
  for _, coord in ipairs(coordinates) do
    local mr = al.createMemoryRecord()
    mr.Description = coord[1]
    mr.Address     = baseAddr + coord[2]
    mr.Type        = coord[3]
    mr.appendToEntry(coordHdr)
  end

  -- create gear group header
  local gearHdr = al.createMemoryRecord()
  gearHdr.IsGroupHeader = true
  gearHdr.Description   = "gear"
  gearHdr.Options       = "[moHideChildren]"
  gearHdr.Collapsed     = true
  gearHdr.appendToEntry(parentHdr)

  -- gear slot definitions [header name, description, offset]
  local gearSlots = {
    {"left_weapon",  "leftWeaponFull",  0x990},
    {"right_weapon", "rightWeaponFull", 0xAA8},
    {"chest",        "chestFull",       0x530},
    {"hands",        "handsFull",       0x760},
    {"feet",         "feetFull",        0x648},
    {"shoulder",     "shoulderFull",    0x878},
    {"neck",         "neckFull",        0x418},
    {"left_ring",    "leftRingFull",    0xBC0},
    {"right_ring",   "rightRingFull",   0xCD8},
    {"special",      "specialFull",     0xF08},
    {"light",        "lightFull",       0xDF0},
    {"pet",          "petFull",         0x1020}
  }

  -- create gear slot headers and byte arrays
  for _, slot in ipairs(gearSlots) do
    -- create gear slot header
    local slotHdr = al.createMemoryRecord()
    slotHdr.IsGroupHeader = true
    slotHdr.Description   = slot[1]
    slotHdr.Options       = "[moHideChildren]"
    slotHdr.Collapsed     = true
    slotHdr.appendToEntry(gearHdr)

    -- create byte array record
    local mr = al.createMemoryRecord()
    mr.Description = slot[2]
    mr.Address     = baseAddr + slot[3]
    mr.Type        = vtByteArray
    mr.Aob.Size  = 277  -- set byte length
    mr.ShowAsHex = true  -- display in hexadecimal
    mr.appendToEntry(slotHdr)
  end

  -- create skills group header
  local skillsHdr = al.createMemoryRecord()
  skillsHdr.IsGroupHeader = true
  skillsHdr.Description   = "skills"
  skillsHdr.Options       = "[moHideChildren]"
  skillsHdr.Collapsed     = true
  skillsHdr.appendToEntry(parentHdr)

  -- skill definitions [name, offset, type]
  local skills = {
    {"skill 1",        0x1150, vtDword},
    {"skill 2",        0x1154, vtDword},
    {"skill 3",        0x1158, vtDword},
    {"pet master",     0x1138, vtDword},
    {"riding",         0x113C, vtDword},
    {"climbing",       0x1140, vtDword},
    {"hang gliding",   0x1144, vtDword},
    {"swimming",       0x1148, vtDword},
    {"sailing",        0x114C, vtDword}
  }

  -- create skill records
  for _, skill in ipairs(skills) do
    local mr = al.createMemoryRecord()
    mr.Description = skill[1]
    mr.Address     = baseAddr + skill[2]
    mr.Type        = skill[3]
    mr.appendToEntry(skillsHdr)
  end
end

-- PTR: Called on each bp hit
function debugger_onBreakpoint()
  if EIP ~= bpAddr then return 1 end

  local esi  = ESI
  local addr = string.format("0x%X", esi)

  if seenESI[esi] then
    print(string.format("🔁 Duplicate ESI 0x%X -> ending scan.", esi))

    -- SCAN COMPLETE → prune any stale headers not seen
    for i = entityHdr.Count - 1, 0, -1 do
      local hdr = entityHdr.getChild(i)
      if hdr.IsGroupHeader and not seenNames[hdr.Description] then
        print("🗑 Removing stale header: " .. hdr.Description)
        hdr.destroy()
      end
    end

    debug_removeBreakpoint(bpAddr)
    debugger_onBreakpoint = nil
    debug_continueFromBreakpoint(co_run)
    return 1
  end

  -- NEW entity encountered
  seenESI[esi] = true
  local name = getName(esi)
  local title = (#name > 0 and name) or addr
  seenNames[title] = true

  print(string.format("➕ Found entity: %s @ %s", title, addr))

  -- ensure header exists
  local hdr = getOrMakePlayerHeader(title)

  -- check if we need to create baseAddress + sections
  local needsSetup = false
  if hdr.Count == 0 then
    needsSetup = true
  else
    -- check if attributes header exists
    local hasAttributes = false
    for j = 0, hdr.Count - 1 do
      local child = hdr.getChild(j)
      if child.IsGroupHeader and child.Description == "attributes" then
        hasAttributes = true
        break
      end
    end
    needsSetup = not hasAttributes
  end

  if needsSetup then
    -- create baseAddress record
    local mr = al.createMemoryRecord()
    mr.Address     = esi
    mr.Type        = vtByte
    mr.Description = "baseAddress"
    mr.appendToEntry(hdr)

    -- create all sections
    setupPlayerSections(hdr, esi)
  end

  debug_continueFromBreakpoint(co_run)
  return 1
end

[DISABLE]

-- not needed?

{$asm}

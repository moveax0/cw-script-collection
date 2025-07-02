{$lua}

[ENABLE]

-- use dkjson and set database path
local json = require "dkjson"
local dbPath = "C:\\your\\database\\file\\path\\gearDB.json"

-- cleanup any existing timer (we're already doing this in [DISABLE])
if myTimer then myTimer.destroy(); myTimer = nil end

-- hide lua console
getLuaEngine().cbShowOnPrint.Checked = false
getLuaEngine().hide()

-- helper to read bytes as space-separated hex string
local function readBytesFormatted(addr, size)
  local bytes = readBytes(addr, size, true)
  local t = {}
  for i = 1, #bytes do 
    t[i] = string.format("%02X", bytes[i])
  end
  return table.concat(t, " ")
end

local function loadDB()
  local f = io.open(dbPath, "r")
  if not f then
    print("[DB] No database found; starting new.")
    return {}
  end
  local data = f:read("*a"); f:close()
  local ok, tbl = pcall(json.decode, data)
  if ok and type(tbl) == "table" then
    print("[DB] Loaded existing database.")
    return tbl
  end
  print("[DB] Corrupt database; resetting.")
  return {}
end

local function saveDB(db)
  local f = io.open(dbPath, "w")
  if not f then print("[DB] Save error."); return end
  
  -- encode with basic indentation
  local json_str = json.encode(db, {indent = true})
  
  -- improved formatting for arrays
  json_str = json_str:gsub('%s*%[%s*"', ' [\n        "')
  json_str = json_str:gsub('"%s*,%s*"', '",\n        "')
  json_str = json_str:gsub('"%s*%]%s*', '"\n      ]')
  
  -- remove empty lines between array elements
  json_str = json_str:gsub(",\n%s+,\n", ",\n")
  json_str = json_str:gsub("%[\n%s+%[", "[[")
  
  f:write(json_str)
  f:close()
  -- print("[DB] Database saved to " .. dbPath)
end

-- classMap to handle both numbers and strings (string handling is from an earlier version and not needed anymore - can be removed)
local classMap = {
    [1] = "warrior", ["1"] = "warrior",
    [2] = "ranger", ["2"] = "ranger",
    [3] = "mage", ["3"] = "mage",
    [4] = "rogue", ["4"] = "rogue"
}
local db = loadDB()

-- timer setup
local entityListRecord = nil
local lastPrintTime = 0

myTimer = createTimer(getMainForm(), false)
myTimer.Interval = 1000
myTimer.OnTimer = function(timer)
  -- only search for entityList if we haven't found it yet
  if not entityListRecord then
    local list = getAddressList()
    
    -- get count of records using getCount()
    local recordCount = list.getCount and list:getCount() or 0
    
    -- search all records for entityList
    for i = 0, recordCount - 1 do
      -- access records
      local rec = list.getMemoryRecord and list:getMemoryRecord(i)
      if rec then
        -- check for entityList record
        if rec.Name == "entityList" or rec.Description == "entityList" then
          entityListRecord = rec
          print("[Timer] entityList found! Starting processing...")
          break
        end
      end
    end

    if not entityListRecord then
      -- throttle "not found" messages
      local now = os.clock()
      if now - lastPrintTime > 5 then
        print("[Timer] entityList not found. Still searching...")
        lastPrintTime = now
      end
      return
    end
  end

  -- process entity list using direct Child access
  local entCount = entityListRecord.Count
  for i = 0, entCount - 1 do
    local ent = entityListRecord.Child[i]
    if not ent then goto cont end
    
    -- safe name handling with fallback
    local name = ent.Description ~= "" and ent.Description or ent.Name or ("entity_" .. i)

    -- find attributes header
    local attr = nil
    for j = 0, ent.Count - 1 do
      local child = ent.Child[j]
      if child and (child.Name == "attributes" or child.Description == "attributes") then
        attr = child
        break
      end
    end
    
    if not attr then 
      print(string.format("[%s] Missing attributes header", name))
      goto cont 
    end

    -- find class value
    local c = nil
    for j = 0, attr.Count - 1 do
      local child = attr.Child[j]
      if child and (child.Name == "class" or child.Description == "class") then
        c = child
        break
      end
    end
    
    -- handle both number and string class values (again, string not needed anymore)
    local classValue = c and c.Value
    local cls = classValue and classMap[classValue]
    
    if not cls then 
      -- try converting to number if it's a string
      if type(classValue) == "string" then
        local num = tonumber(classValue)
        cls = num and classMap[num]
      end
      
      if not cls then
        print(string.format("[%s] Unknown class value [%s] (type: %s)", 
                            name, tostring(classValue), type(classValue)))
        goto cont 
      end
    end

    -- find gear header
    local gear = nil
    for j = 0, ent.Count - 1 do
      local child = ent.Child[j]
      if child and (child.Name == "gear" or child.Description == "gear") then
        gear = child
        break
      end
    end
    
    if not gear then 
      print(string.format("[%s] Missing gear header", name))
      goto cont 
    end

    -- process gear items
    for j = 0, gear.Count - 1 do
      local piece = gear.Child[j]
      if not piece then 
        print(string.format("[%s] Missing gear piece at index %d", name, j))
        goto next_piece 
      end
      
      -- safe piece name handling with fallbacks
      local pieceName = piece.Name or piece.Description or ("gear_" .. j)
      
      -- look for the Cust and Full headers
      local foundCust = nil
      local foundFull = nil
      
      for k = 0, piece.Count - 1 do
        local child = piece.Child[k]
        if not child then
          print(string.format("[%s][%s] Missing child in gear piece %s at index %d", 
                             name, cls, pieceName, k))
          goto next_child 
        end
        
        -- safe child name handling
        local childName = child.Name or child.Description or ""
        
        -- check if this is a Cust header
        if childName:find("Cust") then
          foundCust = child
        end
        
        -- check if this is a Full header
        if childName:find("Full") then
          foundFull = child
        end
        
        ::next_child::
      end

      if foundCust then
        -- convert value to number for comparison
        local v = tonumber(foundCust.Value)
        if v and v > 0 and v <= 32 then
          if foundFull then
            local formattedBytes = readBytesFormatted(foundFull.Address, 277)
            db[name] = db[name] or {}
            db[name][cls] = db[name][cls] or {}
            local gearTbl = db[name][cls]
            gearTbl[pieceName] = gearTbl[pieceName] or {}

            -- check for existing entry
            local exists = false
            if gearTbl[pieceName] then
              for _, old in ipairs(gearTbl[pieceName]) do
                if old == formattedBytes then exists = true; break end
              end
            end

            if exists then
              -- print(string.format("[%s][%s][%s] already in DB", name, cls, pieceName))
            else
              print(string.format("[%s][%s][%s] New gear detected—adding", name, cls, pieceName))
              gearTbl[pieceName] = gearTbl[pieceName] or {}
              table.insert(gearTbl[pieceName], formattedBytes)
              saveDB(db)
            end
          else
            print(string.format("[%s] Missing Full data for %s", name, pieceName))
          end
        else
          -- print(string.format("[%s] Invalid Cust value: %s (converted to %s)", 
                             -- name, tostring(foundCust.Value), tostring(v)))
        end
      end
      ::next_piece::
    end

    ::cont::
  end
end

myTimer.Enabled = true
print("[Script] Timer started (" .. myTimer.Interval .. " ms interval)")

[DISABLE]

-- do we really need to clean the timer twice?
if myTimer then
  myTimer.Enabled = false
  myTimer.destroy()
  myTimer = nil
end
print("[Script] Stopped and cleaned up")

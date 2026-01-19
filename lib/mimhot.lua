
local imgui = require 'mimgui'
local vkeys = require 'vkeys'
local wm = require 'lib.windows.message'

local module = {}
module._VERSION = "1.0.0"
module._SETTINGS = {
    noKeysMessage = "No"
}

-- HotKey:
local tBlockKeys = {[vkeys.VK_RETURN] = true, [vkeys.VK_T] = true, [vkeys.VK_F6] = true, [vkeys.VK_F8] = true}
local tBlockChar = {[116] = true, [84] = true}
local tModKeys = {[vkeys.VK_MENU] = true, [vkeys.VK_SHIFT] = true, [vkeys.VK_CONTROL] = true}
local tBlockNextDown = {}

local tHotKeyData = {
    edit = nil,
	save = {},
   lastTick = os.clock(),
   tickState = false
}
local tKeys = {}

module.HotKey = function(name, keys, lastkeys, width)
    local width = width or 90
    local name = tostring(name)
    local lastkeys = lastkeys or {}
    local keys, bool = keys or {}, false
    lastkeys.v = keys.v

    local sKeys = table.concat(module.getKeysName(keys.v), " + ")

    if #tHotKeyData.save > 0 and tostring(tHotKeyData.save[1]) == name then
        keys.v = tHotKeyData.save[2]
        sKeys = table.concat(module.getKeysName(keys.v), " + ")
        tHotKeyData.save = {}
        bool = true
    elseif tHotKeyData.edit ~= nil and tostring(tHotKeyData.edit) == name then
		if #tKeys == 0 then
			if os.clock() - tHotKeyData.lastTick > 0.5 then
            tHotKeyData.lastTick = os.clock()
            tHotKeyData.tickState = not tHotKeyData.tickState
         end
         sKeys = tHotKeyData.tickState and module._SETTINGS.noKeysMessage or " "
        else
            sKeys = table.concat(module.getKeysName(tKeys), " + ")
        end
    end

    imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.FrameBg])
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.GetStyle().Colors[imgui.Col.FrameBgHovered])
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.GetStyle().Colors[imgui.Col.FrameBgActive])
    if imgui.Button((tostring(sKeys):len() == 0 and module._SETTINGS.noKeysMessage or sKeys) .. name, imgui.ImVec2(width, 0)) then
        tHotKeyData.edit = name
    end
    imgui.PopStyleColor(3)
    return bool
end

function module.getCurrentEdit()
    return tHotKeyData.edit ~= nil
end

function module.getKeysList(bool)
   local bool = bool or false
   local tKeysList = {}
   if bool then
      for k, v in ipairs(tKeys) do
         tKeysList[k] = vkeys.id_to_name(v)
      end
   else
      tKeysList = tKeys
   end
   return tKeysList
end

function module.getKeysName(keys)
    if type(keys) ~= "table" then
       return false
    else
       local tKeysName = {}
       for k, v in ipairs(keys) do
          tKeysName[k] = vkeys.id_to_name(v)
       end
       return tKeysName
    end
 end

local function getKeyNumber(id)
   for k, v in ipairs(tKeys) do
      if v == id then
         return k
      end
   end
   return -1
end

local function reloadKeysList()
    local tNewKeys = {}
    for k, v in pairs(tKeys) do
       tNewKeys[#tNewKeys + 1] = v
    end
    tKeys = tNewKeys
    return true
 end

function module.isKeyModified(id)
if type(id) ~= "number" then
   return false
end
return (tModKeys[id] or false) or (tBlockKeys[id] or false)
end

addEventHandler("onWindowMessage", function (msg, wparam, lparam)
    if tHotKeyData.edit ~= nil and msg == wm.WM_CHAR then
        if tBlockChar[wparam] then
            consumeWindowMessage(true, true)
        end
    end
    if msg == wm.WM_KEYDOWN or msg == wm.WM_SYSKEYDOWN then
        if tHotKeyData.edit ~= nil and wparam == vkeys.VK_ESCAPE then
            tKeys = {}
            tHotKeyData.edit = nil
            consumeWindowMessage(true, true)
        end
        if tHotKeyData.edit ~= nil and wparam == vkeys.VK_BACK then
            tHotKeyData.save = {tHotKeyData.edit, {}}
            tHotKeyData.edit = nil
            consumeWindowMessage(true, true)
        end
        local num = getKeyNumber(wparam)
        if num == -1 then
            tKeys[#tKeys + 1] = wparam
            if tHotKeyData.edit ~= nil then
                if not module.isKeyModified(wparam) then
                    tHotKeyData.save = {tHotKeyData.edit, tKeys}
                    tHotKeyData.edit = nil
                    tKeys = {}
                    consumeWindowMessage(true, true)
                end
            end
        end
        reloadKeysList()
        if tHotKeyData.edit ~= nil then
            consumeWindowMessage(true, true)
        end
    elseif msg == wm.WM_KEYUP or msg == wm.WM_SYSKEYUP then
        local num = getKeyNumber(wparam)
        if num > -1 then
            tKeys[num] = nil
        end
        reloadKeysList()
        if tHotKeyData.edit ~= nil then
            consumeWindowMessage(true, true)
        end
    end
end)

return module
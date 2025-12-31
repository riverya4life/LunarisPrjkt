---@diagnostic disable:lowercase-global
assert(getMoonloaderVersion() ~= "026", ("%s requires MoonLoader v0.26 or higher!"):format(thisScript().name));

script_name = "[LunarisPrjkt]"
script_author = "riverya4life."
script_version(0.96)
script_version_number(0.96)
script_properties("work-in-pause")

--==================================== [ Information for Users or scripters ] ====================================--
--[[ Thanks to Black Jesus for cleo GameFixer 2.0 and Gorskin for lua GameFixer 3.1 (memory addresses) 
Script author: riverya4life.
The author is not responsible for your data, the script is completely clean.
The script has an update system! THE UPDATE WILL BE DOWNLOADED ONLY AFTER CLICKING THE "DOWNLOAD UPDATE" BUTTON
All rights reserved!
When posting on the Internet, please indicate a link to the author, public VK, Github profile, discord. 
After editing the script code by anyone other than the author, if something does not work, it crashes, crashes. 
Please do not write to the author for help.
]]
--==================================== [ Information for Users and scripters ] ====================================--

--==[ REQUIREMENTS ]==--

local sampev = require("lib.samp.events")
local memory = require("memory")
local samp = require("samp.events")
local RakLua = require("RakLua")
local vkeys = require("vkeys")
local rkeys = require("rkeys")
local imgui = require("mimgui")
local mimgui_blur = require("mimgui_blur")
local wm = require("windows")
local encoding = require("encoding")
local fa = require("fAwesome6")
local ffi = require("ffi")
local weapons = require("lib.game.weapons")

imgui.HotKey = require("mimhot").HotKey

encoding.default = 'CP1251'
u8 = encoding.UTF8

------------------------[ конфиг нахуй блять ] -------------------

local inicfg = require "inicfg"
local directIni = "lunaris.ini"

local defaultConfig = {
    main = {
        shownicks = false, showhp = false, noradio = false, delgun = false,
        showchat = true, showhud = true, bighpbar = false, weather = 1,
        time = 12, foggyness = false, drawdist = 250, drawdistair = 1000, drawdistpara = 500,
        fog = 30, lod = 280, blockweather = false, blocktime = false,
        givemedist = false, postfx = true, autoclean = false, animmoney = 3,
        noeffects = false, alphamap = 255, separate_msg = true, vsync = false,
        recolorer = false, language = 1, moneyfontstyle = 3, menufontstyle = 0,
        menuallfontstyle = 2, bindkeys = false, smilesystem = false, gender = 0,
        camhack = false, riveryahellomsg = true, rpguns = false, fisheye = false
    },
    hphud = {
        active = false, text = 3, style = 1, pos = 2, mode = 1,
    },
    fixes = {
        fixbloodwood = true, nolimitmoneyhud = true, sunfix = false, grassfix = false,
        moneyfontfix = false, starsondisplay = false, antiblockedplayer = true,
        sensfix = true, fixblackroads = true, longarmfix = false, placename = false,
        animidle = false, intrun = true, fixcrosshair = true, patchduck = true,
        blurreturn = true, forceaniso = true,
    },
    themesetting = {
        theme = 6, rounded = 4.0, roundedcomp = 2.0, dialogstyle = false,
        windowborder = true, centeredmenu = false, iconstyle = 1, blurmode = true,
        blurradius = 0.5,
    },
    cleaner = {
        limit = 512, autoclean = true, cleaninfo = true, streamupdate = false,
    },
    nop_samp_keys = {
        key_F1 = false, key_F4 = false, key_F7 = false, key_T = false, key_ALTENTER = false,
    },
    commands = {
        openmenu = "/riverya", animmoney = "/animmoney", shownicks = "/shownicks",
        showhp = "/showhp", gameradio = "/gameradio", delgun = "/delgun",
        clearchat = "/clearchat", showchat = "/showchat", showhud = "/showhud",
        dialogstyle = "/dialogstyle", cleanmemory = "/cleanmemory",
    },
    hotkeys = {
        openmenukey = "[113]",
    },
}

local ini = inicfg.load(defaultConfig, directIni)

if not doesFileExist("moonloader/config/lunaris.ini") then
    inicfg.save(ini, "lunaris.ini")
end

function save()
    inicfg.save(ini, directIni)
end

------------------------[ конфиг нахуй блять ] -------------------

local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local tLastKeys = {}
local ActOpenMenuKey = { v = decodeJson(ini.hotkeys.openmenukey) }

local dragging = false
local dragX, dragY = 0, 0
local CDialog, CDXUTDialog = 0, 0

local onspawned = false
local offspawnchecker = true
local showtextdraw = false
local updatesavaliable = false
local MAX_SAMP_MARKERS = 63
local unload_chathider = false
local state = false

local id = nil
local screens = { green = false, black = false }

-- Описание персонажа by Cosmo (https://www.blast.hk/threads/84975/)
local active = nil
local pool = {}
local no_description_text = "* Описание отсутствует *"

-- Homeless Flies by Chapo
local bums_pool = {}
local bums = { 77, 78, 79, 134, 135, 137, 212, 230, 239 }

local sw, sh = getScreenResolution()

local bi = false
local antiafk = false

local notifications = {}

local tabs = {
	fa.HOUSE..u8'\tГлавная', 
	fa.DESKTOP..u8'\tBoost FPS', 
	fa.GEAR..u8'\tИсправления', 
	fa.ICONS..u8'\tПрочее',
	fa.BOOK..u8'\tКоманды', 
	fa.BARS..u8'\tНастройки',
}
local tab = new.int(1)

local tbmtext = {
    u8"Без анимации",
    u8"Быстрая",
    u8"Стандартная",
}
local tmtext = new['const char*'][#tbmtext](tbmtext)
local ivar = new.int(ini.main.animmoney-1)

local textscount = 0

local arr_gender = {
	fa.PERSON_SIMPLE..u8" Мужской", 
	fa.PERSON_DRESS_SIMPLE..u8" Женский",
}
local genders = new['const char*'][#arr_gender](arr_gender)
local gender = new.int(ini.main.gender)

local book_text = {}

local ICON_STYLE_KEYS = {"solid", "regular"}
local ICON_STYLE_NAMES = {["solid"] = "Стандарт", ["regular"] = "Контурные"}
local iconstyle = new.int(ini.themesetting.iconstyle)

function get_memory()
    local function round(num, idp)
        local mult = 10 ^ (idp or 0)
        return math.floor(num * mult + 0.5) / mult
    end
    return round(memory.read(0x8E4CB4, 4, true) / 1048576, 1)
end

-- [ memory funcs (fix for moonloader v. 0.27)]
function memory_getfloat(adr, prot)
    return representIntAsFloat(readMemory(adr, 4, prot))
end

function memory_setfloat(adr, value, prot)
    return writeMemory(adr, 4, representFloatAsInt(value), prot)
end

----------------------------------- Хуйня для мимгуи -----------------------------------

local sliders = {
	weather = new.int(ini.main.weather),
	time = new.int(ini.main.time),
	roundtheme = new.float(ini.themesetting.rounded),
	roundthemecomp = new.float(ini.themesetting.roundedcomp),
	drawdist = new.int(ini.main.drawdist),
    drawdistair = new.int(ini.main.drawdistair),
    drawdistpara = new.int(ini.main.drawdistpara),
    fog = new.int(ini.main.fog),
    lod = new.int(ini.main.lod),
	alphamap = new.int(ini.main.alphamap),
	moneyfontstyle = new.int(ini.main.moneyfontstyle),
	menufontstyle = new.int(ini.main.menufontstyle),
	menuallfontstyle = new.int(ini.main.menuallfontstyle),
	blurradius = new.float(ini.themesetting.blurradius),
    ------------------------------------------------
    limitmem = new.int(ini.cleaner.limit),
}

local checkboxes = {
	blockweather = new.bool(ini.main.blockweather),
	blocktime = new.bool(ini.main.blocktime),
	givemedist = new.bool(ini.main.givemedist),
	fixbloodwood = new.bool(ini.fixes.fixbloodwood),
	nolimitmoneyhud = new.bool(ini.fixes.nolimitmoneyhud),
	sunfix = new.bool(ini.fixes.sunfix),
	grassfix = new.bool(ini.fixes.grassfix),
	postfx = new.bool(ini.main.postfx),
	dialogstyle = new.bool(ini.themesetting.dialogstyle),
	noeffects = new.bool(ini.main.noeffects),
	moneyfontfix = new.bool(ini.fixes.moneyfontfix),
	starsondisplay = new.bool(ini.fixes.starsondisplay),
    antiblockedplayer = new.bool(ini.fixes.antiblockedplayer),
    sensfix = new.bool(ini.fixes.sensfix),
    fixblackroads = new.bool(ini.fixes.fixblackroads),
    blurreturn = new.bool(ini.fixes.blurreturn),
    longarmfix = new.bool(ini.fixes.longarmfix),
    vsync = new.bool(ini.main.vsync),
	windowborder = new.bool(ini.themesetting.windowborder),
	centeredmenu = new.bool(ini.themesetting.centeredmenu),
	blurmode = new.bool(ini.themesetting.blurmode),
	placename = new.bool(ini.fixes.placename),
	animidle = new.bool(ini.fixes.animidle),
	intrun = new.bool(ini.fixes.intrun),
	fixcrosshair = new.bool(ini.fixes.fixcrosshair),
	patchduck = new.bool(ini.fixes.patchduck),
	riveryahellomsg = new.bool(ini.main.riveryahellomsg),
	forceaniso = new.bool(ini.fixes.forceaniso),
    --------------------------------------------------
	nop_samp_keys_F1 = new.bool(ini.nop_samp_keys.key_F1),
    nop_samp_keys_F4 = new.bool(ini.nop_samp_keys.key_F4),
    nop_samp_keys_F7 = new.bool(ini.nop_samp_keys.key_F7),
    nop_samp_keys_T = new.bool(ini.nop_samp_keys.key_T),
    nop_samp_keys_ALTENTER = new.bool(ini.nop_samp_keys.key_ALTENTER),
    --------------------------------------------------
    cleaninfo = new.bool(ini.cleaner.cleaninfo),
    autoclean = new.bool(ini.cleaner.autoclean),
    streamupdate = new.bool(ini.cleaner.streamupdate),
    --------------------------------------------------
    foggyness = new.bool(ini.main.foggyness),
}

local buffers = {
	search_cmd = new.char[64](),
	cmd_openmenu = new.char[64](ini.commands.openmenu),
	cmd_animmoney = new.char[64](ini.commands.animmoney),
	cmd_shownicks = new.char[64](ini.commands.shownicks),
	cmd_showhp = new.char[64](ini.commands.showhp),
	cmd_clearchat = new.char[64](ini.commands.clearchat),
	cmd_showchat = new.char[64](ini.commands.showchat),
	cmd_showhud = new.char[64](ini.commands.showhud),
	cmd_dialogstyle = new.char[64](ini.commands.dialogstyle),
    cmd_cleanmemory = new.char[64](ini.commands.cleanmemory),
}

local imguiCheckboxesFixesAndPatches = {
    [u8"Исправление крови при повреждении дерева"] = {var = checkboxes.fixbloodwood, cfg = "fixbloodwood", fnc = "FixBloodWood"},
    [u8"Cнять лимит на ограничение денег в худе"] = {var = checkboxes.nolimitmoneyhud, cfg = "nolimitmoneyhud", fnc = "NoLimitMoneyHud"},
    [u8"Вернуть солнце"] = {var = checkboxes.sunfix, cfg = "sunfix", fnc = "SunFix"},
    [u8"Вернуть траву"] = {var = checkboxes.grassfix, cfg = "grassfix", fnc = "GrassFix"},
    [u8"Вернуть названия районов"] = {var = checkboxes.placename, cfg = "placename", fnc = "PlaceName"},
    [u8"Удаление нулей в худе"] = {var = checkboxes.moneyfontfix, cfg = "moneyfontfix", fnc = "MoneyFontFix"},
    [u8"Звёзды на экране"] = {var = checkboxes.starsondisplay, cfg = "starsondisplay", fnc = "StarsOnDisplay"},
    [u8"Фикс чувствительности мышки"] = {var = checkboxes.sensfix, cfg = "sensfix", fnc = "FixSensitivity"},
    [u8"Анимации при бездействии"] = {var = checkboxes.animidle, cfg = "animidle", fnc = "_"},
    [u8"Фикс чёрных дорог"] = {var = checkboxes.fixblackroads, cfg = "fixblackroads", fnc = "FixBlackRoads"},
    [u8"Фикс длинных рук"] = {var = checkboxes.longarmfix, cfg = "longarmfix", fnc = "FixLongArm"},
	[u8"Исправление бега в интерьерах"] = {var = checkboxes.intrun, cfg = "intrun", fnc = "InteriorRun"},
	[u8"Исправление белой точки на прицеле"] = {var = checkboxes.fixcrosshair, cfg = "fixcrosshair", fnc = "FixCrosshair"},
	[u8"Патч анимации приседа с оружием"] = {var = checkboxes.patchduck, cfg = "patchduck", fnc = "PatchDuck"},
	[u8"Вернуть размытие при езде"] = {var = checkboxes.blurreturn, cfg = "blurreturn", fnc = "BlurReturn"},
	[u8"Вернуть размытие при езде"] = {var = checkboxes.forceaniso, cfg = "forceaniso", fnc = "ForceAniso"},
}

local imguiInputsCmdEditor = {
    [u8"Открыть меню скрипта"] = {var = buffers.cmd_openmenu, cfg = "openmenu"},
    [u8"Показать ники"] = {var = buffers.cmd_shownicks, cfg = "shownicks"},
    [u8"Показать ХП игроков"] = {var = buffers.cmd_showhp, cfg = "showhp"},
    [u8"Очистить чат"] = {var = buffers.cmd_clearchat, cfg = "clearchat"},
    [u8"Показать/скрыть чат"] = {var = buffers.cmd_showchat, cfg = "showchat"},
    [u8"Показать/скрыть HUD"] = {var = buffers.cmd_showhud, cfg = "showhud"},
    [u8"Новый цвет диалоговых окон"] = {var = buffers.cmd_dialogstyle, cfg = "dialogstyle"},
    [u8"Очистка памяти"] = {var = buffers.cmd_cleanmemory, cfg = "cleanmemory"},
}

----------------------------------- Хуйня для мимгуи -----------------------------------

local listUpdate = {
	{
        v = "Beta v. 0.85",
        context = {
            u8"Change Log | Список изменений:",
            fa.PLUS..u8" Добавлен транслятор команд на кириллице (.ьь -> /mm)",
            fa.PLUS..u8" Функции SetClassSelectionColors и setDialogColor была объединена в setWindowColors.",
            fa.PLUS..u8" Добавлен LoadPatch и onSystemInitialized.",
            fa.MINUS..u8" Временно вырезана локализация клиента сампа (поддержка с R1 до R5)",
            fa.PLUS..u8" Добавлен NormalDapo Fix, а именно onSendGiveDamage.\nthx Therion: (blast.hk/threads/13892/post-563286)\nthx asdzxcjqwe: (blast.hk/threads/18162/post-563373)\nthx CaJlaT: (blast.hk/threads/13892/post-563639)",
            fa.PLUS..u8" Вспывающие уведомления (теперь они отображаются без открытого меню как раньше)",
            fa.PLUS..u8" Добавлен Homeless Flies (летающие мухи) от Chapo.",
            fa.PLUS..u8" Теперь при очистке памяти можно выбирать: очищать зону стрима или нет.",
            fa.PLUS..u8" Добавлена опция, при включении которой будет вечно гуляющий туман вне зависимости от погодных условий.",
            fa.PLUS..u8" Немного изменённое меню! Особенно заметно в меню "..tabs[4].."!\n\n",
            fa.CODE..u8" Оптимизация onShowDialog.",
            fa.CODE..u8" Была проведена чистка FFI cdef.",
            fa.CODE..u8" Переписан gotofunc.",
            fa.CODE..u8" Добавлен getChatCommands для получения команд.",
            fa.CODE..u8" Обновлена пасхалка...",
        },
    },
}

function get_samp_version()
    if samp_base == nil or samp_base == 0 then 
        samp_base = getModuleHandle("samp.dll") 
    end 

    if samp_base ~= 0 then 
        local e_lfanew = ffi.cast("long*", samp_base + 60)[0] 
        local nt_header = samp_base + e_lfanew 
        local entry_point_addr = ffi.cast("unsigned int*", nt_header + 40)[0] 
        local versions = {
            [0x31DF13] = "r1",
            [0x3195DD] = "r2",
            [0xCC4D0] = "r3",
            [0xCBCB0] = "r4",
            [0xFDB60] = "dl"
        }
        return versions[entry_point_addr] or "unknown"
    end 

    return "unknown" 
end

function setWindowColors(window_type, l_up, r_up, l_low, r_bottom)
    -- window_type - Array:
    -- # str class_selection: SetClassSelectionColors by ARMOR (https://www.blast.hk/threads/13380/post-1104630)
    -- # str dialog: setDialogColor by stereoliza (Heroku) (https://www.blast.hk/threads/13380/post-621933)
    -- colors [default color: 0xCC000000]:
    -- # l_up - left up, r_up - right up, l_low - left low, r_bottom - right bottom
    local memhuy = {
        dialog = { r1 = 0x21A0B8, r2 = 0x21A0B8, r3 = 0x26E898, r4 = 0x26E9C8, dl = 0x2AC9E0 },
        class_selection = { r1 = 0x21A18C, r2 = 0x21A194, r3 = 0x26E974, r4 = 0x26EAA4, dl = 0x2ACABC }
    }
    
    local offsets = assert(memhuy[window_type], "Invalid window_type: use 'dialog' or 'class_selection'")
    local version = get_samp_version()
    local offset = assert(offsets[version], "Unsupported SA-MP version: " .. version)
    
    local base_ptr = window_type == "dialog" and getModuleHandle("samp.dll") or sampGetBase()
    local window_ptr = memory.getuint32(base_ptr + offset, true)
    if window_type == "dialog" then window_ptr = memory.getuint32(window_ptr + 0x1C) end
    
    local colors = window_type == "dialog" and
        { {0x12A, l_up}, {0x12E, r_up}, {0x132, l_low}, {0x136, r_bottom} } or
        { {0x12A, r_bottom}, {0x12E, l_low}, {0x132, r_up}, {0x136, l_up} }
    
    for _, v in ipairs(colors) do
        memory.setuint32(window_ptr + v[1], v[2], true)
    end
end

function OffChatBack()
	memhuy = { ["r1"] = 0x65E88, ["r2"] = 0x65F58, ["r3"] = 0x693B8, ["r4"] = 0x69AE8, ["dl"] = 0x69568 }
	for k,v in pairs(memhuy) do
		if get_samp_version() == k then
			memhuy = v
		end
	end
	memory.fill(getModuleHandle("samp.dll") + memhuy, 0x90, 5, true)
end

------------------------------------------ [анимация бездействия by vegas~ (https://www.blast.hk/threads/151523/)]
local player = {
    mainTime = 0,
    time = 0,
    pos = {x = 0, y = 0, z = 0},
    anims = {
        {file = "PLAYIDLES", name = "SHIFT"},
        {file = "PLAYIDLES", name = "SHLDR"},
        {file = "PLAYIDLES", name = "STRETCH"},
        {file = "PLAYIDLES", name = "STRLEG"},
        {file = "PLAYIDLES", name = "TIME"},
        {file = "BENCHPRESS", name = "GYM_BP_CELEBRATE"},
        {file = "PED", name = "XPRESSSCRATCH"},
    },
}

local waitForIdle = 120

player.thePlayerUpdate = function()
    player.time = os.clock() + waitForIdle
end

player.thePlayer = function()
    if not isCharOnFoot(1) then
        return
    end

    local speed = getCharSpeed(1)
    local x, y, z = getActiveCameraCoordinates()

    if speed > 0 or x ~= player.pos.x or y ~= player.pos.y or z ~= player.pos.z then

        if player.mainTime ~= 0 and player.mainTime < os.clock() then
            clearCharTasksImmediately(1)
        end

        player.mainTime = os.clock() + waitForIdle
        player.thePlayerUpdate()
    end

    player.pos.x, player.pos.y, player.pos.z = x, y, z

    if player.time < os.clock() then
        player.thePlayerUpdate()

        local choosedAnim = player.anims[math.random(#player.anims)]

        if choosedAnim.file ~= "PED" then
            requestAnimation(choosedAnim.file)
        end
        taskPlayAnim(1, choosedAnim.name, choosedAnim.file, 1, false, false, false, false, -1)
        taskPlayAnim(1, choosedAnim.name, choosedAnim.file, 1, false, false, false, false, -1)
    end
end

------------------------------------------ [анимация бездействия by vegas~ (https://www.blast.hk/threads/151523/)]
local ui_meta = {
    __index = function(self, v)
        if v == "switch" then
            local switch = function()
                if self.process and self.process:status() ~= "dead" then
                    return false -- // Предыдущая анимация ещё не завершилась!
                end
                self.timer = os.clock()
                self.state = not self.state

                self.process = lua_thread.create(function()
                    local bringFloatTo = function(from, to, start_time, duration)
                        local timer = os.clock() - start_time
                        if timer >= 0.00 and timer <= duration then
                            local count = timer / (duration / 100)
                            return count * ((to - from) / 100)
                        end
                        return (timer > duration) and to or from
                    end

                    while true do wait(0)
                        local a = bringFloatTo(0.00, 1.00, self.timer, self.duration)
                        self.alpha = self.state and a or 1.00 - a
                        if a == 1.00 then break end
                    end
                end)
                return true -- // Состояние окна изменено!
            end
            return switch
        end
 
        if v == "alpha" then
            return self.state and 1.00 or 0.00
        end
    end
}

local riverya = { state = false, duration = 0.4555 }
setmetatable(riverya, ui_meta)

local riveryabook = { state = false, duration = 0.4555 }
setmetatable(riveryabook, ui_meta)

CloseButton = function(str_id, value, rounding) -- by Gorskin (edit) (https://www.blast.hk/members/157398/)
	size = size or 20
	rounding = ini.themesetting.rounded
	local DL = imgui.GetWindowDrawList()
	local p = imgui.GetCursorScreenPos()
	
	local result = imgui.InvisibleButton(str_id, imgui.ImVec2(size, size))
	if result then
		value[0] = false
	end
	local hovered = imgui.IsItemHovered()

    local col = imgui.GetColorU32Vec4(hovered and imgui.GetStyle().Colors[imgui.Col.Text] or imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
	local col_bg = imgui.ColorConvertFloat4ToU32(imgui.GetStyle().Colors[imgui.Col.FrameBg])
	local offs = (size / 4.2)
	DL:AddRectFilled(p, imgui.ImVec2(p.x + size+1, p.y + size), col_bg, rounding, 15)
	
	DL:AddLine(
		imgui.ImVec2(p.x + offs, p.y + offs), 
		imgui.ImVec2(p.x + size - offs, p.y + size - offs), 
		col,
		size / 10
	)
	DL:AddLine(
		imgui.ImVec2(p.x + size - offs, p.y + offs), 
		imgui.ImVec2(p.x + offs, p.y + size - offs),
		col,
		size / 10
	)
	return result
end
-----------------------------------------------------------------------------------------------------

function update() -- by chapo (https://www.blast.hk/threads/114312/)
    local raw = 'https://raw.githubusercontent.com/riverya4life/LunarisPrjkt/refs/heads/main/etc/update.json'
    local dlstatus = require('moonloader').download_status
    local requests = require('requests')
    local f = {}
    function f:getLastVersion()
        local response = requests.get(raw)
        if response.status_code == 200 then
            return decodeJson(response.text)['last']
        else
            return 'UNKNOWN'
        end
    end
    function f:download()
        local response = requests.get(raw)
        if response.status_code == 200 then
            downloadUrlToFile(decodeJson(response.text)['url'], thisScript().path, function (id, status, p1, p2)
                --print('Скачиваю '..decodeJson(response.text)['url']..' в '..thisScript().path)
                if status == dlstatus.STATUSEX_ENDDOWNLOAD then
					sampAddChatMessage(script_name.."{FFFFFF} Скрипт {42B166}успешно обновлен{ffffff}! Перезагрузка...", 0x73b461)
                    thisScript():reload()
                end
            end)
        else
			sampAddChatMessage(script_name.."{dc4747}[Ошибка]{ffffff} Невозможно установить обновление! Код ошибки: {dc4747}"..response.status_code, 0x73b461)
        end
    end
    return f
end

function LoadPatch()
    writeMemory(0x5B8E55, 4, 90000, true) -- flickr
    writeMemory(0x5B8EB0, 4, 90000, true) -- flickr
    local fVol = readMemory(0xEEFCEA, 4, true)
    writeMemory(0xB5FCC8, 4, fVol, true)
    writeMemory(0x5EFFE7, 1, 0xEB, true)-- disable talking
    -------------------------------------------------------------
    writeMemory(0x5557CF, 4, 0x90909090, true) -- binthesky by DK
    writeMemory(0x5557CF+3, 4, 0x90909090, true)
    writeMemory(0x53E94C, 1, 0, true) -- del fps delay 14 ms
    writeMemory(0x745BC9, 2, 0x9090, true) -- SADisplayResolutions(1920x1080// 16:9)
    writeMemory(0xC2B9CC, 4, 0x3EB3B675, true) -- car speed fps fix
    writeMemory(0x57733B, 4, 0x90909090, true) -- Отключает действие на кнопку "Начать новую игру" в меню паузы
    writeMemory(0x57733B+4, 1, 0x90, true)
    writeMemory(7547174, 4, 8753112, true) -- limit lod veh
    writeMemory(0x460500, 1, 0xC3, true) -- no replay
    writeMemory(0x70CEEF, 1, 1, true) -- фикс луны
    -------------------------------------------------------------
    local function OFFSET(POS)
        local OFFSETS = { [0x35E5B1EC] = { 0xA85E2, 0xA85D5 }, [0x583D6F47] = { 0xAD4B2, 0xAD4A5 } }
        return getModuleHandle("samp.dll") + OFFSETS[readMemory(getModuleHandle("samp.dll") + 0x90, 4, true)][POS]
    end
    writeMemory(OFFSET(1), 4, representFloatAsInt(4.0), true)
    writeMemory(OFFSET(2), 4, 0xFFFFFFFF, true)
    -------------------------------------------------------------
    local ops = {
        {memory.fill,      {0x47C8CA, 0x90, 5, true}},   -- Fix CJ Bug
        {memory.fill,      {0x555854, 0x90, 5, true}},   -- InterioRreflections
        {memory.fill,      {0x460773, 0x90, 7, false}},  -- CJFix
        {memory.fill,      {0x00531155, 0x90, 5, true}}, -- Fix Jump in AntiAFK
        {memory.fill,      {0x748E6B, 0x90, 5, true}},   -- CGame::Shutdown
        {memory.fill,      {0x748E82, 0x90, 5, true}},   -- RsEventHandler rsRWTERMINATE
        {memory.fill,      {0x748E75, 0x90, 5, true}},   -- CAudioEngine::Shutdown
        {memory.setuint8,  {0x588550, 0xEB, true}},      -- Enable this-blip
        {memory.setuint32, {0x58A4FE + 0x1, 0x0, true}}, -- Disable arrow
        {memory.setuint32, {0x586A71 + 0x1, 0x0, true}}, -- Disable green rect
        {memory.setuint8,  {0x58A5D2 + 0x1, 0x0, true}}, -- Disable height indicator
        {memory.setuint32, {0x58A73B + 0x1, 0x0, true}}, -- Disable height indicator
        {memory.setint8,   {0x58D3DA, 1, true}},         -- displayGameText border
    }

    for i, v in ipairs(ops) do
        local fn, a = v[1], v[2]
        if not fn then print(("mem fn nil at %d"):format(i)) else
            local ok, err = pcall(fn, table.unpack(a))
            if not ok then print(("op %d failed: %s"):format(i, tostring(err))) end
        end
    end
    -------------------------------------------------------------
    if memory.getuint8(0x748C2B) == 0xE8 then
		memory.fill(0x748C2B, 0x90, 5, true)
	elseif memory.getuint8(0x748C7B) == 0xE8 then
		memory.fill(0x748C7B, 0x90, 5, true)
	end
	if memory.getuint8(0x5909AA) == 0xBE then
		memory.write(0x5909AB, 1, 1, true)
	end
	if memory.getuint8(0x590A1D) == 0xBE then
		memory.write(0x590A1D, 0xE9, 1, true)
		memory.write(0x590A1E, 0x8D, 4, true)
	end
	if memory.getuint8(0x748C6B) == 0xC6 then
		memory.fill(0x748C6B, 0x90, 7, true)
	elseif memory.getuint8(0x748CBB) == 0xC6 then
		memory.fill(0x748CBB, 0x90, 7, true)
	end
	if memory.getuint8(0x590AF0) == 0xA1 then
		memory.write(0x590AF0, 0xE9, 1, true)
		memory.write(0x590AF1, 0x140, 4, true)
	end
    -------------------------------------------------------------
    ---disable input in framelimiter menu (пока не нужно)
    --writeMemory(0xBA6748+0x4C, 1, 0, true)
    --writeMemory(0x57CEC7,4, 0x0008C2, true)
    ------------------------------------------
end

function onSystemInitialized()
    writeMemory(0xFDEAC5, 4, representFloatAsInt(readMemory(0xB6EC1C, 4, true)), true)--curr sens
    --ffi.C.SetPriorityClass(ffi.C.GetCurrentProcess(), 0x00008000)
    local originalVol = representIntAsFloat(readMemory(0xB5FCC8, 4, true))
    writeMemory(0xEEFCEA, 4, representFloatAsInt(originalVol), true)
    if originalVol < 0.0625 then
        writeMemory(0xB5FCC8, 4, representFloatAsInt(0.1000), true)
    end
    LoadPatch()
end

------------------------------------------ [FFI cdef] ---------------------------

ffi.cdef [[
    struct std_string { 
        union { 
            char buf[16]; 
            char* ptr; 
        }; 
        unsigned size; 
        unsigned capacity; 
        };
    struct stCommandInfo { 
        struct std_string name; 
        int type; 
        void* owner; 
    };
    struct std_vector_stCommandInfo { 
        struct stCommandInfo* first; 
        struct stCommandInfo* last; 
        struct stCommandInfo* end; 
    };

	typedef unsigned long HANDLE;
	typedef HANDLE HWND;
	typedef struct _RECT {
		long left;
		long top;
		long right;
		long bottom;
	} RECT, *PRECT;

	HWND GetActiveWindow(void);

	bool GetWindowRect(
		HWND   hWnd,
		PRECT lpRect
	);

	bool ClipCursor(const RECT *lpRect);

	bool GetClipCursor(PRECT lpRect);

    int MessageBoxA(
        void* hWnd, 
        const char* lpText, 
        const char* lpCaption, 
        unsigned int uType
    );
]]

local rcClip, rcOldClip = ffi.new('RECT'), ffi.new('RECT')

------------------------------------------ [FFI cdef] ---------------------------

function riveryahello()
    local currentVersion = thisScript().version
    local lastver = update():getLastVersion()

    if ini.main.riveryahellomsg then
        local openMenuKey = table.concat(rkeys.getKeysName(ActOpenMenuKey.v), " + ")
        sampAddChatMessage(
            string.format(
                "%s{FFFFFF} Загружен! Открыть меню: {dc4747}%s{FFFFFF} или {dc4747}%s. {FFFFFF}Автор: {dc4747}%s", 
                script_name, openMenuKey, ini.commands.openmenu, script_author
            ), 
            0x73b461
        )
    end

    updatesavaliable = currentVersion < lastver
    if updatesavaliable then
        addOneOffSound(0, 0, 0, 1058)
    end
end

function main()
    --------------------- [ dual monitor fix] --------------
    ffi.C.GetWindowRect(ffi.C.GetActiveWindow(), rcClip);
    ffi.C.ClipCursor(rcClip);
    --------------------------------------------------------
    while not isSampAvailable() do wait(0) end

    writeMemory(0x9848DC, 1, 1, true) -- thx asdzxcjqwe: (blast.hk/threads/18162/post-563373)
	runSampfuncsConsoleCommand('0ABA: end_custom_thread_named "noname"')
	runSampfuncsConsoleCommand('0ABA: end_custom_thread_named "AutoReg"') -- thx CaJlaT: (blast.hk/threads/13892/post-563639)
    sampfuncsLog('{52BE80}[NormalDapo Fix] {FFFFFF}Загружен.')

	gotofunc("all") -- load all func
    OffChatBack()
    
	-- rp guns by Gorskin --------------------
	rp_guns_thread = lua_thread.create_suspended(rp_weapons)
    rp_guns_thread:run()
	-- rp guns by Gorskin --------------------
	
	local duration = 0.3 -- Описание персонажа by Cosmo (https://www.blast.hk/threads/84975/)
	local max_alpha = 255 -- Описание персонажа by Cosmo (https://www.blast.hk/threads/84975/)
	local start = os.clock() -- Описание персонажа by Cosmo (https://www.blast.hk/threads/84975/)
	local finish = nil -- Описание персонажа by Cosmo (https://www.blast.hk/threads/84975/)

	---=== HotKeys ===---
	bindOpenmenu = rkeys.registerHotKey(ActOpenMenuKey.v, true, function()
        if not sampIsCursorActive() then
            riverya.switch()
        end
    end)
    ---=== HotKeys ===---
	book()
	
	-- анимация бездействия by vegas~ (https://www.blast.hk/threads/151523/)
	for i, k in pairs(player.anims) do
        if k.file ~= "PED" then
            requestAnimation(k.file)
        end
    end

    addEventHandler("onWindowMessage", function(msg, wparam, lparam)
        if (riverya.state or riveryabook.state) and (msg == 0x100 or msg == 0x101) and wparam == vkeys.VK_ESCAPE and not (isPauseMenuActive() or isGamePaused()) then
            consumeWindowMessage(true, false)
            if msg == 0x101 then
                (riverya.state and riverya or riveryabook).switch()
            end
        end

        if ini.nop_samp_keys.key_ALTENTER and msg == 261 and wparam == 13 then
            consumeWindowMessage(true, true)
        end

        if sampIsDialogActive() then
            if msg == wm.msg.WM_LBUTTONDOWN then
                local curX, curY = getCursorPos()
                local x, y = sampGetDialogPos()
                local w = sampGetDialogSize()
                local h = sampGetDialogCaptionHeight()
                if curX >= x and curX <= x + w and curY >= y and curY <= y + h then
                    dragging = true
                    dragX, dragY = x - curX, y - curY
                end
            elseif msg == wm.msg.WM_LBUTTONUP then
                dragging = false
            elseif msg == wm.msg.WM_MOUSEMOVE and dragging then
                local curX, curY = getCursorPos()
                local _, scrY = getScreenResolution()
                sampSetDialogPos(curX + dragX, math.min(math.max(curY + dragY, -15), scrY - 15))
            end
        end
        --------------------- [ dual monitor fix] --------------
        if msg == wm.WM_KILLFOCUS then
			ffi.C.GetClipCursor(rcOldClip);
			ffi.C.ClipCursor(rcOldClip);
		elseif msg == wm.WM_SETFOCUS then
			ffi.C.GetWindowRect(ffi.C.GetActiveWindow(), rcClip);
			ffi.C.ClipCursor(rcClip);
        end
		--------------------------------------------------------
    end)

    while true do
        wait(0)
		
		if ini.fixes.animidle then
			player.thePlayer() -- анимация бездействия by vegas~ (https://www.blast.hk/threads/151523/)
		end
		
		local car = storeCarCharIsInNoSave(playerPed)
		if car > 0 then
			setCarDrivingStyle(car, 5)
		end
		
		onspawned = sampGetGamestate() == 3
		if onspawned then
			if offspawnchecker == true then			
				riveryahello()
				welcome_text = 'WelCUM to the gym'
				printStyledString("~n~~n~~n~~n~~n~~n~~w~"..welcome_text.."~n~~b~", 500, 2)
			offspawnchecker = false
			end
		end
		
		if script_author ~= 'riverya4life.' then
			ShowMessage("Ошибка выполнения! \n \nПрограмма: " ..getGameDirectory().. "\\moonloader\\!.lunarisprjkt.lua \n \nЭто приложение запросило у среды выполнения необычное завершение его работы. \nПожалуйста, свяжитесь со службой поддержки приложения для получения дополнительной информации.\n\nНу а вообще, риверя пидорас блять ёбаный.", "Microsoft Visual C++ Runtime Library", 0x10)
			callFunction(0x823BDB , 3, 3, 0, 0, 0)
		end
        
        local chatstring = sampGetChatString(99)
        local disconnectMessages = {
            "Server closed the connection.",
            "You are banned from this server.",
            "Сервер закрыл соединение.",
            "Вы забанены на этом сервере."
        }
        if disconnectMessages[chatstring] then
            sampDisconnectWithReason(false)
            sampAddChatMessage("Переподключение...", 0xa9c4e4)
            wait(15000)
            sampSetGamestate(1)
        end
		
		if ini.fixes.blurreturn then
			car = storeCarCharIsInNoSave(PLAYER_PED)
			if isCharInCar(PLAYER_PED, car) then
				speed = getCarSpeed(car)
				if speed >= 120.0 then
					shakeCam(2.5)
				end
			end
		end
		
        ---------------- -- прицел на транспорте by Cosmo (https://www.blast.hk/threads/72683/)
		if isCharInAnyCar(playerPed) then
			local car = storeCarCharIsInNoSave(playerPed)
			local cX, cY, cZ = getCarCoordinates(car)
			if vehHaveGun() then
				fX, fY, fZ = getOffsetFromCarInWorldCoords(car, 0, 128, 0)
				local result, tPoint = processLineOfSight(cX, cY, cZ, fX, fY, fZ, true, false, true, true, false, false, false, true)
				if result then fX, fY, fZ = tPoint.pos[1], tPoint.pos[2], tPoint.pos[3] end
				local _, gx, gy, z, _, _ = convert3DCoordsToScreenEx(fX, fY, fZ)
				if z > 1 then renderCrosshair(gx, gy) end
			elseif isCharInModel(playerPed, 432) then
				local oX, oY, oZ = getOffsetFromCarInWorldCoords(car, 0, 0, 1.1)
		        if not rail then rail = createObject(1551, oX, oY, oZ) end
		        if rail then
		        	local x, y = getRhinoCannonCorner(car)
			        attachObjectToCar(rail, car, 0.0, 0.0, 1.1, y, 0.0, x)
			        local x1, y1, z1 = getOffsetFromObjectInWorldCoords(rail, 0.0, 6.5, 0.0)
			        local x2, y2, z2 = getOffsetFromObjectInWorldCoords(rail, 0.0, 67.0, .0)
			        local result, tPoint = processLineOfSight(x1, y1, z1, x2, y2, z2, true, false, true, true, false, false, false, true)
					if result then x2, y2, z2 = tPoint.pos[1], tPoint.pos[2], tPoint.pos[3] end
					local _, gx, gy, z, _, _ = convert3DCoordsToScreenEx(x2, y2, z2)
					if z > 1 then renderCrosshair(gx, gy) end
				end
			end
		else
			if rail then deleteObject(rail); rail = nil end
		end
        ----------------
		if ini.main.bindkeys then
			if isCharOnAnyBike(playerPed) and isKeyCheckAvailable() and isKeyDown(0xA0) then	-- onBike&onMoto SpeedUP [[LSHIFT]] by checkdasound --
                local bike = {[481] = true, [509] = true, [510] = true}
                local moto = {[448] = true, [461] = true, [462] = true, [463] = true, [468] = true, [471] = true, [521] = true, [522] = true, [523] = true, [581] = true, [586] = true}
				if bike[getCarModel(storeCarCharIsInNoSave(playerPed))] then
					setGameKeyState(16, 255)
					wait(10)
					setGameKeyState(16, 0)
				elseif moto[getCarModel(storeCarCharIsInNoSave(playerPed))] then
					setGameKeyState(1, -128)
					wait(10)
					setGameKeyState(1, 0)
				end
			end
			
			if isCharOnFoot(playerPed) and isKeyDown(0x31) and isKeyCheckAvailable() then -- onFoot&inWater SpeedUP [[1]] by checkdasound --
				setGameKeyState(16, 256)
				wait(10)
				setGameKeyState(16, 0)
			elseif isCharInWater(playerPed) and isKeyDown(0x31) and isKeyCheckAvailable() then
				setGameKeyState(16, 256)
				wait(10)
				setGameKeyState(16, 0)
			end

            local function canExecuteCommand()
                return not sampIsChatInputActive() and
                       not sampIsDialogActive() and
                       not isPauseMenuActive() and
                       not isSampfuncsConsoleActive()
            end

            if canExecuteCommand() then
                local keyCommands = {
                    [0x4C] = "/lock",      -- VK_L
                    [0x4B] = "/key",       -- VK_K
                    [0x58] = "/style",     -- VK_X
                    [0x50] = "/phone",     -- VK_P
                    [0x35] = "/mask",      -- VK_5
                    [0x34] = "/armour",    -- VK_4
                    [0x33] = "/anim 3",    -- VK_3
                    [0x5A] = "/usedrugs 1" -- VK_Z
                }
                
                -- Таблица для комбинаций с Alt (VK_MENU)
                local altKeyCommands = {
                    [0x63] = "/eat",       -- VK_NUMPAD3
                    [0x52] = "/repcar",    -- VK_R
                    [0x32] = "/fillcar"    -- VK_2
                }
                
                -- Проверка одиночных клавиш
                for key, command in pairs(keyCommands) do
                    if isKeyJustPressed(key) then
                        sampSendChat(command)
                    end
                end
                
                -- Проверка комбинаций с Alt (VK_MENU = 0x12)
                if isKeyDown(0x12) then
                    for key, command in pairs(altKeyCommands) do
                        if isKeyJustPressed(key) then
                            sampSendChat(command)
                        end
                    end
                end
            end
		end
        ---------------- Описание персонажа by Cosmo (https://www.blast.hk/threads/84975/)
		local result, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
		if result then
			finish = nil
			local id = select(2, sampGetPlayerIdByCharHandle(ped))
			if pool[id] ~= nil then
				if active == nil then start = os.clock() end
				local alpha = saturate(((os.clock() - start) / duration) * max_alpha)
				local color = join_argb((os.clock() - start) <= duration and alpha or max_alpha, 204, 204, 204)
				active = pool[id]
				sampCreate3dTextEx(pool[id].id, pool[id].text, color, pool[id].pos.x, pool[id].pos.y, pool[id].pos.z, pool[id].dist, pool[id].wall, pool[id].PID, -1)
			else
				if active == nil then start = os.clock() end
				local alpha = saturate(((os.clock() - start) / duration) * max_alpha)
				local color = join_argb((os.clock() - start) <= duration and alpha or max_alpha, 204, 204, 204)
				active = {id = 13, text = no_description_text, col = color, pos = {x = 0, y = 0, z = -1}, dist = 3, wall = false, PID = id, VID = -1}
				sampCreate3dTextEx(active.id, active.text, color, active.pos.x, active.pos.y, active.pos.z, active.dist, active.wall, active.PID, active.VID)
			end
		elseif active ~= nil then
			if finish == nil then finish = os.clock() end
			local alpha = saturate(((os.clock() - finish) / duration) * max_alpha)
			local color = join_argb(max_alpha - alpha, 204, 204, 204)
			sampCreate3dTextEx(active.id, active.text, color, active.pos.x, active.pos.y, active.pos.z, active.dist, active.wall, active.PID, active.VID)
			if (os.clock() - finish) >= duration then
				sampDestroy3dText(active.id)
				active, finish = nil, nil
			end
		end

        ---------------- Описание персонажа by Cosmo (https://www.blast.hk/threads/84975/)

		if ini.main.blockweather == true and memory.read(0xC81320, 2, true) ~= ini.main.weather then
			gotofunc("SetWeather") 
		end

		if ini.main.blocktime == true and memory.read(0xB70153, 1, true) ~= ini.main.hours then 
			gotofunc("SetTime") 
		end
		
		if ini.main.givemedist == true then
            memory.write(0x53EA95, 0xB7C7F0, 4, true)-- вкл
			memory.write(0x7FE621, 0xC99F68, 4, true)-- вкл
		else
			memory.write(0x53EA95, 0xB7C4F0, 4, true)-- выкл
			memory.write(0x7FE621, 0xC992F0, 4, true)-- выкл
		end
		
		if memory.setfloat(12044272, true) ~= ini.main.drawdist then
			memory.setfloat(12044272, ini.main.drawdist, true)
		end
		if isCharInAnyPlane(PLAYER_PED) or isCharInAnyHeli(PLAYER_PED) then
			if memory.getfloat(12044272, true) ~= ini.main.drawdistair then
				memory.setfloat(12044272, ini.main.drawdistair, true)
			end
		end
		if getCurrentCharWeapon(PLAYER_PED) == 46 then
			if memory.getfloat(12044272, true) ~= ini.main.drawdistpara then
				memory.setfloat(12044272, ini.main.drawdistpara, true)
			end
		end
		if memory.setfloat(13210352, true) ~= ini.main.fog then
			memory.setfloat(13210352, ini.main.fog, true)
		end

        if ini.cleaner.autoclean then
            if tonumber(get_memory()) > tonumber(ini.cleaner.limit) then
                gotofunc("CleanMemory")
            end
        end
		
		if ini.fixes.placename then -- Regions by Nishikinov
			gotofunc("PlaceName")
		end

        --[[
        if enabled then
            if isCurrentCharWeapon(PLAYER_PED, 34) and isKeyDown(2) then
                if not locked then 
                    cameraSetLerpFov(70.0, 70.0, 1000, 1)
                    locked = true
                end
            else
                cameraSetLerpFov(101.0, 101.0, 1000, 1)
                locked = false
            end
        end]]
		
		--fix bug photograph
        if getCurrentCharWeapon(PLAYER_PED) == 43 and readMemory(0x70476E, 4, true) == 2866 and readMemory(0x53E227, 1, true) ~= 233 then
            writeMemory(0x53E227, 1, 0xE9, true)
        elseif getCurrentCharWeapon(PLAYER_PED) ~= 43 and readMemory(0x53E227, 1, true) ~= 195 and readMemory(0x70476E, 4, true) == 2866 then
            writeMemory(0x53E227, 1, 0xC3, true)
        end

		----------------------------------------------------------------
        CDialog = sampGetDialogInfoPtr()
        CDXUTDialog = memory.getuint32(CDialog + 0x1C)
        ----------------------------------------------------------------
    end
end

function isKeyCheckAvailable()
	if not isSampLoaded() then
		return true
	end
	if not isSampfuncsLoaded() then
		return not sampIsChatInputActive() and not sampIsDialogActive()
	end
	return not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive()
end

function samp.onShowDialog(id, style, title, button1, button2, text)
    local dialogStyleOverrides = {
        ["{929290}Вы должны подтвердить свой PIN-код к карточке.\nВведите свой код в ниже указаную строку."] = 3,
        ["{ffffff}Чтобы открыть этот склад, введите специальный"] = 3,
    }

    if id == 1000 then
        sampSendDialogResponse(1000, 1, 0, 0)
        return false
    end

    if text then
        for k, v in pairs(dialogStyleOverrides) do
            if text:find(k, 1, true) then
                style = v
                break
            end
        end
    end
    return { id, style, title, button1, button2, text }
end

RakLua.registerHandler(RakLuaEvents.OUTGOING_RPC,
    function(id, bs, priority, reliability, orderingChannel, shiftTimestamp)
        if id == 50 then
            local cmd_len = bs:readInt32()
            local cmd = bs:readString(cmd_len)
        
            cmd = string.lower(cmd)

            local commands = {
                [ini.commands.openmenu] = function()
                    gotofunc("OpenMenu")
                end,
                ["/riveryaloh"] = function()
                    CallBSOD()
                end,
                [ini.commands.shownicks] = function()
                    ini.main.shownicks = not ini.main.shownicks
                    gotofunc("ShowNicks")
                    save()
                    sampAddChatMessage(string.format("%s {FFFFFF}Ники игроков %s", 
                        script_name, ini.main.shownicks and "{73b461}включены" or "{dc4747}выключены"), 0x73b461
                    )
                end,
                [ini.commands.showhp] = function()
                    ini.main.showhp = not ini.main.showhp
                    gotofunc("ShowHP")
                    save()
                    sampAddChatMessage(string.format("%s {FFFFFF}ХП игроков %s", 
                        script_name, ini.main.showhp and "{73b461}включен" or "{dc4747}выключен"), 0x73b461
                    )
                end,
                [ini.commands.gameradio] = function()
                    ini.main.noradio = not ini.main.noradio
                    gotofunc("NoRadio")
                    save()
                    sampAddChatMessage(string.format("%s {FFFFFF}Радио %s", 
                        script_name, ini.main.noradio and "{73b461}включено" or "{dc4747}выключено"), 0x73b461
                    )
                end,
                [ini.commands.delgun] = function()
                    ini.main.delgun = not ini.main.delgun
                    gotofunc("DelGun")
                    save()
                    sampAddChatMessage(string.format("%s {FFFFFF}Удаление всего оружия в руках на клавишу DELETE %s", 
                        script_name, ini.main.delgun and "{73b461}включено!" or "{dc4747}отключено!"), -1
                    )
                end,
                [ini.commands.clearchat] = function()
                    gotofunc("ClearChat")
                end,
                [ini.commands.showchat] = function()
                    ini.main.showchat = not ini.main.showchat
                    gotofunc("ShowChat")
                    save()
                    sampAddChatMessage(string.format("%s {FFFFFF}Чат %s", 
                        script_name, ini.main.showchat and "{dc4747}отключен!" or "{73b461}включен!"), -1
                    )
                end,
                [ini.commands.dialogstyle] = function()
                    ini.themesetting.dialogstyle = not ini.themesetting.dialogstyle
                    gotofunc("DialogStyle")
                    save()
                    checkboxes.dialogstyle[0] = ini.themesetting.dialogstyle
                    sampAddChatMessage(string.format("%s {FFFFFF}Новый цвет диалогов %s", 
                        script_name, ini.themesetting.dialogstyle and "{73b461}включен!" or "{dc4747}отключен!"), -1
                    )
                end,
                [ini.commands.showhud] = function()
                    ini.main.showhud = not ini.main.showhud
                    gotofunc("ShowHud")
                    save()
                    sampAddChatMessage(string.format("%s {FFFFFF}HUD %s", 
                        script_name, ini.main.showhud and "{73b461}включен!" or "{dc4747}отключен!"), -1
                    )
                end,
                [ini.commands.cleanmemory] = function()
                    gotofunc("CleanMemory")
                end
            }

            for cmd_pattern, action in pairs(commands) do
                if cmd:find("^" .. cmd_pattern .. "$") then
                    action()
                    return false
                end
            end
        end
    end
)

function onReceiveRpc(id, bs)
    local block_time_ids = { [29] = true, [30] = true, [94] = true }
    if (ini.main.blocktime and block_time_ids[id]) or (ini.main.blockweather and id == 152) then
        return false
    end
end

local SMILE_TEXT = {
    ["=("] = { "/me выглядит огорченным, чем-то расстроен", "/me выглядит огорченной, чем-то расстроена" },
    ["("] = { "/me слегка расстроен, не подаёт виду", "/me слегка расстроена, не подаёт виду" },
    [":("] = { "/me выглядит подавленным, грустит", "/me выглядит подавленной, грустит" },
    [":(("] = { "/me очень расстроился, выглядит убитым", "/me очень расстроилась, выглядит убитой" },
    [":с"] = { "/me печально опустил нижнюю губу", "/me печально опустила нижнюю губу" },
    ["о_о"] = { "/me выпучил глаза от удивления", "/me выпучила глаза от удивления" },
    ["О_О"] = { "/me очень сильно шокирован", "/me очень сильно шокирована" },
    [":о"] = { "/me слегка удивлён", "/me слегка удивлена" },
    [":О"] = { "/me сильно удивился, охает", "/me сильно удивилась, охает" },
    [":/"] = "/me испытывает легкое недовольство",
    ["-_-"] = "/me испытывает недовольное отвращение",
    ["=_="] = "/me испытывает недовольное отвращение",
    [":D"] = "/me добродушно смеется",
    ["xD"] = "/me угарает во весь голос, закрывая глаза со смеху",
    ["c:"] = { "/me скруглил щёки, доволен как ребёнок", "/me скруглила щёки, довольна как ребёнок" },
    ["C:"] = "/me сильно радуется с блестящими глазами",
    [":*"] = "/me посылает воздушный поцелуй",
    ["=)"] = { "/me улыбается как придурок с лёгкой иронией", "/me улыбается как дурочка с лёгкой иронией" },
    [")"] = "/me легонько улыбается",
    ["))"] = { "/me давит лыбу, чем-то доволен", "/me давит лыбу, чем-то довольна" },
    [":)"] = "/me добродушно улыбается",
    [":))"] = "/me лыбится во весь рот",
    [";)"] = "/me легонько подмигивает",
    [";("] = "/me тихо плачет неторопливыми слезами",
    [";(("] = "/me ревёт, захлёбывается слезами",
    [":-)"] = "/me улыбается как глупый клоун",
}

function getSmileList(gender)
    local list = {}
    for emote, v in pairs(SMILE_TEXT) do
        local text = type(v) == "table" and v[gender + 1] or v
        text = text:gsub("^/me%s+", "")
        table.insert(list, emote .. " - " .. text)
    end
    table.sort(list)
    return table.concat(list, "\n")
end

function getBindList()
    local list = {}
    local BIND_KEYS_INFO = {
        { key = "L", action = "Открыть/закрыть машину" },
        { key = "K", action = "Вставить/вытащить ключи" },
        { key = "X", action = "Стиль езды (Comfort | Sport)" },
        { key = "P", action = "Телефон" },
        { key = "5", action = "Надеть/снять маску" },
        { key = "4", action = "Надеть/снять бронежилет" },
        { key = "3", action = "Танцевать" },
        { key = "Z", action = "Принять наркотики" },
        { key = "Alt + Num3", action = "Покушать" },
        { key = "Alt + R", action = "Починить машину" },
        { key = "Alt + 2", action = "Заправить машину" }
    }
    for i = 1, #BIND_KEYS_INFO do
        local key, action = BIND_KEYS_INFO[i].key, BIND_KEYS_INFO[i].action
        table.insert(list, key .. " - " .. action)
    end
    table.sort(list)
    return table.concat(list, "\n")
end

function sampev.onSendChat(msg)
    if ini.main.smilesys then
        for k, v in pairs(SMILE_TEXT) do
            if msg == k then
                sampSendChat(type(v) == "table" and v[ini.main.gender + 1] or v)
                return false
            end
        end
    end
    ----------------------- separate messages by Gorskin (https://www.blast.hk/members/157398/)
    if ini.main.separate_msg == true then
        if bi then bi = false; return end
        local length = msg:len()
        if length > 83 then
            divide(msg, "", "")
            return false
        end

		msg = string.gsub(msg, "^[А-zА-я]", function(s)
			for i = 224, 255 do
				s = string.gsub(s, _G.string.char(i), _G.string.char(i - 32))
			end
			s = string.gsub(s, _G.string.char(184), _G.string.char(168))
			return string.upper(s)
		end)
		msg = string.gsub(msg, "%s*$", "")
		if not string.find(msg, "%p$") then
			return { msg .. "." }
		end
		return { msg }
    end
    --------------------------------
    if msg:find("^%.(.+)") then
    --if msg:find("^%.") then
        local chars = {
            ["й"] = "q", ["ц"] = "w", ["у"] = "e", ["к"] = "r", ["е"] = "t", ["н"] = "y", ["г"] = "u", ["ш"] = "i", ["щ"] = "o", ["з"] = "p", ["х"] = "[", ["ъ"] = "]", ["ф"] = "a",
            ["ы"] = "s", ["в"] = "d", ["а"] = "f", ["п"] = "g", ["р"] = "h", ["о"] = "j", ["л"] = "k", ["д"] = "l", ["ж"] = ";", ["э"] = "'", ["я"] = "z", ["ч"] = "x", ["с"] = "c", ["м"] = "v",
            ["и"] = "b", ["т"] = "n", ["ь"] = "m", ["б"] = ",", ["ю"] = ".", ["Й"] = "Q", ["Ц"] = "W", ["У"] = "E", ["К"] = "R", ["Е"] = "T", ["Н"] = "Y", ["Г"] = "U", ["Ш"] = "I",
            ["Щ"] = "O", ["З"] = "P", ["Х"] = "{", ["Ъ"] = "}", ["Ф"] = "A", ["Ы"] = "S", ["В"] = "D", ["А"] = "F", ["П"] = "G", ["Р"] = "H", ["О"] = "J", ["Л"] = "K", ["Д"] = "L",
            ["Ж"] = ":", ["Э"] = "\"", ["Я"] = "Z", ["Ч"] = "X", ["С"] = "C", ["М"] = "V", ["И"] = "B", ["Т"] = "N", ["Ь"] = "M", ["Б"] = "<", ["Ю"] = ">"
        }
        local system_commands = {
            "q", "quit", "save", "rs", "interior", "fpslimit", "rcon", 
            "pagesize", "fontsize", "headmove", "mem", "timestamp",
            "dl", "nametagstatus", "audiomsg", "testdw", "togobjlight", 
            "ctd", "cmpstat", "hudscalefix", "logurls",
        }
        --local cmd, args = msg:match("^%.([^%s]*)(.*)")
        local cmd, args = msg:match("^%.(%S+)%s*(.*)$")  -- вот эта строка важна
        if not cmd then return false end

        -- Транслитерируем ТОЛЬКО команду
        local cmd_en = cmd
        for ru, en in pairs(chars) do
            cmd_en = cmd_en:gsub(ru, en)
        end

        -- Формируем финальную команду: /mm [оригинальные аргументы как есть]
        local final_cmd = "/" .. cmd_en
        if args ~= "" then
            final_cmd = final_cmd .. " " .. args
        end
        
        lua_thread.create(function()
            wait(0)
            if system_commands[transformed_cmd] or getChatCommands() then
                sampProcessChatInput(final_cmd)
            else
                sampSendChat(final_cmd)
            end
        end)
        return false
    end
end

function sampev.onSendGiveDamage(playerID, damage, weapon, bodyPart)
    local function weaponCheck(id) -- thx Therion: (blast.hk/threads/13892/post-563286)
        return getCurrentCharWeapon(PLAYER_PED) == tonumber(id)
    end
	local name = sampGetPlayerNickname(playerID)
    local autismPlayers = { 
        "[DM]Black_Jesus.", "[GW]Black_Jesus.", "Black_Jesus", 
        "[DM]Dapo_Dope", "[GW]Dapo_Dope", "Dapo_Dope", "Jesus_Black", 
        "Mira_Headdyson", "Jezus_Black", "Jezuz_Black" 
    }
	for j = 1, #autismPlayers do
		if name == autismPlayers[j] and weaponCheck(weapon) and sampIsPlayerConnected(playerID) and not sampIsPlayerNpc(playerID) then
			sampSendGiveDamage(playerID, damage, weapon, bodyPart)
		end
	end
end

-- Homeless Flies by Chapo

function sampev.onPlayerStreamIn(id, _, model, ...)
    HomelessFlies(id, model)
end

function sampev.onSetPlayerSkin(id, model)
    HomelessFlies(id, model)
end

function sampev.onPlayerStreamOut(id)
    HomelessFlies(id, nil, true)
end

function HomelessFlies(id, model, forceRemove)
    if not table.includes(bums, model) or forceRemove then
        local obj = bums_pool[id]
        if obj then
            if doesObjectExist(obj) then
                deleteObject(obj)
            end
            bums_pool[id] = nil
        end
    else
        lua_thread.create(function()
            wait(5)
            local result, ped = sampGetCharHandleBySampPlayerId(id)
            if result then
                local newObject = createObject(18698, 0, 0, 0)
                attachObjectToChar(newObject, ped, 0, 0, -1.4, 0, 0, 0)
                bums_pool[id] = newObject
            end
        end)
    end
end

function table.includes(self, value)
    for k, v in pairs(self) do
        if v == value then return true end
    end
end

-- Homeless Flies by Chapo

function samp.onSendCommand(msg)
--------------- separate messages by Gorskin (https://www.blast.hk/members/157398/) ---------------------------------
    if ini.main.separate_msg == true then
        if bi then bi = false; return end
        local cmd, msg = msg:match("/(%S*) (.*)")
        if msg == nil then return end
        if cmd == "sms" or cmd == "t" or cmd == "todo" or cmd == "seeme" then return end
        -- cmd = cmd:lower()

        --Рация, радио, ООС чат, шепот, крик (с поддержкой переноса ООС-скобок)
        local chatcommands = {'c', 's', 'b', 'w', 'r', 'm', 'd', 'f', 'rb', 'fb', 'rt', 'pt', 'ft', 'cs', 'ct', 'fam', 'vr', 'al', 'me', 'do', 'todo', 'seeme', 'fc', 'u', 'jb', 'j', 'jf', 'a', 'o'}
        for i, v in ipairs(chatcommands) do if cmd == v then
            local length = msg:len()
            if msg:sub(1, 2) == "((" then
                msg = string.gsub(msg:sub(4), "%)%)", "")
                if length > 80 then divide(msg, "/" .. cmd .. " (( ", " ))"); return false end
            else
                if length > 80 then divide(msg, "/" .. cmd .. " ", ""); return false end
            end
        end end

        --РП команды
        if cmd == "me" or cmd == "do" then
            local length = msg:len()
            if length > 75 then divide(msg, "/" .. cmd .. " ", "", "ext"); return false end
        end
    end
end

function divide(msg, beginning, ending, doing) -- разделение сообщения msg на два by Gorskin (https://www.blast.hk/members/157398/)
	limit = 72
	
	local one, two = string.match(msg:sub(1, limit), "(.*) (.*)")
	if two == nil then two = "" end 
	local one, two = one .. "...", "..." .. two .. msg:sub(limit + 1, msg:len())

	bi = true; sampSendChat(beginning .. one .. ending)
	if doing == "ext" then
		beginning = "/do "
		if two:sub(-1) ~= "." then two = two .. "." end
	end
	bi = true; lua_thread.create(function() wait(1400) sampSendChat(beginning .. two .. ending) end) 
end

function samp.onCreate3DText(id, col, pos, dist, wall, PID, VID, text) -- описание персонажа
	if PID ~= 65535 and col == -858993409 and pos.z == -1 then
		pool[PID] = {id = id, col = col, pos = pos, dist = dist, wall = wall, PID = PID, VID = VID, text = text }
		return false
	end
end

function samp.onRemove3DTextLabel(id) -- описание персонажа by Cosmo (https://www.blast.hk/threads/84975/)
	for i, info in ipairs(pool) do
		if info.id == id then
			table.remove(pool, i)
		end
	end
end

function rp_weapons()
    if not ini.main.rpguns then return end

    local isMale = tonumber(ini.main.gender) == 0
    local rpTakeNames = {{"из-за спины", "за спину"}, {"из кармана", "в карман"}, {"из пояса", "на пояс"}, {"из кобуры", "в кобуру"}}
    local rpTake = {[2]=1, [5]=1, [6]=1, [7]=1, [8]=1, [9]=1, [14]=1, [15]=1, [25]=1, [26]=1, [27]=1, [28]=1, [29]=1, [30]=1, [31]=1, [32]=1, [33]=1, [34]=1, [35]=1, [36]=1, [37]=1, [38]=1, [42]=1, [1]=2, [4]=2, [10]=2, [11]=2, [12]=2, [13]=2, [41]=2, [43]=2, [44]=2, [45]=2, [46]=2, [3]=3, [16]=3, [17]=3, [18]=3, [39]=3, [40]=3, [22]=4, [23]=4, [24]=4}
    local gunOn, gunOff, gunPartOn, gunPartOff = {}, {}, {}, {}
    local specialOn, specialOff = {[3]=1, [16]=1, [17]=1, [18]=1}, {[3]=1, [16]=1, [17]=1, [18]=1, [39]=1, [40]=1}

    for id in pairs(weapons.names) do
        gunOn[id] = specialOn[id] and (isMale and 'снял' or 'сняла') or (isMale and 'достал' or 'достала')
        gunOff[id] = specialOff[id] and (isMale and 'повесил' or 'повесила') or (isMale and 'убрал' or 'убрала')
        if id > 0 then gunPartOn[id], gunPartOff[id] = rpTakeNames[rpTake[id]][1], rpTakeNames[rpTake[id]][2] end
    end

    local nowGun = getCurrentCharWeapon(PLAYER_PED)
    while true do
        wait(0)
        local currentGun = getCurrentCharWeapon(PLAYER_PED)
        if nowGun ~= currentGun then
            local oldGun = nowGun
            nowGun = currentGun
            sampSendChat(
                oldGun == 0 and string.format("/me %s %s %s", gunOn[nowGun], weapons.get_name(nowGun), gunPartOn[nowGun]) or
                nowGun == 0 and string.format("/me %s %s %s", gunOff[oldGun], weapons.get_name(oldGun), gunPartOff[oldGun]) or
                string.format("/me %s %s %s, после чего %s %s %s", gunOff[oldGun], weapons.get_name(oldGun), gunPartOff[oldGun], gunOn[nowGun], weapons.get_name(nowGun), gunPartOn[nowGun])
            )
        end
    end
end

function createTextdraw(color, shadowColor)
    id = id or (function()
        for i = 1, 10000 do 
            if not sampTextdrawIsExists(i) then return i end 
        end
    end)()

    sampTextdrawCreate(id, "usebox", -7.000000, -7.000000)
    sampTextdrawSetLetterSizeAndColor(id, 0.474999, 55.000000, 0x00000000)
    sampTextdrawSetBoxColorAndSize(id, 1, color, 638.000000, 62.000000)
    sampTextdrawSetShadow(id, 0, shadowColor)
    sampTextdrawSetOutlineColor(id, 1, shadowColor)
    sampTextdrawSetAlign(id, 1)
    sampTextdrawSetProportional(id, 1)
end

function toggleScreen(screenType)
    local colors = {
        green = {0xFF008000, 0xFF008000},
        black = {0xFF000000, 0xFF000000}
    }

    if colors[screenType] then
        if not screens[screenType] then
            createTextdraw(colors[screenType][1], colors[screenType][2])
            screens[screenType] = true
        else
            sampTextdrawDelete(id)
            id = nil
            screens[screenType] = false
        end
    end
end

function onScriptTerminate(script, quitGame)
	if script == thisScript() then
        for index, handle in pairs(bums_pool) do
            if doesObjectExist(handle) then
                deleteObject(handle)
                table.remove(bums_pool, index)
            end
        end
        if id then
            sampTextdrawDelete(id)
            id = nil
        end
    end
end

--=========================================| Шрифты и прочее | =====================================
local fonts, fontsize_book, logo = {}, nil, nil
imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    SwitchTheStyle(ini.themesetting.theme)
    local config = imgui.ImFontConfig()
    config.MergeMode = true
	
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    local path = getFolderPath(0x14) .. "\\tahomabd.ttf"
    local sec_path = getFolderPath(0x14) .. "\\trebucbd.ttf"
    local iconRanges = new.ImWchar[3](fa.min_range, fa.max_range, 0)
	imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(
        fa.get_font_data_base85(ICON_STYLE_KEYS[ini.themesetting.iconstyle]), 14, config, iconRanges
    ) -- solid - тип иконок, так же есть thin, regular, light и duotone
    
	fonts[22] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 22, nil, glyph_ranges)
    logofont = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(
        fa.get_font_data_base85(ICON_STYLE_KEYS[ini.themesetting.iconstyle]), 32, config, iconRanges
    )
    fonts[14] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 14, nil, glyph_ranges)
	iconFont = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(
        fa.get_font_data_base85(ICON_STYLE_KEYS[ini.themesetting.iconstyle]), 14, config, iconRanges
    ) -- solid - тип иконок, так же есть thin, regular, light и duotone
    fonts[15] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 16, nil, glyph_ranges)
	
	if fontsize_book == nil then
        fontsize_book = imgui.GetIO().Fonts:AddFontFromFileTTF(sec_path, 15, nil, glyph_ranges)
    end
end)
--=========================================| Шрифты и прочее | =====================================

local Frame = imgui.OnFrame(
    function() return riverya.alpha > 0.00 and not isGamePaused() end,
    function(self)
        self.HideCursor = not riverya.state
        if isKeyDown(32) and self.HideCursor == false then
            self.HideCursor = true
        elseif not isKeyDown(32) and self.HideCursor == true and riverya.state then
            self.HideCursor = false
        end

        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, riverya.alpha)
        imgui.SetNextWindowSize(imgui.ImVec2(750, 400), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(imgui.ImVec2((sw / 2), sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		mimgui_blur.apply(imgui.GetBackgroundDrawList(), ini.themesetting.blurmode and sliders.blurradius[0] or 0)
		imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
		imgui.Begin(
            fa.GEARS..u8" LunarisPrjkt by "..script_author.."", new.bool(true), imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar) -- imgui.WindowFlags.NoResize
			imgui.SetCursorPos(imgui.ImVec2(0, 0))
			imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.0, 0.0, 0.0, -0.50))
			imgui.BeginChild("##LeftMenu", imgui.ImVec2(170, 395), false)
				-- Логотип LunarisPrjkt (ранее SAMPFixer)
				local logotext = u8"LunarisPrjkt"
				imgui.PushFont(logofont)
				
				-- Кэширование размеров текста
				local logoSize = imgui.CalcTextSize(logotext)
				local logoVerSize = imgui.CalcTextSize(versiontext)
				
				-- Установка цвета текста и позиции логотипа
				imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(rainbow(1)))
				imgui.SetCursorPos(imgui.ImVec2(133.5 / 2 - logoSize.x / 2, 4)) -- Упрощено вычисление (115 / 2 = 57.5, оптимизировано до 85 для центрирования)
				imgui.Text(logotext)
				
				-- Обработка клика по логотипу
				if imgui.IsItemClicked(0) then
					riverya.EasterEgg()
				end
				
				imgui.PopStyleColor()
				imgui.PopFont()
				
				-- Меню вкладок
				imgui.SetCursorPos(imgui.ImVec2(-4, 35))
				imgui.PushFont(iconFont)
				imgui.PushFont(fonts[14])
				imgui.CustomMenu(tabs, tab, imgui.ImVec2(142, 35))
				imgui.PopFont()
				imgui.PopFont()

                imgui.SetCursorPos(imgui.ImVec2(10, 375))
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.60, 0.60, 0.60, 0.60))
                imgui.Text(fa.ADDRESS_CARD..u8' Автор:')
                imgui.PopStyleColor()

				imgui.SameLine() 

                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(rainbow(1)))
				imgui.Link("https://github.com/riverya4life", script_author)
                imgui.PopStyleColor()
			imgui.EndChild()
			
			imgui.SetCursorPos(imgui.ImVec2(722, 7.5))
			--if CloseButton(u8"", new.bool(true), imgui.ImVec2(imgui.GetWindowSize().x, 0)) then
			if CloseButton(u8"", new.bool(true)) then
				riverya.switch()
			end
			imgui.SetCursorPos(imgui.ImVec2(0, 35))
			imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(5, 5))
			
			imgui.SetCursorPos(imgui.ImVec2(150, 35))
			imgui.BeginChild('##main', imgui.ImVec2(-8, 356.5), true)
			imgui.PushFont(fonts[14])
			if tab[0] == 1 then
				if ini.main.blockweather then
					imgui.Text(fa.CLOUD_SUN_RAIN..u8" Погода:")
					imgui.SameLine()
					imgui.Hint(u8("Изменяет игровую погоду на свою.\nТекущая погода: "..getStrGameWeather()), 0.2)
					if imgui.SliderInt(u8"##Weather", sliders.weather, 0, 45) then
						ini.main.weather = sliders.weather[0] 
						save()
						gotofunc("SetWeather")
					end
				end

				if ini.main.blocktime then
					imgui.Text(fa.MOON..u8" Время:")
					imgui.SameLine()
					imgui.Hint(u8"Изменяет игровое время на своё.", 0.2)
					if imgui.SliderInt(u8"##Time", sliders.time, 0, 23) then
						ini.main.time = sliders.time[0] 
						save()
						gotofunc("SetTime")
					end
				end

				if imgui.Checkbox(u8"Блокировать изменение погоды сервером", checkboxes.blockweather) then
					ini.main.blockweather = checkboxes.blockweather[0] 
					save()
					gotofunc("BlockWeather")
					gotofunc("SetWeather")
				end

				if imgui.Checkbox(u8"Блокировать изменение времени сервером", checkboxes.blocktime) then
					ini.main.blocktime = checkboxes.blocktime[0] 
					save()
					gotofunc("BlockTime")
					gotofunc("SetTime")
				end

                if imgui.Checkbox(u8"Вечно гуляющий туман", checkboxes.foggyness) then
                    ini.main.foggyness = checkboxes.foggyness[0]
                    save()
                    gotofunc("Foggyness")
                end

				imgui.Text(fa.CIRCLE_DOLLAR_TO_SLOT..u8" Анимация прибавления / убавления денег:")
                if imgui.Combo("##2", ivar, tmtext, #tbmtext) then
					ini.main.animmoney = ivar[0]+1
					save()
					gotofunc("AnimationMoney")
				end

				imgui.Text(fa.CIRCLE_DOLLAR_TO_SLOT..u8" Стиль шрифта денег:")
				imgui.SameLine()
				imgui.Hint(u8"Изменяет стиль шрифта денег если вам надоел оригинальный (стандартное значение 3).", 0.2)
				if imgui.SliderInt(u8"##MoneyFontStyle", sliders.moneyfontstyle, 0, 3) then
					ini.main.moneyfontstyle = sliders.moneyfontstyle[0]
					save()
                    gotofunc("MoneyFontStyle")
				end

				imgui.Text(fa.CIRCLE_DOLLAR_TO_SLOT..u8" Стиль шрифта в меню:")
				imgui.SameLine()
				imgui.Hint(u8"1 Слайдер - Изменяет стиль шрифта в меню текста 'МЕНЮ ПАУЗЫ' если вам надоел оригинальный (стандартное значение 0).\n2 Слайдер - Изменяет стиль шрифта в меню ПОЛНОСТЬЮ если вам надоел оригинальный (стандартное значение 2).", 0.2)
				if imgui.SliderInt(u8"##MenuFontStyle", sliders.menufontstyle, 0, 3) then
					ini.main.menufontstyle = sliders.menufontstyle[0]
					save()
                    gotofunc("MenuFontStyle")
				end

				if imgui.SliderInt(u8"##MenuAllFontStyle", sliders.menuallfontstyle, 0, 3) then
					ini.main.menuallfontstyle = sliders.menuallfontstyle[0]
					save()
                    gotofunc("MenuAllFontStyle")
				end

				imgui.Text(fa.CLOUD_SUN_RAIN..u8" Прозрачность карты на радаре:")
				imgui.SameLine()
				imgui.Hint(u8"Изменяет прозрачность карты на радаре. Сама карта в меню ESC будет обычной (значение от 0 до 255).", 0.2)
				if imgui.SliderInt(u8"##AlphaMap", sliders.alphamap, 0, 255) then
					ini.main.alphamap = sliders.alphamap[0]
					save()
                    gotofunc("AlphaMap")
				end

                if imgui.Button(u8(ini.main.vsync and 'Выключить' or 'Включить')..u8" вертикальную синхронизацию", imgui.ImVec2(334, 25)) then
                    ini.main.vsync = not ini.main.vsync
                    sampAddChatMessage(ini.main.vsync and script_name..' {FFFFFF}Вертикальная синхронизация {73b461}включена' or script_name..' {FFFFFF}Вертикальная синхронизация {dc4747}выключена', 0x73b461)
                    save()
                    gotofunc("Vsync")
                end

				imgui.SetCursorPos(imgui.ImVec2(425, -5))
				imgui.BeginTitleChild(u8"Блокировка клавиш", imgui.ImVec2(150, 150), 4, 13, false)
                    local sampKeys = {
                        { label = u8" F1",          cb = "nop_samp_keys_F1",    ini_key = "key_F1",     fnc = true, },
                        { label = u8" F4",          cb = "nop_samp_keys_F4",    ini_key = "key_F4",     fnc = true },
                        { label = u8" F7",          cb = "nop_samp_keys_F7",    ini_key = "key_F7",     fnc = true },
                        { label = u8" T",           cb = "nop_samp_keys_T",     ini_key = "key_T",      fnc = true },
                        { label = u8" ALT + ENTER", cb = "nop_samp_keys_ALTENTER", ini_key = "key_ALTENTER", fnc = false },
                    }
                    for _, v in ipairs(sampKeys) do
                        local cb = checkboxes[v.cb]
                        if imgui.Checkbox(v.label, cb) then
                            ini.nop_samp_keys[v.ini_key] = cb[0]
                            save()
                            if v.fnc then gotofunc("BlockSampKeys") end
                        end
                    end
				imgui.EndChild()

			elseif tab[0] == 2 then
				if imgui.Checkbox(u8"Отключить пост-обработку", checkboxes.postfx) then
					ini.main.postfx = checkboxes.postfx[0]
					save()
					gotofunc("NoPostfx")
				end
				imgui.SameLine()
				imgui.Hint(u8"Отключает пост-обработку, если у вас слабый пк.", 0.2)
				
				if imgui.Checkbox(u8"Отключить эффекты", checkboxes.noeffects) then
					ini.main.noeffects = checkboxes.noeffects[0]
					save()
				end
				imgui.SameLine()
				imgui.Hint(u8"Отключает эффекты в игре, если у вас слабый пк.", 0.2)
                if imgui.CollapsingHeader(fa.EYE..u8' Дальность прорисовки') then
                    if imgui.Checkbox(u8" Включить возможность менять прорисовку", checkboxes.givemedist) then
                        ini.main.givemedist = checkboxes.givemedist[0] 
                        save()
                    end
                    if ini.main.givemedist then
                        imgui.Text(fa.EYE..u8" Основная дальность прорисовки:")
                        if imgui.SliderInt(u8"##Drawdist", sliders.drawdist, 35, 3600) then
                            ini.main.drawdist = sliders.drawdist[0]
                            save()
                        end
                        imgui.SameLine()
						imgui.Hint(u8"Изменяет основную дальность прорисовки.", 0.2)
                        imgui.Text(fa.PLANE_UP..u8" Дальность прорисовки в воздушном транспорте:")
                        if imgui.SliderInt(u8"##drawdistair", sliders.drawdistair, 35, 3600) then
                            ini.main.drawdistair = sliders.drawdistair[0]
                            save()
                        end
                        imgui.SameLine()
						imgui.Hint(u8"Изменяет дальность прорисовки в воздушном транспорте.", 0.2)
                        imgui.Text(fa.PARACHUTE_BOX..u8" Дальность прорисовки при использовании парашута:")
                        if imgui.SliderInt(u8"##drawdistpara", sliders.drawdistpara, 35, 3600) then
                            ini.main.drawdistpara = sliders.drawdistpara[0]
                            save()
                        end
                        imgui.SameLine()
						imgui.Hint(u8"Изменяет дальность прорисовки при использовании парашута.", 0.2)
                        imgui.Text(fa.SMOG..u8" Дальность прорисовки тумана:")
                        if imgui.SliderInt(u8"##fog", sliders.fog, 0, 500) then
                            ini.main.fog = sliders.fog[0]
                            save()
                        end
                        imgui.SameLine()
						imgui.Hint(u8"Изменяет дальность прорисовки тумана.", 0.2)
                        imgui.Text(fa.MOUNTAIN..u8" Дальность прорисовки лодов:")
                        if imgui.SliderInt(u8"##lod", sliders.lod, 0, 300) then
                            ini.main.lod = sliders.lod[0]
                            save()
							gotofunc("LodDist")
                        end
                        imgui.SameLine()
						imgui.Hint(u8"Изменяет дальность прорисовки лодов.", 0.2)
                        end
                    end
                    if imgui.CollapsingHeader(fa.EYE..u8' Очистка памяти', imgui.TreeNodeFlags.DefaultOpen) then
                        if imgui.Checkbox(u8"Включить авто-очистку памяти", checkboxes.autoclean) then
                            ini.cleaner.autoclean = checkboxes.autoclean[0]
                            save()
                        end
                        if imgui.Checkbox(u8"Показывать сообщение об очистке памяти", checkboxes.cleaninfo) then
                            ini.cleaner.cleaninfo = checkboxes.cleaninfo[0]
                            save()
                        end
                        if imgui.Checkbox(u8"Обновлять зону стрима", checkboxes.streamupdate) then
                            ini.cleaner.streamupdate = checkboxes.streamupdate[0]
                            save()
                        end
                        if ini.cleaner.autoclean then
                            if imgui.SliderInt(u8"##memlimit", sliders.limitmem, 80, 3000, u8"Лимит для авто-очистки: %d МБ") then
                                ini.cleaner.limit = sliders.limitmem[0]
                                save()
                            end
                        end
                        if imgui.Button(fa.TRASH_CAN_CLOCK..u8" Очистить память", imgui.ImVec2(334, 25)) then
                            gotofunc("CleanMemory")
                        end
                    end
				
			elseif tab[0] == 3 then
				for k, v in orderedPairs(imguiCheckboxesFixesAndPatches) do
					if imgui.Checkbox(k, v.var) then
						ini.fixes[v.cfg] = v.var[0]
						save()
						if v.fnc ~= "_" then
							gotofunc(v.fnc)
						end
					end
				end

			elseif tab[0] == 4 then
				if imgui.Button(fa.ERASER..u8" Очистить чат", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                    gotofunc("ClearChat")
					imgui.addNotification(fa.CHECK..u8" Чат был успешно очищен!", 3, "73b461")
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(u8"Чтобы быстро очистить чат\nвведите в чат команду: "..ini.commands.clearchat)
                end
				
                imgui.SameLine()
                if imgui.Button(fa.BOOK..u8" Книга", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                    if ini.main.gender == 0 then
                        sampSendChat("/me достал книгу и начал читать её")
                    elseif ini.main.gender == 1 then
                        sampSendChat("/me достала книгу и начала читать её")
                    end
					gotofunc("OpenBook")
                end

				if imgui.Button(fa.CAMERA..u8" Green Screen: "..(gscreen and 'ON' or 'OFF').."", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                    toggleScreen(green)
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(u8"Функция включает зеленый экран\nУдобно когда вы делаете скриншот ситуации")
                end
				
				imgui.SameLine()
				if imgui.Button(fa.CAMERA..u8" Black Screen: "..(bscreen and 'ON' or 'OFF').."", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
					toggleScreen(black)
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(u8"Функция включает черный экран (кому не нравится зелёный)\nУдобно когда вы делаете скриншот ситуации")
                end

				if imgui.Button(fa.FIRE..u8" Получить бутылку пива", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                    runSampfuncsConsoleCommand('0afd:20')
                end
                imgui.SameLine()
                if imgui.Button(fa.FIRE..u8" Получить бутылку пива 2", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                    runSampfuncsConsoleCommand('0afd:22')
                end

                if imgui.Button(fa.FIRE..u8" Получить Sprunk", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                    runSampfuncsConsoleCommand('0afd:23')
                end

                imgui.SameLine()

                if imgui.Button(fa.FIRE..u8" Получить сигарету", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                    runSampfuncsConsoleCommand('0afd:21')
                end

				if imgui.Button(fa.WATER..u8" Обоссать", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                    runSampfuncsConsoleCommand('0afd:68')
                end

				imgui.SameLine()

				if imgui.Button(fa.EYE_SLASH..u8" Скрывать текстдравы: "..(showtextdraw and 'ON' or 'OFF').."", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                    showtextdraw = not showtextdraw
                    for i = 0, 199999 do
                        sampTextdrawDelete(i)
                    end
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(u8"Функция скрывает все текстдравы\nПримечание: после выключения данной функции будут возвращены не все текстдравы\nБудут возвращены лишь те что рисуются заново.")
                end

                imgui.Separator()

                imgui.PushItemWidth(100)
                if imgui.Combo(fa.ARROW_LEFT..u8" Ваш пол |", gender, genders, #arr_gender) then
                    ini.main.gender = gender[0]
                    save()
                end
                imgui.SameLine()
                imgui.Text(fa.FACE_SMILE..u8" Список доступных смайлов")
                imgui.SameLine()
                imgui.Hint(u8("Полный список смайлов:\n\n"..getSmileList(ini.main.gender)), 0.2)
                imgui.SameLine()
                imgui.Text("| "..fa.KEYBOARD..u8" Список биндов")
                imgui.SameLine()
                imgui.Hint(u8("Полный список биндов:\n\n"..getBindList()), 0.2)
                imgui.PopItemWidth()

                if imgui.Button(fa.FACE_SMILE..u8(ini.main.smilesys and ' Выключить' or ' Включить')..u8" систему смайлов", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                    ini.main.smilesys = not ini.main.smilesys
                    save()
                end

                imgui.SameLine()

                if imgui.Button(fa.GUN..u8(ini.main.rpguns and ' Выключить' or ' Включить')..u8" отыгровку оружия", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                    ini.main.rpguns = not ini.main.rpguns
                    rp_thread:terminate()
                    rp_thread:run()
                    save()
                end

                if imgui.Button(fa.KEYBOARD..u8(ini.main.bindkeys and " Выключить" or " Включить")..u8" бинды для Arizona RP", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                    ini.main.bindkeys = not ini.main.bindkeys
                    save()
                end

                imgui.SameLine()
				if imgui.Button(fa.KEYBOARD..u8(antiafk and " Выключить" or " Включить")..u8" AntiAFK", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                    antiafk = not antiafk
                    --sampAddChatMessage(antiafk and script_name..' {FFFFFF}Анти-АФК {73b461}включен' or script_name..' {FFFFFF}Анти-АФК {dc4747}выключен', 0x73b461)
                    imgui.addNotification((antiafk and fa.CHECK or fa.XMARK)..u8(" Анти-АФК "..(antiafk and "включен" or "выключен")..""), 3, antiafk and "73b461" or "dc4747")
                    if antiafk then
                        memory.setuint8(7634870, 1, false)
                        memory.setuint8(7635034, 1, false)
                        memory.fill(7623723, 144, 8, false)
                        memory.fill(5499528, 144, 6, false)
                    else
                        memory.setuint8(7634870, 0, false)
                        memory.setuint8(7635034, 0, false)
                        memory.hex2bin('0F 84 7B 01 00 00', 7623723, 8)
                        memory.hex2bin('50 51 FF 15 00 83 85 00', 5499528, 6)
                    end
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(fa.EXCLAMATION..u8" Функция включает Анти-АФК\nесли вам не нужно чтобы после\nсворачивания игры она не вставала в паузу\n(Опасно, ибо можно получить бан!)")
                end

                if imgui.Button(fa.COMMENTS..u8(ini.main.separate_msg and " Выключить" or " Включить")..u8" разделение сообщения на два", imgui.ImVec2(imgui.GetMiddleButtonX(1), 25)) then
                    ini.main.separate_msg = not ini.main.separate_msg
                    save()
                end
				
			elseif tab[0] == 5 then
				imgui.SetCursorPosX(imgui.GetWindowSize().x / 4)
				imgui.NewInputText('##SearchBar', buffers.search_cmd, 300, u8'Поиск по списку', 2)
				imgui.Separator()
				imgui.PushItemWidth(130)
				
				for k, v in orderedPairs(imguiInputsCmdEditor) do
					if str(buffers.search_cmd) ~= "" then
						if k:find(str(buffers.search_cmd)) or str(v.var):find(str(buffers.search_cmd)) then
							if imgui.InputText(k, v.var, sizeof(v.var)) then
								ini.commands[v.cfg] = str(v.var)
								save()
							end
						end
					else
						if imgui.InputText(k, v.var, sizeof(v.var)) then
							ini.commands[v.cfg] = str(v.var)
							save()
						end
					end
				end
				
			elseif tab[0] == 6 then
                if imgui.HotKey("##Открыть меню скрипта", ActOpenMenuKey, tLastKeys, 100) then
                    rkeys.changeHotKey(bindOpenmenu, ActOpenMenuKey.v)
                    --sampAddChatMessage(script_name.." {FFFFFF}Старое значение: {dc4747}" .. table.concat(rkeys.getKeysName(tLastKeys.v), " + ") .. "{ffffff} | Новое: {dc4747}" .. table.concat(rkeys.getKeysName(ActOpenMenuKey.v), " + "), 0x73b461)
                    imgui.addNotification(fa.KEYBOARD..u8(" Старое значение: " .. table.concat(rkeys.getKeysName(tLastKeys.v), " + ") .. " | Новое: " .. table.concat(rkeys.getKeysName(ActOpenMenuKey.v),  " + ")), 3, "000000")
                    ini.hotkeys.openmenukey = encodeJson(ActOpenMenuKey.v)
                    save()
                end
                imgui.SameLine()
                imgui.Text(fa.KEYBOARD..u8" Открыть меню скрипта")
                imgui.SameLine()
                imgui.Hint(u8("Задайте кнопку для открытия меню скрипта\nСтандартное значение: F2"), 0.2)
                
				imgui.Text(fa.PALETTE..u8" Настройка темы:")
				local clrs = {
                    { name = u8"Синяя",           col = imgui.ImVec4(0.26, 0.59, 0.98, 1.00) },
                    { name = u8"Красная",         col = imgui.ImVec4(1.00, 0.28, 0.28, 1.00) },
					{ name = u8"Коричневая",      col = imgui.ImVec4(0.98, 0.43, 0.26, 1.00) },
					{ name = u8"Аква",            col = imgui.ImVec4(0.26, 0.98, 0.85, 1.00) },
					{ name = u8"Черная",          col = imgui.ImVec4(0.10, 0.09, 0.12, 1.00) },
					{ name = u8"Фиолетовая",      col = imgui.ImVec4(0.41, 0.19, 0.63, 1.00) },
					{ name = u8"Черно-оранжевая", col = imgui.ImVec4(0.10, 0.09, 0.12, 1.00) },
					{ name = u8"Серая",           col = imgui.ImVec4(0.20, 0.25, 0.29, 1.00) },
					{ name = u8"Вишневая",        col = imgui.ImVec4(0.457, 0.200, 0.303, 1.00) },
					{ name = u8"Зеленая",         col = imgui.ImVec4(0.00, 0.69, 0.33, 1.00) },
					{ name = u8"Пурпурная",       col = imgui.ImVec4(0.46, 0.11, 0.29, 1.00) },
					{ name = u8"Темно-зеленая",   col = imgui.ImVec4(0.13, 0.75, 0.55, 1.00) },
					{ name = u8"Оранжевая",       col = imgui.ImVec4(0.73, 0.36, 0.00, 1.00) }
				}
                
				for i = 1, #clrs do
                    local name, col = clrs[i].name, clrs[i].col
                    local imvec4_to_argb = function(vec4)
                        local r = math.floor(vec4.x * 255 + 0.5)
                        local g = math.floor(vec4.y * 255 + 0.5)
                        local b = math.floor(vec4.z * 255 + 0.5)
                        local a = math.floor(vec4.w * 255 + 0.5)
                        return join_argb(a, r, g, b)
                    end
                    local hex_str = string.format("%06X", bit.band(imvec4_to_argb(col), 0xFFFFFF))
					imgui.PushStyleColor(imgui.Col.CheckMark, col)
					if ini.themesetting.theme == i then
						imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.80, 0.80, 0.80, 1.00)) 
					end
					
					if imgui.RadioButtonBool(u8"##темаблять"..i, ini.themesetting.theme == i and false or true) then
						ini.themesetting.theme = i
						save()
						SwitchTheStyle(ini.themesetting.theme)
                        imgui.addNotification(fa.KEYBOARD..u8" Тема изменена!\nТекущая тема: "..name, 1, hex_str)
					end
                    if imgui.IsItemHovered() then
                        imgui.SetTooltip(u8"Тема: "..name)
                    end

					imgui.SameLine()
					imgui.PopStyleColor()
					SwitchTheStyle(ini.themesetting.theme)
				end
				imgui.NewLine()
				
				if imgui.SliderFloat(u8"##Rounded", sliders.roundtheme, 0, 10, '%.1f') then
					ini.themesetting.rounded = sliders.roundtheme[0]
					imgui.GetStyle().WindowRounding = sliders.roundtheme[0]
					imgui.GetStyle().ChildRounding = sliders.roundtheme[0]
					imgui.GetStyle().FrameRounding = sliders.roundtheme[0]
					imgui.GetStyle().GrabRounding = sliders.roundtheme[0]
					imgui.GetStyle().PopupRounding = sliders.roundtheme[0]
					imgui.GetStyle().ScrollbarRounding = sliders.roundtheme[0]
					imgui.GetStyle().TabRounding = sliders.roundtheme[0]
					save()
				end
				imgui.SameLine()
				imgui.Hint(u8"Изменяет значение закругления окна, чайлдов, пунктов меню и компонентов (стандартное значение 4.0).", 0.2)

                if imgui.Checkbox(u8"Обводка окна и компонентов", checkboxes.windowborder) then
                    ini.themesetting.windowborder = checkboxes.windowborder[0]
                    local size = ini.themesetting.windowborder and 1 or 0
                    local style = imgui.GetStyle()
                    style.WindowBorderSize, style.FrameBorderSize, style.PopupBorderSize, style.TabBorderSize = size, size, size, size
                    save()
                end
				imgui.SameLine()
				imgui.Hint(u8"Включает и выключает легкую обводку окна и компонентов (кнопки, слайдеры и т.д.).", 0.2)
				if imgui.Checkbox(u8"Центрирование текста пунктов меню", checkboxes.centeredmenu) then
					ini.themesetting.centeredmenu = checkboxes.centeredmenu[0]
					save()
				end
				imgui.SameLine()
				imgui.Hint(u8"Вы можете выровнять текст в меню по своему желанию.", 0.2)
				
				if imgui.Checkbox(u8"Размытие заднего фона", checkboxes.blurmode) then
					ini.themesetting.blurmode = checkboxes.blurmode[0]
					save()
				end
				imgui.SameLine()
				imgui.Hint(u8"Вы можете выровнять текст в меню по своему желанию.", 0.2)
				if ini.themesetting.blurmode then
                    imgui.SameLine()
                    if imgui.CustomSlider(u8"##BlurRadius", sliders.blurradius, 0.5, 5.0, u8"%.2f", 135) then
					--if imgui.SliderFloat("##BlurRadius", sliders.blurradius, 0.500, 5.0) then
						ini.themesetting.blurradius = sliders.blurradius[0]
						save()
					end
				end

				if imgui.Checkbox(u8"Новый цвет диалогов", checkboxes.dialogstyle) then
					ini.themesetting.dialogstyle = checkboxes.dialogstyle[0]
					save()
					gotofunc("DialogStyle")
				end
				imgui.SameLine()
				imgui.Hint(u8"Изменяет цвет диалоговых окон похожих как на лаунчере Arizona RP.", 0.2)
				
				if imgui.Checkbox(u8"Сообщение скрипта при загрузке", checkboxes.riveryahellomsg) then
					ini.main.riveryahellomsg = checkboxes.riveryahellomsg[0]
					save()
					if ini.main.riveryahellomsg then
						sampAddChatMessage(script_name..'{FFFFFF} Приветственное сообщение скрипта {73b461}включено!', 0x73b461)
					else
						sampAddChatMessage(script_name..'{FFFFFF} Приветственное сообщение скрипта {DC4747}отключено!', 0x73b461)
					end
				end
				imgui.SameLine()
				imgui.Hint(u8"Включает или выключает сообщение скрипта при загрузке", 0.2)
				
				if imgui.Button(u8'Перезагрузить скрипт '..fa.ARROWS_ROTATE..'', imgui.ImVec2(imgui.GetMiddleButtonX(3), 25)) then
					showCursor(false, false)
					sampAddChatMessage(script_name..'{FFFFFF} Скрипт был перезагружен из-за нажатия кнопки {DC4747}"Перезагрузить скрипт"{FFFFFF}!', 0x73b461)
					thisScript():reload()
				end
                imgui.SameLine()
				if imgui.Button(u8'Выключить скрипт '..fa.POWER_OFF..'', imgui.ImVec2(imgui.GetMiddleButtonX(3), 25)) then 
					showCursor(false, false)
					sampAddChatMessage(script_name..'{FFFFFF} Скрипт был выгружен из-за нажатия кнопки {DC4747}"Выключить скрипт"{FFFFFF}!', 0x73b461)
					thisScript():unload() 
				end
				
				versionold = updatesavaliable and u8'(не актуальная)' or u8'(актуальная)'
                imgui.SameLine()
                if imgui.Button(u8"Проверить обновление " .. fa.DOWNLOAD, imgui.ImVec2(imgui.GetMiddleButtonX(3), 25)) then
                    if updatesavaliable then
                        imgui.OpenPopup(fa.DOWNLOAD..u8" Доступно обновление!")
                    else
                        imgui.addNotification(fa.FILE_ARROW_DOWN..u8(" У вас установлена самая последняя версия скрипта!"), 3, "73b461")
                    end
                end

                if imgui.BeginPopupModal(fa.DOWNLOAD .. u8" Доступно обновление!", new.bool(true), imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoResize) then
                    imgui.SetWindowSizeVec2(imgui.ImVec2(305, 135))
                    imgui.Text(u8"Вам доступно обновление с репозитория GitHub!")
                    imgui.Text(u8"Желаете обновиться с версии " .. thisScript().version .. u8" до актуальной?")
                    imgui.NewLine()
                    imgui.SetCursorPosX(5)
                    imgui.SetCursorPosY(104)
            
                    if imgui.Button(u8"Обновить", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then
                        sampAddChatMessage(script_name .. "{FFFFFF} Скрипт {42B166}обновляется...", 0x73b461)
                        update():download()
                    end
                    imgui.SameLine()
                    if imgui.Button(u8"Закрыть", imgui.ImVec2(imgui.GetMiddleButtonX(2), 25)) then 
                        imgui.CloseCurrentPopup() 
                    end
                    imgui.EndPopup()
                end

				if imgui.Button(fa.CLOCK..u8" Список обновлений", imgui.ImVec2(imgui.GetMiddleButtonX(1), 25)) then
					imgui.OpenPopup(fa.CLOCK..u8" Список обновлений") 
                end
                if imgui.BeginPopupModal(fa.CLOCK..u8" Список обновлений", new.bool(true), imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoResize) then
                	imgui.SetWindowSizeVec2(imgui.ImVec2(475, 300))
					for k,v in pairs(listUpdate) do
						local header = v.v
						if k == 1 then header = fa.FIRE .. u8(' ' .. header .. ' | Актуальная версия') end
						if imgui.CollapsingHeader(header) then
                            for i = 1, #v.context do 
                                imgui.TextWrapped(v.context[i]) 
                            end
                            imgui.Spacing()
						end
                        imgui.Separator()
                        imgui.SetCursorPosX(imgui.GetWindowSize().x / 5)
                        imgui.Text(u8"Полный список новвоведений смотрите")
                        imgui.SameLine()
                        imgui.Link("https://github.com/riverya4life", u8"здесь")
					end
					imgui.EndPopup()
			    end
				
				imgui.Separator()
                imgui.Spacing()
				
				local _, myid = sampGetPlayerIdByCharHandle(playerPed)
				local mynick = sampGetPlayerNickname(myid) -- наш ник крч
				local myping = sampGetPlayerPing(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
				
				imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.5, 0.5, 0.5, 1))
				imgui.Text(fa.USER..u8' Пользователь: '..mynick..'['..myid..u8'] ('..fa.SIGNAL..u8' Пинг: '..myping..')')
				imgui.Text(fa.FOLDER..u8' Версия: '..thisScript().version..' '..versionold..'')
				
				imgui.SetCursorPos(imgui.ImVec2(474, 10))
				imgui.BeginChild("##iconstyles", imgui.ImVec2(110, 80), true)
					imgui.Text(fa.LEAF..u8" Тип иконок:")
					for i, key in pairs(ICON_STYLE_KEYS) do
						local v = ICON_STYLE_NAMES[key]
						if imgui.RadioButtonBool(u8(v), ini.themesetting.iconstyle == i) then
							ini.themesetting.iconstyle = i
							save()
							sampAddChatMessage(script_name.."{FFFFFF} Стиль иконок изменен на {dc4747}"..v.."!", 0x73b461)
							sampAddChatMessage(script_name.."{FFFFFF} Так как Вы внесли изменения в стиль иконок скрипта, ему потребуется перезагрузка (Кнопка 'Перезагрузить скрипт')!", 0x73b461)
						end
					end
				imgui.EndChild()
			end
			imgui.PopFont()
			imgui.PopStyleColor()
			imgui.EndChild()
        imgui.End()
    end
)

local BookFrame = imgui.OnFrame(
    function() return riveryabook.alpha > 0.00 end,
    function(self)
        self.HideCursor = not riveryabook.state
        if isKeyDown(32) and self.HideCursor == false then
            self.HideCursor = true
        elseif not isKeyDown(32) and self.HideCursor == true and riveryabook.state then
            self.HideCursor = false
        end
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, riveryabook.alpha)
		
        imgui.SetNextWindowSize(imgui.ImVec2(460, 280), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(imgui.ImVec2((sw / 2), sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
		imgui.Begin(fa.BOOK..u8" Book", new.bool(true), imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar)
			imgui.SetCursorPos(imgui.ImVec2(5, 5))
			if CloseButton(u8"", new.bool(true)) then
				riveryabook.switch()
			end
			imgui.SetCursorPos(imgui.ImVec2(30, 5))
			if imgui.Button(u8"Обновить") then
				if doesFileExist("moonloader\\LunarisPrjkt\\mybook.txt") then
					book_text = {}
					local file = io.open("moonloader\\LunarisPrjkt\\mybook.txt", "a+") -- открываем файл
					for line in file:lines() do -- читаем его построчно
						book_text[#book_text+1] = line -- записываем строки в массив
					end
					file:close() -- закрываем файл
				end
			end
			imgui.SameLine()
			imgui.Hint(u8"Ваша книга находится по пути:\n\"ваша сборка/moonloader/LunarisPrjkt/mybook.txt\"\nВы можете изменять содержимое файла\nP.S сохраняйте файл в кодировке UTF-8 чтобы у вас не было иероглифов или вопросов!", 0.2)
			imgui.SameLine()
			imgui.SetCursorPos(imgui.ImVec2(103, 5))
			imgui.Text(fa.BOOK..u8" Книга by "..script_author.."")
			imgui.Separator()
            imgui.Spacing()
            imgui.PushTextWrapPos(imgui.GetWindowSize().x - 40 );
            for _,v in ipairs(book_text) do
                imgui.PushFont(fontsize_book)
                    imgui.CenterText(v)
                imgui.PopFont()
            end
		imgui.End()
	end
)

local Notf = imgui.OnFrame(
    function() return isSampAvailable() and not isPauseMenuActive() and true end,
    function(self)
        imgui.PushFont(fonts[14])
        self.HideCursor = true
        imgui.drawNotifications()
    end
)

function book()
	local file = io.open("moonloader\\LunarisPrjkt\\mybook.txt", "a+") -- открываем и создаем файл
	file:close()
    local file = io.open("moonloader\\LunarisPrjkt\\mybook.txt", "a+") -- открываем файл
    book_text = {}
    for line in file:lines() do -- читаем его построчно
        book_text[#book_text+1] = line -- записываем строки в массив
    end
    file:close() -- закрываем файл
end

function onReceivePacket(id) -- будет флудить wrong server password до тех пор, пока сервер не откроется
	if id == 37 then
		sampSetGamestate(1)
	end
end

function samp.onSendPlayerSync(data) -- банни хоп
	if data.keysData == 40 or data.keysData == 42 then sendOnfootSync(); 
    data.keysData = 32 end
end

function sendOnfootSync()
	local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
	local data = allocateMemory(68)
	sampStorePlayerOnfootData(myId, data)
	setStructElement(data, 4, 1, 0, false)
	sampSendOnfootData(data)
	freeMemory(data)
end -- тут конец уже

function samp.onSetVehicleVelocity(turn, velocity)
    if velocity.x ~= velocity.x or velocity.y ~= velocity.y or velocity.z ~= velocity.z then
        sampAddChatMessage("[Warning] ignoring invalid SetVehicleVelocity", 0x00FF00)
        return false
    end
end

function samp.onServerMessage(color, text)
	if text:find("%[Ошибка%] {FFFFFF}Доступно только с мобильного или PC лаунчера!") then
		return false
	end
end

-- Functions Mooving Dialog by хуй его знает не помню уже
function sampGetDialogSize()
    return memory.getint32(CDialog + 0xC, true),
    memory.getint32(CDialog + 0x10, true)
end

function sampGetDialogCaptionHeight()
    return memory.getint32(CDXUTDialog + 0x126, true)
end

function sampGetDialogPos()
    return memory.getint32(CDialog + 0x04, true),
    memory.getint32(CDialog + 0x08, true)
end

function sampSetDialogPos(x, y)
    memory.setint32(CDialog + 0x04, x, true)
    memory.setint32(CDialog + 0x08, y, true)

    memory.setint32(CDXUTDialog + 0x116, x, true)
    memory.setint32(CDXUTDialog + 0x11A, y, true)
end

function vehHaveGun() -- прицен на транспорте by Cosmo (https://www.blast.hk/threads/72683/)
	for _, v in ipairs({425, 447, 464, 476, 520}) do
		if isCharInModel(playerPed, v) then 
			return true 
		end
	end
	return false
end

function renderCrosshair(x, y) -- прицен на транспорте by Cosmo (https://www.blast.hk/threads/72683/)
	renderDrawPolygon(x, y, 5, 5, 8, 0, 0xFF606060)
	renderDrawPolygon(x, y, 3, 3, 8, 0, 0xFFFFFFFF)
end

function getRhinoCannonCorner(carHandle) -- прицен на транспорте by Cosmo (https://www.blast.hk/threads/72683/)
	local ptr = getCarPointer(carHandle)
	local x = memory.getfloat(ptr + 0x94C, false) * 180.0 / math.pi
	local y = memory.getfloat(ptr + 0x950, false) * 180.0 / math.pi
	return x, y
end

function samp.onShowTextDraw(id, data)
    if showtextdraw then
        return false
    end
end

function samp.onSetMapIcon(iconId, position, type, color, style)
    if type > MAX_SAMP_MARKERS then
        return false
    end
end

function gotofunc(fnc) -- by Gorskin (https://www.blast.hk/members/157398/) (просто удобно юзать пиздец)
    ------------------------------------Фиксы и прочее-----------------------------
    if fnc == "all" then
        callFunction(0x7469A0, 0, 0) -- mousefix in pause
        --------[фикс спавна с бутылкой и сигарой]----------
        memory.setuint32(0x736F88, 0, false) -- вертолет не взрывается много раз
        memory.fill(0x4217F4, 0x90, 21, false) -- исправление спавна с бутылкой
        memory.fill(0x4218D8, 0x90, 17, false) -- исправление спавна с бутылкой
        memory.fill(0x5F80C0, 0x90, 10, false) -- исправление спавна с бутылкой
        memory.fill(0x5FBA47, 0x90, 10, false) -- исправление спавна с бутылкой

        memory.write(sampGetBase() + 643864, 37008, 2, true) -- чтобы Дiма Колодич не злился, вот второй вариант реализации: memory.setint16(getModuleHandle("samp.dll") + 0x09D318, 37008, true)
        ---------------------------------------------
        local settings = {
            r1 = {0x64ACA, 0x64ACF, 0xD7B00, 0xD7B04, 0x64A51, 0xD7AD5},
            r3 = {0x67F2A, 0x67F2F, 0xE9DE0, 0xE9DE4, 0x67EB1, 0xE9DB5}
        }
        local values = {0xFB, 0x07, 0x7420352D, 0x37206F, 0x32, 0x35}
        local sizes = {1, 1, 4, 4, 1, 1}
        
        local version = get_samp_version()
        if settings[version] then
            for i, offset in ipairs(settings[version]) do
                memory.write(sampGetBase() + offset, values[i], sizes[i], true)
            end
        end
    end

    local actions = {
        OpenMenu = riverya.switch,
        OpenBook = riveryabook.switch,
    }
    local fn = actions[fnc]
    if fn then fn() end

	----------------------- Главная -----------------------

	if fnc == "BlockWeather" or fnc == "all" then
        local offsets = { r1 = 0x9C130, r3 = 0xA0430 }
        local version = get_samp_version()
        if offsets[version] then
            memory.write(sampGetBase() + offsets[version], ini.main.blockweather and 0x0004C2 or 0x5D418B, 4, true)
        end
    end
    
    if fnc == "BlockTime" or fnc == "all" then
        local offsets = { r1 = 0x9C0A0, r3 = 0xA03A0 }
        local version = get_samp_version()
        if offsets[version] then
            memory.write(sampGetBase() + offsets[version], ini.main.blocktime and 0x000008C2 or 0x0824448B, 4, true)
        end
    end

    if fnc == "SetWeather" or fnc == "all" then
        forceWeatherNow(ini.main.weather)
	end

    if fnc == "SetTime" or fnc == "all" then
        setTimeOfDay(ini.main.time)
	end

    if fnc == "Foggyness" or fnc == "all" then
        local value = ini.main.foggyness and 0x9090 or 0x12EB
        writeMemory(0x72BE29, 2, value, true)
    end
	
	if fnc == "AnimationMoney" or fnc == "all" then
        memory.write(5707667, (ini.main.animmoney + 136), 1, true)
	end

	if fnc == "MoneyFontStyle" or fnc == "all" then
        memory.setint8(0x58F57F, ini.main.moneyfontstyle, true)
    end

	if fnc == "MenuFontStyle" or fnc == "all" then
        memory.setuint8(0x57958B, ini.main.menufontstyle, true)
    end

	if fnc == "MenuAllFontStyle" or fnc == "all" then
        memory.setuint8(0x5799AD, ini.main.menuallfontstyle, true)
    end

    if fnc == "AlphaMap" or fnc == "all" then
		memory.setuint8(0x5864BD, ini.main.alphamap, true)
    end

	if fnc == "BlockSampKeys" or fnc == "all" then
        local keys = {
            key_F1 = {r1 = 0x713E0, r3 = 0x752D0, off = 0, on = 0x70, size = 1},
            key_F4 = {r1 = 0x797E, r3 = 0x79A4, off = 0, on = 115, size = 1},
            key_F7 = {r1 = 0x5D8AD, r3 = 0x60C4D, off = 0xC3, on = 0x8B, size = 1},
            key_T = {
                {r1 = 0x5DB04, r3 = 0x60EA4, off = 0xC3, on = 0x852F7574, size = 4}, 
                {r1 = 0x5DAFA, r3 = 0x60E9A, off = 0xC3, on = 0x900A7490, size = 4}
            }
        }
        
        local v, b = get_samp_version() == "r1" and "r1" or "r3", sampGetBase()
        for k, c in pairs(keys) do
            for _, s in ipairs(type(c) == "table" and not c[1] and {c} or c) do
                memory.write(b + s[v], ini.nop_samp_keys[k] and s.off or s.on, s.size, true)
            end
        end
	end

	----------------------- Boost FPS -----------------------

    if fnc == "NoPostfx" or fnc == "all" then
        local postfx = ini.main.postfx
        local value1 = postfx and 2866 or 1448280247
        local value2 = postfx and -380152237 or -988281383
        local value3 = postfx and 0xC3 or 0xE9
    
        memory.write(7358318, value1, 4, true)
        memory.write(7358314, value2, 4, true)
        writeMemory(0x53E227, 1, value3, true)
    end

    if fnc == "NoEffect" or fnc == "all" then
        local value = ini.main.noeffects and 8386 or 1443425411
        memory.write(4891712, value, 4, false)
    end

    if fnc == "CleanMemory" then
        local oldram = ("%d"):format(tonumber(get_memory()))
        callFunction(0x53C500, 2, 2, 1, 1)
        if ini.cleaner.streamupdate then
            callFunction(0x40D7C0, 1, 1, -1)
        end
        callFunction(0x53C810, 1, 1, 1)
        callFunction(0x40CF80, 0, 0)
        callFunction(0x4090A0, 0, 0)
        callFunction(0x5A18B0, 0, 0)
        callFunction(0x707770, 0, 0)
        callFunction(0x40CFD0, 0, 0)
        local newram = ("%d"):format(tonumber(get_memory()))
        if ini.cleaner.cleaninfo then
            --sampAddChatMessage(script_name.."{FFFFFF} Памяти до: {dc4747}"..oldram.." МБ. {FFFFFF}Памяти после: {dc4747}"..newram.." МБ. {FFFFFF}Очищено: {dc4747}"..oldram - newram.." МБ.", 0x73b461)
            imgui.addNotification(fa.TRASH_CLOCK..u8(" Памяти до: "..oldram.." МБ. Памяти после: "..newram.." МБ. Очищено: "..oldram - newram.." МБ."), 3, "73b461")
        end
    end

	if fnc == "LodDist" or fnc == "all" then
        memory.setfloat(0xCFFA11, ini.main.lod, true)
        local aWrites = {
            [1] = 0x555172+2, [2] = 0x555198+2, [3] = 0x5551BB+2, [4] = 0x55522E+2, [5] = 0x555238+2,
            [6] = 0x555242+2, [7] = 0x5552F4+2, [8] = 0x5552FE+2, [9] = 0x555308+2, [10] = 0x555362+2,
            [11] = 0x55537A+2, [12] = 0x555388+2, [13] = 0x555A95+2, [14] = 0x555AB1+2, [15] = 0x555AFB+2,
            [16] = 0x555B05+2, [17] = 0x555B1C+2, [18] = 0x555B2A+2, [19] = 0x555B38+2, [20] = 0x555B82+2,
            [21] = 0x555B8C+2, [22] = 0x555B9A+2, [23] = 0x5545E6+2, [24] = 0x554600+2, [25] = 0x55462A+2,
            [26] = 0x5B527A+2,
        }
        for i = 0, #aWrites do
            writeMemory(aWrites[i], 4, 0xCFFA11, true)
        end
    end

	----------------------- Исправления блять -----------------------

	if fnc == "FixBloodWood" or fnc == "all" then
        writeMemory(0x49EE63 + 1, 4, ini.fixes.fixbloodwood and 0 or 0x3F800000, true)
    end

    if fnc == "NoLimitMoneyHud" or fnc == "all" then
        local value = ini.fixes.nolimitmoneyhud and 0x57C7FFF or 0x57C3B9A
        for _, addr in ipairs({0x571784, 0x57179C}) do
            writeMemory(addr, 4, value, true)
        end
    end

	if fnc == "SunFix" or fnc == "all" then
		if ini.fixes.sunfix then 
			memory.hex2bin("E865041C00", 0x53C136, 5) 
			memory.protect(0x53C136, 5, memory.unprotect(0x53C136, 5))
		else 
			memory.fill(0x53C136, 0x90, 5, true)
		end
	end

	if fnc == "GrassFix" or fnc == "all" then
		if ini.fixes.grassfix then 
			memory.hex2bin("E8420E0A00", 0x53C159, 5) 
			memory.protect(0x53C159, 5, memory.unprotect(0x53C159, 5)) 
		else 
			memory.fill(0x53C159, 0x90, 5, true)
        end
	end

    if fnc ~= "MoneyFontFix" or fnc == "all" then
        local values = ini.fixes.moneyfontfix and { 
            0x6430302524, 0x64303025242D } or { 0x6438302524, 0x64373025242D 
        }
        memory.setint32(0x866C94, values[1], true)
        memory.setint64(0x866C8C, values[2], true)
    end

	if fnc == "StarsOnDisplay" or fnc == "all" then
        local value = ini.fixes.starsondisplay and 0x9090 or (fnc ~= "all" and 0x097E)
        if value then
            writeMemory(0x58DD1B, 2, value, true)
        end
	end

    if fnc == "Vsync" or fnc == "all" then
        memory.write(0xBA6794, ini.main.vsync and 1 or 0, 1, true)
    end

    if fnc ~= "FixSensitivity" or fnc == "all" then
        local value = ini.fixes.sensfix and 11987996 or 11987992
        for _, addr in ipairs{5382798, 5311528, 5316106} do
            memory.write(addr, value, 4, true)
        end
    end

    if fnc == "FixBlackRoads" or fnc == "all" then
        memory.write(8931716, ini.fixes.fixblackroads and 0 or 2, 4, true)
    end

    if fnc == "FixLongArm" or fnc == "all" then
        local value = ini.fixes.longarmfix and 33807 or 59792
        memory.write(7045634, value, 2, true)
        memory.write(7046489, value, 2, true)
    end

    if fnc == "InteriorRun" or fnc == "all" then
        local value1 = ini.fixes.intrun and -1027591322 or 69485707
        local value2 = ini.fixes.intrun and 4 or 1165
        memory.write(5630064, value1, 4, true)
        memory.write(5630068, value2, 2, true)
    end

    if fnc == "FixCrosshair" or fnc == "all" then
        memory.write(0x058E280, ini.fixes.fixcrosshair and 0xEB or 0x7A, 1, true)
    end

	if fnc == "PlaceName" or fnc == "all" then
		if ini.fixes.placename then
			location = getGxtText(getNameOfZone(getCharCoordinates(PLAYER_PED)))
			if location ~= plocation then
				printStyledString("~w~"..location, 500, 2)
				plocation = location
			end
		end
	end

    if fnc == "PatchDuck" or fnc == "all" then
        writeMemory(0x692649 + 1, 1, (ini.fixes.patchduck and 6) or 8, true)
    end

    if fnc == "BlurReturn" or fnc == "all" then
        local bytes = ini.fixes.blurreturn and { 
            0xE8, 0x11, 0xE2, 0xFF, 0xFF } or { 0x90, 0x90, 0x90, 0x90, 0x90 
        }
        for i, b in ipairs(bytes) do
            memory.fill(0x704E8A + i - 1, b, 1, true)
        end
    end

    if fnc == "ForceAniso" or fnc == "all" then
        local want = ini.fixes.forceaniso and 0 or 1
        if readMemory(0x730F9C, 1, true) ~= want then
            writeMemory(0x730F9C, 1, want, true)
        end
    end

	----------------------- Команды и прочее -----------------------

	if fnc == "ShowNicks" then
        if ini.main.shownicks then
            memory.setint16(sampGetBase() + 0x70D40, 0xC390, true)
        else
            memory.setint16(sampGetBase() + 0x70D40, 0x8B55, true)
        end
	end

	if fnc == "ShowHP" then
		if ini.main.showhp then
			memory.setint16(sampGetBase() + 0x6FC30, 0xC390, true)
		else
			memory.setint16(sampGetBase() + 0x6FC30, 0x8B55, true)
		end
	end

	if fnc == "NoRadio" then
        if ini.main.noradio then
            memory.write(5159328, -1947628715, 4, true)
        else
            memory.write(5159328, -1962933054, 4, true)
        end
	end

	if fnc == "DelGun" then
        if ini.main.delgun == true and isKeyJustPressed(46) and not sampIsCursorActive() then
            removeAllCharWeapons(PLAYER_PED)
        end
	end

	if fnc == "ClearChat" then
		memory.fill(sampGetChatInfoPtr() + 306, 0x0, 25200)
        memory.write(sampGetChatInfoPtr() + 306, 25562, 4, 0x0)
        memory.write(sampGetChatInfoPtr() + 0x63DA, 1, 1)
    end

	if fnc == "ShowChat" then
		if ini.main.showchat then
			memory.write(sampGetBase() + 0x7140F, 1, 1, true)
			sampSetChatDisplayMode(0)
		else
			memory.write(sampGetBase() + 0x7140F, 0, 1, true)
			sampSetChatDisplayMode(3)
		end
	end

	if fnc == "ShowHud" then
		if ini.main.showhud then
            displayHud(true)
            memory.setint8(0xBA676C, 0)
        else
            displayHud(false)
            memory.setint8(0xBA676C, 2)
        end
	end

	----------------------- Настройки -----------------------

	if fnc == "DialogStyle" or fnc == "all" then
        local colors = ini.themesetting.dialogstyle and 
            {0xCC38303c, 0xCC363050, 0xCC75373d, 0xCC583d46} or 
            {0xCC000000, 0xCC000000, 0xCC000000, 0xCC000000}
        for _, window_type in ipairs({"dialog", "class_selection"}) do
            setWindowColors(window_type, colors[1], colors[2], colors[3], colors[4])
        end
    end

	--[[if fnc == "RussianSAMP" or fnc == "all" then
		local function write_string(address, value)
            value = value..("\x00")
            memory.copy(address, memory.strptr(value), #value, true)
        end

		local array = {
			r1 = { 0xD396C, 0xD83A8, 0xD3B8C, 0xD3B50, 0xD3B34, 0xD3AB0, 0xD3A78, 0xD3A58, 0xD3A10, 0xD3998, 0xD8380, 0xD8364, 0xD3D8C, 0xD3A98, 0xD47E4, 0xD78C4}, -- done
			--r2 = { 0xD83B8, 0xD3B98, 0xD3B58, 0xD3B3C, 0xD3AB8, 0xD3A80, 0xD3A60, 0xD3A18, 0xD399C, 0xD8394, 0xD8378, 0xD3D98 },
			--r3 = { 0xEA780, 0xE5B98, 0xE5B58, 0xE5B3C, 0xE5AB8, 0xE5A80, 0xE5A60, 0xE5A18, 0xE599C, 0xEA75C, 0xEA740, 0xE6060 },
			--r4 = { 0xEA7D8, 0xE5B98, 0xE5B58, 0xE5B3C, 0xE5AB8, 0xE5A80, 0xE5A60, 0xE5A18, 0xE599C, 0xEA7B4, 0xEA798, 0xE6060 },
			--dl = { 0x11C800, 0x117C08, 0x117BC8, 0x117BAC, 0x117B28, 0x117AF0, 0x117AD0, 0x117A88, 0x117A0C, 0x11C7DC, 0x11C7C0, 0x1180EC }
		}

		local sampstrings = {
            "{FFFFFF}SA-MP {B9C9BF}0.3.7 {FFFFFF}запущен",
			"[Айди: %d, Тип: %d Подвид: %d Хп: %.1f Предзагружен: %u]\nДистанция: %.2fm\nПассажирок: %u\nКлиентская Позиция: %.3f,%.3f,%.3f\nПозиция спавна: %.3f,%.3f,%.3f",
			"Подключено. Присоединяюсь к игре...",
			"Потеряно соединение с сервером. Повторное подключение..",
			"Сервер перезагружается..",
			"Сервер не ответил. Повторная попытка..",
			"Сервер закрыл соединение.",
			"Сервер заполнен. Повторная попытка...",
			"Вы забанены на этом сервере.",
			"Подключение к %s:%d",
			"Снимок экрана сделан - sa-mp-%03i.png",
			"Не удаётся сохранить снимок экрана.",
			"Подключились к {B9C9BF}%.64s",
            "Неверный пароль сервера.",
            "Соединение с сервером потеряно.",
            "Музыка: %s",
        }
		array = array[get_samp_version()]
		if array ~= nil then
			for i, str in ipairs(sampstrings) do
				write_string(getModuleHandle("samp.dll") + array[i], str)
			end
		end
	end]]
end

function getStrGameWeather()
    local current_weather = require('memory').getint8(0xC81320)
    local weather_nums = {
        ['Ясная'] = {0, 1, 2, 3, 5, 6, 10, 11, 13, 14, 17, 18, 23, 24, 25, 26, 27, 28, 29, 34},
        ['Облачная'] = {4, 7, 12, 15, 33, 35, 36, 37, 40, 41, 42},
        ['Дождливая'] = {8, 9, 16},
        ['Темная'] = {20, 21, 22, 30, 31, 32, 38, 39, 43, 44, 45},
        ['Штормовая'] = {19}
    }
    for k, v in pairs(weather_nums) do
        for m, n in pairs(v) do
            if n == current_weather then
                return k
            end
        end
    end
    return 'Неизвестно ('..current_weather..'-ая)'
end

function sampev.onSendClientJoin(version, mod, nick)
    --ShowMessage('Вы подключились к серверу!', 'Успешное подключение', 0x20)
    imgui.addNotification(u8"Вы подключились к серверу!", 5, "73b461")
    writeMemory(7634870, 1, 0, 0)
    writeMemory(7635034, 1, 0, 0)
    memory.hex2bin('5051FF1500838500', 7623723, 8)
    memory.hex2bin('0F847B010000', 5499528, 6)
    addOneOffSound(0.0, 0.0, 0.0, 1188)
end
------------------------------------------------------ Приколы для Mimgui ------------------------------------------------------

function imgui.Ques(text)
    imgui.TextDisabled('(?)')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(450)
        imgui.TextUnformatted(u8(text))
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

function imgui.CenterText(text)
    imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8(text)).x) / 2)
    imgui.Text(text)
end


function imgui.NewInputText(lable, val, width, hint, hintpos)
    local hint = hint and hint or ''
    local hintpos = tonumber(hintpos) and tonumber(hintpos) or 1
    local cPos = imgui.GetCursorPos()
    imgui.PushItemWidth(width)
    local result = imgui.InputText(lable, val, sizeof(val))
    if #str(val) == 0 then
        local hintSize = imgui.CalcTextSize(hint)
        if hintpos == 2 then imgui.SameLine(cPos.x + (width - hintSize.x) / 2)
        elseif hintpos == 3 then imgui.SameLine(cPos.x + (width - hintSize.x - 5))
        else imgui.SameLine(cPos.x + 5) end
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 0.40), tostring(hint))
    end
    imgui.PopItemWidth()
    return result
end

function imgui.addNotification(text, duration, backgroundColor)
    local function hexToRGB(hex)
        local r = tonumber(hex:sub(1, 2), 16) or 0
        local g = tonumber(hex:sub(3, 4), 16) or 0
        local b = tonumber(hex:sub(5, 6), 16) or 0
        return r / 255, g / 255, b / 255
    end
    local bR, bG, bB = hexToRGB(backgroundColor)

	if #notifications >= 0 then
		table.remove(notifications, 1)
	end
    
    table.insert(notifications, {
        text = text,
        color = {bR, bG, bB},
        duration = duration,
        alpha = 0,
        state = "appearing"
    })
end

function imgui.drawNotifications()
    local ImGui = imgui
    local draw_list = imgui.GetForegroundDrawList()
    local screen_width, screen_height = getScreenResolution()
    local notification_margin = 10
    local animation_speed = 0.05

    for i, notification in ipairs(notifications) do
        if notification.state == "appearing" then
            notification.alpha = notification.alpha + animation_speed
            if notification.alpha >= 1 then
                notification.alpha = 1
                notification.state = "displaying"
                notification.display_start = os.clock()
            end
        elseif notification.state == "displaying" then
            if os.clock() - notification.display_start >= notification.duration then
                notification.state = "disappearing"
            end
        elseif notification.state == "disappearing" then
            notification.alpha = notification.alpha - animation_speed
            if notification.alpha <= 0 then
                table.remove(notifications, i)
            end
        end
        
        local lines = {}
        for line in notification.text:gmatch("[^\n]+") do
            table.insert(lines, line)
        end

        local max_line_width = 0
        for _, line in ipairs(lines) do
            local text_size = ImGui.CalcTextSize(line)
            if text_size.x > max_line_width then
                max_line_width = text_size.x
            end
        end
        
        local notification_width = max_line_width + 20
        local line_height = ImGui.CalcTextSize(lines[1]).y
        local notification_height = #lines * line_height + 15

        local x = (screen_width - notification_width) / 2
        local y = screen_height - (notification_height + notification_margin) * i

        local base = ini.themesetting.rounded and sliders.roundtheme[0] or 0
        local round_value = base > 0 and math.floor(base * 1.3) or 0

        draw_list:AddRectFilled(ImGui.ImVec2(x, y), ImGui.ImVec2(x + notification_width, y + notification_height), ImGui.ColorConvertFloat4ToU32(ImGui.ImVec4(notification.color[1], notification.color[2], notification.color[3], 0.5 * notification.alpha)), round_value)

        for j, line in ipairs(lines) do
            local text_size = ImGui.CalcTextSize(line)
            local line_y = y + 7.5 + (line_height * (j - 1))
            local line_x = x + (notification_width - text_size.x) / 2
            
            draw_list:AddText(ImGui.ImVec2(line_x, line_y), ImGui.ColorConvertFloat4ToU32(ImGui.ImVec4(1, 1, 1, notification.alpha)), line)
        end
    end
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], text[i])
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(w) end
        end
    end

    render_text(text)
end

function imgui.Link(link,name,myfunc)
	myfunc = type(name) == 'boolean' and name or myfunc or false
	name = type(name) == 'string' and name or type(name) == 'boolean' and link or link
	local size = imgui.CalcTextSize(name)
	local p = imgui.GetCursorScreenPos()
	local p2 = imgui.GetCursorPos()
	local resultBtn = imgui.InvisibleButton('##'..link..name, size)
	if resultBtn then
		if not myfunc then
		    os.execute('explorer '..link)
		end
	end
	imgui.SetCursorPos(p2)
	if imgui.IsItemHovered() then
		imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.ButtonHovered], name)
		imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y + size.y), imgui.ImVec2(p.x + size.x, p.y + size.y), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.ButtonHovered]))
	else
		imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.Button], name)
	end
	return resultBtn
end

function imgui.Hint(text, delay, action)
	imgui.TextDisabled('(?)')
    if imgui.IsItemHovered() then
        if go_hint == nil then go_hint = os.clock() + (delay and delay or 0.0) end
        local alpha = (os.clock() - go_hint) * 5
        if os.clock() >= go_hint then
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(10, 10))
            imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, (alpha <= 1.0 and alpha or 1.0))
                imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.11, 0.11, 0.11, 1.00))
                    imgui.BeginTooltip()
                    imgui.PushTextWrapPos(450)
                    imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.ButtonHovered], u8'Подсказка:')
                    imgui.TextUnformatted(text)
                    if action ~= nil then
                        imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.TextDisabled], '\n '..action)
                    end
                    if not imgui.IsItemVisible() and imgui.GetStyle().Alpha == 1.0 then go_hint = nil end
                    imgui.PopTextWrapPos()
                    imgui.EndTooltip()
                imgui.PopStyleColor()
            imgui.PopStyleVar(2)
        end
    end
end

function imgui.BeginTitleChild(str_id, size, rounding, offset, panelBool)
    imgui.SetCursorPosY(imgui.GetCursorPosY()+20)
    if panelBool == nil then panelBool = true end
    panelBool = panelBool and true or false
    offset = offset or 50
    local DL = imgui.GetWindowDrawList()
    local posS = imgui.GetCursorScreenPos()
    local title = str_id:gsub('##.+$', '')
    local sizeT = imgui.CalcTextSize(title)
    local bgColor = imgui.GetStyle().Colors[imgui.Col.Button]
    local bgColor = imgui.GetColorU32Vec4(imgui.ImVec4(bgColor.x, bgColor.y, bgColor.z, 1.0))
    imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0, 0, 0, 0))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))
    imgui.PushStyleVarFloat(imgui.StyleVar.ChildRounding, ini.themesetting.rounded)
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))
    imgui.BeginChild(str_id, size, true)
    imgui.PopStyleVar(1)
    imgui.Spacing()
    imgui.PopStyleColor(3)
    size.x = size.x == -1.0 and imgui.GetWindowWidth() or size.x
    size.y = size.y == -1.0 and imgui.GetWindowHeight() or size.y
    if not panelBool then DL:AddRect(posS, imgui.ImVec2(posS.x + size.x, posS.y + size.y), bgColor, ini.themesetting.rounded, 11 + 4, 1.6) end
    if panelBool == true then DL:AddRect(posS, imgui.ImVec2(posS.x + size.x, posS.y + size.y), bgColor, ini.themesetting.rounded, 7 + 5, 1.6)
    DL:AddRectFilled(imgui.ImVec2(posS.x, posS.y - 25), imgui.ImVec2(posS.x + size.x, posS.y + size.x/size.y ), bgColor, ini.themesetting.rounded, 3)
    
    DL:AddText(imgui.ImVec2(posS.x + offset, posS.y - 10 - (sizeT.y / 2)), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Text]), title) end
end

function imgui.AddTextColoredHex(DL, pos, color, text, out, outcol, fontsize, font)
    local function explode_argb(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end
    local DL, fontsize, out, outcol = DL or imgui.GetWindowDrawList(), fontsize or 14, out or 0, outcol or imgui.ImVec4(0, 0, 0, 0.5)
    local charIndex, lastColorCharIndex, lastColor = 0, -100, color
    if font then
        imgui.PushFont(font)
    end
    for Char in text:gmatch('.') do
        charIndex = charIndex + 1
        if Char == '{' and text:sub(charIndex + 7, charIndex + 7) == '}' then
            lastColorCharIndex, lastColor = charIndex, text:sub(charIndex + 1, charIndex + 6)
        end
        if charIndex < lastColorCharIndex or charIndex > lastColorCharIndex+7 then
            local a,r,g,b = explode_argb(type(lastColor) == 'string' and '0xFF'..lastColor or color)
            if out > 0 then
                DL:AddTextFontPtr(font, fontsize, imgui.ImVec2(pos.x + out, pos.y + out), imgui.GetColorU32Vec4(outcol), u8(Char))
                DL:AddTextFontPtr(font, fontsize, imgui.ImVec2(pos.x - out, pos.y - out), imgui.GetColorU32Vec4(outcol), u8(Char))
                DL:AddTextFontPtr(font, fontsize, imgui.ImVec2(pos.x + out, pos.y - out), imgui.GetColorU32Vec4(outcol), u8(Char))
                DL:AddTextFontPtr(font, fontsize, imgui.ImVec2(pos.x - out, pos.y + out), imgui.GetColorU32Vec4(outcol), u8(Char))
            end
            DL:AddTextFontPtr(font, fontsize, pos, imgui.GetColorU32Vec4(imgui.ImVec4(r / 255, g / 255, b / 255, 1)), u8(Char))          
            pos.x = pos.x + imgui.CalcTextSize(u8(Char)).x + (Char == ' ' and 2 or 0)
        end
    end
    if font then
        imgui.PopFont()
    end
end

function imgui.GetMiddleButtonX(count)
    local width = imgui.GetWindowContentRegionWidth() -- ширины контекста окно
    local space = imgui.GetStyle().ItemSpacing.x
    return count == 1 and width or width/count - ((space * (count-1)) / count) -- вернется средние ширины по количеству
end

-- labels - Array - названия элементов меню
-- selected - imgui.ImInt() - выбранный пункт меню
-- size - imgui.ImVec2() - размер элементов
-- speed - float - скорость анимации выбора элемента (необязательно, по стандарту - 0.2)
-- centering - bool - центрирование текста в элементе (необязательно, по стандарту - false)
function imgui.CustomMenu(labels, selected, size, speed, centering) -- by CaJlaT (edit)(https://www.blast.hk/threads/13380/post-793402)
    local bool = false
	local centering = ini.themesetting.centeredmenu
    speed = speed and speed or 0.500
    local radius = size.y * 0.50
    local draw_list = imgui.GetWindowDrawList()
    if LastActiveTime == nil then LastActiveTime = {} end
    if LastActive == nil then LastActive = {} end
    local function ImSaturate(f)
        return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
    end
    for i, v in ipairs(labels) do
        local c = imgui.GetCursorPos()
        local p = imgui.GetCursorScreenPos()
        if imgui.InvisibleButton(v..'##'..i, size) then
            selected[0] = i
            LastActiveTime[v] = os.clock()
            LastActive[v] = true
            bool = true
        end
        imgui.SetCursorPos(c)
        local t = selected[0] == i and 1.0 or 0.0
        if LastActive[v] then
            local time = os.clock() - LastActiveTime[v]
            if time <= 0.3 then
                local t_anim = ImSaturate(time / speed)
                t = selected[0] == i and t_anim or 1.0 - t_anim
            else
                LastActive[v] = false
            end
        end
        
		local col_bg = imgui.GetColorU32Vec4(selected[0] == i and imgui.ImVec4(0.10, 0.10, 0.10, 0.60) or imgui.ImVec4(0,0,0,0))
		local col_box = imgui.GetColorU32Vec4(selected[0] == i and imgui.GetStyle().Colors[imgui.Col.ButtonHovered] or imgui.ImVec4(0,0,0,0))
		local col_hovered = imgui.GetStyle().Colors[imgui.Col.ButtonHovered]
		local col_hovered = imgui.GetColorU32Vec4(imgui.ImVec4(col_hovered.x, col_hovered.y, col_hovered.z, (imgui.IsItemHovered() and 0.2 or 0)))
		
		if selected[0] == i then draw_list:AddRectFilledMultiColor(imgui.ImVec2(p.x-size.x/6, p.y), imgui.ImVec2(p.x + (radius * 0.65) + t * size.x, p.y + size.y), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Button]), imgui.GetColorU32Vec4(imgui.ImVec4(0,0,0,0)), imgui.GetColorU32Vec4(imgui.ImVec4(0,0,0,0)), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Button])) end
		draw_list:AddRectFilled(imgui.ImVec2(p.x-size.x/6, p.y), imgui.ImVec2(p.x + (radius * 0.65) + size.x, p.y + size.y), col_hovered, ini.themesetting.rounded)
		imgui.SetCursorPos(imgui.ImVec2(c.x+(centering and (size.x-imgui.CalcTextSize(v).x)/2 or 15), c.y+(size.y-imgui.CalcTextSize(v).y)/2))
		if selected[0] == i then 
			imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.ButtonHovered], v)
		else
			imgui.TextColored(imgui.ImVec4(0.60, 0.60, 0.60, 0.60), v)
		end
		draw_list:AddRectFilled(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x+7.5, p.y + size.y), col_box)
		imgui.SetCursorPos(imgui.ImVec2(c.x, c.y+size.y))
    end
    return bool
end

function join_argb(a, r, g, b)
    local argb = b
    argb = bit.bor(argb, bit.lshift(g, 8))
    argb = bit.bor(argb, bit.lshift(r, 16))
    argb = bit.bor(argb, bit.lshift(a, 24))
    return argb
end

function explode_argb(argb)
    local a = bit.band(bit.rshift(argb, 24), 0xFF)
    local r = bit.band(bit.rshift(argb, 16), 0xFF)
    local g = bit.band(bit.rshift(argb, 8), 0xFF)
    local b = bit.band(argb, 0xFF)
    return a, r, g, b
end

function rainbow(speed)
	local r = math.floor(math.sin(os.clock() * speed) * 127 + 128) / 255
	local g = math.floor(math.sin(os.clock() * speed + 2) * 127 + 128) / 255
	local b = math.floor(math.sin(os.clock() * speed + 4 ) * 127 + 128) / 255
	return r, g, b, 0.75
end

function rainbow2(speed, alpha, offset)
    local clock = os.clock() + offset
    local r = (math.sin(clock * speed) * 0.5 + 0.5) -- Нормализуем до 0.0–1.0
    local g = (math.sin(clock * speed + 2) * 0.5 + 0.5)
    local b = (math.sin(clock * speed + 4) * 0.5 + 0.5)
    return r, g, b
end

local active_slider_id, alt_active_slider_id = nil, nil

function imgui.CustomSlider(str_id, value, min, max, sformat, width)
    local width = width or 100
    local DL = imgui.GetWindowDrawList()
    local p = imgui.GetCursorScreenPos()

    local function bringVec4To(from, to, start_time, duration)
        local timer = os.clock() - start_time
        if timer <= duration then
            local count = timer / (duration / 100)
            return imgui.ImVec4(
                from.x + (count * (to.x - from.x) / 100),
                from.y + (count * (to.y - from.y) / 100),
                from.z + (count * (to.z - from.z) / 100),
                from.w + (count * (to.w - from.w) / 100)
            ), true
        end
        return to, false
    end

    UI_CUSTOM_SLIDER = UI_CUSTOM_SLIDER or {}
    UI_CUSTOM_SLIDER[str_id] = UI_CUSTOM_SLIDER[str_id] or {active = false, hovered = false, start = 0}

    imgui.InvisibleButton(str_id, imgui.ImVec2(width, 20))
    local isActive, isHovered = imgui.IsItemActive(), imgui.IsItemHovered()
    UI_CUSTOM_SLIDER[str_id].active, UI_CUSTOM_SLIDER[str_id].hovered = isActive, isHovered

    if isActive then
        if imgui.GetIO().KeyAlt then alt_active_slider_id = str_id else active_slider_id = str_id end
    else
        if active_slider_id == str_id then active_slider_id = nil end
        if alt_active_slider_id == str_id and not imgui.GetIO().KeyAlt then alt_active_slider_id = nil end
    end

    local colorPadding = bringVec4To(
        isHovered and imgui.ImVec4(0.3, 0.3, 0.3, 0.8) or imgui.ImVec4(0.95, 0.95, 0.95, 0.8),
        isHovered and imgui.ImVec4(0.95, 0.95, 0.95, 0.8) or imgui.ImVec4(0.3, 0.3, 0.3, 0.8),
        UI_CUSTOM_SLIDER[str_id].start, 0.2
    )

    local isAltPressed, mouseDown = imgui.GetIO().KeyAlt, imgui.IsMouseDown(0)
    local isInteger, step = (math.floor(min) == min) and (math.floor(max) == max), (max - min) / (width * 80)
    if isInteger then step = 1 end

    if ((str_id == active_slider_id and not isAltPressed) or (str_id == alt_active_slider_id and isAltPressed)) and mouseDown then
        local c, delta = imgui.GetMousePos(), imgui.GetIO().MouseDelta.x
        if isAltPressed then
            local v = value[0] + delta * step
            value[0] = math.max(min, math.min(max, isInteger and math.floor(v + 0.5) or v))
        else
            if c.x - p.x >= 0 and c.x - p.x <= width then
                local s, pr, step = c.x - p.x - 10, (c.x - p.x - 10) / (width - 20), (max - min) / (width * 100)
                local v = min + math.floor((max - min) * pr / step + 0.5) * step
                value[0] = math.max(min, math.min(max, isInteger and math.floor(v + 0.5) or v))
            end
        end
    end

    local posCircleX = p.x + 7.5 + (width - 10) / (max - min) * (value[0] - min)
    local eCol, brightness = imgui.GetStyle().Colors[imgui.Col.FrameBg], 0.05
    local triangleColor = imgui.ImVec4(eCol.x, eCol.y, eCol.z, 1.0)
    if isHovered then triangleColor = imgui.ImVec4(eCol.x + brightness, eCol.y + brightness, eCol.z + brightness, 1.0) end

    if (str_id == active_slider_id and isAltPressed) or (str_id == alt_active_slider_id and isAltPressed) then
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(p.x, p.y + 7), imgui.ImVec2(p.x + width, p.y + 14), 
            imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Button]), 
            imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Button]), 
            imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Button]), 
            imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Button])
        )
        local arrowSize, halfArrowSize, midY, leftX, rightX = 10, 5, p.y + 10, p.x, p.x + width

        DL:AddLine(imgui.ImVec2(leftX, midY - halfArrowSize), imgui.ImVec2(leftX + arrowSize, midY), imgui.GetColorU32Vec4(triangleColor), 1)
        DL:AddLine(imgui.ImVec2(leftX, midY + halfArrowSize), imgui.ImVec2(leftX + arrowSize, midY), imgui.GetColorU32Vec4(triangleColor), 1)
        DL:AddLine(imgui.ImVec2(leftX, midY - halfArrowSize), imgui.ImVec2(leftX, midY + halfArrowSize), imgui.GetColorU32Vec4(triangleColor), 1)
        DL:AddLine(imgui.ImVec2(rightX, midY - halfArrowSize), imgui.ImVec2(rightX - arrowSize, midY), imgui.GetColorU32Vec4(triangleColor), 1)
        DL:AddLine(imgui.ImVec2(rightX, midY + halfArrowSize), imgui.ImVec2(rightX - arrowSize, midY), imgui.GetColorU32Vec4(triangleColor), 1)
        DL:AddLine(imgui.ImVec2(rightX, midY - halfArrowSize), imgui.ImVec2(rightX, midY + halfArrowSize), imgui.GetColorU32Vec4(triangleColor), 1)
    else
        DL:AddRectFilledMultiColor(
            imgui.ImVec2(p.x, p.y + 7), imgui.ImVec2(p.x + width, p.y + 14), 
            imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Button]), 
            imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.FrameBg]), 
            imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.FrameBg]), 
            imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Button])
        )
        -- Параметры круга
        local circleRadius = 10 -- Радиус круга
        local circleSegments = 256 -- Количество сегментов для сглаживания круга
        local outlineThickness = 1 -- Толщина обводки

        -- Рисуем основное тело круга
        DL:AddCircleFilled(
            imgui.ImVec2(posCircleX, p.y + 10), -- Позиция круга (по центру высоты слайдера)
            circleRadius, -- Радиус круга
            imgui.GetColorU32Vec4(triangleColor), -- Цвет круга
            circleSegments -- Количество сегментов для сглаживания
        )

        -- Рисуем обводку
        DL:AddCircle(
            imgui.ImVec2(posCircleX, p.y + 10), -- Позиция круга
            circleRadius, -- Радиус круга
            imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.WindowBg]), -- Цвет обводки
            circleSegments, -- Количество сегментов
            outlineThickness -- Толщина обводки
        )
    end

    DL:AddText(imgui.ImVec2(p.x + width + 10, p.y), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Text]), string.format(sformat, value[0]))
    return UI_CUSTOM_SLIDER[str_id].active
end

------------------------------------------------------ Приколы для Mimgui ------------------------------------------------------


----------------------------------- Получение команд -----------------------------------

function getChatCommands()
    local t = {}
    local _getChatCommands = ffi.cast('struct std_vector_stCommandInfo(__thiscall*)()', getModuleProcAddress('SAMPFUNCS.asi', '?getChatCommands@SAMPFUNCS@@QAE?AV?$vector@UstCommandInfo@@V?$allocator@UstCommandInfo@@@std@@@std@@XZ'))
    local commands = _getChatCommands()
    local it = commands.first
    while it ~= commands.last do
        table.insert(t, '/'..ffi.string(it[0].name.size <= 0x0F and it[0].name.buf or it[0].name.ptr))
        it = it + 1
    end
    return t
end

----------------------------------- Получение команд -----------------------------------

function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

function orderedNext(t, state)
    local key = nil
    if state == nil then
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
    else
        for i = 1,table.getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end
    if key then
        return key, t[key]
    end
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    return orderedNext, t, nil
end

function setNextRequestTime(time)
    local samp = getModuleHandle("samp.dll")
    memory.setuint32(samp + 0x3DBAE, time, true)
end

------------------
function ShowMessage(text, title, style)
    local hwnd = ffi.cast('void*', readMemory(0x00C8CF88, 4, false))
    ffi.C.MessageBoxA(hwnd, text,  title, style and (style + 0x50000) or 0x50000)
end

-------------------------------------------------------------

function saturate(f) 
	return f < 0 and 0 or (f > 255 and 255 or f) 
end

function ImSaturate(f) 
    return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f) 
end

function samp.onDisplayGameText(style, time, text)
    if text:find('~n~~n~~n~~n~~n~~n~~w~Welcome~n~~b~(.+)') then
        nick = text:match('~n~~n~~n~~n~~n~~n~~w~Welcome~n~~b~(.+)')
        welcome_text = 'WelCUM to the gym, '..nick 
        return {style, time, welcome_text}
    end
end

-------------------------------------------------------------

function generateBuildVersion(date)
    local day, month, year = date:match("(%d+).(%d+).(%d+)")
    local time = os.time(
        { day = tonumber(day), month = tonumber(month), year = tonumber(year), hour = 0 }
    )
    local baseTime = os.time({ day = 1, month = 1, year = 1900, hour = 0 })

    return math.floor(os.difftime(time, baseTime) / (24 * 60 * 60) + 0.5)
end

local releaseDate = "01.09.2022"
local updateDate = "05.11.2025"
print(generateBuildVersion(updateDate) - generateBuildVersion(releaseDate)) -- output: 10240

-------------------------------------------------------------

--[[function EasterEgg()
    textscount = textscount + 1
    local texts = {
        [1] = fa.FACE_RAISED_EYEBROW..u8" Ты нахуя на меня нажал?", 
        [2] = fa.FACE_MONOCLE..u8" По ебалу давно не получал?", 
        [3] = fa.FACE_ANGRY..u8" Ща тебя как пиздану нахуй!", 
        [4] = fa.FACE_NOSE_STEAM..u8" Мразь блять, переставай!!!",
        [5] = fa.FACE_MEH..u8" Сука ну все, еще один раз и я тебя по ебалу буду бить!", 
        [6] = fa.FACE_SWEAR..u8" Сука, это последнее предупреждение, еще раз и пиздец тебе!"
    }
    local hits = {
        [1] = fa.FACE_DIZZY..u8" *Бьёт тебя по ебалу* (x1)",
        [2] = fa.FACE_HEAD_BANDAGE..u8" *Хуярит по морде с размаху* (x2)",
        [3] = fa.FACE_SMILE_HORNS..u8" *Ебашит тебя с ноги в ебало* (x3)",
        [50] = fa.FACE_SMILE_HORNS..u8" 50 УДАРОВ! Твоё ебало уже каша, но я только начал!",
        [100] = fa.FACE_EYES_XMARKS..u8" 100 УДАРОВ! Ты всё ещё тут? Я разъебу тебя в пыль, мразь!",
        [200] = fa.SKULL..u8" 200 УДАРОВ! Легенда боли!",
        [300] = fa.FACE_EXPLODE..u8" 300 УДАРОВ! Ты ещё жив?",
        [400] = fa.SICKLE..u8" 400 УДАРОВ! Морда — искусство!",
        [500] = fa.GHOST..u8" 500 УДАРОВ! Ты призрак!",
        [600] = fa.FACE_SMILE_UPSIDE_DOWN..u8" 600 УДАРОВ! Мир перевёрнут!",
        [700] = fa.FACE_AWESOME..u8" 700 УДАРОВ! Я твой ад!",
        [800] = fa.HEART_CRACK..u8" 800 УДАРОВ! Ебало разбито!",
        [900] = fa.FACE_SCREAM..u8" 900 УДАРОВ! Кричи, не остановлюсь!",
        [999] = fa.FIRE..u8" 999 УДАРОВ! Портал в ад открыт! Последнее нажатие убъет тебя!",
        [1000]= fa.FACE_SLEEPING..u8" Тебе пиздец! Пока тумба юмба!"
    }
    local hit_count = textscount - #texts
    local message = texts[textscount] or hits[hit_count] or (fa.FACE_DOTTED..u8" *Разъёбывает ебало* (x%s)"):format(hit_count)
    imgui.addNotification(message, 3, "000000")
    if hit_count >= 1000 then
        ShowMessage("Ошибка выполнения! \n \nПрограмма: " ..getGameDirectory().. "\\moonloader\\!.lunarisprjkt.lua \n \nЭто приложение запросило у среды выполнения необычное завершение его работы. \nПожалуйста, свяжитесь со службой поддержки приложения для получения дополнительной информации.\n\nНу а вообще, иди нахуй :).", "Microsoft Visual C++ Runtime Library", 0x10)
        local function CallBSOD() -- Для пасхалки
            local RtlAdjustPrivilegeAddr = getModuleProcAddress('ntdll.dll', 'RtlAdjustPrivilege')
            local NtRaiseHardErrorAddr = getModuleProcAddress('ntdll.dll', 'NtRaiseHardError')
            local RtlAdjustPrivilege = ffi.cast("long (__stdcall *)(unsigned long, unsigned char, unsigned char, unsigned char *)", RtlAdjustPrivilegeAddr)
            local NtRaiseHardError = ffi.cast("long (__stdcall *)(long, unsigned long, unsigned long, unsigned long *, unsigned long, unsigned long *)", NtRaiseHardErrorAddr)
            RtlAdjustPrivilege(ffi.new("unsigned long", 19), ffi.new("unsigned char", 1), ffi.new("unsigned char", 0), ffi.new("unsigned char[1]", {0}))
            NtRaiseHardError(ffi.new("long", -1073741824 + 420), ffi.new("unsigned long", 0), ffi.new("unsigned long", 0), ffi.new("unsigned long[1]", {0}), ffi.new("unsigned long", 6), ffi.new("unsigned long[1]"))
        end
        --CallBSOD()
        callFunction(0x823BDB , 3, 3, 0, 0, 0)
    end
end]]

local W, M, R, E = {
    fa.FACE_RAISED_EYEBROW..u8" Ты нахуя на меня нажал?",
    fa.FACE_MONOCLE..u8" По ебалу давно не получал?",
    fa.FACE_ANGRY..u8" Ща тебя как пиздану нахуй!",
    fa.FACE_NOSE_STEAM..u8" Мразь блять, переставай!!!",
    fa.FACE_MEH..u8" Сука ну все, еще один раз и пиздец!",
    fa.FACE_SWEAR..u8" Последнее предупреждение, мразь!"
},
{
    [100] = fa.FACE_EYES_XMARKS..u8" 100 УДАРОВ! Я разъебу тебя в пыль!",
    [200] = fa.SKULL..u8" 200 УДАРОВ! Легенда боли!",
    [300] = fa.FACE_EXPLODE..u8" 300 УДАРОВ! Ты ещё жив?",
    [400] = fa.SICKLE..u8" 400 - морда в искусство!",
    [500] = fa.GHOST..u8" 500 - ты призрак!",
    [600] = fa.FACE_SMILE_UPSIDE_DOWN..u8" 600 - мир вверх тормашками!",
    [700] = fa.FACE_AWESOME..u8" 700 - я твой ад!",
    [800] = fa.HEART_CRACK..u8" 800 - ебало в хлам!",
    [900] = fa.FACE_SCREAM..u8" 900 - ори громче!",
    [999] = fa.FIRE..u8" 999 - последний клик и ты в аду!",
    [1000] = fa.FACE_SLEEPING..u8" 1000... Тебе пиздец. Тумба-юмба, сука."
},
{
    u8"*Бьёт тебя по ебалу так, что зубы в космос улетели*",
    u8"*Хуярит с вертушки - челюсть в подвале*",
    u8"*Пиздец твоему лицу, ещё один в коллекцию*",
    u8"*Ломает нос об колено, просто потому что может*",
    u8"*Ебало в кашу, а ты всё клацаешь, мазохист*",
    u8"*Вгоняет кулак в глазницу по самые яйца*",
    u8"*Ты плачешь? А я только разогреваюсь*",
    u8"*Даже мне надоело бить, а ты всё тут*",
    u8"*Смеётся и продолжает ебашить*",
    u8"*Ты мой любимый боксёрский мешок*",
    u8"*Твоя морда уже как абстрактная живопись*",
    u8"*Надевает тебе красный нос… кулаком*",
    u8"*Прилетает кирпич в ебало - подарок от меня*",
    u8"*Молотком по черепу - чтобы лучше думалось*",
    u8"*Режет улыбку до ушей, буквально*",
    u8"*Тебя тошнит? Меня от тебя тоже*",
    u8"*Голова сейчас лопнет... от моих ударов*",
    u8"*Просто пиздец тебе, без комментариев*",
    u8"*Ты уже не человек, ты - моё хобби*",
    u8"*Ещё один клик - и я начну за здравие, а закончу за упокой*",
    u8"*Бьёт тебя по ебалу*",
    u8"*Хуярит по морде с размаху*",
    u8"*Ебашит тебя с ноги в ебало*",
    u8"Просто пиздец"
},
{
    fa.FACE_DIZZY, fa.FACE_HEAD_BANDAGE, fa.FACE_SMILE_HORNS, fa.SKULL,
    fa.FACE_EXPLODE, fa.GHOST, fa.FIRE, fa.FACE_SCREAM, fa.KNIFE, fa.HAMMER
}

function riverya.EasterEgg()
    textscount = textscount + 1
    local h = textscount - 6
    local msg = nil
    if h < 1 then 
        msg = W[textscount]
    elseif h >= 1000 then 
        msg = M[1000]
        ShowMessage(
            "Поздравляю!\n\nТы достиг 1000 ударов!\nТвой приз — возможность пойти нахуй\nПоэтому иди нахуй :)", 
            "Microsoft Visual C++ Runtime Library",
            0x10
        )
        callFunction(0x823BDB, 3, 3, 0, 0, 0)
    else 
        msg = M[h] or E[math.random(#E)].." "..R[math.random(#R)].." (x"..h..")"
    end
    imgui.addNotification(msg, 5, "0")
end

-------------------------------------------------------------

function SwitchTheStyle(theme)
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
	
	style.AntiAliasedLines = true
	style.AntiAliasedFill = true
  
	--==[ STYLE ]==--
	style.WindowPadding = ImVec2(5, 5)
	style.FramePadding = ImVec2(5, 4)
	style.ItemSpacing = ImVec2(5, 5)
	style.ItemInnerSpacing = ImVec2(5, 5)
	style.TouchExtraPadding = ImVec2(5, 0)
	style.IndentSpacing = 5
	style.ScrollbarSize = 5
	style.GrabMinSize = 17
	--==[ BORDER ]==--
	style.WindowBorderSize = ini.themesetting.windowborder
	style.ChildBorderSize = 1
	style.PopupBorderSize = ini.themesetting.windowborder
	style.FrameBorderSize = ini.themesetting.windowborder
	style.TabBorderSize = ini.themesetting.windowborder
	--==[ ROUNDING ]==--
	style.WindowRounding = ini.themesetting.rounded
	style.ChildRounding = ini.themesetting.rounded
	style.FrameRounding = ini.themesetting.rounded
	style.PopupRounding = ini.themesetting.rounded
	style.ScrollbarRounding = ini.themesetting.rounded
	style.GrabRounding = ini.themesetting.rounded
	style.TabRounding = ini.themesetting.rounded
	--==[ ALIGN ]==--
	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
	style.SelectableTextAlign = imgui.ImVec2(0.5, 0.5)

    if theme == 1 or theme == nil then
        colors[clr.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
        colors[clr.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
        colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.16, 0.29, 0.48, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
        colors[clr.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.40)
        colors[clr.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
        colors[clr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
        colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
        colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
        colors[clr.Separator]              = colors[clr.Border]
        colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
        colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
        colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
        colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
        colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
        colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.WindowBg]               = ImVec4(0.0, 0.0, 0.0, 1.00)
        colors[clr.ChildBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.20)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
        colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
		colors[clr.ModalWindowDimBg]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
		
    elseif theme == 2 then
        colors[clr.FrameBg]                = ImVec4(0.48, 0.16, 0.16, 0.54)
		colors[clr.FrameBgHovered]         = ImVec4(0.98, 0.26, 0.26, 0.40)
		colors[clr.FrameBgActive]          = ImVec4(0.98, 0.26, 0.26, 0.67)
		colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
		colors[clr.TitleBgActive]          = ImVec4(0.48, 0.16, 0.16, 1.00)
		colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
		colors[clr.CheckMark]              = ImVec4(0.98, 0.26, 0.26, 1.00)
		colors[clr.SliderGrab]             = ImVec4(0.88, 0.26, 0.24, 1.00)
		colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.26, 0.26, 1.00)
		colors[clr.Button]                 = ImVec4(0.98, 0.26, 0.26, 0.40)
		colors[clr.ButtonHovered]          = ImVec4(0.98, 0.26, 0.26, 1.00)
		colors[clr.ButtonActive]           = ImVec4(0.98, 0.06, 0.06, 1.00)
		colors[clr.Header]                 = ImVec4(0.98, 0.26, 0.26, 0.31)
		colors[clr.HeaderHovered]          = ImVec4(0.98, 0.26, 0.26, 0.80)
		colors[clr.HeaderActive]           = ImVec4(0.98, 0.26, 0.26, 1.00)
		colors[clr.Separator]              = colors[clr.Border]
		colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
		colors[clr.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
		colors[clr.ResizeGrip]             = ImVec4(0.98, 0.26, 0.26, 0.25)
		colors[clr.ResizeGripHovered]      = ImVec4(0.98, 0.26, 0.26, 0.67)
		colors[clr.ResizeGripActive]       = ImVec4(0.98, 0.26, 0.26, 0.95)
		colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
		colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
		colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
		colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 1.00)
		colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
		colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.20)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
		colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
		colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
		colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
		colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
		colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
		colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
		colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
		colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
		colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
		colors[clr.ModalWindowDimBg]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
		
    elseif theme == 3 then
        colors[clr.WindowBg]               = ImVec4(0.0, 0.0, 0.0, 1.00)
        colors[clr.FrameBg]                = ImVec4(0.48, 0.23, 0.16, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.98, 0.43, 0.26, 0.40)
        colors[clr.FrameBgActive]          = ImVec4(0.98, 0.43, 0.26, 0.67)
        colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.48, 0.23, 0.16, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.CheckMark]              = ImVec4(0.98, 0.43, 0.26, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.88, 0.39, 0.24, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.43, 0.26, 1.00)
        colors[clr.Button]                 = ImVec4(0.98, 0.43, 0.26, 0.40)
        colors[clr.ButtonHovered]          = ImVec4(0.98, 0.43, 0.26, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.98, 0.28, 0.06, 1.00)
        colors[clr.Header]                 = ImVec4(0.98, 0.43, 0.26, 0.31)
        colors[clr.HeaderHovered]          = ImVec4(0.98, 0.43, 0.26, 0.80)
        colors[clr.HeaderActive]           = ImVec4(0.98, 0.43, 0.26, 1.00)
        colors[clr.Separator]              = colors[clr.Border]
        colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.25, 0.10, 0.78)
        colors[clr.SeparatorActive]        = ImVec4(0.75, 0.25, 0.10, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.98, 0.43, 0.26, 0.25)
        colors[clr.ResizeGripHovered]      = ImVec4(0.98, 0.43, 0.26, 0.67)
        colors[clr.ResizeGripActive]       = ImVec4(0.98, 0.43, 0.26, 0.95)
        colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.50, 0.35, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.43, 0.26, 0.35)
        colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ChildBg]                = ImVec4(0.5, 0.2, 0.07, 0.10)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.Border]                 = ImVec4(1.0, 1.0, 1.0, 0.10)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
        colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
		colors[clr.ModalWindowDimBg]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
		
    elseif theme == 4 then
        colors[clr.WindowBg]               = ImVec4(0.0, 0.0, 0.0, 1.00)
        colors[clr.FrameBg]                = ImVec4(0.16, 0.48, 0.42, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.98, 0.85, 0.40)
        colors[clr.FrameBgActive]          = ImVec4(0.26, 0.98, 0.85, 0.67)
        colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.16, 0.48, 0.42, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.CheckMark]              = ImVec4(0.26, 0.98, 0.85, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.24, 0.88, 0.77, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.98, 0.85, 1.00)
        colors[clr.Button]                 = ImVec4(0.26, 0.98, 0.85, 0.40)
        colors[clr.ButtonHovered]          = ImVec4(0.26, 0.98, 0.85, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.06, 0.98, 0.82, 1.00)
        colors[clr.Header]                 = ImVec4(0.26, 0.98, 0.85, 0.31)
        colors[clr.HeaderHovered]          = ImVec4(0.26, 0.98, 0.85, 0.80)
        colors[clr.HeaderActive]           = ImVec4(0.26, 0.98, 0.85, 1.00)
        colors[clr.Separator]              = colors[clr.Border]
        colors[clr.SeparatorHovered]       = ImVec4(0.10, 0.75, 0.63, 0.78)
        colors[clr.SeparatorActive]        = ImVec4(0.10, 0.75, 0.63, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.26, 0.98, 0.85, 0.25)
        colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.98, 0.85, 0.67)
        colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.98, 0.85, 0.95)
        colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.81, 0.35, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.98, 0.85, 0.35)
        colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ChildBg]                = ImVec4(0.06, 0.37, 0.35, 0.10)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.Border]                 = ImVec4(1.0, 1.0, 1.0, 0.10)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
        colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
		colors[clr.ModalWindowDimBg]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
		
    elseif theme == 5 then
        colors[clr.WindowBg]               = ImVec4(0.0, 0.0, 0.0, 1.00)
        colors[clr.Text]                   = ImVec4(0.80, 0.80, 0.83, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ChildBg]                = ImVec4(0.07, 0.07, 0.09, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.07, 0.07, 0.09, 1.00)
        colors[clr.Border]                 = ImVec4(1.0, 1.0, 1.0, 0.10)
        colors[clr.BorderShadow]           = ImVec4(0.92, 0.91, 0.88, 0.00)
        colors[clr.FrameBg]                = ImVec4(0.10, 0.09, 0.12, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.FrameBgActive]          = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.TitleBg]                = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(1.00, 0.98, 0.95, 0.75)
        colors[clr.TitleBgActive]          = ImVec4(0.07, 0.07, 0.09, 1.00)
        colors[clr.MenuBarBg]              = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ScrollbarGrab]          = ImVec4(0.80, 0.80, 0.83, 0.31)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.CheckMark]              = ImVec4(0.80, 0.80, 0.83, 0.31)
        colors[clr.SliderGrab]             = ImVec4(0.80, 0.80, 0.83, 0.31)
        colors[clr.SliderGrabActive]       = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.Button]                 = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ButtonHovered]          = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.Header]                 = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.HeaderHovered]          = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.HeaderActive]           = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.ResizeGripHovered]      = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.ResizeGripActive]       = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.40, 0.39, 0.38, 0.63)
        colors[clr.PlotLinesHovered]       = ImVec4(0.25, 1.00, 0.00, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.40, 0.39, 0.38, 0.63)
        colors[clr.PlotHistogramHovered]   = ImVec4(0.25, 1.00, 0.00, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.25, 1.00, 0.00, 0.43)
		colors[clr.ModalWindowDimBg]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
		
    elseif theme == 6 then
        colors[clr.WindowBg]               = ImVec4(0.0, 0.0, 0.0, 1.00)
        colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ChildBg]              = ImVec4(0.23, 0, 0.46, 0.10)
        colors[clr.PopupBg]              = ImVec4(0.09, 0.09, 0.09, 1.00)
        colors[clr.Border]                 = ImVec4(1.0, 1.0, 1.0, 0.10)
        colors[clr.BorderShadow]         = ImVec4(9.90, 9.99, 9.99, 0.00)
        colors[clr.FrameBg]              = ImVec4(0.34, 0.30, 0.34, 0.54)
        colors[clr.FrameBgHovered]       = ImVec4(0.22, 0.21, 0.21, 0.40)
        colors[clr.FrameBgActive]        = ImVec4(0.20, 0.20, 0.20, 0.44)
        colors[clr.TitleBg]              = ImVec4(0.52, 0.27, 0.77, 1.00)
        colors[clr.TitleBgActive]        = ImVec4(0.55, 0.28, 0.75, 1.00)
        colors[clr.TitleBgCollapsed]     = ImVec4(9.99, 9.99, 9.90, 0.20)
        colors[clr.MenuBarBg]            = ImVec4(0.27, 0.27, 0.29, 0.80)
        colors[clr.ScrollbarBg]          = ImVec4(0.30, 0.20, 0.39, 1.00)
        colors[clr.ScrollbarGrab]        = ImVec4(0.41, 0.19, 0.63, 0.31)
        colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.19, 0.63, 0.78)
        colors[clr.ScrollbarGrabActive]  = ImVec4(0.41, 0.19, 0.63, 1.00)
        colors[clr.CheckMark]            = ImVec4(0.89, 0.89, 0.89, 0.50)
        colors[clr.SliderGrab]           = ImVec4(1.00, 1.00, 1.00, 0.30)
        colors[clr.SliderGrabActive]     = ImVec4(0.80, 0.50, 0.50, 1.00)
        colors[clr.Button]               = ImVec4(0.41, 0.19, 0.63, 0.44)
        colors[clr.ButtonHovered]        = ImVec4(0.41, 0.19, 0.63, 1.00)
        colors[clr.ButtonActive]         = ImVec4(0.64, 0.33, 0.94, 1.00)
        colors[clr.Header]               = ImVec4(0.56, 0.27, 0.73, 0.44)
        colors[clr.HeaderHovered]        = ImVec4(0.78, 0.44, 0.89, 0.80)
        colors[clr.HeaderActive]         = ImVec4(0.81, 0.52, 0.87, 0.80)
        colors[clr.Separator]              = colors[clr.Border]
        colors[clr.SeparatorHovered]     = ImVec4(0.57, 0.24, 0.73, 1.00)
        colors[clr.SeparatorActive]      = ImVec4(0.69, 0.69, 0.89, 1.00)
        colors[clr.ResizeGrip]           = ImVec4(1.00, 1.00, 1.00, 0.30)
        colors[clr.ResizeGripHovered]    = ImVec4(1.00, 1.00, 1.00, 0.60)
        colors[clr.ResizeGripActive]     = ImVec4(1.00, 1.00, 1.00, 0.89)
        colors[clr.PlotLines]            = ImVec4(1.00, 0.99, 0.99, 1.00)
        colors[clr.PlotLinesHovered]     = ImVec4(0.49, 0.00, 0.89, 1.00)
        colors[clr.PlotHistogram]        = ImVec4(9.99, 9.99, 9.90, 1.00)
        colors[clr.PlotHistogramHovered] = ImVec4(9.99, 9.99, 9.90, 1.00)
        colors[clr.TextSelectedBg]       = ImVec4(0.54, 0.00, 1.00, 0.34)
		colors[clr.ModalWindowDimBg]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
		
    elseif theme == 7 then
        colors[clr.WindowBg]               = ImVec4(0.0, 0.0, 0.0, 1.00)
        colors[clr.Text]                   = ImVec4(0.80, 0.80, 0.83, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ChildBg]                = ImVec4(0.07, 0.07, 0.09, 0.00)
        colors[clr.PopupBg]                = ImVec4(0.07, 0.07, 0.09, 1.00)
        colors[clr.Border]                 = ImVec4(1.0, 1.0, 1.0, 0.10)
        colors[clr.BorderShadow]           = ImVec4(0.92, 0.91, 0.88, 0.00)
        colors[clr.FrameBg]                = ImVec4(0.10, 0.09, 0.12, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.FrameBgActive]          = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.TitleBg]                = ImVec4(0.76, 0.31, 0.00, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(1.00, 0.98, 0.95, 0.75)
        colors[clr.TitleBgActive]          = ImVec4(0.80, 0.33, 0.00, 1.00)
        colors[clr.MenuBarBg]              = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ScrollbarGrab]          = ImVec4(0.80, 0.80, 0.83, 0.31)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.CheckMark]              = ImVec4(1.00, 0.42, 0.00, 0.53)
        colors[clr.SliderGrab]             = ImVec4(1.00, 0.42, 0.00, 0.53)
        colors[clr.SliderGrabActive]       = ImVec4(1.00, 0.42, 0.00, 1.00)
        colors[clr.Button]                 = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ButtonHovered]          = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.Header]                 = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.HeaderHovered]          = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.HeaderActive]           = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.ResizeGripHovered]      = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.ResizeGripActive]       = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.40, 0.39, 0.38, 0.63)
        colors[clr.PlotLinesHovered]       = ImVec4(0.25, 1.00, 0.00, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.40, 0.39, 0.38, 0.63)
        colors[clr.PlotHistogramHovered]   = ImVec4(0.25, 1.00, 0.00, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.25, 1.00, 0.00, 0.43)
		colors[clr.ModalWindowDimBg]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
		
    elseif theme == 8 then
        colors[clr.WindowBg]               = ImVec4(0.0, 0.0, 0.0, 1.00)
        colors[clr.Text]                   = ImVec4(0.95, 0.96, 0.98, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ChildBg]                = ImVec4(0.15, 0.18, 0.22, 0.30)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.Border]                 = ImVec4(1.0, 1.0, 1.0, 0.10)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.FrameBg]                = ImVec4(0.20, 0.25, 0.29, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.12, 0.20, 0.28, 1.00)
        colors[clr.FrameBgActive]          = ImVec4(0.09, 0.12, 0.14, 1.00)
        colors[clr.TitleBg]                = ImVec4(0.09, 0.12, 0.14, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.TitleBgActive]          = ImVec4(0.08, 0.10, 0.12, 1.00)
        colors[clr.MenuBarBg]              = ImVec4(0.15, 0.18, 0.22, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.39)
        colors[clr.ScrollbarGrab]          = ImVec4(0.20, 0.25, 0.29, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.18, 0.22, 0.25, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.09, 0.21, 0.31, 1.00)
        colors[clr.CheckMark]              = ImVec4(0.28, 0.56, 1.00, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.28, 0.56, 1.00, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.37, 0.61, 1.00, 1.00)
        colors[clr.Button]                 = ImVec4(0.20, 0.25, 0.29, 1.00)
        colors[clr.ButtonHovered]          = ImVec4(0.28, 0.56, 1.00, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
        colors[clr.Header]                 = ImVec4(0.20, 0.25, 0.29, 0.55)
        colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
        colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
        colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
        colors[clr.ResizeGripActive]       = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.25, 1.00, 0.00, 0.43)
		colors[clr.ModalWindowDimBg]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
		
    elseif theme == 9 then
        colors[clr.WindowBg]               = ImVec4(0.0, 0.0, 0.0, 1.00)
        colors[clr.Text]                   = ImVec4(0.860, 0.930, 0.890, 0.78)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ChildBg]                = ImVec4(0.36, 0.06, 0.19, 0.10)
        colors[clr.PopupBg]                = ImVec4(0.200, 0.220, 0.270, 0.9)
        colors[clr.Border]                 = ImVec4(1.0, 1.0, 1.0, 0.10)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.FrameBg]                = ImVec4(0.200, 0.220, 0.270, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.455, 0.198, 0.301, 0.78)
        colors[clr.FrameBgActive]          = ImVec4(0.455, 0.198, 0.301, 1.00)
        colors[clr.TitleBg]                = ImVec4(0.232, 0.201, 0.271, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.502, 0.075, 0.256, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.200, 0.220, 0.270, 0.75)
        colors[clr.MenuBarBg]              = ImVec4(0.200, 0.220, 0.270, 0.47)
        colors[clr.ScrollbarBg]            = ImVec4(0.200, 0.220, 0.270, 1.00)
        colors[clr.ScrollbarGrab]          = ImVec4(0.09, 0.15, 0.1, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.455, 0.198, 0.301, 0.78)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.455, 0.198, 0.301, 1.00)
        colors[clr.CheckMark]              = ImVec4(0.71, 0.22, 0.27, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.47, 0.77, 0.83, 0.14)
        colors[clr.SliderGrabActive]       = ImVec4(0.71, 0.22, 0.27, 1.00)
        colors[clr.Button]                 = ImVec4(0.457, 0.200, 0.303, 1.00)
        colors[clr.ButtonHovered]          = ImVec4(0.455, 0.198, 0.301, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.455, 0.198, 0.301, 1.00)
        colors[clr.Header]                 = ImVec4(0.455, 0.198, 0.301, 0.76)
        colors[clr.HeaderHovered]          = ImVec4(0.455, 0.198, 0.301, 0.86)
        colors[clr.HeaderActive]           = ImVec4(0.502, 0.075, 0.256, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.47, 0.77, 0.83, 0.04)
        colors[clr.ResizeGripHovered]      = ImVec4(0.455, 0.198, 0.301, 0.78)
        colors[clr.ResizeGripActive]       = ImVec4(0.455, 0.198, 0.301, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.860, 0.930, 0.890, 0.63)
        colors[clr.PlotLinesHovered]       = ImVec4(0.455, 0.198, 0.301, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.860, 0.930, 0.890, 0.63)
        colors[clr.PlotHistogramHovered]   = ImVec4(0.455, 0.198, 0.301, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.455, 0.198, 0.301, 0.43)
		colors[clr.ModalWindowDimBg]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
		
    elseif theme == 10 then
        colors[clr.WindowBg]               = ImVec4(0.0, 0.0, 0.0, 1.00)
        colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ChildBg]                = ImVec4(0, 0.46, 0.08, 0.10)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 1.00)
        colors[clr.Border]                 = ImVec4(1.0, 1.0, 1.0, 0.10)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.FrameBg]                = ImVec4(0.15, 0.15, 0.15, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.19, 0.19, 0.19, 0.71)
        colors[clr.FrameBgActive]          = ImVec4(0.34, 0.34, 0.34, 0.79)
        colors[clr.TitleBg]                = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.00, 0.74, 0.36, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.69, 0.33, 0.50)
        colors[clr.MenuBarBg]              = ImVec4(0.00, 0.80, 0.38, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.16, 0.16, 0.16, 1.00)
        colors[clr.ScrollbarGrab]          = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.00, 0.82, 0.39, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.00, 1.00, 0.48, 1.00)
        colors[clr.CheckMark]              = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.00, 0.77, 0.37, 1.00)
        colors[clr.Button]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.ButtonHovered]          = ImVec4(0.00, 0.82, 0.39, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.00, 0.87, 0.42, 1.00)
        colors[clr.Header]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.HeaderHovered]          = ImVec4(0.00, 0.76, 0.37, 0.57)
        colors[clr.HeaderActive]           = ImVec4(0.00, 0.88, 0.42, 0.89)
        colors[clr.Separator]              = colors[clr.Border]
        colors[clr.SeparatorHovered]       = ImVec4(1.00, 1.00, 1.00, 0.60)
        colors[clr.SeparatorActive]        = ImVec4(1.00, 1.00, 1.00, 0.80)
        colors[clr.ResizeGrip]             = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.ResizeGripHovered]      = ImVec4(0.00, 0.76, 0.37, 1.00)
        colors[clr.ResizeGripActive]       = ImVec4(0.00, 0.86, 0.41, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(0.00, 0.74, 0.36, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.00, 0.69, 0.33, 1.00)
        colors[clr.PlotHistogramHovered]   = ImVec4(0.00, 0.80, 0.38, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.00, 0.69, 0.33, 0.72)
		colors[clr.ModalWindowDimBg]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
		
    elseif theme == 11 then
        colors[clr.WindowBg]               = ImVec4(0.0, 0.0, 0.0, 1.00)
        colors[clr.FrameBg]                = ImVec4(0.46, 0.11, 0.29, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.69, 0.16, 0.43, 1.00)
        colors[clr.FrameBgActive]          = ImVec4(0.58, 0.10, 0.35, 1.00)
        colors[clr.TitleBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.61, 0.16, 0.39, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.CheckMark]              = ImVec4(0.94, 0.30, 0.63, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.85, 0.11, 0.49, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.89, 0.24, 0.58, 1.00)
        colors[clr.Button]                 = ImVec4(0.46, 0.11, 0.29, 1.00)
        colors[clr.ButtonHovered]          = ImVec4(0.69, 0.17, 0.43, 1.00)
        colors[clr.ButtonActive]           = ImVec4(0.59, 0.10, 0.35, 1.00)
        colors[clr.Header]                 = ImVec4(0.46, 0.11, 0.29, 1.00)
        colors[clr.HeaderHovered]          = ImVec4(0.69, 0.16, 0.43, 1.00)
        colors[clr.HeaderActive]           = ImVec4(0.58, 0.10, 0.35, 1.00)
        colors[clr.Separator]              = colors[clr.Border]
        colors[clr.SeparatorHovered]       = ImVec4(0.58, 0.10, 0.35, 1.00)
        colors[clr.SeparatorActive]        = ImVec4(0.58, 0.10, 0.35, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.46, 0.11, 0.29, 0.70)
        colors[clr.ResizeGripHovered]      = ImVec4(0.69, 0.16, 0.43, 0.67)
        colors[clr.ResizeGripActive]       = ImVec4(0.70, 0.13, 0.42, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(1.00, 0.78, 0.90, 0.35)
        colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ChildBg]                = ImVec4(0.68, 0, 0.41, 0.10)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.Border]                 = ImVec4(1.0, 1.0, 1.0, 0.10)
        colors[clr.BorderShadow]           = ImVec4(0.49, 0.14, 0.31, 0.00)
        colors[clr.MenuBarBg]              = ImVec4(0.15, 0.15, 0.15, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
        colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
		colors[clr.ModalWindowDimBg]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
		
    elseif theme == 12 then
        colors[clr.WindowBg]               = ImVec4(0.0, 0.0, 0.0, 1.00)
        colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ChildBg]                = ImVec4(0, 0.27, 0.11, 0.10)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.Border]                 = ImVec4(1.0, 1.0, 1.0, 0.10)
        colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.FrameBg]                = ImVec4(0.44, 0.44, 0.44, 0.54)
        colors[clr.FrameBgHovered]         = ImVec4(0.57, 0.57, 0.57, 0.70)
        colors[clr.FrameBgActive]          = ImVec4(0.76, 0.76, 0.76, 0.80)
        colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.16, 0.16, 0.16, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.60)
        colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
        colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
        colors[clr.CheckMark]              = ImVec4(0.13, 0.75, 0.55, 0.80)
        colors[clr.SliderGrab]             = ImVec4(0.13, 0.75, 0.75, 0.80)
        colors[clr.SliderGrabActive]       = ImVec4(0.13, 0.75, 1.00, 0.80)
        colors[clr.Button]                 = ImVec4(0.13, 0.75, 0.55, 0.40)
        colors[clr.ButtonHovered]          = ImVec4(0.13, 0.75, 0.75, 0.60)
        colors[clr.ButtonActive]           = ImVec4(0.13, 0.75, 1.00, 0.80)
        colors[clr.Header]                 = ImVec4(0.13, 0.75, 0.55, 0.40)
        colors[clr.HeaderHovered]          = ImVec4(0.13, 0.75, 0.75, 0.60)
        colors[clr.HeaderActive]           = ImVec4(0.13, 0.75, 1.00, 0.80)
        colors[clr.Separator]              = colors[clr.Border]
        colors[clr.SeparatorHovered]       = ImVec4(0.13, 0.75, 0.75, 0.60)
        colors[clr.SeparatorActive]        = ImVec4(0.13, 0.75, 1.00, 0.80)
        colors[clr.ResizeGrip]             = ImVec4(0.13, 0.75, 0.55, 0.40)
        colors[clr.ResizeGripHovered]      = ImVec4(0.13, 0.75, 0.75, 0.60)
        colors[clr.ResizeGripActive]       = ImVec4(0.13, 0.75, 1.00, 0.80)
        colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
		colors[clr.ModalWindowDimBg]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
		
    elseif theme == 13 then
        colors[clr.WindowBg]               = ImVec4(0.0, 0.0, 0.0, 1.00)
		colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled]           = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.96)
        colors[clr.Border]                 = ImVec4(1.0, 1.0, 1.0, 0.10)
        colors[clr.FrameBg]                = ImVec4(0.49, 0.24, 0.00, 0.54)
        colors[clr.ChildBg]                = ImVec4(0.8, 0.24, 0, 0.10)
        colors[clr.FrameBgHovered]         = ImVec4(0.65, 0.32, 0.00, 1.00)
        colors[clr.FrameBgActive]          = ImVec4(0.73, 0.36, 0.00, 1.00)
        colors[clr.TitleBg]                = ImVec4(0.15, 0.11, 0.09, 1.00)
        colors[clr.TitleBgActive]          = ImVec4(0.73, 0.36, 0.00, 1.00)
        colors[clr.TitleBgCollapsed]       = ImVec4(0.15, 0.11, 0.09, 0.51)
        colors[clr.MenuBarBg]              = ImVec4(0.62, 0.31, 0.00, 1.00)
        colors[clr.CheckMark]              = ImVec4(1.00, 0.49, 0.00, 1.00)
        colors[clr.SliderGrab]             = ImVec4(0.84, 0.41, 0.00, 1.00)
        colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.49, 0.00, 1.00)
        colors[clr.Button]                 = ImVec4(0.73, 0.36, 0.00, 0.40)
        colors[clr.ButtonHovered]          = ImVec4(0.73, 0.36, 0.00, 1.00)
        colors[clr.ButtonActive]           = ImVec4(1.00, 0.50, 0.00, 1.00)
        colors[clr.Header]                 = ImVec4(0.49, 0.24, 0.00, 1.00)
        colors[clr.HeaderHovered]          = ImVec4(0.70, 0.35, 0.01, 1.00)
        colors[clr.HeaderActive]           = ImVec4(1.00, 0.49, 0.00, 1.00)
        colors[clr.SeparatorHovered]       = ImVec4(0.49, 0.24, 0.00, 0.78)
        colors[clr.SeparatorActive]        = ImVec4(0.49, 0.24, 0.00, 1.00)
        colors[clr.ResizeGrip]             = ImVec4(0.48, 0.23, 0.00, 1.00)
        colors[clr.ResizeGripHovered]      = ImVec4(0.78, 0.38, 0.00, 1.00)
        colors[clr.ResizeGripActive]       = ImVec4(1.00, 0.49, 0.00, 1.00)
        colors[clr.PlotLines]              = ImVec4(0.83, 0.41, 0.00, 1.00)
        colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.99, 0.00, 1.00)
        colors[clr.PlotHistogram]          = ImVec4(0.93, 0.46, 0.00, 1.00)
        colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.00)
        colors[clr.ScrollbarBg]            = ImVec4(0.00, 0.00, 0.00, 0.53)
        colors[clr.ScrollbarGrab]          = ImVec4(0.33, 0.33, 0.33, 1.00)
        colors[clr.ScrollbarGrabHovered]   = ImVec4(0.39, 0.39, 0.39, 1.00)
        colors[clr.ScrollbarGrabActive]    = ImVec4(0.48, 0.48, 0.48, 1.00)
		colors[clr.ModalWindowDimBg]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
    elseif theme == 14 then
        ---
    end
end
----------------------------------------------------- [end script] ----------------------------------------------------------
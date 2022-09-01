script_author('RIVERYA4LIFE.')
require 'lib.moonloader'

-- ������������ Libs
local samp = require 'lib.samp.events'
local ev = require 'samp.events'
local mem = require 'memory'
local vkeys = require 'vkeys'
local commands = {'clear', 'threads', 'chatcmds'}

-- stats
local currentmoney = 0
local nowmymoney = 0

-- info
local author = 'RIVERYA4LIFE.'
local tiktok = 'tiktok.com/@riverya4life'
local vk = 'vk.com/riverya4life'

-- ��� ������� �������� �����
local active = nil
local pool = {}

-- Message if the description does not exist:
no_description_text = "* �������� ����������� *"

function ev.onCreate3DText(id, col, pos, dist, wall, PID, VID, text)
	if PID ~= 65535 and col == -858993409 and pos.z == -1 then
		pool[PID] = {id = id, col = col, pos = pos, dist = dist, wall = wall, PID = PID, VID = VID, text = text }
		return false
	end
end

function ev.onRemove3DTextLabel(id)
	for i, info in ipairs(pool) do
		if info.id == id then
			table.remove(pool, i)
		end
	end
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end
    while sampGetGamestate() ~= 3 do return true end

	sampAddChatMessage('{FFFFFF}������ ������ {42B166}'..author..' {FFFFFF}| {74adfc}'..vk..' {FFFFFF}I{74adfc} '..tiktok..'', -1)
	sampAddChatMessage('{42B166}[��������� :)]{ffffff} ���� �������: {dc4747}/riverya{FFFFFF}', -1)

  _, myid = sampGetPlayerIdByCharHandle(playerPed)
  mynick = sampGetPlayerNickname(myid) -- ��� ��� ���
  -- nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))

  -- ��� ������� �������� �����
  local duration = 0.3
  local max_alpha = 255
  local start = os.clock()
  local finish = nil

-- ���� ������
  mem.setint8(0xB7CEE4, 1) -- ����������� ���
  mem.fill(0x58DD1B, 0x90, 2, true) -- ����� �� ������
  mem.setuint8(0x588550, 0xEB, true) -- disable arrow
  mem.setuint32(0x58A4FE + 0x1, 0x0, true) -- disable green rect
  mem.setuint32(0x586A71 + 0x1, 0x0, true) -- disable height indicator
  mem.setuint8(0x58A5D2 + 0x1, 0x0, true)
  mem.setuint32(0x58A73B + 0x1, 0x0, true) -- ������ ������� ����� ��� ��������
  mem.write(sampGetBase() + 383732, -1869574000, 4, true) -- ���� ������� � (���. �)


  for i = 1, #commands do
    runSampfuncsConsoleCommand(commands[i])
end

-- ���� ������������������ ������
  sampRegisterChatCommand("riverya", riverya)
  sampRegisterChatCommand("riveryahelp", riveryahelp)
  sampRegisterChatCommand("kosdmitop", riveryatop)
  sampRegisterChatCommand("riveryalox", riveryatop)
  sampRegisterChatCommand("riveryaloh", riveryatop)

  sampRegisterChatCommand('pivko', cmd_pivko) -- ������
  sampRegisterChatCommand('givepivo', cmd_givepivo) -- ������ �2
  sampRegisterChatCommand('takebich', cmd_takebich) -- �� ������ � �����
  sampRegisterChatCommand('mystonks', cmd_getmystonks)

  sampRegisterChatCommand("fps", function() -- ���������� ��� � �������� � main
	runSampfuncsConsoleCommand('fps')
end)
sampRegisterChatCommand("riveryatop", function()
	sampAddChatMessage('{42B166}[�������] {ffffff}�������, ��� �������!', -1)
end)

	while true do 
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
		wait(0)
	end
end

function riverya()
    sampShowDialog(13337,'{dc4747}[Info]','{ffffff}������������, {dc4747}'..mynick..'!{ffffff}\n\n{ffffff}������ ������ �, {42B166}'..author..' (������).\n\n{ffffff}� ������ �� ���������� � ������� ��-�� ����� ����.{ffffff}\n�� ��� �� �������� ���� ���������� � ������.\n��������� �� ��� ��� ���:\n{dc4747}� '..tiktok..'.\n\n\n{dc4747}*{ffffff}���� �� �� ��� ���������, �� ����� ���������, � �� ��� ������ ����� ���� ����({dc4747}*{ffffff}\n\n{dc4747}��������� �������:{ffffff}\n {42B166}�{ffffff} /riverya - �������� ����\n {42B166}�{ffffff} /riveryatop - ���� �������\n {dc4747}� /riveryahelp - *��� �� �������� �������*{ffffff}','{42B166}���������','{dc4747}���',0)
    lua_thread.create(hui)
end

function riveryahelp()
    sampShowDialog(13339,'{dc4747}[Help]','{ffffff}������ ��� ���, � ���� ������� ��, ��� ���� � �������, ������� � ����� ��� ������.\n{42B166}��� ���� ���������:{ffffff}\n\n   �   ������ �� �� ������� ������� � ������� ����� � ������� ���������� {dc4747}Alt + Enter{ffffff} �� ��������� ������ ����.\n   �   ���� ������ ����� ��� �������, �� ����� ������� ������� {dc4747}"Wrong Server Password"{ffffff} �� ��� ���, ���� � ������� �� ������ ������.\n   �   ��� ����� � ���� � ������� {dc4747}SampFuncs{ffffff} ����� ��������� ������� {dc4747}clear, threads � chatcmds{ffffff} �������������.\n   �   {dc4747}�����{ffffff} ������ ������������ �� ������ ������.\n   �   ������ ����� ������� ������� {dc4747}FPS{ffffff} ���������� ��������� � ��� ������� {dc4747}/fps{ffffff} (������ � ������� {dc4747}SampFuncs{ffffff} �������� �� �����������)\n   �   ����� ����������� ������ ����� ��� ����� (�������� ������ ������� � {dc4747}hud.txd{ffffff}, ������� ���������� �� ������� ������)\n   �   ��������� ������� {dc4747}/mystonks{ffffff} ��� ��� ��������� ������ ������ �� ������� ������.\n   �   ��������� ������� {dc4747}/pivko{ffffff} ��� ��������� � ��������� �������� ��� ��� RP ��������, ��� �� ���� ������� {dc4747}/givepivo ID{ffffff} ����� �������� (� ��� � ����� ��������� �����)\n   �   ��������� ������� {dc4747}/takebich{ffffff} ����� ����� ���� �������� � ������� �� ������ (���� ����� �����)\n   �   ������ {dc4747}��������{ffffff} �� ����� �����, ���� �� �� ���������� �� ������ (��� ������� ��� ����� FPS UP)\n   �   ������ ������� {dc4747}T (���. �){ffffff} �� ��������� ��� (�� ��������� ������ ������� {dc4747}F6{ffffff})\n   �   ��� ����� ������ {dc4747}/riveryaloh{ffffff} ��� {dc4747}/riveryalox{ffffff} ��� ��� ������� {dc4747}<3{ffffff}','{42B166}���������','',0)
    lua_thread.create(negrtop)
end

function hui()
	while sampIsDialogActive() do
	wait(0)
	local __, button, list, input = sampHasDialogRespond(13337)
	if __ and button == 1 then
        sampAddChatMessage('{42B166}[#riverya4life] {ffffff}����� ������ ������� ����.', -1)
	elseif __ and button == 0 then
		sampShowDialog(13338,'{dc4747}[�������]','{ffffff}����� �� ���� �� {dc4747}Arizona Role Play Scottdale.{ffffff}\n\n������������� �� ��� ��� {42B166}Tape_Riverya{ffffff} � ������� ����� {42B166}300.000${FFFFFF} �� 5 ������.\n�� ������� �� 6 ������ ����� �������� {42B166}#riverya4life{FFFFFF}\n�� ������� �������� {42B166}100.000${FFFFFF} � �� ���� ��� ����� {42B166}������� ��������!{FFFFFF}\n\n\n�� � ��� ����� �������� ���� {dc4747}<3{FFFFFF}','{42B166}���������','',0)
		end
	end
end

function negrtop()
	while sampIsDialogActive() do
	wait(0)
	local __, button, list, input = sampHasDialogRespond(13339)
	if __ and button == 0 then
		sampAddChatMessage('{42B166}[#riverya4life] {ffffff}��������� ����.', -1)
		end
	end
end

function riveryatop()
	readMemory(0, 1)
end

function onReceivePacket(id) -- ����� ������� wrong server password �� ��� ���, ���� ������ �� ���������
	if id == 37 then
		sampSetGamestate(1)
	end
end

function ev.onSendPlayerSync(data) -- ����� ���
	if data.keysData == 40 or data.keysData == 42 then sendOnfootSync(); data.keysData = 32 end
end

function sendOnfootSync()
	local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
	local data = allocateMemory(68)
	sampStorePlayerOnfootData(myId, data)
	setStructElement(data, 4, 1, 0, false)
	sampSendOnfootData(data)
	freeMemory(data)
end -- ��� ����� ���

function onWindowMessage(msg, wparam, lparam) -- ���������� ������ alt + tab 
	if msg == 261 and wparam == 13 then consumeWindowMessage(true, true) end
end

function cmd_getmystonks()
	local _, myid = sampGetPlayerIdByCharHandle(playerPed)
	mynick = sampGetPlayerNickname(myid)
	
	local result = 0
	nowmymoney = getPlayerMoney(mynick)
	result = nowmymoney - currentmoney
	
	sampAddChatMessage('{dc4747}[#riverya4life]{ffffff} �� ������ �� ���������� '..'{5EEE0C}'.. result ..'${FF0000}', -1)
end

function cmd_givepivo(arg1)
	local targetnick = sampGetPlayerNickname(arg1)
	lua_thread.create(function()
		sampSendChat('/me ������ �� ����� ����.')
		wait(500)
		runSampfuncsConsoleCommand('0afd:22')
		wait(1500)
		sampSendChat('/me ������� ���� '..targetnick)
		wait(1500)
		sampSendChat('�������� ���!')
	end)
end

function cmd_pivko()
	lua_thread.create(function()
		sampSendChat('/me ������ �� ����� ����, ������ �������, ����� ����.')
		wait(500)
		runSampfuncsConsoleCommand('0afd:22')
	end)
end

function cmd_takebich()
	lua_thread.create(function()
		sampSendChat("/me ������ � ������� ����� �������, �������.")
		wait(500)
		runSampfuncsConsoleCommand('0afd:21')
	end)
end

function join_argb(a, r, g, b)
    local argb = b
    argb = bit.bor(argb, bit.lshift(g, 8))
    argb = bit.bor(argb, bit.lshift(r, 16))
    argb = bit.bor(argb, bit.lshift(a, 24))
    return argb
end

function saturate(f) 
	return f < 0 and 0 or (f > 255 and 255 or f) 
end

function setNextRequestTime(time)
    local samp = getModuleHandle("samp.dll")
    mem.setuint32(samp + 0x3DBAE, time, true)
end

function ev.onSetVehicleVelocity(turn, velocity)
    if velocity.x ~= velocity.x or velocity.y ~= velocity.y or velocity.z ~= velocity.z then
        sampAddChatMessage("[Warning] ignoring invalid SetVehicleVelocity", 0x00FF00)
        return false
    end
end

function ev.onServerMessage(color, text)
	if text:find("%[������%] {FFFFFF}�������� ������ � ���������� ��� PC ��������!") then
		return false
	end
end
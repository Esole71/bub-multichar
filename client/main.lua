local config = require 'config.client'
local defaultSpawn = require 'config.shared'.defaultSpawn
local ESX = exports['es_extended']:getSharedObject()

local previewCam = nil
local randomLocation = nil -- <-- set it nil first, no random yet

local randomPeds = {
    { 
        model = `mp_m_freemode_01`,
        appearance = {
            model = `mp_m_freemode_01`,
            components = {
                [0] = { drawable = 0, texture = 0 }, -- Face
                [1] = { drawable = 0, texture = 0 }, -- Mask
                [2] = { drawable = 0, texture = 0 }, -- Hair
                [3] = { drawable = 0, texture = 0 }, -- Torso
                [4] = { drawable = 0, texture = 0 }, -- Legs
                [5] = { drawable = 0, texture = 0 }, -- Bags
                [6] = { drawable = 0, texture = 0 }, -- Shoes
                [7] = { drawable = 0, texture = 0 }, -- Scarf
                [8] = { drawable = 0, texture = 0 }, -- Shirt
                [9] = { drawable = 0, texture = 0 }, -- Body Armor
                [10] = { drawable = 0, texture = 0 }, -- Decals
                [11] = { drawable = 0, texture = 0 }  -- Jacket
            }
        }
    },
    { 
        model = `mp_f_freemode_01`,
        appearance = {
            model = `mp_f_freemode_01`,
            components = {
                [0] = { drawable = 0, texture = 0 }, -- Face
                [1] = { drawable = 0, texture = 0 }, -- Mask
                [2] = { drawable = 0, texture = 0 }, -- Hair
                [3] = { drawable = 0, texture = 0 }, -- Torso
                [4] = { drawable = 0, texture = 0 }, -- Legs
                [5] = { drawable = 0, texture = 0 }, -- Bags
                [6] = { drawable = 0, texture = 0 }, -- Shoes
                [7] = { drawable = 0, texture = 0 }, -- Scarf
                [8] = { drawable = 0, texture = 0 }, -- Shirt
                [9] = { drawable = 0, texture = 0 }, -- Body Armor
                [10] = { drawable = 0, texture = 0 }, -- Decals
                [11] = { drawable = 0, texture = 0 }  -- Jacket
            }
        }
    }
}

local function setupPreviewCam()
    DoScreenFadeIn(1000)
    SetTimecycleModifier('hud_def_blur')
    SetTimecycleModifierStrength(1.0)
    FreezeEntityPosition(cache.ped, false)
    previewCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', randomLocation.camCoords.x, randomLocation.camCoords.y, randomLocation.camCoords.z, -6.0, 0.0, randomLocation.camCoords.w, 40.0, false, 0)
    SetCamActive(previewCam, true)
    SetCamUseShallowDofMode(previewCam, true)
    SetCamNearDof(previewCam, 0.4)
    SetCamFarDof(previewCam, 1.8)
    SetCamDofStrength(previewCam, 0.7)
    RenderScriptCams(true, false, 1, true, true)
    CreateThread(function()
        while DoesCamExist(previewCam) do
            SetUseHiDof()
            Wait(0)
        end
    end)
end

local function destroyPreviewCam()
    if not previewCam then return end
    SetTimecycleModifier('default')
    SetCamActive(previewCam, false)
    DestroyCam(previewCam, true)
    RenderScriptCams(false, false, 1, true, true)
    FreezeEntityPosition(cache.ped, false)
end

local function randomPed(gender)
    local ped = gender == 'Male' and randomPeds[1] or randomPeds[2]
    print('Ped selected based on gender:', gender, 'Model:', ped.model)
    
    lib.requestModel(ped.model, config.loadingModelsTimeout)
    SetPlayerModel(cache.playerId, ped.model)
    print('SetPlayerModel called with:', ped.model)
    
    -- Set default skin using ESX skinchanger
    TriggerEvent('skinchanger:loadDefaultModel', gender == 'Male')
    
    -- Open the skin menu
    TriggerEvent('esx_skin:openSaveableMenu', function(data, menu)
        menu.close()
        -- Save the skin
        TriggerEvent('esx_skin:save', function(success)
            if success then
                lib.notify({
                    title = 'Success',
                    description = 'Appearance saved successfully',
                    type = 'success'
                })
            end
        end)
    end)
    
    SetModelAsNoLongerNeeded(ped.model)
end

local function previewPed(identifier)
    if not identifier then
        -- Get the character's gender from the metadata
        local characters = lib.callback.await('bub-multichar:server:getCharacters', false)
        local selectedChar = nil
        for _, char in ipairs(characters) do
            if char.citizenid == identifier then
                selectedChar = char
                break
            end
        end
        
        if selectedChar then
            local gender = nil
            for _, meta in ipairs(selectedChar.metadata) do
                if meta.key == 'gender' then
                    gender = meta.value
                    break
                end
            end
            randomPed(gender)
        else
            randomPed('Male') -- Default to male if we can't find the character
        end
        return
    end

    local clothing = lib.callback.await('bub-multichar:server:getPreviewPedData', false, identifier)
    if clothing then
        local appearance = json.decode(clothing)
        if appearance then
            exports['illenium-appearance']:setPedAppearance(PlayerPedId(), appearance)
        else
            -- Get the character's gender from the metadata
            local characters = lib.callback.await('bub-multichar:server:getCharacters', false)
            local selectedChar = nil
            for _, char in ipairs(characters) do
                if char.citizenid == identifier then
                    selectedChar = char
                    break
                end
            end
            
            if selectedChar then
                local gender = nil
                for _, meta in ipairs(selectedChar.metadata) do
                    if meta.key == 'gender' then
                        gender = meta.value
                        break
                    end
                end
                randomPed(gender)
            else
                randomPed('Male') -- Default to male if we can't find the character
            end
        end
    else
        -- Get the character's gender from the metadata
        local characters = lib.callback.await('bub-multichar:server:getCharacters', false)
        local selectedChar = nil
        for _, char in ipairs(characters) do
            if char.citizenid == identifier then
                selectedChar = char
                break
            end
        end
        
        if selectedChar then
            local gender = nil
            for _, meta in ipairs(selectedChar.metadata) do
                if meta.key == 'gender' then
                    gender = meta.value
                    break
                end
            end
            randomPed(gender)
        else
            randomPed('Male') -- Default to male if we can't find the character
        end
    end
end

local function capString(str)
    return str:gsub("(%w)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

local function spawnDefault()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    destroyPreviewCam()

    pcall(function() exports.spawnmanager:spawnPlayer({
        x = defaultSpawn.x,
        y = defaultSpawn.y,
        z = defaultSpawn.z,
        heading = defaultSpawn.w
    }) end)

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    TriggerServerEvent('esx:onPlayerSpawn')
    TriggerEvent('esx:onPlayerSpawn')

    DoScreenFadeIn(500)
end

local function spawnLastLocation()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    destroyPreviewCam()

    local xPlayer = ESX.GetPlayerData()
    
    -- First ensure player has control before spawning
    SetPlayerControl(cache.playerId, true)
    SetEntityVisible(cache.ped, true)
    FreezeEntityPosition(cache.ped, false)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    DisplayRadar(true)
    DisplayHud(true)
    
    pcall(function() exports.spawnmanager:spawnPlayer({
        x = xPlayer.coords.x,
        y = xPlayer.coords.y,
        z = xPlayer.coords.z,
        heading = xPlayer.coords.w
    }) end)

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    TriggerServerEvent('esx:onPlayerSpawn')
    TriggerEvent('esx:onPlayerSpawn')

    -- Double check control after spawning
    SetPlayerControl(cache.playerId, true)
    SetEntityVisible(cache.ped, true)
    FreezeEntityPosition(cache.ped, false)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    DisplayRadar(true)
    DisplayHud(true)

    DoScreenFadeIn(500)
end

---@param identifier integer
---@return boolean
local function createCharacter(identifier, character)
    print('DEBUG: createCharacter called with gender:', character.gender)
    
    -- Set the model based on gender before previewing
    local model = character.gender == 'Male' and `mp_m_freemode_01` or `mp_f_freemode_01`
    print('DEBUG: Setting model based on gender:', character.gender, 'Model hash:', model)
    lib.requestModel(model, config.loadingModelsTimeout)
    SetPlayerModel(cache.playerId, model)
    SetModelAsNoLongerNeeded(model)
    
    previewPed()

    DoScreenFadeOut(150)

    print('DEBUG: Sending character data to server:', json.encode({
        firstname = capString(character.firstName),
        lastname = capString(character.lastName),
        nationality = capString(character.nationality),
        gender = character.gender == 'Male' and 0 or 1,
        birthdate = character.birthdate,
        height = tonumber(character.height) or config.ui.height.default,
        identifier = identifier
    }))

    local newData, errorMsg = lib.callback.await('bub-multichar:server:createCharacter', false, {
        firstname = capString(character.firstName),
        lastname = capString(character.lastName),
        nationality = capString(character.nationality),
        gender = character.gender == 'Male' and 0 or 1,
        birthdate = character.birthdate,
        height = tonumber(character.height) or config.ui.height.default,
        identifier = identifier
    })
    
    if not newData then
        -- Show error message if character creation failed
        if errorMsg then
            lib.notify({
                title = 'Character Creation Failed',
                description = errorMsg,
                type = 'error'
            })
        else
            lib.notify({
                title = 'Character Creation Failed',
                description = 'Failed to create character. Please try again.',
                type = 'error'
            })
        end
        
        -- Return to character selection UI with refreshed data
        lib.callback('bub-multichar:server:getCharacters', false, function(chars, allowedAmount)
            SendNUIMessage({
                action = "showMultiChar",
                data = {
                    characters = chars,
                    allowedCharacters = allowedAmount
                }
            })
            -- Reset selection state
            SetNuiFocus(true, true)
        end)
        return false
    end

    print('DEBUG: Character created successfully, newData:', json.encode(newData))

    -- Ensure proper cleanup before spawning
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    DisplayRadar(true)
    DisplayHud(true)
    SetPlayerControl(cache.playerId, true, 0)
    SetEntityVisible(cache.ped, true)
    FreezeEntityPosition(cache.ped, false)

    spawnDefault()
    destroyPreviewCam()
    return true
end

local function chooseCharacter()
    if config.characters.locations and #config.characters.locations > 0 then
        randomLocation = config.characters.locations[math.random(1, #config.characters.locations)]
    else
        randomLocation = {
            pedCoords = vec4(0, 0, 72, 0),
            camCoords = vec4(0, 0, 72, 0)
        }
    end

    SetFollowPedCamViewMode(2)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() and cache.ped ~= PlayerPedId() do Wait(0) end

    local ped = PlayerPedId()
    SetEntityCoords(ped, randomLocation.pedCoords.x, randomLocation.pedCoords.y, randomLocation.pedCoords.z, false, false, false, false)
    SetEntityHeading(ped, randomLocation.pedCoords.w)
    SetEntityVisible(ped, true)
    FreezeEntityPosition(ped, true)
    print('Ped moved to preview location:', randomLocation.pedCoords, 'Model:', GetEntityModel(ped))

    setupPreviewCam()
    DoScreenFadeIn(500)
end


-- Threads
CreateThread(function()
    while true do
        if NetworkIsSessionStarted() then
            TriggerEvent('bub-multichar:client:chooseChar')
            return
        end
        Wait(100)
    end
end)

CreateThread(function()
    while not ESX do Wait(100) end
    while not ESX.PlayerLoaded do Wait(100) end
    chooseCharacter()
end)

-- NUI Callbacks
RegisterNetEvent('bub-multichar:client:chooseChar', function()
    SetNuiFocus(false, false)
    DoScreenFadeOut(10)
    Wait(1000)
    chooseCharacter()
    lib.callback('bub-multichar:server:getCharacters', false, function(chars, allowedAmount)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "showMultiChar",
            data = {
                characters = chars,
                allowedCharacters = allowedAmount,
                uiConfig = config.ui -- Send UI configuration to web UI
            }
        })
    end)
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    local identifier = data.identifier
    
    -- Save current appearance before previewing new character
    local currentAppearance = exports['illenium-appearance']:getPedAppearance(PlayerPedId())
    if currentAppearance then
        local xPlayer = ESX.GetPlayerData()
        if xPlayer and xPlayer.identifier then
            lib.callback('bub-multichar:server:saveAppearance', false, function(success)
                if success then
                    -- After saving, preview the selected character
                    previewPed(identifier)
                end
            end, xPlayer.identifier, currentAppearance)
        else
            previewPed(identifier)
        end
    else
        previewPed(identifier)
    end
    
    cb('ok')
end)

RegisterNUICallback('playCharacter', function(data, cb)
    local identifier = data.citizenid
    
    -- First ensure NUI focus is completely released
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    -- Ensure player has control before proceeding
    SetPlayerControl(cache.playerId, true)
    SetEntityVisible(cache.ped, true)
    FreezeEntityPosition(cache.ped, false)
    DisplayRadar(true)
    DisplayHud(true)
    
    -- First get and set the appearance data
    local clothing = lib.callback.await('bub-multichar:server:getPreviewPedData', false, identifier)
    
    lib.callback('bub-multichar:server:loadCharacter', false, function(charData)
        if clothing then
            local appearance = json.decode(clothing)
            if appearance then
                -- Set the model based on gender first
                local model = charData.gender == 0 and `mp_m_freemode_01` or `mp_f_freemode_01`
                lib.requestModel(model, config.loadingModelsTimeout)
                SetPlayerModel(cache.playerId, model)
                SetModelAsNoLongerNeeded(model)
                
                -- Then apply the saved appearance
                exports['illenium-appearance']:setPedAppearance(PlayerPedId(), appearance)
            end
        end
        
        -- Double check NUI focus and player control before spawning
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SetPlayerControl(cache.playerId, true)
        SetEntityVisible(cache.ped, true)
        FreezeEntityPosition(cache.ped, false)
        DisplayRadar(true)
        DisplayHud(true)
        
        spawnLastLocation()
    end, identifier)
    
    cb('ok')
end)

RegisterNUICallback('createNewCharacter', function(data, cb)
    local identifier = data.cid or data.identifier
    local character = data.character or data
    createCharacter(identifier, character)
    cb('ok')
end)

RegisterNUICallback('removeCharacter', function(data, cb)
    local identifier = data.identifier
    local success = lib.callback.await('bub-multichar:server:deleteCharacter', false, identifier)
    
    if success then
        -- Return to character selection UI with refreshed data
        chooseCharacter() -- Reset the character preview state
        
        lib.callback('bub-multichar:server:getCharacters', false, function(chars, allowedAmount)
            SendNUIMessage({
                action = "showMultiChar",
                data = {
                    characters = chars,
                    allowedCharacters = allowedAmount
                }
            })
            -- Reset selection state and ensure screen is visible
            SetNuiFocus(true, true)
            DoScreenFadeIn(500)
        end)
    end
    
    cb('ok')
end)

RegisterNUICallback('closeNUI', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    local identifier = data.citizenid or data.identifier
    if not identifier then
        cb({ ok = false, error = "No identifier provided" })
        return
    end
    
    local success = lib.callback.await('bub-multichar:server:deleteCharacter', false, identifier)
    
    if success then
        -- Return to character selection UI with refreshed data
        chooseCharacter() -- Reset the character preview state
        
        lib.callback('bub-multichar:server:getCharacters', false, function(chars, allowedAmount)
            SendNUIMessage({
                action = "showMultiChar",
                data = {
                    characters = chars,
                    allowedCharacters = allowedAmount
                }
            })
            -- Reset selection state and ensure screen is visible
            SetNuiFocus(true, true)
            DoScreenFadeIn(500)
        end)
    end
    
    cb({ ok = true })
end)

RegisterNUICallback('createCharacter', function(data, cb)
    local identifier = data.cid or data.identifier
    local character = data.character or data
    
    -- Remove NUI focus before creating character
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    createCharacter(identifier, character)
    cb('ok')
end)

RegisterNUICallback('getNationalities', function(_, cb)
    local nationalities = lib.callback.await('bub-multichar:server:getNationalities', false)
    cb(nationalities)
end)

RegisterNUICallback('getUIConfig', function(_, cb)
    cb(config.ui)
end)

-- ESX Events
RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
    ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)

RegisterNetEvent('esx:setJob2', function(job2)
    ESX.PlayerData.job2 = job2
end)

RegisterNetEvent('esx:setGroup', function(group)
    ESX.PlayerData.group = group
end)

RegisterNetEvent('esx:setAccountMoney', function(account)
    ESX.PlayerData.accounts[account.name] = account
end)

RegisterNetEvent('esx:addInventoryItem', function(item, count, showNotification)
    ESX.PlayerData.inventory[item.name] = item
end)

RegisterNetEvent('esx:removeInventoryItem', function(item, count, showNotification)
    ESX.PlayerData.inventory[item.name] = item
end)

RegisterNetEvent('esx:setAccountMoney', function(account)
    ESX.PlayerData.accounts[account.name] = account
end)

RegisterNetEvent('bub-multichar:client:spawnNewCharacter', function(coords, genderValue)
    -- Teleport player to the specified coordinates
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
    SetEntityHeading(PlayerPedId(), coords.w)
    
    -- Wait a short moment to ensure the player is properly teleported
    Wait(1000)
    
    -- Use the provided gender value
    print('DEBUG: Spawning new character with gender value:', genderValue)
    
    -- Load model based on gender value (0 for male, 1 for female)
    local model = genderValue == 0 and `mp_m_freemode_01` or `mp_f_freemode_01`
    print('DEBUG: Loading model:', model)
    
    -- Request and load the model
    lib.requestModel(model, config.loadingModelsTimeout)
    SetPlayerModel(cache.playerId, model)
    SetModelAsNoLongerNeeded(model)
    
    -- Ensure ped is visible and has control
    SetEntityVisible(PlayerPedId(), true)
    SetPlayerControl(cache.playerId, true)
    FreezeEntityPosition(PlayerPedId(), false)
    
    -- Set NUI focus before opening appearance menu
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    
    -- Set a default appearance based on gender
    local defaultAppearance = {
        model = model,
        components = {
            [0] = { drawable = 0, texture = 0 }, -- Face
            [1] = { drawable = 0, texture = 0 }, -- Mask
            [2] = { drawable = 0, texture = 0 }, -- Hair
            [3] = { drawable = 0, texture = 0 }, -- Torso
            [4] = { drawable = 0, texture = 0 }, -- Legs
            [5] = { drawable = 0, texture = 0 }, -- Bags
            [6] = { drawable = 0, texture = 0 }, -- Shoes
            [7] = { drawable = 0, texture = 0 }, -- Scarf
            [8] = { drawable = 0, texture = 0 }, -- Shirt
            [9] = { drawable = 0, texture = 0 }, -- Body Armor
            [10] = { drawable = 0, texture = 0 }, -- Decals
            [11] = { drawable = 0, texture = 0 }  -- Jacket
        }
    }
    
    -- Apply the default appearance
    exports['illenium-appearance']:setPedAppearance(PlayerPedId(), defaultAppearance)
    
    -- Wait a moment for the appearance to be applied
    Wait(1000)

    
    
    -- Open the customization menu
    exports['illenium-appearance']:startPlayerCustomization(function(appearance)
        if appearance then
            -- Save the appearance when customization is complete
            local xPlayer = ESX.GetPlayerData()
            if xPlayer and xPlayer.identifier then
                lib.callback('bub-multichar:server:saveAppearance', false, function(success)
                    if success then
                        lib.notify({
                            title = 'Success',
                            description = 'Appearance saved successfully',
                            type = 'success'
                        })
                    end
                end, xPlayer.identifier, appearance)
            end
        end
        
        -- Clean up after customization
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        DisplayRadar(true)
        DisplayHud(true)
    end)
end)

-- Add event handlers for appearance saving
RegisterNetEvent('esx_skin:playerRegistered', function()
    -- Save the current appearance
    local currentAppearance = exports['illenium-appearance']:getPedAppearance(PlayerPedId())
    if currentAppearance then
        local xPlayer = ESX.GetPlayerData()
        if xPlayer and xPlayer.identifier then
            lib.callback('bub-multichar:server:saveAppearance', false, function(success)
                if success then
                    lib.notify({
                        title = 'Success',
                        description = 'Appearance saved successfully',
                        type = 'success'
                    })
                end
            end, xPlayer.identifier, currentAppearance)
        end
    end
    
    -- Ensure proper cleanup after skin menu
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    DisplayRadar(true)
    DisplayHud(true)
    
    -- Ensure player has full control
    SetPlayerControl(cache.playerId, true, 0)
    SetEntityVisible(cache.ped, true)
    FreezeEntityPosition(cache.ped, false)
end)

-- Add event handler for when skin is changed
RegisterNetEvent('skinchanger:modelLoaded', function()
    -- Save the current appearance
    local currentAppearance = exports['illenium-appearance']:getPedAppearance(PlayerPedId())
    if currentAppearance then
        local xPlayer = ESX.GetPlayerData()
        if xPlayer and xPlayer.identifier then
            lib.callback('bub-multichar:server:saveAppearance', false, function(success)
                if success then
                    lib.notify({
                        title = 'Success',
                        description = 'Appearance saved successfully',
                        type = 'success'
                    })
                end
            end, xPlayer.identifier, currentAppearance)
        end
    end
end)

-- Add event handler for when skin is saved
RegisterNetEvent('esx_skin:setLastSkin', function(skin)
    -- Save the current appearance
    local currentAppearance = exports['illenium-appearance']:getPedAppearance(PlayerPedId())
    if currentAppearance then
        local xPlayer = ESX.GetPlayerData()
        if xPlayer and xPlayer.identifier then
            lib.callback('bub-multichar:server:saveAppearance', false, function(success)
                if success then
                    lib.notify({
                        title = 'Success',
                        description = 'Appearance saved successfully',
                        type = 'success'
                    })
                end
            end, xPlayer.identifier, currentAppearance)
        end
    end
end)

-- Add event handler for when appearance is modified in preview
RegisterNetEvent('illenium-appearance:client:appearanceChanged', function()
    local currentAppearance = exports['illenium-appearance']:getPedAppearance(PlayerPedId())
    if currentAppearance then
        local xPlayer = ESX.GetPlayerData()
        if xPlayer and xPlayer.identifier then
            lib.callback('bub-multichar:server:saveAppearance', false, function(success)
                if success then
                    lib.notify({
                        title = 'Success',
                        description = 'Appearance saved successfully',
                        type = 'success'
                    })
                end
            end, xPlayer.identifier, currentAppearance)
        end
    end
end)
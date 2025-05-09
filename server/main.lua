local config = require 'config.server'
local nationalities = require 'config.nationalities'
local ESX = exports['es_extended']:getSharedObject()

local starterItems = { -- Character starting items
  { name = 'phone', amount = 1 },
  { name = 'id_card', amount = 1 },
  { name = 'driver_license', amount = 1 }
}

local function fetchPlayerSkin(identifier)
  local result = MySQL.query.await('SELECT skin FROM users WHERE identifier = ?', {identifier})
  if result and result[1] and result[1].skin then
    return result[1].skin
  end
  return nil
end

local function fetchAllPlayerEntities(identifier)
  local chars = {}
  local result = MySQL.query.await('SELECT * FROM users WHERE identifier = ?', {identifier})

  for i = 1, #result do
    local charinfo = result[i].charinfo and json.decode(result[i].charinfo) or {}

    if charinfo.firstname and charinfo.lastname then
      chars[#chars+1] = {
        citizenid = result[i].id, -- Use the database row ID as the unique identifier
        name = ("%s %s"):format(charinfo.firstname, charinfo.lastname),
        metadata = {
          { key = "job", value = ("%s (%s)"):format(result[i].job, result[i].job_grade) },
          { key = "nationality", value = charinfo.nationality or "Unknown" },
          { key = "bank", value = tostring(result[i].bank or 0) },
          { key = "cash", value = tostring(result[i].money or 0) },
          { key = "birthdate", value = charinfo.birthdate or "Unknown" },
          { key = "gender", value = (charinfo.gender == 0 and 'Male' or 'Female') },
          { key = "height", value = tostring(charinfo.height or 170) .. " cm" },
        },
        cid = i -- Simply use the index for cid
      }
    else
      print(('[bub-multichar] Skipping user with invalid charinfo (identifier: %s)'):format(result[i].identifier))
    end
  end

  return chars
end

local function giveStarterItems(source)
  if GetResourceState('esx_inventory') == 'missing' then return end
  for i = 1, #starterItems do
    local item = starterItems[i]
    exports.esx_inventory:AddItem(source, item.name, item.amount)
  end
end

local function getAllowedAmountOfCharacters(identifier)
  return config.playersNumberOfCharacters[identifier] or config.defaultNumberOfCharacters or 5
end

local function setPlayerIdentity(source, identifier, charinfo)
  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer then return end

  xPlayer.set('firstName', charinfo.firstname)
  xPlayer.set('lastName', charinfo.lastname)
  xPlayer.set('dateOfBirth', charinfo.birthdate)
  xPlayer.set('sex', charinfo.gender == 0 and 'm' or 'f')
  xPlayer.set('height', charinfo.height or 180)

  TriggerClientEvent('esx:identity:setIdentity', source, {
    firstName = charinfo.firstname,
    lastName = charinfo.lastname,
    dateOfBirth = charinfo.birthdate,
    sex = charinfo.gender == 0 and 'm' or 'f',
    height = charinfo.height or 180
  })
end

lib.callback.register('bub-multichar:server:getCharacters', function(source)
  local identifier = ESX.GetIdentifier(source)
  local chars = fetchAllPlayerEntities(identifier)
  local allowedAmount = getAllowedAmountOfCharacters(identifier)
  local fivemName = GetPlayerName(source)

  -- Add fivemName to each character
  for i, char in ipairs(chars) do
    char.fivemName = fivemName
  end

  -- fill empty slots if needed
  local sortedChars = {}
  for i = 1, allowedAmount do
    sortedChars[i] = chars[i] or nil
  end

  return sortedChars, allowedAmount
end)

lib.callback.register('bub-multichar:server:getPreviewPedData', function(source, identifier)
  local skin = fetchPlayerSkin(identifier)
  if skin then
    -- If the skin is already a JSON string, return it directly
    if type(skin) == 'string' then
      return skin
    end
    -- If it's a table, convert it to JSON
    return json.encode(skin)
  end
  return nil
end)

lib.callback.register('bub-multichar:server:getNationalities', function(source)
  return nationalities.nationalities
end)

lib.callback.register('bub-multichar:server:loadCharacter', function(source, identifier)
  local result = MySQL.single.await('SELECT charinfo FROM users WHERE identifier = ?', {identifier})
  if not result then return end

  local charinfo = result.charinfo and json.decode(result.charinfo) or {}

  -- Update basic fields
  MySQL.update('UPDATE users SET firstname = ?, lastname = ?, dateofbirth = ?, sex = ?, height = ? WHERE identifier = ?', {
    charinfo.firstname,
    charinfo.lastname,
    charinfo.birthdate,
    charinfo.gender == 0 and 'm' or 'f',
    charinfo.height or 180,
    identifier
  })

  setPlayerIdentity(source, identifier, charinfo)

  local skin = fetchPlayerSkin(identifier)
  if skin then
    TriggerClientEvent('illenium-appearance:client:loadAppearance', source, json.decode(skin))
  end

  lib.print.info(('[bub-multichar] %s (Identifier: %s) loaded successfully!'):format(GetPlayerName(source), identifier))

  -- Return gender info to client
  return { gender = charinfo.gender }
end)

---@param data unknown
---@return table? newData
lib.callback.register('bub-multichar:server:createCharacter', function(source, data)
  print('DEBUG: createCharacter called', json.encode(data))
  local identifier = ESX.GetIdentifier(source)
  local char = data.character or data

  -- Validate nationality
  local isValidNationality = false
  for _, nationality in ipairs(nationalities.nationalities) do
    if nationality:lower() == (char.nationality or ""):lower() then
      isValidNationality = true
      break
    end
  end
  
  if not isValidNationality then
    return false, "Invalid nationality. Please select a valid nationality from the list."
  end

  -- Map gender string to numeric value and ensure consistent format
  local genderValue = char.gender
  if type(genderValue) == 'string' then
    genderValue = genderValue == 'Male' and 0 or 1
  end
  local sex = genderValue == 0 and 'm' or 'f'

  -- Check how many characters this identifier already has
  local charCount = MySQL.scalar.await('SELECT COUNT(*) FROM users WHERE identifier = ?', {identifier})
  if charCount >= 5 then
    return false, "Character limit reached"
  end

  -- Ensure charinfo has the correct gender format
  char.gender = genderValue

  MySQL.insert('INSERT INTO users (identifier, firstname, lastname, dateofbirth, sex, height, job, job_grade, `group`, nationality, charinfo, accounts, metadata, is_dead, status, skin, inventory, loadout, position) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
    identifier,
    char.firstName or char.firstname,
    char.lastName or char.lastname,
    char.birthdate,
    sex,
    char.height or 180,
    'unemployed',
    0,
    'user',
    char.nationality,
    json.encode(char),
    json.encode({ bank = 5000, money = 500 }),
    json.encode({}),
    0,
    json.encode({}),
    json.encode({}),
    json.encode({}),
    json.encode({}),
    json.encode({ x = 164.7351, y = -987.3799, z = 30.0919, w = 164.0576 })
  })

  giveStarterItems(source)
  setPlayerIdentity(source, identifier, char)

  -- Trigger client events for spawn and appearance menu
  TriggerClientEvent('bub-multichar:client:spawnNewCharacter', source, {
    x = 164.7351,
    y = -987.3799,
    z = 30.0919,
    w = 164.0576
  }, genderValue) -- Pass the gender value to the client

  lib.print.info(('[bub-multichar] %s has created a character'):format(GetPlayerName(source)))
  return { identifier = identifier, charinfo = char }
end)

lib.callback.register('bub-multichar:server:deleteCharacter', function(source, characterId)
  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer then return false end
  
  -- Delete the specific character using their ID
  local success = MySQL.query.await('DELETE FROM users WHERE id = ? AND identifier = ? LIMIT 1', {characterId, ESX.GetIdentifier(source)})
  
  if success then
    xPlayer.showNotification('Successfully deleted your character')
    return true
  else
    xPlayer.showNotification('Character not found')
    return false
  end
end)

-- Add this function to handle skin saving
local function saveSkin(identifier, skin)
    if not skin then return false end
    
    local result = MySQL.query.await('UPDATE users SET skin = ? WHERE identifier = ?', {
        json.encode(skin),
        identifier
    })
    
    return result.affectedRows > 0
end

-- Add this event handler
RegisterNetEvent('esx_skin:save', function(skin)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local success = saveSkin(xPlayer.identifier, skin)
    if success then
        TriggerClientEvent('esx_skin:responseSaveSkin', source, true)
    else
        TriggerClientEvent('esx_skin:responseSaveSkin', source, false)
    end
end)


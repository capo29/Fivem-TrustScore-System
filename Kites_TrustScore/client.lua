--=== for any help contact me directly on Github.com/capo29
local spectating = false
local specTarget = nil
local lastPos = nil

CreateThread(function()
  Wait(500)

  TriggerEvent("chat:addSuggestion", "/trustscore", "Check your trust score and playtime (or staff: /trustscore [id])")
  TriggerEvent("chat:addSuggestion", "/commend", "Commend a player (adds trust score)", {
    { name = "id", help = "Server ID of the player" },
    { name = "reason", help = "Reason for commendation" }
  })
  TriggerEvent("chat:addSuggestion", "/warn", "Warn a player (removes trust score)", {
    { name = "id", help = "Server ID of the player" },
    { name = "reason", help = "Reason for warning" }
  })
  TriggerEvent("chat:addSuggestion", "/kick", "Kick a player", {
    { name = "id", help = "Server ID of the player" },
    { name = "reason", help = "Reason for kick" }
  })
  TriggerEvent("chat:addSuggestion", "/ban", "Ban a player (permanent)", {
    { name = "id", help = "Server ID of the player" },
    { name = "reason", help = "Reason for ban" }
  })
  TriggerEvent("chat:addSuggestion", "/tempban", "Ban a player (temporary)", {
    { name = "id", help = "Server ID of the player" },
    { name = "minutes", help = "Duration in minutes" },
    { name = "reason", help = "Reason for tempban" }
  })
  TriggerEvent("chat:addSuggestion", "/freeze", "Freeze a player", {
    { name = "id", help = "Server ID of the player" }
  })
  TriggerEvent("chat:addSuggestion", "/unfreeze", "Unfreeze a player", {
    { name = "id", help = "Server ID of the player" }
  })
  TriggerEvent("chat:addSuggestion", "/tp", "Teleport to a player", {
    { name = "id", help = "Server ID of the player" }
  })
  TriggerEvent("chat:addSuggestion", "/spectate", "Spectate a player (toggle)", {
    { name = "id", help = "Server ID of the player" }
  })
end)

RegisterNetEvent("pls:freeze", function(state)
  local ped = PlayerPedId()
  if not DoesEntityExist(ped) then return end
  FreezeEntityPosition(ped, state == true)
end)

RegisterNetEvent("pls:tpToPlayer", function(targetServerId)
  targetServerId = tonumber(targetServerId)
  local targetPlayer = -1

  for i = 1, 20 do
    targetPlayer = GetPlayerFromServerId(targetServerId)
    if targetPlayer ~= -1 then break end
    Wait(50)
  end

  if targetPlayer == -1 then return end

  local targetPed = GetPlayerPed(targetPlayer)
  if not DoesEntityExist(targetPed) then return end

  local coords = GetEntityCoords(targetPed)
  SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 0.75, false, false, false, true)
end)

local function stopSpectate()
  if not spectating then return end
  NetworkSetInSpectatorMode(false, 0)

  if lastPos then
    SetEntityCoords(PlayerPedId(), lastPos.x, lastPos.y, lastPos.z, false, false, false, true)
  end

  spectating = false
  specTarget = nil
  lastPos = nil
end

RegisterNetEvent("pls:spectate", function(targetServerId)
  targetServerId = tonumber(targetServerId)

  if spectating then
    stopSpectate()
    return
  end

  local targetPlayer = -1
  for i = 1, 20 do
    targetPlayer = GetPlayerFromServerId(targetServerId)
    if targetPlayer ~= -1 then break end
    Wait(50)
  end
  if targetPlayer == -1 then return end

  local targetPed = GetPlayerPed(targetPlayer)
  if not DoesEntityExist(targetPed) then return end

  lastPos = GetEntityCoords(PlayerPedId())
  local coords = GetEntityCoords(targetPed)
  SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 5.0, false, false, false, true)
  Wait(250)

  NetworkSetInSpectatorMode(true, targetPed)
  spectating = true
  specTarget = targetServerId
end)

CreateThread(function()
  while true do
    Wait(1000)
    if spectating and specTarget then
      if GetPlayerFromServerId(specTarget) == -1 then
        stopSpectate()
      end
    end
  end
end)

--=== for any help contact me directly on Github.com/capo29 (DO NOT CLAIM  MY CODE AS YOUR OWN)
Config = Config or {}

Config.ChatTag = Config.ChatTag or ""

Config.Trust = Config.Trust or {}
Config.Trust.DefaultScore = Config.Trust.DefaultScore or 70
Config.Trust.MinScore = Config.Trust.MinScore or 0
Config.Trust.MaxScore = Config.Trust.MaxScore or 100
Config.Trust.WarnRemove = Config.Trust.WarnRemove or 5
Config.Trust.CommendAdd = Config.Trust.CommendAdd or 3

Config.Trust.GainAmount = Config.Trust.GainAmount or 1
Config.Trust.HourlyGainUntil = Config.Trust.HourlyGainUntil or 85
Config.Trust.GainIntervalMinutesLow = Config.Trust.GainIntervalMinutesLow or 60
Config.Trust.GainIntervalMinutesHigh = Config.Trust.GainIntervalMinutesHigh or 120

Config.CommendCooldownSeconds = Config.CommendCooldownSeconds or 120

Config.IdentifierTypes = Config.IdentifierTypes or { "license", "discord", "fivem", "steam", "xbl", "live", "ip" }

Config.DiscordWebhook = Config.DiscordWebhook or ""

local MySQL = MySQL
if not MySQL then
  local ok, ox = pcall(function() return exports.oxmysql end)
  if ok and ox then
    MySQL = {
      insert = function(q, p, cb) return ox:insert(q, p, cb) end,
      query  = function(q, p, cb) return ox:query(q, p, cb) end,
      update = function(q, p, cb) return ox:update(q, p, cb) end,
    }
  end
end

local function IsValidPlayer(src)
  if src == nil then return false end
  src = tonumber(src)
  if not src then return false end
  return GetPlayerName(src) ~= nil
end

local function pname(src)
  src = tonumber(src)
  return (src and GetPlayerName(src)) or ("ID " .. tostring(src))
end

local function clamp(n, a, b)
  if n < a then return a end
  if n > b then return b end
  return n
end

local function hasCmd(src, cmd)
  src = tonumber(src)
  if not src then return false end

  if IsPlayerAceAllowed(src, ("command.%s"):format(cmd)) then
    return true
  end

  if IsPlayerAceAllowed(src, "group.staff")
     or IsPlayerAceAllowed(src, "group.senioradmin")
     or IsPlayerAceAllowed(src, "group.executive")
     or IsPlayerAceAllowed(src, "group.owner") then
    return true
  end

  return false
end

local function getPrimaryIdentifier(src)
  if not IsValidPlayer(src) then return nil end
  local ids = GetPlayerIdentifiers(src)
  if not ids or #ids == 0 then return nil end

  for _, id in ipairs(ids) do
    if type(id) == "string" and id:sub(1, 8) == "license:" then
      return id
    end
  end
  return ids[1]
end

local function getIdentifierSet(src)
  if not IsValidPlayer(src) then return {} end
  local ids = GetPlayerIdentifiers(src)
  if not ids or #ids == 0 then return {} end

  local set = {}
  for _, id in ipairs(ids) do
    if type(id) == "string" then
      local prefix = id:match("^(%w+):")
      if prefix then
        for _, allowed in ipairs(Config.IdentifierTypes) do
          if prefix == allowed then
            set[#set + 1] = id
            break
          end
        end
      end
    end
  end

  local primary = getPrimaryIdentifier(src)
  if primary then
    local exists = false
    for _, v in ipairs(set) do
      if v == primary then exists = true break end
    end
    if not exists then set[#set + 1] = primary end
  end

  return set
end

local function getIdentifier(src)
  return getPrimaryIdentifier(src)
end

local function discordLog(title, description, color)
  if not Config.DiscordWebhook or Config.DiscordWebhook == "" then return end
  local embedColor = color or 16711680
  PerformHttpRequest(Config.DiscordWebhook, function() end, "POST",
    json.encode({
      username = (Config.ChatTag or "Kite") .. " Logger",
      embeds = {{
        title = tostring(title or "LOG"),
        description = tostring(description or ""),
        color = embedColor,
        footer = { text = os.date("!%Y-%m-%d %H:%M:%S UTC") },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
      }}
    }),
    { ["Content-Type"] = "application/json" }
  )
end

local function staffNotify(src, message)
  src = tonumber(src)
  if not src then return end
  if not message or message == "" then return end

  TriggerClientEvent("chat:addMessage", src, {
    template = [[
      <div style="
        width:100%;
        margin:6px 0;
        padding:10px 14px;
        background: rgba(0,0,0,0.18);
        color:#ffffff;
        font-size:14px;
        line-height:18px;
        text-align:left;
      ">
        <span style="color:#f1c40f;font-weight:800;">[{0}]</span>
        <span style="font-weight:500;"> {1}</span>
      </div>
    ]],
    args = { (Config.ChatTag or ""), tostring(message) }
  })
end

local function staffNotifyTrust(src, playerName, trustPercent, playtimeText)
  src = tonumber(src)
  if not src then return end

  TriggerClientEvent("chat:addMessage", src, {
    template = [[
      <div style="
        width:100%;
        margin:6px 0;
        padding:10px 14px;
        background: rgba(0,0,0,0.18);
        color:#ffffff;
        font-size:14px;
        line-height:18px;
        text-align:left;
      ">
        <span style="color:#f1c40f;font-weight:800;">[{0}]</span>
        <span style="color:#f1c40f;font-weight:700;"> {1}</span>
        <span style="color:#ffffff;"> has a playtime of </span>
        <span style="color:#99cc00;font-weight:800;">{2}</span>
        <span style="color:#ffffff;"> and a trustscore of </span>
        <span style="color:#99cc00;font-weight:900;">{3}%</span>
      </div>
    ]],
    args = {
      (Config.ChatTag or ""),
      tostring(playerName or "You"),
      tostring(playtimeText or "0h 0m"),
      tonumber(trustPercent) or (Config.Trust.DefaultScore or 70)
    }
  })
end

local function broadcastAction(actionText, targetName, staffName, reason)
  local extra = reason and ("(" .. tostring(reason) .. ")") or ""

  TriggerClientEvent("chat:addMessage", -1, {
    template = [[
      <div style="
        width:100%;
        margin:6px 0;
        padding:10px 14px;
        background: rgba(0,0,0,0.18);
        color:#ffffff;
        font-size:14px;
        line-height:18px;
        text-align:left;
      ">
        <span style="color:#f1c40f;font-weight:800;">[{0}]</span>
        <span style="color:#f1c40f;font-weight:700;"> {1}</span>
        <span style="color:#ffffff;"> {2} by </span>
        <span style="color:#4dd2ff;font-weight:800;">{3}</span>
        <span style="color:#bdbdbd;"> {4}</span>
      </div>
    ]],
    args = {
      Config.ChatTag or "",
      tostring(targetName),
      tostring(actionText),
      tostring(staffName),
      extra
    }
  })
end

local MemoryPlayers = {}

local function dbEnsurePlayer(identifier)
  if not identifier or identifier == "" then return end
  if MySQL then
    MySQL.insert(
      "INSERT IGNORE INTO projectla_players (identifier, trustscore, playtime_seconds) VALUES (?, ?, ?)",
      { identifier, Config.Trust.DefaultScore, 0 }
    )
  else
    if not MemoryPlayers[identifier] then
      MemoryPlayers[identifier] = { trustscore = Config.Trust.DefaultScore, playtime_seconds = 0 }
    end
  end
end

local function dbGetPlayer(identifier, cb)
  if not identifier or identifier == "" then return cb(nil) end
  if MySQL then
    MySQL.query(
      "SELECT identifier, trustscore, playtime_seconds FROM projectla_players WHERE identifier = ? LIMIT 1",
      { identifier },
      function(rows) cb(rows and rows[1] or nil) end
    )
  else
    cb(MemoryPlayers[identifier])
  end
end

local function dbSetTrust(identifier, trust)
  if not identifier or identifier == "" then return end
  if MySQL then
    MySQL.update("UPDATE projectla_players SET trustscore = ? WHERE identifier = ?", { trust, identifier })
  else
    dbEnsurePlayer(identifier)
    MemoryPlayers[identifier].trustscore = trust
  end
end

local function dbAddPlaytime(identifier, seconds)
  if not identifier or identifier == "" then return end
  if MySQL then
    MySQL.update(
      "UPDATE projectla_players SET playtime_seconds = playtime_seconds + ? WHERE identifier = ?",
      { seconds, identifier }
    )
  else
    dbEnsurePlayer(identifier)
    MemoryPlayers[identifier].playtime_seconds = (MemoryPlayers[identifier].playtime_seconds or 0) + (seconds or 0)
  end
end

local function dbInsertStaffLog(action, staffId, staffName, targetId, targetName, reason, meta)
  if not MySQL then return end
  MySQL.insert([[
    INSERT INTO projectla_staff_logs (action, staff_identifier, staff_name, target_identifier, target_name, reason, meta)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ]], {
    tostring(action or ""),
    tostring(staffId or ""),
    tostring(staffName or ""),
    tostring(targetId or ""),
    tostring(targetName or ""),
    reason and tostring(reason) or nil,
    meta and json.encode(meta) or nil
  })
end

local function isIdentifierBanned(identifier, cb)
  if not MySQL then return cb(nil) end
  if not identifier or identifier == "" then return cb(nil) end

  MySQL.update([[
    UPDATE projectla_bans
    SET active = 0
    WHERE active = 1 AND expires_at IS NOT NULL AND expires_at <= NOW()
  ]], {}, function()
    MySQL.query([[
      SELECT id, reason, banned_by_name, expires_at
      FROM projectla_bans
      WHERE active = 1 AND identifier = ?
      ORDER BY id DESC
      LIMIT 1
    ]], { identifier }, function(rows)
      cb(rows and rows[1] or nil)
    end)
  end)
end

AddEventHandler("playerConnecting", function(playerName, setKickReason, deferrals)
  if not MySQL then return end

  local src = source
  deferrals.defer()
  Wait(0)
  deferrals.update("Checking bans...")

  local idSet = getIdentifierSet(src)
  if not idSet or #idSet == 0 then
    deferrals.done()
    return
  end

  local checked, bannedRow = 0, nil
  for _, ident in ipairs(idSet) do
    isIdentifierBanned(ident, function(row)
      checked = checked + 1
      if row and not bannedRow then bannedRow = row end

      if checked >= #idSet then
        if bannedRow then
          local exp = bannedRow.expires_at and (" until " .. tostring(bannedRow.expires_at)) or " permanently"
          deferrals.done(("You are banned%s.\nReason: %s\nBy: %s"):format(
            exp,
            bannedRow.reason or "N/A",
            bannedRow.banned_by_name or "N/A"
          ))
        else
          deferrals.done()
        end
      end
    end)
  end
end)

local joinTimes = {}

AddEventHandler("playerJoining", function()
  local src = source
  if not IsValidPlayer(src) then return end
  local ident = getPrimaryIdentifier(src)
  if not ident then return end
  dbEnsurePlayer(ident)
  joinTimes[src] = os.time()
end)

AddEventHandler("playerDropped", function()
  local src = source
  local jt = joinTimes[src]
  joinTimes[src] = nil
  if not jt then return end

  local ident = getPrimaryIdentifier(src)
  if not ident then return end

  local seconds = math.max(0, os.time() - jt)
  dbAddPlaytime(ident, seconds)
end)

CreateThread(function()
  while true do
    Wait(60 * 1000)
    for _, s in ipairs(GetPlayers()) do
      local src = tonumber(s)
      if IsValidPlayer(src) then
        local ident = getPrimaryIdentifier(src)
        if ident then
          dbEnsurePlayer(ident)
          dbAddPlaytime(ident, 60)
        end
      end
    end
  end
end)

CreateThread(function()
  while true do
    Wait(60 * 1000)
    for _, s in ipairs(GetPlayers()) do
      local src = tonumber(s)
      if IsValidPlayer(src) then
        local ident = getPrimaryIdentifier(src)
        if ident then
          dbGetPlayer(ident, function(row)
            if not row then return end

            local trust = tonumber(row.trustscore) or Config.Trust.DefaultScore
            local play  = tonumber(row.playtime_seconds) or 0

            local interval =
              (trust < Config.Trust.HourlyGainUntil)
                and Config.Trust.GainIntervalMinutesLow
                or  Config.Trust.GainIntervalMinutesHigh

            if interval <= 0 then return end

            local gainedTotal = math.floor(play / (interval * 60)) * Config.Trust.GainAmount
            local desired = clamp(Config.Trust.DefaultScore + gainedTotal, Config.Trust.MinScore, Config.Trust.MaxScore)

          if trust < desired and trust >= Config.Trust.DefaultScore then
            dbSetTrust(ident, desired)
          end
          end)
        end
      end
    end
  end
end)

local function canBypassCommendCooldown(src)
  src = tonumber(src)
  if not src then return false end

  return
    IsPlayerAceAllowed(src, "group.senioradmin")
    or IsPlayerAceAllowed(src, "group.executive")
    or IsPlayerAceAllowed(src, "group.owner")
end

local commendCooldown = {}

local function checkCommendCooldown(src)
  if canBypassCommendCooldown(src) then return true, 0 end

  local staffIdent = getPrimaryIdentifier(src) or ("src:" .. tostring(src))
  local last = commendCooldown[staffIdent] or 0
  local now = os.time()
  local remaining = (last + Config.CommendCooldownSeconds) - now

  if remaining > 0 then
    return false, remaining
  end

  commendCooldown[staffIdent] = now
  return true, 0
end

local function parseId(args, i)
  local v = args[i]
  if not v then return nil end
  local n = tonumber(v)
  if not n then return nil end
  if not IsValidPlayer(n) then return nil end
  return n
end

local function restArgs(args, startIndex)
  if #args < startIndex then return "" end
  local t = {}
  for i = startIndex, #args do t[#t + 1] = args[i] end
  return table.concat(t, " ")
end

RegisterCommand("trustscore", function(src, args)
  src = tonumber(src) or 0
  if not IsValidPlayer(src) then return end

  local target = tonumber(args[1])

  if target then
    if not hasCmd(src, "trustscore") then
      staffNotify(src, "You do not have permission to view other players.")
      return
    end
    if not IsValidPlayer(target) then
      staffNotify(src, "Invalid player ID.")
      return
    end

    local ident = getPrimaryIdentifier(target)
    if not ident then
      staffNotify(src, "Could not read target identifier.")
      return
    end

    dbEnsurePlayer(ident)
    dbGetPlayer(ident, function(row)
      local trust = tonumber(row and row.trustscore) or Config.Trust.DefaultScore
      local play  = tonumber(row and row.playtime_seconds) or 0
      local hours = math.floor(play / 3600)
      local mins  = math.floor((play % 3600) / 60)

      staffNotifyTrust(src, pname(target), trust, ("%dh %dm"):format(hours, mins))
    end)

  else
    local ident = getPrimaryIdentifier(src)
    if not ident then return end

    dbEnsurePlayer(ident)
    dbGetPlayer(ident, function(row)
      local trust = tonumber(row and row.trustscore) or Config.Trust.DefaultScore
      local play  = tonumber(row and row.playtime_seconds) or 0
      local hours = math.floor(play / 3600)
      local mins  = math.floor((play % 3600) / 60)

      staffNotifyTrust(src, "You", trust, ("%dh %dm"):format(hours, mins))
    end)
  end
end, false)

RegisterCommand("warn", function(src, args)
  src = tonumber(src) or 0
  if not hasCmd(src, "warn") then
    staffNotify(src, "You do not have permission to use /warn.")
    return
  end

  local target = parseId(args, 1)
  if not target then staffNotify(src, "Usage: /warn [id] [reason]") return end

  local reason = restArgs(args, 2)
  if reason == "" then reason = "No reason provided" end

  local staffName  = pname(src)
  local targetName = pname(target)

  local tid = getPrimaryIdentifier(target)
  if not tid then staffNotify(src, "Could not read target identifiers.") return end

  dbEnsurePlayer(tid)
  dbGetPlayer(tid, function(row)
    local trust = tonumber(row and row.trustscore) or Config.Trust.DefaultScore
    trust = clamp(trust - Config.Trust.WarnRemove, Config.Trust.MinScore, Config.Trust.MaxScore)
    dbSetTrust(tid, trust)

    broadcastAction("has been warned", targetName, staffName, reason)
    discordLog("WARN", ("**Staff:** %s\n**Target:** %s (%s)\n**Reason:** %s\n**New Trust:** %d%%"):format(staffName, targetName, tid, reason, trust), 16776960)
    dbInsertStaffLog("warn", getPrimaryIdentifier(src), staffName, tid, targetName, reason, { newTrust = trust })
  end)
end, false)

RegisterCommand("commend", function(src, args)
  src = tonumber(src) or 0
  if not hasCmd(src, "commend") then
    staffNotify(src, "You do not have permission to use /commend.")
    return
  end

  local target = parseId(args, 1)
  if not target then staffNotify(src, "Usage: /commend [id] [reason]") return end

  local reason = restArgs(args, 2)
  if reason == "" then reason = "No reason provided" end

  local ok, remaining = checkCommendCooldown(src)
  if not ok then
    staffNotify(src, ("You must wait %ds before commending again."):format(remaining))
    return
  end

  local staffName  = pname(src)
  local targetName = pname(target)

  local tid = getPrimaryIdentifier(target)
  if not tid then staffNotify(src, "Could not read target identifiers.") return end

  dbEnsurePlayer(tid)
  dbGetPlayer(tid, function(row)
    local trust = tonumber(row and row.trustscore) or Config.Trust.DefaultScore
    trust = clamp(trust + Config.Trust.CommendAdd, Config.Trust.MinScore, Config.Trust.MaxScore)
    dbSetTrust(tid, trust)

    broadcastAction("has been commended", targetName, staffName, reason)

    discordLog("COMMEND", ("**Staff:** %s\n**Target:** %s (%s)\n**Reason:** %s\n**New Trust:** %d%%"):format(staffName, targetName, tid, reason, trust), 3066993)
    dbInsertStaffLog("commend", getPrimaryIdentifier(src), staffName, tid, targetName, reason, { newTrust = trust })
  end)
end, false)

RegisterCommand("kick", function(src, args)
  src = tonumber(src) or 0
  if not hasCmd(src, "kick") then
    staffNotify(src, "You do not have permission to use /kick.")
    return
  end

  local target = parseId(args, 1)
  if not target then staffNotify(src, "Usage: /kick [id] [reason]") return end

  local reason = restArgs(args, 2)
  if reason == "" then reason = "No reason provided" end

  local staffName  = pname(src)
  local targetName = pname(target)

  local tid = getPrimaryIdentifier(target)
  if tid then
    dbEnsurePlayer(tid)
    dbGetPlayer(tid, function(row)
      local trust = tonumber(row and row.trustscore) or Config.Trust.DefaultScore
      trust = clamp(trust - Config.Trust.WarnRemove, Config.Trust.MinScore, Config.Trust.MaxScore)
      dbSetTrust(tid, trust)
    end)
  end

  broadcastAction("has been kicked", targetName, staffName, reason)
  discordLog("KICK", ("**Staff:** %s\n**Target:** %s (%s)\n**Reason:** %s"):format(staffName, targetName, tid or "N/A", reason), 15158332)
  dbInsertStaffLog("kick", getPrimaryIdentifier(src), staffName, tid or "", targetName, reason, nil)

  DropPlayer(target, ("[%s] You were kicked: %s"):format(Config.ChatTag or "", reason))
end, false)

RegisterCommand("ban", function(src, args)
  src = tonumber(src) or 0
  if not hasCmd(src, "ban") then
    staffNotify(src, "You do not have permission to use /ban.")
    return
  end

  local target = parseId(args, 1)
  if not target then staffNotify(src, "Usage: /ban [id] [reason]") return end

  local reason = restArgs(args, 2)
  if reason == "" then reason = "No reason provided" end

  local staffName  = pname(src)
  local targetName = pname(target)
  local staffIdent = getPrimaryIdentifier(src) or ("src:" .. tostring(src))

  local ids = getIdentifierSet(target)
  if not ids or #ids == 0 then
    staffNotify(src, "Could not read target identifiers.")
    return
  end

  if MySQL then
    for _, ident in ipairs(ids) do
      MySQL.insert([[
        INSERT INTO projectla_bans (identifier, reason, banned_by, banned_by_name, expires_at, active)
        VALUES (?, ?, ?, ?, NULL, 1)
      ]], { ident, reason, staffIdent, staffName })
    end
  end

  broadcastAction("has been banned", targetName, staffName, reason)
  discordLog("BAN", ("**Staff:** %s\n**Target:** %s\n**Reason:** %s\n**Identifiers Stored:** %d"):format(staffName, targetName, reason, #ids), 15158332)
  dbInsertStaffLog("ban", staffIdent, staffName, getPrimaryIdentifier(target) or "", targetName, reason, { identifiers = ids })

  DropPlayer(target, ([[
[%s] You were banned from the server.

Staff: %s
Reason: %s

Appeal:
%s
]]):format(
  Config.ChatTag or "",
  staffName,
  reason,
  Config.AppealLink or ""
))
end, false)

RegisterCommand("tempban", function(src, args)
  src = tonumber(src) or 0
  if not hasCmd(src, "tempban") then
    staffNotify(src, "You do not have permission to use /tempban.")
    return
  end

  local target  = parseId(args, 1)
  local minutes = tonumber(args[2])
  if not target or not minutes then
    staffNotify(src, "Usage: /tempban [id] [minutes] [reason]")
    return
  end

  local reason = restArgs(args, 3)
  if reason == "" then reason = "No reason provided" end

  local staffName  = pname(src)
  local targetName = pname(target)
  local staffIdent = getPrimaryIdentifier(src) or ("src:" .. tostring(src))

  local ids = getIdentifierSet(target)
  if not ids or #ids == 0 then
    staffNotify(src, "Could not read target identifiers.")
    return
  end

  if MySQL then
    for _, ident in ipairs(ids) do
      MySQL.insert([[
        INSERT INTO projectla_bans (identifier, reason, banned_by, banned_by_name, expires_at, active)
        VALUES (?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? MINUTE), 1)
      ]], { ident, reason, staffIdent, staffName, minutes })
    end
  end

  broadcastAction(("has been temp-banned (%dm)"):format(minutes), targetName, staffName, reason)
  discordLog("TEMPBAN", ("**Staff:** %s\n**Target:** %s\n**Duration:** %dm\n**Reason:** %s\n**Identifiers Stored:** %d"):format(staffName, targetName, minutes, reason, #ids), 15158332)
  dbInsertStaffLog("tempban", staffIdent, staffName, getPrimaryIdentifier(target) or "", targetName, reason, { minutes = minutes, identifiers = ids })

  DropPlayer(target, ("[%s] You were temp-banned (%dm): %s"):format(Config.ChatTag or "", minutes, reason))
end, false)

RegisterCommand("freeze", function(src, args)
  src = tonumber(src) or 0
  if not hasCmd(src, "freeze") then
    staffNotify(src, "You do not have permission to use /freeze.")
    return
  end

  local target = parseId(args, 1)
  if not target then staffNotify(src, "Usage: /freeze [id]") return end

  TriggerClientEvent("kites:freeze", target, true)

  broadcastAction("has been frozen", pname(target), pname(src), nil)
  discordLog("FREEZE", ("**Staff:** %s\n**Target:** %s"):format(pname(src), pname(target)), 3447003)
  dbInsertStaffLog("freeze", getPrimaryIdentifier(src), pname(src), getPrimaryIdentifier(target) or "", pname(target), nil, nil)
end, false)

RegisterCommand("unfreeze", function(src, args)
  src = tonumber(src) or 0
  if not hasCmd(src, "unfreeze") then
    staffNotify(src, "You do not have permission to use /unfreeze.")
    return
  end

  local target = parseId(args, 1)
  if not target then staffNotify(src, "Usage: /unfreeze [id]") return end

  TriggerClientEvent("kites:freeze", target, false)

  broadcastAction("has been unfrozen", pname(target), pname(src), nil)
  discordLog("UNFREEZE", ("**Staff:** %s\n**Target:** %s"):format(pname(src), pname(target)), 3066993)
  dbInsertStaffLog("unfreeze", getPrimaryIdentifier(src), pname(src), getPrimaryIdentifier(target) or "", pname(target), nil, nil)
end, false)

RegisterCommand("tp", function(src, args)
  src = tonumber(src) or 0
  if not hasCmd(src, "tp") then
    staffNotify(src, "You do not have permission to use /tp.")
    return
  end

  local target = parseId(args, 1)
  if not target then staffNotify(src, "Usage: /tp [id]") return end

  TriggerClientEvent("kites:tpToPlayer", src, target)

  discordLog("TP", ("**Staff:** %s\n**To:** %s"):format(pname(src), pname(target)), 3447003)
  dbInsertStaffLog("tp", getPrimaryIdentifier(src), pname(src), getPrimaryIdentifier(target) or "", pname(target), nil, nil)
end, false)

RegisterCommand("spectate", function(src, args)
  src = tonumber(src) or 0
  if not hasCmd(src, "spectate") then
    staffNotify(src, "You do not have permission to use /spectate.")
    return
  end

  local target = parseId(args, 1)
  if not target then staffNotify(src, "Usage: /spectate [id]") return end

  TriggerClientEvent("kites:spectate", src, target)

  discordLog("SPECTATE", ("**Staff:** %s\n**Target:** %s"):format(pname(src), pname(target)), 3447003)
  dbInsertStaffLog("spectate", getPrimaryIdentifier(src), pname(src), getPrimaryIdentifier(target) or "", pname(target), nil, nil)
end, false)


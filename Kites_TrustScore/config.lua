Config = {}

Config.DiscordWebhook = "" -- Logs for actions

Config.ChatTag = ""  -- Server Name

Config.AppealLink = ""  -- Ban appeal link

Config.Ace = {
  Staff = "group.staff",               --- configurable ACE groups
  Senior = "group.senioradmin",
  Executive = "group.executive"
}

Config.Trust = {               --- configurable trust settings
  DefaultScore = 70,
  MinScore = 0,
  MaxScore = 100,

  CommendAdd = 3,
  WarnRemove = 5,

  HourlyGainUntil = 85,
  GainAmount = 1,
  GainIntervalMinutesLow = 60,
  GainIntervalMinutesHigh = 120
}

Config.CommendCooldownSeconds = 120             --- configurable commend cooldown

Config.IdentifierTypes = {                 --- (ignore this)
  "license",
  "license2",
  "discord",
  "steam",
  "xbl",
  "live",
  "fivem"
}

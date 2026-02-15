# Kites TrustScore - Staff System

A FiveM resource that adds a trust score system and staff management tools to your server.

## What It Does

This script tracks player trust scores and playtime, and gives staff members commands to manage players. Players start with a default trust score that can go up or down based on their behavior and playtime.

## Features

- **Trust Score System**: Players have a trust score (0-100) that changes based on warnings, commendations, and playtime
- **Playtime Tracking**: Automatically tracks how long players have been on the server
- **Staff Commands**: Warn, commend, kick, ban, tempban, freeze, unfreeze, teleport, and spectate players
- **Ban System**: Permanent and temporary bans stored in the database
- **Staff Logging**: All staff actions are logged to the database and optionally to Discord

## Installation

1. Place the folder in your `resources` directory
2. Add `ensure Kites_TrustScore` to your `server.cfg`
3. Run the SQL file (`sql.sql`) in your database
4. Configure the settings in `config.lua`
5. Restart your server

## Configuration

Edit `config.lua` to customize:

- `Config.ChatTag`: Your server name (shown in messages)
- `Config.DiscordWebhook`: Discord webhook URL for logging (leave empty to disable)
- `Config.AppealLink`: Link for ban appeals
- `Config.Trust`: Adjust default scores, min/max values, and gain rates
- `Config.CommendCooldownSeconds`: How long staff must wait between commendations

## Permissions

Staff commands use ACE permissions. Make sure your staff have the appropriate permissions:

- `command.trustscore` - View trust scores
- `command.warn` - Warn players
- `command.commend` - Commend players
- `command.kick` - Kick players
- `command.ban` - Ban players
- `command.tempban` - Temporary ban players
- `command.freeze` - Freeze players
- `command.unfreeze` - Unfreeze players
- `command.tp` - Teleport to players
- `command.spectate` - Spectate players

Or add them to one of these groups:
- `group.staff`
- `group.senioradmin`
- `group.executive`
- `group.owner`

## Commands

### Player Commands

- `/trustscore` - Check your own trust score and playtime

### Staff Commands

- `/trustscore [id]` - View another player's trust score and playtime
- `/warn [id] [reason]` - Warn a player (lowers trust score)
- `/commend [id] [reason]` - Commend a player (raises trust score)
- `/kick [id] [reason]` - Kick a player from the server
- `/ban [id] [reason]` - Permanently ban a player
- `/tempban [id] [minutes] [reason]` - Temporarily ban a player
- `/freeze [id]` - Freeze a player in place
- `/unfreeze [id]` - Unfreeze a player
- `/tp [id]` - Teleport to a player
- `/spectate [id]` - Spectate a player (use again to stop)

## Requirements

- FiveM Server
- oxmysql or MySQL resource
- Database (MySQL/MariaDB)

## How Trust Scores Work

- New players start with a default trust score (configurable, default is 70)
- Trust score increases automatically over time based on playtime
- Warnings lower the trust score
- Commendations raise the trust score
- Trust score is capped between 0 and 100

## Support

For help, contact me on GitHub: github.com/capo29

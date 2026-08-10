# RobloxClient

Client modules for a few Roblox games, injected automatically based on the game you join. The loader fetches the matching script from this repo and runs it once the client library is detected.

## Loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/examiners/robloxclient/main/loader.lua"))()
```

## Usage

1. Inject the client library into the game. The loader auto-detects it under `shared.library` (or the stock key), so either registration works.
2. Join one of the supported games below.
3. Run the loadstring above.

The loader checks `game.PlaceId`, pulls the matching client script from GitHub, and loads it. You'll see an in-game notification for each step if the library is loaded; otherwise it falls back to console output.

## Supported games

| Game | PlaceId | Script |
| --- | --- | --- |
| 1.8 client | `77790193039862` | `client/1.8.lua` |
| Flee the Facility | `893973440` | `client/ftf.lua` |

## Modules

### 1.8 client
Combat: AutoClicker, Reach, Sprint, Velocity, AutoBlock
Blatant: Fly, HighJump, HitBoxes, Killaura, LongJump, NoSlowdown, Speed, Spider
World: FastBreak, FastPlace

### Flee the Facility
Blatant: NoSlowdown, PhaseHammer, RestrainBeast, SlowBeast, SpamBeast
Render: ComputerESP
Utility: AutoComputer

## Disclaimer

For educational purposes only. Use at your own risk.

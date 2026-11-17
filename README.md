# Brainrot Bazaar

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/WV629/brainrot-bazaar/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/WV629/brainrot-bazaar/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

Brainrot Bazaar is a 3D Steal-a-Brainrot-style game built for make.fun's "Make the best AI Roblox brainrot game" bounty. Absurd original characters — Toast Knight, DJ Pickle, Burrito Professor, Disco Llama, Grandma's WiFi Router and seven more — walk the conveyor through a real 3D bazaar. Buy one and it stands on your base earning money every second; climb the rarity ladder from Common to Secret, chase Golden, Diamond and Rainbow mutations, lock your base against thieves, slap the rival Baron von Crumb when he sneaks in, and dash home every few minutes when the tsunami wave sweeps the map. Rebirth to trade it all for a permanent income multiplier and start the climb again, richer.

How to play: walk up to a brainrot on the conveyor and press E to buy it. It earns money on your base while you shop for rarer ones. Press F to slap a thief, click a brainrot on an unlocked rival base to steal it (then run home before the wave or a slap makes you drop it), lock your base for 60 seconds when the Baron is about, and hit Rebirth when you can afford the climb again.

## Run it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to the output directory and writes `dossier.json` with `vendor/makefun-roblox.ts`. The place is a Rojo project: the server game loop lives in `src/server`, the HUD and keybinds in `src/client`, and the one-job modules (cast, economy, world builder, wave clock) in `src/shared`.

---

<sub>Entered on [make.fun](https://make.fun/?ref=wkn1wnrf&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>

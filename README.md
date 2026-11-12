# Squeezy Game (Godot 4.7)

Offline one-tap 3D casual game for Android. Jump, flip, butt-slam, get fatter. 200 levels.
No ads, no internet, no data collection.

- Run: Godot 4.7 -> Import -> `project.godot` -> F5. Click / Space = tap.
- Release build (Play Store .aab): dekho `CLAUDE.md` -> "RELEASE TASK".
- Play Store listing, policy answers: `store/PLAY_STORE.md`
- Privacy policy (Cloudflare Pages, company domain): `docs/privacy-policy.html`
- Look / lighting tuning: `scripts/look.gd`


## Screens (tumhari images jaisi)
- Home: SQUEEZY GAME, Play, Settings (gear), Level Up, coins. (Mail aur Shop v1.0 mein chhupe hain: home_screen.gd -> SHOW_MAIL / SHOW_SHOP)
- Level map: 200 levels ka ghumavdaar raasta, khule level purple, band level grey (taala), current level pe teer.
- Settings: Music / Sound / Effect ON-OFF (save hote hain), Help, Quit.
- Game ke andar: back (home), restart, coins, level progress. Jeetne pe NEXT/HOME, girne pe RETRY/HOME.

## 200 levels
Har level thoda mushkil: zyada cheezein (6 se 24), zyada door aur oonche platforms (zyada taps),
badi cheezein, ooncha final. Har 3 level pe ek NAYI cheez aati hai ("NEW!" dikhta hai):
20 fruits + Monitor, Keyboard, Mouse, CPU Cabinet, Speaker, UPS, Printer, Refrigerator,
Washing Machine, Flower Pot + purani cheezein (kursi, bottle, drum...). Order: scripts/object_factory.gd -> ORDER

## Font
`fonts/game_font.ttf` = "Lilita One" (SIL Open Font License, `fonts/OFL.txt`).

## Licence
Copyright (c) 2026 Rekixo. All rights reserved. Dekho `LICENSE`.

## Sounds
Game khud sounds aur music banata hai. Apni files `sounds/` mein daal sakte ho (music.ogg, jump.ogg, splat.ogg ...).

## Files
- scripts/main.gd: screens badalna
- scripts/game.gd: gameplay + HUD
- scripts/ui/: home_screen, level_map, settings_screen, coin_bar, modal_box, ui_kit
- scripts/game_data.gd: coins, unlocked level, settings save
- scripts/audio.gd: music + sound effects
- scripts/level_data.gd: 200 levels ki difficulty
- scripts/object_factory.gd, fruit_factory.gd: saari cheezein
- ui/: tumhari images se kaate gaye buttons/backgrounds

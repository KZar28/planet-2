# planet-2

A Godot 4.3 prototype. You're stranded on a tiny spherical planet and have to survive waves of monsters.

## Running

Open the folder in Godot 4.3 or newer (**Import → project.godot**) and press **F5**.

The project uses the **Compatibility** (OpenGL 3) renderer so it runs on laptops and integrated GPUs without Vulkan.

## Controls

| Action | Input |
| --- | --- |
| Move | WASD / arrow keys |
| Look / aim | Mouse |
| Jump | Space |
| Sprint (uses solar energy) | Shift |
| Mine fuel (hold) / launch at dropship | E |
| Shoot | Left mouse button (hold for auto-fire) |
| Nova blast (area damage, 6s cooldown, 30 energy) | F / Right mouse button |
| Pause / release mouse | Esc |
| Restart after game over | R / Enter |

## How it works

**Game loop.** You land on an asteroid next to your dropship. Fuel deposits (glowing orange crystals) are scattered at least 25° of arc away from it. Hold E next to one to mine it. You can carry 40 fuel and it slows you down, so you walk it back; walking onto the dropship pad deposits it automatically. Once the dropship has its quota (60 + 20 × asteroid number), press E at the dropship to launch to the next asteroid. Each asteroid has a new layout, a bigger quota, more deposits and tougher, more numerous monsters. Waves keep coming the whole time.

- **Title, landing and launch sequences** (`scripts/main.gd`, `Phase` enum). The first load shows a title screen over an orbiting view of the asteroid. Starting the game plays a landing: the dropship descends with thrusters while a cinematic camera tracks it, then you get control and the waves begin. Launching plays a 3-2-1 countdown, liftoff, and a fade to "Traveling to Asteroid N", then the landing on the next asteroid. Click or Esc skips a cinematic.
- **Day/night spin** (`scripts/day_night.gd`). The sun orbits the asteroid once every 480s (8 minutes). `DayNight.light_at(pos)` returns 0 (night) to 1 (day) for any surface point, and the other systems use it.
- **Crawler player** (`scripts/crawler_rig.gd`). The player is a six-legged sci-fi crawler built and animated procedurally. Walking uses an alternating tripod gait with 2-bone IK legs, idling adds a slight bob, and mining braces it in a crouched, splayed stance with the turret laser locked on the deposit. Mining (4 fuel/s) roots you in place. Taking damage, firing or Nova interrupts it; release and press E again to resume.
- **Shop console.** A terminal on the side of the dropship. Press E next to it to open the shop, which pauses the game. Kills earn credits scaled by tier (Crawler 10, Runner 15, Brute 40), +50% on the dark side. Each asteroid offers one random permanent upgrade per category (Offense, Defense, Mining), and you can buy each card once per asteroid. Prices grow ×1.6 per level owned. The catalog is in `scripts/upgrades.gd`, and credits/upgrades live in `GameState` (reset on game over).
  - Offense: Twin Barrel (+1 parallel gun), Nova Capacitor (+1 Nova charge)
  - Defense: Regen Shield (+25 shield, recharges after 4s without damage), Armor Plating (+25 max HP)
  - Mining: Laser Focus (+25% mining speed), Cargo Pods (+10 cargo)
- **Solar energy.** The panel on your back charges energy in sunlight (9/s in full sun) and you lose 0.8/s in darkness. Sprinting (12/s), mining (5/s) and Nova (30) use it, so long night trips are risky.
- **Dark side.** Monsters prefer to spawn in darkness. In full dark they move 45% faster, hit 60% harder and take 1/1.6 damage, and their eyes turn magenta.
- **Night powerups** (`scripts/powerup_spawner.gd`, `scripts/powerup.gd`). While you're on the night side, every 4s there's a 40% chance a powerup drops nearby (max 3 at once, they despawn after 30s): Shield (blocks all damage, 8s), Speed Boost (1.5×, 10s), Double Damage (10s), Spread Shot (3-way fire, 12s).
- **HUD waypoints.** The dropship is always marked. Fuel deposits are marked when they're in line of sight.
- The run's asteroid number and score live in the `GameState` autoload (`scripts/game_state.gd`) and carry across launches. Dying resets them.

- **Spherical gravity.** `SphereWalker` (`scripts/sphere_walker.gd`) is the base class for the player and the monsters. It pulls toward the planet center and re-orients the body every physics frame so local +Y points away from the surface. `up_direction` is updated too, so `is_on_floor()` and `move_and_slide()` behave as they would on flat ground.
- **Waves.** `scripts/wave_manager.gd` spawns monsters at least 50° around the asteroid from the player. When a wave is cleared there's a 10-second intermission and you heal 25 HP. Each wave adds more monsters and gives them more HP.
- **Monsters** (`scripts/enemy.gd`). There are three types, tuned through the `STATS` table:
  - **Crawler** (red crab): the baseline monster. Crabs (`scripts/crab_rig.gd`) scuttle on six legs with swinging, clacking pincers that snap forward on attack.
  - **Runner** (orange crab): small, fast and fragile. Appears from wave 2.
  - **Brute** (purple frog, `scripts/frog_rig.gd`): big, slow and tanky. Appears from wave 3. It crouches for `hop_pause` (0.8s), then leaps; hop distance keeps its average speed at its stat speed and never overshoots the player.
- **Asteroid** (`scripts/planet.gd`, radius 40). Craters, rocks, crystals and fuel deposits are scattered from a seed that changes per asteroid. Rocks and deposits have collision.
- Your best score is saved to `user://save.cfg`.

## Layout

```
scenes/   main, planet, player, enemy, projectile, hud
scripts/  one script per scene + sphere_walker.gd base class
```

Physics layers: 1 = world, 2 = player, 3 = enemies.

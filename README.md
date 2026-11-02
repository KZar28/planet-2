# planet-2

A Godot 4.3 prototype. You're stranded on a tiny spherical planet and have to survive waves of monsters.

## Running

Open the folder in Godot 4.3 or newer (**Import → project.godot**) and press **F5**.

## Controls

| Action | Input |
| --- | --- |
| Move | WASD / arrow keys |
| Look / aim | Mouse |
| Jump | Space |
| Sprint | Shift |
| Shoot | Left mouse button (hold for auto-fire) |
| Nova blast (area damage, 6s cooldown) | F / Right mouse button |
| Pause / release mouse | Esc |
| Restart after game over | R / Enter |

## How it works

- **Spherical gravity.** `SphereWalker` (`scripts/sphere_walker.gd`) is the base class for the player and the monsters. It pulls toward the planet center and re-orients the body every physics frame so local +Y points away from the surface. `up_direction` is updated too, so `is_on_floor()` and `move_and_slide()` behave as they would on flat ground.
- **Waves.** `scripts/wave_manager.gd` spawns monsters at least 50° around the planet from the player. When a wave is cleared there's a short intermission and you heal 25 HP. Each wave adds more monsters and gives them more HP.
- **Monsters** (`scripts/enemy.gd`). There are three types, tuned through the `STATS` table:
  - **Crawler** (red): the baseline monster.
  - **Runner** (orange): small, fast and fragile. Appears from wave 2.
  - **Brute** (purple): big, slow and tanky. Appears from wave 3.
- **Planet** (`scripts/planet.gd`). Trees, rocks and crystals are scattered from a fixed seed. Trees and rocks have collision; crystals are decorative only.
- Your best score is saved to `user://save.cfg`.

## Layout

```
scenes/   main, planet, player, enemy, projectile, hud
scripts/  one script per scene + sphere_walker.gd base class
```

Physics layers: 1 = world, 2 = player, 3 = enemies.

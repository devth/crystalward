# Third-party assets

Vendored free game art used by Crystalward. Prefer **CC0** packs; one pack is **CC-BY 4.0** (attribution required).

Paths are under `assets/third_party/`.

---

## Kenney Particle Pack

| | |
|---|---|
| **Author** | Kenney Vleugels ([kenney.nl](https://kenney.nl)) |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://kenney.nl/assets/particle-pack |
| **Vendor path** | `kenney_particle_pack/` |
| **How used** | Soft particle stamps for GPU particles: circle, spark, glow/light, star, magic, smoke, flare. Driven via `AssetPaths` + `FX.spark_particles` / `FX.burst_particles` (crystal motes, combat bursts, tower fire, build complete). |

Only transparent PNGs are kept (black-background / Unity sample trees removed to save space).

---

## Kenney UI Pack

| | |
|---|---|
| **Author** | Kenney Vleugels ([kenney.nl](https://kenney.nl)) |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://kenney.nl/assets/ui-pack |
| **Vendor path** | `kenney_ui_pack/` |
| **How used** | Grey `button_rectangle_depth_flat` as `StyleBoxTexture` nine-patch on HUD top bar, pause panel, and end panel (`FX.style_panel_kenney`). |

Trimmed to Grey/Default PNG set only.

---

## Kenney Smoke Particles

| | |
|---|---|
| **Author** | Kenney Vleugels ([kenney.nl](https://kenney.nl)) |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://kenney.nl/assets/smoke-particles |
| **Vendor path** | `kenney_smoke_particles/` |
| **How used** | White puff + flash textures for death/impact smoke via particle kind `"puff"` / `"flash"`. |

---

## Kenney Roguelike Caves & Dungeons

| | |
|---|---|
| **Author** | Kenney Vleugels ([kenney.nl](https://kenney.nl)) |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://kenney.nl/assets/roguelike-caves-dungeons |
| **Vendor path** | `kenney_roguelike_caves_dungeons/` |
| **How used** | Spritesheet path exposed in `AssetPaths` for future dungeon tiles; not yet drawn in the ritual-forest map layout. |

---

## Seasons of Forest free sample

| | |
|---|---|
| **Author** | Inkbubi (itch.io) |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://opengameart.org/content/seasons-of-forest-free-sample (full set: https://inkbubi.itch.io/seasons-of-forest-tileset) |
| **Vendor path** | `seasons_of_forest_free/` |
| **How used** | Trees, stones, bushes, grass sprites scattered at map edges and thickets (`ground_visual.gd`), scaled ~2–4× with nearest-neighbor filter and purple-green modulate. |

Nested demo Godot project / duplicates stripped; textures only + license.

---

## Forest / Graveyard tileset

| | |
|---|---|
| **Author** | marionline |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://opengameart.org/content/forest-graveyard-tileset |
| **Vendor path** | `forest_graveyard_tileset/` |
| **How used** | Small tileset PNG kept for future tilemap work; not wired into the current ground scatter. |

---

## DawnLike — 16×16 Universal Rogue-like tileset v1.81

| | |
|---|---|
| **Author** | DragonDePlatino; palette by DawnBringer |
| **License** | [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| **Source** | https://opengameart.org/content/dawnlike-16x16-universal-rogue-like-tileset-v181 |
| **Vendor path** | `dawnlike/` |
| **How used** | Demon (and undead fallback) 16×16 cells as nightspawn `Sprite2D` bodies; tree atlas available as forest fallback. |

**Required credit:** DawnBringer (palette) and DragonDePlatino (art). License also asks that the hidden “Platino” reptile sprite be used somewhere in products that ship DawnLike — easter-egg friendly for a later build; characters + tree objects are the integration surface for v0.

---

## Not found / skipped

| Pack | Reason |
|---|---|
| Kenney Input Prompts Pixel 16 | Page 404 at https://kenney.nl/assets/input-prompts-pixel-16 |

---

## Integration entry points

- `scripts/asset_paths.gd` (autoload `AssetPaths`) — path constants + texture cache
- `scripts/fx.gd` (autoload `FX`) — particle textures + UI panel styling
- `scripts/ground_visual.gd` — forest prop scatter
- `scripts/enemy.gd` — DawnLike nightspawn sprites
- `scripts/player.gd` / `tower.gd` / `tower_site.gd` — combat / build particle bursts

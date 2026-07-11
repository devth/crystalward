# Third-party assets

Vendored free game art used by Crystalward. Prefer **CC0** packs; DawnLike is **CC-BY 4.0** and one grotesque creature is **CC-BY 3.0** (attribution required).

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

## Kenney Top-down Shooter (trimmed)

| | |
|---|---|
| **Author** | Kenney Vleugels ([kenney.nl](https://kenney.nl)) |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://kenney.nl/assets/top-down-shooter |
| **Vendor path** | `kenney_top_down_shooter/` |
| **How used** | Zombie / robot stand frames kept as optional dark-tone character references; primary nightspawn still use DawnLike organic sheets. Full modern-human cast stripped. |

---

## Seasons of Forest free sample

| | |
|---|---|
| **Author** | Inkbubi (itch.io) |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://opengameart.org/content/seasons-of-forest-free-sample (full set: https://inkbubi.itch.io/seasons-of-forest-tileset) |
| **Vendor path** | `seasons_of_forest_free/` |
| **How used** | Trees, stones, bushes, grass sprites scattered across the large map (`ground_visual.gd`), scaled ~2–4× with nearest-neighbor filter and purple-green modulate. |

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

## Misc. Dark Fantasy Scenery Sprites

| | |
|---|---|
| **Author** | ETTiNGRiNDER |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://opengameart.org/content/misc-dark-fantasy-scenery-sprites |
| **Vendor path** | `misc_dark_fantasy_scenery/` |
| **How used** | Packed scenery sheet sliced and scattered as far-map props (`ground_visual.gd`). |

---

## Dark Fantasy item sprites

| | |
|---|---|
| **Author** | ETTiNGRiNDER |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://opengameart.org/content/dark-fantasy-item-sprites |
| **Vendor path** | `dark_fantasy_items/` |
| **How used** | Item sheet cells as ritual debris / idol crumbs mid-far from the crystal; optional crystal base under lightwell glow. |

---

## Assorted 32×32 creatures

| | |
|---|---|
| **Author** | Buch |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://opengameart.org/content/assorted-32x32-creatures |
| **Vendor path** | `assorted_32x32_creatures/` |
| **How used** | Random nightspawn skin pool (organic critters) via `AssetPaths.random_enemy_skin()`. |

---

## 50 monochrome 32×32 critters (CC0)

| | |
|---|---|
| **Author** | Stephen "Redshrike" Challener / others as listed on OGA |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://opengameart.org/content/50-monochrome-32-by-32-critters-cc0 |
| **Vendor path** | `critters_32x32_cc0/` |
| **How used** | Occasional nightspawn skins with heavy red-purple modulate. |

---

## Haunted Forest Trees

| | |
|---|---|
| **Author** | ETTiNGRiNDER |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://opengameart.org/content/haunted-forest-trees |
| **Vendor path** | `haunted_forest_trees/` |
| **How used** | Spooky tree stamps mixed into large-map forest scatter. |

---

## Limbo Land monster sprites

| | |
|---|---|
| **Author** | bevouliin.com |
| **License** | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| **Source** | https://opengameart.org/content/limbo-land-monster-sprites-0 |
| **Vendor path** | `limbo_land_monsters/` |
| **How used** | Rare large organic nightspawn (idle frames scaled down) for Dark Crystal–esque silhouettes. GIF previews stripped. |

---

## 64×64 Pixel Art: Grotesque Surreal Creature 7

| | |
|---|---|
| **Author** | Henrique Lazarini (page credit on OGA) |
| **License** | [CC-BY 3.0](https://creativecommons.org/licenses/by/3.0/) |
| **Source** | https://opengameart.org/content/64x64-pixel-art-grotesque-surreal-creature-7 |
| **Vendor path** | `grotesque_surreal_creature/` |
| **How used** | Rare nightspawn skin (heavily scaled) — weird organic puppet vibe. |

**Required credit** when this asset is used: author as listed on the OGA page.

---

## DawnLike — 16×16 Universal Rogue-like tileset v1.81

| | |
|---|---|
| **Author** | DragonDePlatino; palette by DawnBringer |
| **License** | [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| **Source** | https://opengameart.org/content/dawnlike-16x16-universal-rogue-like-tileset-v181 |
| **Vendor path** | `dawnlike/` |
| **How used** | **Characters inventory** (frame 0/1 walk pairs): Aquatic, Avian, Cat, Demon, Dog, Elemental, Humanoid, Misc, Pest, Plant, Player, Quadraped, Reptile, Rodent, Slime, Undead. **Objects:** Tree0/Tree1. Wardens use Elemental / Plant / Humanoid cells with moss-purple modulate. Nightspawn randomize Demon, Undead, Pest, Quadraped, Slime, Plant (+ other packs). Tree cells as crystal base / forest fallback. |

**Required credit:** DawnBringer (palette) and DragonDePlatino (art). License also asks that the hidden “Platino” reptile sprite be used somewhere in products that ship DawnLike — easter-egg friendly for a later build.

---

## Not found / skipped

| Pack | Reason |
|---|---|
| Kenney Input Prompts Pixel 16 | Page 404 at https://kenney.nl/assets/input-prompts-pixel-16 |
| itch.io exclusive packs | Login wall — skipped per project policy |

---

## Integration entry points

- `scripts/asset_paths.gd` (autoload `AssetPaths`) — path constants, DawnLike cells, `warden_skin()`, `random_enemy_skin()`
- `scripts/fx.gd` (autoload `FX`) — particle textures + UI panel styling
- `scripts/ground_visual.gd` — large-map forest / scenery scatter + landmarks
- `scripts/enemy.gd` — varied nightspawn sprites
- `scripts/player.gd` — Dark Crystal–esque warden sprites + aura
- `scripts/main.gd` — extra essence / tower / spawn markers for big map
- `scripts/tower.gd` / `tower_site.gd` — combat / build particle bursts

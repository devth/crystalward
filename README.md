# Crystalward

Local co-op **action tower defense** — wardens protect a sacred crystal from the soft dark.

Tone: *The Dark Crystal* × *Legend* (1980s dark fantasy). Pacing: action RTS (high APM).  
**Look:** PixelJunk-inspired — bold sprite outlines, lush moss ground, living tree-towers, soft bloom/vignette, readable cream UI.

**Players:** 1–2 local in v0 (pad slots ready for more) · **any player can do any job**  
**Stack:** Godot 4 · isometric-ish 2.5D presentation · shared bank

### Map scale

The ritual forest is **large**: floor ~±2200, soft player/camera bounds ~±1800, camera roam radius ~1400 from the crystal with light pull (0.08). Path arteries radiate far from the lightwell; essence wells and tower pads spawn in wide rings; nightspawn approach from distant markers (≈800–1400 out). Walk outward — the forest thickets and stone circles keep going.

## Play (macOS)

1. Install [Godot 4.3+](https://godotengine.org/download) (or `brew install --cask godot`).
2. Open this folder in Godot, or from a terminal:

```bash
cd ~/crystalward
godot --path .
```

3. **Title → Campaign** map select → battle. Progress saves unlocks.

### Flow
- **Title** — Play Campaign / Quick Battle / Quit (+ music)
- **Campaign** — 6 maps, difficulty, stars, unlock path
- **Battle** — 6 tower types, paths, call-wave, lives, co-op heroes

### Controls

| | P1 | P2 |
|---|---|---|
| Move | WASD | Arrows |
| Gather | E (hold, ground only) | `.` (hold, ground only) |
| Queue tower | Q | `,` |
| Attack | **C** | `/` |
| Jump / double-jump | **Space** | **Shift** |
| **Pause / help** | **Esc** or **P** or pad **Start** | same |
| Restart | R | R |

In-game: **Esc / Start** opens the full controls panel and pauses. Press again to resume.

Switch Pro / Joy-Cons: device 0 → P1, device 1 → P2 (A gather, B attack, X build — layout may vary by OS mapping).

### Loop (Kingdom Rush × co-op heroes)

- Shared **Essence** (💰). Kills pay bounty; gather wells along paths for more.
- **Stone build pads** → **Q** build / upgrade (Lv1–3). Near pad **E** sells (60% refund) if not gathering.
- **T / LB** = **Call Wave early** for bonus gold (prep phase only).
- **F / Y** = summon **fairy** (20 Essence, max 6) — auto-**loot** + auto-**gather**.
- **Space / RB** = **jump** + **double jump**. Campaign → Powers for permanent auras (dust).
- **1 Rush** (sprint) · **2 Skybound** (super jumps) · **3 Dire Strike** (lunge nearest foe) — temporary CDs for emergencies.
- Nightspawn march **path lanes**; leaks cost **Lives** (♥). Stars 1–3 on victory.
- Towers auto-fire (prefer enemies closest to crystal); floating dmg/+gold text.
- Survive **8 waves**. **R** restart. Esc pause. Minimap top-right.

## Spec

- Living design: [`docs/SPEC.md`](docs/SPEC.md)
- Towers, upgrades, synergies, matchups: [`docs/TOWERS.md`](docs/TOWERS.md)

## Third-party assets

Free (mostly **CC0**) art is vendored under [`assets/third_party/`](assets/third_party/) — Kenney particles/UI/smoke/top-down, Seasons of Forest, DawnLike (CC-BY 4.0), dark fantasy scenery/items, assorted organic creatures, haunted trees, limbo monsters, and one CC-BY grotesque creature.

Full author / license / usage list: [`assets/third_party/ATTRIBUTION.md`](assets/third_party/ATTRIBUTION.md).

Wardens and nightspawn use **pixel creature sheets** (DawnLike elemental/demon/undead/pest/etc.) with purple-moss modulate for a puppet-like Dark Crystal read.

## Agent notes

See [`AGENTS.md`](AGENTS.md) — default branch `master`, push after meaningful work.

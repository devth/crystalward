# Crystalward — Living Design Spec

> **Status:** draft / living  
> **Last updated:** 2026-07-10  
> **How to use:** This is the product source of truth. Update it when we make decisions; do not let code drift from it without a note here.

---

## Tech stack (locked)

| Item | Decision |
|---|---|
| **Engine** | **Godot 4** |
| **Presentation** | **Isometric 2.5D** |
| **Default branch** | `master` |

---

## 1. One-liner

**Crystalward** is a local co-op action tower defense game: 1–4 players walk a living dark-fantasy map, gather, build, and fight under high APM pressure to protect the Crystal / Lightwell from night surges.

---

## 2. Tone & references

| Pull from | Leave behind |
|---|---|
| *The Dark Crystal* — sacred crystal, puppet-creature weirdness, prophecy, tactile materials | Pure synthwave / CRT neon metal |
| *Legend* (1985) — soft dark fairy tale, forest botanical beauty, beauty + soft dark | Grimdark gore-first |
| Action RTS (*StarCraft*) — constant decisions, hotkeys, multitasking, no idle downtime | Casual “stand and dance towers up” pacing |
| PixelJunk Monsters — shared-screen co-op, walk-the-map builders, defend a home | Low APM, long idle build rituals |
| *Kingdom Rush* — fixed build pads, kill bounties, call-early waves, lives, stars, range rings, upgrade/sell, floating gold/dmg | Pure pure-click god-game with no hero on the field |

**Art direction (target):** warm amber crystal light vs cold blue/violet night; moss, bone, bark, cloth, crystal; slight practical/puppet *feel* even in digital art. Silhouette-readable units.

**Map palette (implementation):** deep teal–moss floor under violet mist pools; paths of bark/bone with amber dust veins + soft violet glow; Lightwell plaza = amber heart in cyan/violet rings; canopy trees cool blue-green (not lime); fireflies amber + cyan + violet. Avoid flat dull olive and pure grey mud.

**Working fiction:** Wardens guard a **Lightwell** that cradles a **Crystal**. Nightspawn and thralls push paths toward it. Players **awaken** map features (roots, standing stones, ruins, thorn gates) into defenses, fight on the field, and scramble economy under wave pressure.

---

## 3. Design pillars

1. **Protect the light** — The Crystal / Lightwell is the win condition and emotional center.
2. **Anyone can do anything** — No locked roles. Every player has the full verb set. Coordination is social, not class-gated.
3. **APM over ceremony** — The skill ceiling is *thinking and acting fast*: pathing, build queues, micro, callouts. Standing still should feel wrong.
4. **Shared screen, shared fate** — Local co-op first. One map, one economy (or clearly shared stakes), one loss condition.
5. **Map is the tech tree** — Defenses come from transforming / claiming map features and structures, not only abstract build menus.
6. **Readable chaos** — High action density must stay legible for 2–4 players on one screen.

---

## 4. Players & platform

| Item | Decision |
|---|---|
| Players | **1–4 local** (design for 2 first; 3–4 must not break economy or UI) |
| Input | Keyboard + mouse; **Nintendo Switch Pro / Joy-Cons** on macOS (native Game Controller) |
| Host | MacBook (dev + primary play target for v0) |
| View | Shared single screen (no split-screen unless proven necessary) |
| Online | **Out of scope for v0** (local only) |

### Co-op model: full flexibility

- Every warden can: **move, gather, build/upgrade, attack, repair, interact, spend**.
- No role select screen. No “builder class” vs “fighter class.”
- Skill expression = *who covers which fire*, not loadout locks.
- Friendly-fire / grief: avoid hard trolling (no stealing exclusive build slots permanently); prefer shared progress and clear feedback when two players contest the same action.
- Optional later: cosmetics / slight preference loadouts that do **not** remove verbs.

---

## 5. Core loop (high APM)

### Session structure

1. **Brief calm** — scout path, claim first nodes, seed early defenses.
2. **Surge** — wave(s) of nightspawn; multitask defense + income + tech.
3. **Between surges** — short, *not* leisurely; re-bank, re-wall, expand, re-spec under a timer or incoming threat.
4. **Boss / conjunction beat** — spike intensity; all hands.
5. **Win** (crystal survives N surges / dawn) or **Lose** (crystal integrity hits 0).

### Always-on verbs (StarCraft-shaped)

Players should almost always be choosing among:

| Verb | Notes |
|---|---|
| **Move / path** | Continuous map presence; no “god cursor only” for primary play |
| **Gather / deposit** | Income requires action (nodes, drops, carries) — design for multiplayer contention without grief |
| **Build / claim** | Convert map features or place structures with **fast** confirm (not long channel dances) |
| **Upgrade / tech** | Hot, interruptible or queue-based; minimize forced stand-still |
| **Fight / spell** | Field combat + tower support; micro matters |
| **Repair / triage** | Crystal, towers, gates under pressure |
| **Macro call** | Minimap pings, camera nudges (if useful), shared alerts |

**Anti-pattern (explicit):** long “dance / channel / stand on tile” build rituals as the main progression. Build and upgrade may have *short* cast or queue times for balance, but the fantasy is **snap decisions and constant motion**, not AFK stacking.

### Pacing targets (soft; tune in playtests)

- Solo / duo should feel busy by mid-game: multiple fronts, income, and tech decisions overlapping.
- Downtime between meaningful actions ideally **seconds**, not tens of seconds of forced idle.
- Complexity scales with player count by **more simultaneous fires**, not by inventing exclusive jobs.

---

## 6. Economy & map features

### Resources (locked)

| Resource | Role |
|---|---|
| **Essence** | Common currency — income, basic builds, repairs |
| **Crystal dust** | Rare currency — heavy upgrades / big tech |

- **Wallet:** **one shared bank** for all players. Crystal integrity is always shared. Spend feedback should show *who* spent what so silent bank-draining is visible.
- **Sources:** map nodes, enemy drops, optional crystal “tithe” risk/reward (tune later).
- **Towers / defenses:** primarily **claimed world objects** (thorns, stones, ruins, root-gates) plus a small set of placeables if needed for readability. Full roster, synergies, and matchups: [`TOWERS.md`](TOWERS.md).
- **Build timing:** **queue** — start a build/upgrade, leave while it finishes (RTS multitask). No long stand-and-dance channels.
- **Node contest:** **shared progress** — multiple wardens contribute to the same gather/build bar; no hard grief steals.
- **Tech:** upgrades on structures + global or semi-global unlocks that all players can trigger.
- **Expansion:** claiming farther nodes increases income and path pressure (risk/reward).

---

## 7. Combat & units (draft)

- **Nightspawn** follow **authored path lanes** (`PathNetwork` autoload) from outer portals into the Lightwell — multi-segment polylines with lateral road slack, not pure free-path chase.
- Variety later: armor, speed, swarm, siege, flyer (keep flyer count low for readability). **Elites** spawn mid-campaign (larger, tougher, bonus Essence/dust).
- **Wardens** are fragile-to-medium heroes: useful in a fight, not a full substitute for towers.
- **Towers** do the bulk of wave DPS; players multiply value via placement, upgrades, and focus-fire micro.
- **Bosses / lieutenants:** telegraphed specials, multi-phase attention checks (APM spikes).

---

## 8. Win / lose

| Outcome | Condition (v0 prototype) |
|---|---|
| **Victory** | Survive **8 surges** (dawn) with crystal integrity > 0 |
| **Defeat** | Crystal integrity reaches 0 (or Lightwell destroyed) |

Lives / integrity should be **shared** and highly visible (screen edge glow, crystal UI, juice flash/shake on crystal hits).

---

## 9. Camera & controls

### Camera (locked)

- **Centroid follow** on a shared screen: camera tracks the center of active wardens.
- Clamp / bias so the **Crystal / Lightwell** stays relevant (not dragged off forever by a straggler).
- **Pings + minimap** required for callouts under multi-front pressure.
- Solo may allow freer pan/zoom later if it doesn’t break co-op defaults.

### Controls (draft principles)

- **Gamepad-first** for couch co-op; keyboard+mouse must remain first-class for high-APM solo.
- Face buttons / triggers bound to **high-frequency verbs** (build confirm, attack, gather, upgrade, ping).
- Avoid deep menu stacks mid-fight; radial or contextual build preferred.
- Multi-Joy-Con: each Joy-Con or Pro Controller = one player.

*Exact bindings: TBD in prototype.*

---

## 10. Scope ladder

### v0 — vertical slice (in repo — playable)

- Godot 4 project at repo root (`project.godot`, `scenes/main.tscn`)
- Large ritual forest map: glowing **path network** (12 lanes), zone labels, path-aligned essence wells + tower sites
- Crystal HP, queueable towers, path-following nightspawn (+ elites from surge 2+)
- 2 local players (keyboard + gamepad device 0/1)
- Shared Essence bank; Crystal dust drops (rare)
- **8 surges** win / crystal 0 lose; **R** restart; Esc/Start pause + controls
- **Polish systems:** `PathNetwork`, `Juice` (shake/flash/hitstop), `Sfx` (procedural WAV), minimap, Kenney particles/UI, pixel creature skins
- Atmosphere: moss shader ground, mist, path glow, ambient motes

### v1 — real session

- More defenses / enemies / 1 boss
- Clear economy curve for 2 and 4 players
- Tutorial / first-run guidance without killing APM (optional practice calm)

### Later (not now)

- Online multiplayer
- Campaign / many maps
- Heavy narrative production
- Ranked / asymmetric roles

---

## 11. Non-goals (for now)

- Locked classes or mandatory role queue
- Long idle build ceremonies as core progression
- PixelJunk Monsters clone fidelity over action-RTS tension
- Mobile touch-first controls
- Licensed *Dark Crystal* / *Legend* IP (spiritual tone only)

---

## 12. Open questions

Prior round closed. Next decisions when we hit them:

| # | Question | Status |
|---|---|---|
| — | Exact gamepad/keyboard bindings | Open — prototype |
| — | Win condition numbers (surge count, crystal HP) | **Closed for v0** — 8 surges, 120 crystal HP |
| — | First map layout / path topology | **Closed for v0** — 12 authored lanes via `PathNetwork` |
| — | Tower kit detail | See [`TOWERS.md`](TOWERS.md); implement T1+ over time |
| — | Enemy kit / tags implementation | Open — tags defined in TOWERS.md |

---

## 13. Decision log

| Date | Decision |
|---|---|
| 2026-07-10 | Title: **Crystalward** |
| 2026-07-10 | Theme: 80s dark fantasy (*Dark Crystal* / *Legend*), not synth-metal neon |
| 2026-07-10 | Co-op: any player can do any job |
| 2026-07-10 | Pacing: high APM / action-RTS emphasis over Monsters-style idle dancing |
| 2026-07-10 | Platform target: MacBook + Nintendo Switch controllers; local 1–4 |
| 2026-07-10 | Living spec lives in `docs/SPEC.md` |
| 2026-07-10 | Engine: **Godot 4** |
| 2026-07-10 | Presentation: **isometric 2.5D** |
| 2026-07-10 | Economy: **shared bank**; resources **Essence** + **Crystal dust** |
| 2026-07-10 | Build timing: **queue** (no long channels) |
| 2026-07-10 | Camera: **centroid follow** + pings/minimap |
| 2026-07-10 | Node contest: **shared progress** |
| 2026-07-10 | Git default branch: **master** |
| 2026-07-11 | Tower design doc: [`TOWERS.md`](TOWERS.md) (8 types, auras, matchups) |
| 2026-07-11 | Kingdom Rush inspiration: lives, kill gold, call-early, upgrade/sell, range rings, stars, floating text |
| 2026-07-10 | Path-following enemies via `PathNetwork` (12 lanes → Lightwell) |
| 2026-07-10 | Campaign length: **8 surges**; elites mid-run; juice + procedural SFX + minimap polish |

---

## 14. Glossary

| Term | Meaning |
|---|---|
| **Crystal / Lightwell** | The shared objective to protect |
| **Warden** | A player-controlled hero |
| **Nightspawn** | Standard enemies |
| **Essence** | Common shared-bank currency |
| **Crystal dust** | Rare shared-bank currency |
| **Claim / awaken** | Turn a map feature into a defense or income node |
| **Surge** | A wave or wave-group of nightspawn |
| **Conjunction** | Optional climax beat / stage finale naming |

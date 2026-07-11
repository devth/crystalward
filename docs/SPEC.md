# Crystalward — Living Design Spec

> **Status:** draft / living  
> **Last updated:** 2026-07-10  
> **How to use:** This is the product source of truth. Update it when we make decisions; do not let code drift from it without a note here.

---

## 1. One-liner

**Crystalward** is a local co-op action tower defense game: 1–4 players walk a living dark-fantasy map, gather, build, and fight under high APM pressure to protect the Crystal / Lightwell from night surges.

---

## 2. Tone & references

| Pull from | Leave behind |
|---|---|
| *The Dark Crystal* — sacred crystal, puppet-creature weirdness, prophecy, tactile materials | Pure synthwave / CRT neon metal |
| *Legend* (1985) — soft dark fairy tale, forest vs eternal night, beauty + horror | Grimdark gore-first |
| Action RTS (*StarCraft*) — constant decisions, hotkeys, multitasking, no idle downtime | Casual “stand and dance towers up” pacing |
| PixelJunk Monsters — shared-screen co-op, walk-the-map builders, defend a home | Low APM, long idle build rituals |

**Art direction (target):** warm amber crystal light vs cold blue/violet night; moss, bone, bark, cloth, crystal; slight practical/puppet *feel* even in digital art. Silhouette-readable units.

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

## 6. Economy & map features (draft)

> Details TBD; principles only until prototype.

- **Resources:** at least one primary (e.g. **essence / amber**) and possibly a second rare (e.g. **shard dust**) for big tech.
- **Sources:** map nodes, enemy drops, optional crystal “tithe” risk/reward.
- **Towers / defenses:** primarily **claimed world objects** (thorns, stones, ruins, root-gates) plus a small set of placeables if needed for readability.
- **Tech:** upgrades on structures + global or semi-global unlocks that all players can trigger.
- **Expansion:** claiming farther nodes increases income and path pressure (risk/reward).

---

## 7. Combat & units (draft)

- **Nightspawn** follow paths / aggro rules toward the Lightwell; variety by armor, speed, swarm, siege, flyer (keep flyer count low for readability).
- **Wardens** are fragile-to-medium heroes: useful in a fight, not a full substitute for towers.
- **Towers** do the bulk of wave DPS; players multiply value via placement, upgrades, and focus-fire micro.
- **Bosses / lieutenants:** telegraphed specials, multi-phase attention checks (APM spikes).

---

## 8. Win / lose

| Outcome | Condition (draft) |
|---|---|
| **Victory** | Survive the stage’s surges / reach dawn / complete the conjunction ritual |
| **Defeat** | Crystal integrity reaches 0 (or Lightwell destroyed) |

Lives / integrity should be **shared** and highly visible (screen edge glow, crystal UI).

---

## 9. Controls (draft principles)

- **Gamepad-first** for couch co-op; keyboard+mouse must remain first-class for high-APM solo.
- Face buttons / triggers bound to **high-frequency verbs** (build confirm, attack, gather, upgrade, ping).
- Avoid deep menu stacks mid-fight; radial or contextual build preferred.
- Multi-Joy-Con: each Joy-Con or Pro Controller = one player.

*Exact bindings: TBD in prototype.*

---

## 10. Scope ladder

### v0 — vertical slice (prove the feel)

- 1 map, 1 crystal, 2–3 enemy types, 2–3 defense types
- 1–2 players fully supported; 3–4 controllers connect without breaking
- Full verb set on every player
- Wave structure + lose condition
- Mac + Switch controllers validated

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

Track decisions here as we close them.

| # | Question | Status |
|---|---|---|
| 1 | Engine (Godot 4 vs other)? | Open |
| 2 | 2D vs 2.5D presentation? | Open |
| 3 | Shared wallet vs per-player wallets with shared crystal? | Open — lean shared stakes |
| 4 | Exact resource names & counts? | Open |
| 5 | Build confirm: instant place vs short cast vs queue? | Open — lean short/queue, not long channel |
| 6 | Camera: free per-player vs shared locked? | Open — lean shared with smart focus |
| 7 | How hard can players contest the same node? | Open |

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

---

## 14. Glossary

| Term | Meaning |
|---|---|
| **Crystal / Lightwell** | The shared objective to protect |
| **Warden** | A player-controlled hero |
| **Nightspawn** | Standard enemies |
| **Claim / awaken** | Turn a map feature into a defense or income node |
| **Surge** | A wave or wave-group of nightspawn |
| **Conjunction** | Optional climax beat / stage finale naming |

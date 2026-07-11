# Crystalward — Tower Design

> **Status:** **6 of 8 core types implemented** in v0 code (`TowerTypes` + `tower.gd`): Thornspire, Shardbow, Mistvent, Hex Lantern, Hearthstone, Bonehowl. Rootgate + Skyshard remain design-only (T3–T4).  
> **Last updated:** 2026-07-10  
> **Parent:** [`SPEC.md`](SPEC.md)  
> **How to use:** Source of truth for defense types, upgrades, auras, and matchups. Tune numbers in playtests; keep *roles* and *interactions* stable unless we deliberately rework the system.

---

## 1. Design goals

More complex than PixelJunk Monsters: not just “DPS / slow / bomb,” but a **small composition puzzle** under high APM.

| Goal | Meaning |
|---|---|
| **Readable roles** | Each tower answers “what is this for?” in under a second (silhouette + color + VFX). |
| **Composition matters** | 2–3 tower types in range of each other should feel stronger than the same count isolated — without requiring a wiki. |
| **Matchups** | Monsters have tags; towers have strengths/weaknesses. Wrong line dies; right line thrives. |
| **Opportunity cost** | Every pad / site is precious. Upgrading A vs placing B is a real choice. |
| **Co-op friendly** | No class-locked builders. Anyone can queue any tower/upgrade from the shared bank. |
| **APM-safe** | Synergies are mostly **passive auras / adjacency**, not minigames that force standing still. |

**Anti-goals:** 20 near-identical turrets; invisible math; mandatory perfect grids; soft-lock failing a stage because one tower is “the only answer.”

---

## 2. Core rules

### 2.1 Claiming & queueing

- Most defenses start as **map sites** (standing stone, thorn ring, root-gate, ruin socket, mist vent, bone spire, etc.).
- Wardens **queue** a tower type on an empty site (or convert within rules — see §6).
- Queue uses **Essence** (base) and sometimes **Crystal dust** (advanced / high tiers).
- Build finishes while players leave (no long channels).

### 2.2 Levels

Every tower has levels **I → II → III** (plus rare **Conjunction** capstone on one site per stage — optional later).

| Level | Typical cost | Effect |
|---|---|---|
| **I** | Essence only | Role online |
| **II** | Essence + small dust | Bigger numbers + one branch choice *or* fixed upgrade path (v1: fixed path for simplicity) |
| **III** | Essence + more dust | Role peak + unlocks stronger aura / special |

**v1 upgrade model (recommended):** single linear path per tower type (fewer decisions mid-fight).  
**v2 optional:** at II, pick **A/B branch** (e.g. Thornspire: *Barbed* vs *Reaching*).

### 2.3 Adjacency & aura range

- **Adjacency** = towers whose **footprints** or **aura circles** overlap (prefer circle radius in world units, not chess-king, so isometric stays fair).
- Auras tick continuously; no “dance to activate.”
- **Aura stacking:** same aura type from multiple sources uses **diminishing returns** (e.g. 100% + 50% + 25%) unless noted as unique.
- **Hard cap:** a tower may receive at most **3 different buff aura types** at once (keeps UI/VFX sane).

### 2.4 Targeting & tags

Towers and monsters use **tags**. Combat is tag-aware, not pure HP races.

**Monster tags (see also enemy design later):**

| Tag | Fantasy | Typical threat |
|---|---|---|
| **Swarm** | Many small thralls | Overwhelm single-target; weak to splash / thorns |
| **Armored** | Bone plate, carapace | Soak physical; weak to shatter / light pierce |
| **Swift** | Skitterers, hounds | Rush crystal; weak to root / slow / snares |
| **Siege** | Crystal-eaters, brutes | High crystal damage; must be focused |
| **Shade** | Semi-ethereal | Resist solid projectiles; weak to light / mist-burn |
| **Flyer** | Rare wing-things | Ignores ground thorns/paths; weak to skyward / beam |
| **Elite** | Named lieutenant pack leaders | Buffs nearby nightspawn; worth focus fire |
| **Boss** | Surge finale | Phases, telegraphs; multi-role response |

**Damage channels:**

| Channel | Color cue | Notes |
|---|---|---|
| **Thorn** (physical/nature) | Green | Baseline; strong vs Swarm, weak vs Armored/Shade |
| **Light** (crystal/radiant) | Amber | Strong vs Shade/Elite; can overheat or cost dust upkeep on high tiers |
| **Shatter** (sonic/force) | Blue-white | Strong vs Armored; weak vs Swarm (overkill) |
| **Mist** (arcane/decay) | Violet | DoTs, soft CC; strong vs Swift; less burst |
| **Hex** (curse) | Magenta | Debuffs, mark for allies; low raw DPS |

---

## 3. Tower roster

Eight core types for full game. **v0 prototype** may ship 1–3; this doc defines the full kit so placement and economy can be planned.

### Legend for stat columns (relative, not final numbers)

- **DPS:** single-target damage rate  
- **AoE:** splash / multi  
- **CC:** slow, root, stun, fear  
- **Utility:** buffs, marks, vision, economy  
- **Range:** short / med / long  
- **Cost tier:** £ / ££ / £££ (Essence + dust weight)

---

### 3.1 Thornspire — *barbed root pillar*

| | |
|---|---|
| **Role** | Primary ground DPS / lane melt |
| **Site fantasy** | Awakened thorn ring or living oak |
| **Damage** | Thorn |
| **Tags** | `dps`, `ground`, `physical` |
| **Range** | Medium |
| **Cost tier** | £ |

**Behavior**

- Fires spiked roots at nearest valid ground target in range.
- Small pierce (I: 1 target, II: 2, III: 3) along a short line.

**Pros**

- Best generalist vs **Swarm** and unarmored packs.
- Cheap to mass; forms the “spine” of a line.

**Cons**

- Poor vs **Armored** and **Shade**.
- No flyer attack.
- Pure DPS — dies in value if enemies are kited past or immune tags dominate.

**Upgrades**

| Lv | Name | Effect |
|---|---|---|
| I | Thornspire | Single / light pierce root shots |
| II | Barbed Growth | +DPS, pierce +1, slight attack speed |
| III | Heartwood Lance | High pierce thorn lance; on-kill thorn nova (small) |

**Auras given**

- **Briarlink (III only, short radius):** adjacent `dps` towers +attack speed (small).

**Auras wanted**

- Loves **Hearthstone** cadence, **Hex Lantern** marks, **Mistvent** slows (more time on target).

---

### 3.2 Shardbow — *crystal ballista*

| | |
|---|---|
| **Role** | Long-range single-target / priority |
| **Site fantasy** | Ruin socket or crystal tripod |
| **Damage** | Light (+ mild Shatter on III) |
| **Tags** | `dps`, `long_range`, `priority` |
| **Range** | Long |
| **Cost tier** | ££ |

**Behavior**

- Slow, heavy bolts. Prefers **Elite / Siege / Boss** if in range, else highest max-HP.
- Projectiles are **hitscan or very fast** so high APM micro still feels fair.

**Pros**

- Deletes **Siege** and **Elite** before they reach the well.
- Strong vs **Shade** (Light).

**Cons**

- Awful vs **Swarm** (overkill, slow RoF).
- Expensive; bad when starved of Essence mid-surge.
- Blind spots if placed with no vision of path bends (no true fog in v0, but long min-range optional later).

**Upgrades**

| Lv | Name | Effect |
|---|---|---|
| I | Shardbow | Heavy Light bolt, priority targeting |
| II | Focusing Rail | +damage, slight RoF; marks target briefly for +taken damage |
| III | Sunstring | Bolt splits to 1 nearby enemy; minor Shatter vs Armored |

**Auras given**

- **Spotter (II+):** adjacent towers gain +range (small, non-stacking globally per tower).

**Auras wanted**

- **Hex Lantern** (mark amplify), **Hearthstone** (RoF).

---

### 3.3 Mistvent — *breathing violet fissure*

| | |
|---|---|
| **Role** | Soft CC / zone control |
| **Site fantasy** | Mist vent, bog throat, fairy mire |
| **Damage** | Mist (DoT) |
| **Tags** | `cc`, `zone`, `dot` |
| **Range** | Short–medium ground aura |
| **Cost tier** | £ |

**Behavior**

- Passive field: enemies inside are **slowed** and take Mist DoT.
- Does not hard-stop; creates time for DPS towers and wardens.

**Pros**

- Excellent vs **Swift**.
- Multiplies whole line’s effective DPS by dwell time.
- Cheap glue tower.

**Cons**

- Low kill power alone — pure Mistvent lines **leak**.
- Weak vs **Siege** (they tank the field and walk through).
- Flyers ignore ground mist (unless III branch later).

**Upgrades**

| Lv | Name | Effect |
|---|---|---|
| I | Mistvent | Slow + light DoT aura |
| II | Choking Bloom | Stronger slow; DoT stacks up to 3 |
| III | Dreamhaze | Occasional brief root pulse; DoT can spread once on death |

**Auras given**

- **Clinging Damp (II+):** adjacent `dps` towers’ projectiles apply a **micro-slow** on hit.

**Auras wanted**

- Pairs with everything; especially **Thornspire** / **Bonehowl**.

---

### 3.4 Bonehowl — *resonant bone spire*

| | |
|---|---|
| **Role** | Anti-armor / shatter pulse |
| **Site fantasy** | Bone spire, fossil horn |
| **Damage** | Shatter |
| **Tags** | `dps`, `anti_armor`, `pulse` |
| **Range** | Medium (pulse ring) |
| **Cost tier** | ££ |

**Behavior**

- Periodic shockwave; damage scales with target **Armored** stacks/tag.
- Non-armored take reduced damage (deliberate).

**Pros**

- Best answer to **Armored** packs and plated Siege variants.
- Pulse hits groups of armors efficiently.

**Cons**

- Weak vs **Swarm** and **Shade**.
- Tempo gaps between pulses — needs Mistvent or thorns to cover gaps.

**Upgrades**

| Lv | Name | Effect |
|---|---|---|
| I | Bonehowl | Shatter pulse, anti-armor bonus |
| II | Crack Choir | Faster pulse; shreds armor tag (enemies take +Thorn for a few seconds) |
| III | Catacomb Bell | Big pulse; briefly **stuns** Armored only |

**Auras given**

- **Resonance (II+):** adjacent Shatter/Light towers +damage vs Armored.

**Auras wanted**

- **Shardbow** focus fire, **Hex Lantern** marks on armors.

---

### 3.5 Hex Lantern — *cursed lamp post*

| | |
|---|---|
| **Role** | Debuff / mark support |
| **Site fantasy** | Iron lantern, witchlight post |
| **Damage** | Hex (low) |
| **Tags** | `support`, `debuff`, `mark` |
| **Range** | Medium |
| **Cost tier** | ££ |

**Behavior**

- Attacks apply **Hex Mark** (increased damage taken from all sources).
- Passive: slight vision of stealthed/shade (when those exist).
- Low personal DPS by design.

**Pros**

- Force-multiplier for whole composition.
- Marks make **Elite/Boss** phases much cleaner.
- Enables “wrong” DPS types to still contribute.

**Cons**

- Almost never holds a lane alone.
- Priority target for enemies that **snipe supports** (if we add that behavior).
- Opportunity cost vs another DPS on tight Essence.

**Upgrades**

| Lv | Name | Effect |
|---|---|---|
| I | Hex Lantern | Apply Mark; low Hex tick |
| II | Twin Flame | Can maintain 2 marks; mark amplifies more |
| III | Wyrd Beacon | Marked deaths grant tiny shared Essence; fear pulse on Elite death |

**Auras given**

- **Witchglow (I+):** adjacent towers +damage to **marked** targets (primary synergy engine).

**Auras wanted**

- Place near **Shardbow** + **Thornspire** clusters.

---

### 3.6 Hearthstone — *warm ruin kiln*

| | |
|---|---|
| **Role** | Cadence buff / anti-shade warmth |
| **Site fantasy** | Hearth ruin, kiln stone |
| **Damage** | Light (very low aura burn) |
| **Tags** | `support`, `buff`, `anti_shade` |
| **Range** | Short aura |
| **Cost tier** | ££ |

**Behavior**

- Aura: +attack speed / shorter cooldown to allied towers in range.
- Small Light burn vs **Shade** inside aura (support that still “does something” alone).

**Pros**

- Best **buff hub** for dense builds.
- Soft answer to **Shade** blobs hugging the line.

**Cons**

- Short range — forces clumping (vulnerable to boss AoE later).
- No help vs flyers outside aura.
- Gold-inefficient if only 1 tower in radius.

**Upgrades**

| Lv | Name | Effect |
|---|---|---|
| I | Hearthstone | +AS aura; tiny Light burn |
| II | Ember Circlet | Stronger AS; burn upticks vs Shade |
| III | Dawn Kiln | Periodic empower pulse (next shot free mega-crit style) |

**Auras given**

- **Kindling (I+):** +attack speed (the main buff).
- **Ember Ward (III):** adjacent towers briefly shrug one projectile (optional complexity — cut if too much).

**Auras wanted**

- Center of **Thornspire** + **Shardbow** nests.

---

### 3.7 Rootgate — *living barricade*

| | |
|---|---|
| **Role** | Blocker / soak / path force |
| **Site fantasy** | Root-gate, thorn arch across a path |
| **Damage** | Thorn (reflect) |
| **Tags** | `tank`, `block`, `reflect` |
| **Range** | Melee / contact |
| **Cost tier** | ££ |

**Behavior**

- Occupies path: enemies **attack the gate** or path around if alternate route exists.
- Has **structure HP**; wardens can **repair** (spend Essence, shared progress).
- Reflects a portion of Thorn damage to attackers.

**Pros**

- Creates chokepoints for Mistvent + AoE.
- Buys time vs **Swift** and **Siege** (Siege deal bonus damage to gates — risk/reward).

**Cons**

- **Siege** melts gates.
- Flyers ignore.
- Blocks *friendly* pathing slightly (wardens can pass; design so players don’t get soft-locked).
- Bad in open maps with many bypasses.

**Upgrades**

| Lv | Name | Effect |
|---|---|---|
| I | Rootgate | HP block + light reflect |
| II | Ironbark | +HP, +reflect; taunt pulse (enemies prefer gate) |
| III | Sacrifice Bloom | On death: thorn nova + temporary slow field; can rebuild cheaper once |

**Auras given**

- **Brace (II+):** adjacent towers take less damage if enemies can attack towers later.

**Auras wanted**

- **Mistvent** in front, **Bonehowl** behind for armors chewing the gate.

---

### 3.8 Skyshard — *leaning crystal antenna*

| | |
|---|---|
| **Role** | Anti-air / rare flyer answer |
| **Site fantasy** | Crystal antenna, spire needle |
| **Damage** | Light |
| **Tags** | `dps`, `anti_air` |
| **Range** | Long (air), poor ground |
| **Cost tier** | ££ |

**Behavior**

- Prioritizes **Flyer**; weak ground beam (or cannot hit ground until III).
- Exists so flyer rounds aren’t “everyone panic micro.”

**Pros**

- Only reliable anti-air without warden focus.
- Long reach on air lanes.

**Cons**

- Near-dead weight on pure ground surges.
- Should stay rare on maps; 0–2 sites that *prefer* Skyshard.

**Upgrades**

| Lv | Name | Effect |
|---|---|---|
| I | Skyshard | Air-only Light beam |
| II | Needlesky | +DPS air; chain to second flyer |
| III | Firmament | Can snipe ground Elites at reduced rate; air execute threshold |

**Auras given**

- **Updraft (II+):** adjacent towers gain token anti-air damage (small) — so one Skyshard lifts a cluster.

**Auras wanted**

- **Hearthstone** for beam uptime.

---

## 4. Interaction matrix (tower ↔ tower)

Synergies are **intentional combos**, not every pair.

| Giver → Receiver | Effect (summary) |
|---|---|
| **Hex Lantern → any DPS** | Marked targets take more damage; core multiplier |
| **Hearthstone → any attack tower** | +attack speed / shorter CD |
| **Mistvent → any DPS** | Micro-slow on hit (II+); more dwell |
| **Shardbow → nearby** | Spotter +range (II+) |
| **Thornspire III → DPS** | Briarlink +AS (small) |
| **Bonehowl → Shatter/Light** | +damage vs Armored |
| **Skyshard → nearby** | Token anti-air |
| **Rootgate → nearby** | Damage reduction if structures can be attacked |

### Flagship compositions (teach in tutorial / loading tips)

1. **Briar Line:** Mistvent + Thornspire ×2 + Hearthstone  
   - Ground swarm melt; classic “Monsters+” lane.

2. **Plate Crackers:** Rootgate + Bonehowl + Hex Lantern + Shardbow  
   - Armored / siege; mark + shatter + priority.

3. **Witch Nest:** Hex Lantern + Hearthstone + mixed DPS  
   - Max aura density; vulnerable to boss AoE — spread a little.

4. **Skywatch:** Skyshard + Hearthstone + one Shardbow  
   - Flyer surge insurance without dumping whole bank into air.

5. **Soft Dark:** Mistvent + Hex + Bonehowl  
   - Shade/armor hybrid; thorns optional if essence tight.

### Anti-synergy / soft rules

- **Do not** stack 4 Hearthstones — diminishing returns + wasted pads.
- **Rootgate walls** without DPS behind them = expensive delay, not a win.
- **Skyshard-only** corners lose ground maps.

---

## 5. Matchup matrix (tower role ↔ monster tag)

Values are design intent: **S** strong, **A** good, **B** fine, **C** weak, **F** avoid as primary answer.

| Tower \ Tag | Swarm | Armored | Swift | Siege | Shade | Flyer | Elite | Boss |
|---|---|---|---|---|---|---|---|---|
| **Thornspire** | S | C | B | B | C | F | B | B |
| **Shardbow** | F | B | C | S | A | C | S | A |
| **Mistvent** | A | B | S | C | B | F | B | B |
| **Bonehowl** | C | S | C | A | F | F | B | B |
| **Hex Lantern** | B | A | B | A | A | B | S | S |
| **Hearthstone** | B | B | B | B | A | B | B | B |
| **Rootgate** | A | B | S | C* | B | F | B | C |
| **Skyshard** | F | F | F | F | C | S | C | C |

\*Siege deals **bonus damage to Rootgates** — gate is a deliberate sacrifice / time buy, not a hard counter.

### Surge composition examples

| Surge theme | Nightspawn mix | Suggested line |
|---|---|---|
| **Thrall Tide** | Swarm heavy | Mistvent + Thornspires + Hearth |
| **Iron Procession** | Armored + Siege | Bonehowl + Shardbow + Hex + optional gate |
| **Wild Hunt** | Swift | Mistvent + Rootgate + thorns |
| **Soft Dark** | Shade | Hearthstone + Shardbow + Hex |
| **Winged Blight** | Flyer pack | Skyshard + Hearth; wardens focus stragglers |
| **Lieutenant** | Elite + escort | Hex + Shardbow priority; thorns on escort |

---

## 6. Sites, conversion, and map design

### Site types (map authors place these)

| Site | Natural tower affinity | Can build |
|---|---|---|
| **Thorn ring** | Thornspire, Rootgate | Those + Mistvent |
| **Ruin socket** | Shardbow, Hex Lantern | Most non-gate |
| **Bone bed** | Bonehowl | Bonehowl, Hex |
| **Mist fissure** | Mistvent | Mistvent, Hex |
| **Hearth ruin** | Hearthstone | Hearthstone, Thornspire |
| **Antenna stub** | Skyshard | Skyshard, Shardbow |
| **Path arch** | Rootgate only | Rootgate |

**Rule of thumb:** each site offers **2–3 legal tower types** (readable radial menu). Full free choice on every pad is too fuzzy for high APM.

### Conversion

- **Salvage:** destroy owned tower, refund ~50% Essence (not dust), site empty after short queue.
- **No free morph** mid-surge without salvage (prevents churn cheese) — optional “emergency convert” with dust cost later.

---

## 7. Economy hooks

| Action | Essence | Crystal dust |
|---|---|---|
| Build I (cheap) | 20–30 | 0 |
| Build I (support / specialty) | 30–45 | 0–1 |
| Upgrade II | 25–40 | 1–2 |
| Upgrade III | 40–60 | 2–4 |
| Repair Rootgate (tick) | small | 0 |
| Salvage | refund ~50% essence | dust not refunded |

**Starting bank / node income** must support: early 2 DPS + 1 support before surge 2, without making surge 1 free.

Dust sinks are **II/III and specialty towers** so dust drops feel exciting, not mandatory for wave 1.

---

## 8. Presentation & readability

| Type | Silhouette | Palette |
|---|---|---|
| Thornspire | Tall barbed pillar | Moss green |
| Shardbow | Angled tripod / bow | Amber crystal |
| Mistvent | Low vent / pool | Violet haze |
| Bonehowl | Horned spire | Bone + blue pulse |
| Hex Lantern | Lamp post | Magenta flame |
| Hearthstone | Low kiln | Warm orange |
| Rootgate | Arch across path | Dark green bark |
| Skyshard | Needle antenna | Pale gold |

- **Aura rings** only for *support* towers (Hex, Hearth, Mist) to reduce noise.
- **Mark** icon above hexed enemies (must be visible in 4p chaos).
- Damage numbers optional/toggle; prioritize **flash color by channel**.

---

## 9. Warden interaction

Wardens remain full verb set:

- **Queue / upgrade / salvage** any legal tower.
- **Repair** gates (shared progress).
- **Focus fire** with attacks — same damage channels optional later (v0: generic).
- Standing in **Hearthstone** aura could slightly buff warden AS (tiny co-op candy).

No tower type is “player-only” to operate.

---

## 10. Implementation tiers

| Tier | Content | Goal | Status |
|---|---|---|---|
| **T0** | Generic tower in prototype | Feel queue + shoot | Done (superseded) |
| **T1** | Thornspire, Mistvent, Shardbow | First real composition | **Done** |
| **T2** | Hex Lantern, Hearthstone | Aura engine online | **Done** |
| **T3a** | Bonehowl | Armor / pulse tools | **Done** |
| **T3b** | Rootgate | Choke / block | Not yet |
| **T4** | Skyshard + flyer tag | Full matrix | Not yet |
| **T5** | Branches at II, Conjunction capstone | Depth without new bases | Not yet |

**In code now (cycle with ←→ on empty sites):** `thornspire`, `shardbow`, `mistvent`, `hex_lantern`, `hearthstone`, `bonehowl` — see `scripts/tower_types.gd`.

---

## 11. Open balance questions

| # | Question | Status |
|---|---|---|
| 1 | Linear upgrades only vs A/B branch at II? | Lean linear for T1–T2 |
| 2 | Exact aura radii in tiles/px? | Open — tune in editor |
| 3 | Can multiple Hex Lanterns mark the same target harder? | Lean no — duration refresh only |
| 4 | Do bosses ignore Rootgate? | Lean path-prefer crystal but attack gate if blocked |
| 5 | Essence costs table final numbers? | Open — playtest |
| 6 | Site affinity strictness (2–3 options vs free)? | Lean 2–3 options |

---

## 12. Decision log

| Date | Decision |
|---|---|
| 2026-07-11 | Full roster of **8** tower types drafted |
| 2026-07-11 | Damage channels: Thorn / Light / Shatter / Mist / Hex |
| 2026-07-11 | Monster tags for matchups defined |
| 2026-07-11 | Synergy model: passive auras + Hex mark; diminishing returns |
| 2026-07-11 | Map sites restrict 2–3 legal towers each |
| 2026-07-11 | Implementation order T0→T5 sketched |
| 2026-07-10 | **v0 ships 6 types** (T1+T2+Bonehowl); free cycle on all pads for prototype speed |

---

## 13. Quick reference card

```
SWARM     → Thornspire + Mistvent (+ Hearth)
ARMORED   → Bonehowl + Hex (+ Shardbow)
SWIFT     → Mistvent + Rootgate
SIEGE     → Shardbow + Hex (gate is time, not answer)
SHADE     → Light: Shardbow + Hearth + Hex
FLYER     → Skyshard (+ Hearth)
ELITE     → Hex mark + Shardbow
BOSS      → full aura nest + priority DPS; don't all-in gates
```

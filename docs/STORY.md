# Crystalward — Campaign Story

> **Status:** campaign bible (5 levels × 10 phases)  
> **Tone:** *The Dark Crystal* × *Legend* (1980s dark fantasy)  
> **Last updated:** 2026-07-17  

---

## 1. Logline

When the last true light of the world cracks, **Wardens of the Crystal** must carry a failing shard through a living forest of soft dark — where beauty and hunger share the same roots — and reseat it before **Conjunction**, when night and dawn become one throat and swallow the map forever.

---

## 2. Structure (locked)

| | |
|---|---|
| **Levels** | **5** |
| **Phases per level** | **10** (game “waves”) |
| **Progression** | Unlock next level on victory |
| **Escalation** | Each level more epic in look, lanes, and pressure |

**Phase** = one surge of nightspawn. Survive 10 phases to clear a level.

---

## 3. Tone bible

| From *The Dark Crystal* | From *Legend* (1985) |
|---|---|
| Sacred crystal as world’s heartbeat | Soft fairy-tale forest that can turn cruel |
| Puppet-creature weirdness; bone, bark, silk | Beauty and darkness as lovers |
| Prophecy, ritual architecture | Unicorn-pure light wounded |
| Castle chambers, fire shafts | Goblin thralls, marsh mists, black roses |

**Voice:** archaic-soft storybook captions. Fear is quiet. Wonder is dangerous.

---

## 4. World: Thren

**Thren** — forest-realm under a sick sky. The **Crystal of Truth** cracked at the last Great Conjunction. Light still pours, thinner each dusk. The **Soft Dark** seeps in: velvet night that grows flowers and loves company.

- **Lightwells** — local tower-housings that tether crystal light (your defend target).
- **Essence** — liquid starlight; **Crystal dust** — rarer powdered truth.
- **Lord Umbrael** — velvet hunger; wants the Crystal *dim*, not smashed.
- **Wardens** — players; anyone can gather, build, fight.

---

## 5. Five levels (more epic each chapter)

### Chapter 1 — *Homeland Vale*  
**id:** `glade` · **look:** `homeland` · **lanes:** single · **phases:** 10

**Look:** Gentle Gelfling homeland × *Legend* opening forest — warm meadow greens, pale sand paths, pollen light, fairy rings, soft sun shafts. Beauty first. The tower-Lightwell still almost pure.

**Story:** The Soft Dark is a rumor in the pollen. One road. Ten soft lessons. Learn the kill-zone while the world still smiles.

**Pressure:** Low HP/count scales; long prep; no elites.

---

### Chapter 2 — *Twinveil Crossing*  
**id:** `thorns` · **look:** `twinveil` · **lanes:** dual · **phases:** 10

**Look:** Silver-violet mist rivers; cool teal grass; dual roads merge at the well.

**Story:** Split attention. Refugees of light cross the ford. Umbrael divides the keepers.

---

### Chapter 3 — *Crosswind Mire*  
**id:** `bog` · **look:** `mire` · **lanes:** cross · **phases:** 10

**Look:** *Legend* swamp — black water, night-flowers, lying lights. Diagonal choke.

**Story:** Beauty as bait. First titled thralls (elites). Hold the dry throat or drown.

---

### Chapter 4 — *Western March*  
**id:** `march` · **look:** `march` · **lanes:** winding · **phases:** 10

**Look:** Bruise-sky dusk-heath; long serpentine dual paths; sparse stones; lonely pads.

**Story:** Umbrael’s highway. Exhaustion. Choose which serpent to starve.

---

### Chapter 5 — *Nightfall Gate*  
**id:** `conjunction` · **look:** `gate` · **lanes:** full (triple) · **phases:** 10

**Look:** Castle approach; three portals; violet stone; fire-shaft reflections; Conjunction halo.

**Story:** The Gloaming Court arrives. Endure until the Crystal knits — or Thren forgets the sun.

**Victory:** *The three lights find each other. Umbrael bows. “Another dusk, keepers.”*  
**Defeat:** *The Gate opens inward. The chamber learns a new name for night.*

---

## 6. Escalation ladder

| Ch | Epic feel | Visual | Gameplay |
|---|---|---|---|
| 1 | Pastoral wonder | Warm meadow | 1 path, gentle |
| 2 | Rising mysticism | Mist rivers | 2 merge paths |
| 3 | Romantic dread | Night swamp | Choke + elites |
| 4 | Lonely epic | Dusk heath | Long dual serpents |
| 5 | Ritual siege | Castle gate | Triple + max pressure |

---

## 7. Opening crawl

> *In the age after the Crystal cracked,*  
> *night learned how to bloom.*  
>  
> *Wardens still walk the roads of Thren,*  
> *from Homeland Vale to Nightfall Gate,*  
> *binding Lightwells through ten breaths of dusk*  
> *while Lord Umbrael smiles from the soft dark.*  
>  
> *Hold the light.*  
> *The forest is listening.*

---

## 8. Implementation notes

| Field | Use |
|---|---|
| `waves: 10` | Phases per level (`GameState.waves_to_win`) |
| `look` | Ground palette, plaza, path dirt, botanicals |
| `theme` | Soft modulate grade on Main |
| `lane_set` | PathNetwork layout |
| HUD | Shows **Phase N / 10** |

**Look keys:** `homeland` · `twinveil` · `mire` · `march` · `gate`  
Homeland is fully themed; later looks get progressive palette hooks (expand per chapter).

---

## 9. Decision log

| Date | Decision |
|---|---|
| 2026-07-17 | Story bible drafted (6-map draft) |
| 2026-07-17 | **Locked: 5 levels × 10 phases** |
| 2026-07-17 | Ch1 = Homeland Vale (Gelfling / Legend ethereal forest) |
| 2026-07-17 | Dropped Silveroak as separate level; arc is Vale → Crossing → Mire → March → Gate |

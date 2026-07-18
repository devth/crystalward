# Crystalward — Campaign Story

> **Status:** draft story bible for the campaign  
> **Tone:** *The Dark Crystal* × *Legend* (1980s dark fantasy)  
> **Last updated:** 2026-07-17  
> **Use:** Source of truth for narrative, map identity, and level blurbs. Gameplay numbers stay in `campaign.gd`; *feel* and *fiction* live here.

---

## 1. Logline

When the last true light of the world cracks, **Wardens of the Crystal** must carry a failing shard through a living forest of soft dark — where beauty and hunger share the same roots — and reseat it before **Conjunction**, when night and dawn become one throat and swallow the map forever.

---

## 2. Tone bible

Pull hard from both films; do not water them into generic fantasy.

| From *The Dark Crystal* | From *Legend* (1985) |
|---|---|
| A sacred crystal as the world’s heartbeat | A soft, fairy-tale forest that can turn cruel |
| Puppet-creature weirdness; tactile bone, bark, silk, stone | Beauty and darkness as lovers, not pure good vs pure evil |
| Prophecy, fractured cosmic order, ritual architecture | Unicorn / pure light stolen or wounded |
| Castle chambers, shafts of fire, violet stone | Goblin thralls, marsh mists, black roses, velvet night |
| Skeksis decadence vs gentle natural order | Darkness personified — charming, hungry, patient |

**What Crystalward is *not*:** grimdark gore-first; modern snark; high-tech sci-fi; pure neon synthwave.

**Voice:** archaic-soft, slightly formal, short sentences that feel like storybook captions read by candlelight. Fear is quiet. Wonder is dangerous.

**Visual emotion:** amber crystal light vs cold violet night; moss that drinks starlight; roads of pale dust and bone; roses that open only for the dark; creatures that look *made*, not merely drawn.

---

## 3. The world: Thren

**Thren** is a single forest-realm under a sick sky. Once, the **Crystal of Truth** hung in the **Castle of the Well** and kept day and night in honest balance. Seasons turned. Beasts slept when they should. Dreams did not walk in daylight.

Then the Crystal **cracked**.

Not shattered — *wounded*. A hairline of black ice ran through its heart during the last Great Conjunction. Light still pours from it, but thinner each dusk. Where the light fails, the **Soft Dark** seeps in: a velvet, breathing night that grows flowers, wears masks, and loves company.

The Soft Dark does not always scream. Often it **sings**.

### The Crystal & the Lightwell

- The **Crystal** is pure, faceted, and nearly alive. It remembers names.
- It is housed in a **tower-chamber** of organic stone (the Castle of the Well’s outpost spires, not one city alone) — each campaign map has a local **Lightwell**: a smaller housing that *tethers* a shard or echo of the true Crystal so the land does not drown overnight.
- **Lives / crystal HP** in game = the Lightwell’s integrity. If nightspawn reach it and drink enough, the tether snaps and that region falls to permanent dusk.
- **Essence** is liquid starlight that beads in wells and on dying thralls — the same soft currency Wardens spend to wake defenses.
- **Crystal dust** is rarer: powdered truth, shed when the Crystal dreams or weeps.

### The Soft Dark

Not pure evil; **appetite wearing beauty**.

- It wants the Crystal *dim*, not necessarily destroyed — a world of endless blue hour where its children never burn.
- Its thralls are **nightspawn**: briar-bodies, soft shades, ironclad processions, wing-things that blot moons.
- Its lords do not always show their faces. When they do, they speak politely.

**Working antagonist (name locked for v1):** **Lord Umbrael** — a titled hunger. Velvet, antlers of smoke, a smile like a cut in fruit. He does not conquer with armies alone; he *invites* the map to forget the sun.

### The Wardens

Players are **Wardens** — keepers bound by oath and dust to the Crystal’s light.

- Not knights of shining steel first; more **guardians of a dying garden**. Cloth, crystal, thorn, borrowed fairy-light.
- Anyone can gather, build, fight. The story does not assign classes; the forest does not care who holds the spade.
- In co-op, they are **two (or more) lights that refuse to go out alone**.

### Other powers (light touch — for blurbs & later content)

| Name | Role |
|---|---|
| **The Gloaming Court** | Soft Dark nobility; Umbrael’s peers and rivals |
| **Moss-Sisters** | Old green witches who may aid or tax the Wardens |
| **Podfolk / well-keepers** | Small folk who tend essence wells (PixelJunk cousin energy, Thren-flavored) |
| **The Three Suns (memory)** | Once watched Conjunction; now one is veiled, one is weak, one is watching *too hard* |

---

## 4. Core conflict

**Umbrael** has learned that a wounded Crystal can be **tamed**.

If nightspawn drink enough Lightwells along a path from the outer glades to the **Nightfall Gate**, the Soft Dark will climb the last stair into the Castle of the Well and **seat a black shard** beside the true Crystal — a second heart. Then Conjunction will not heal the world; it will **finalize the dusk**.

The Wardens must:

1. Hold each Lightwell as the Soft Dark tests it.
2. Follow the **Road of Wounds** inward (campaign map order).
3. Reach **Nightfall Gate** before Umbrael’s full court arrives.
4. Endure the siege so the Crystal can **knit** — or at least hold — until a greater healing (sequel / endgame fantasy).

**Win fantasy:** dawn that hurts the eyes; roses closing; crystal song returning, thin but true.  
**Lose fantasy:** the chamber goes quiet; only the Lake of Fire still breathes, and it breathes *cold*.

---

## 5. Campaign structure — six chapters

Maps map 1:1 to current `campaign.gd` ids. Names and blurbs below are **story canon**; implement when we reskin levels.

Each chapter needs:

- **Story beat** (what the Soft Dark is doing)
- **Place** (unique look / biome)
- **Gameplay pressure** (lane identity — already partly in code)
- **Emotional color** (what the player should feel)

---

### Chapter I — *The First Thorn*  
**Map id:** `glade`  
**Story name:** **Briar Glade** (was Lightwell Glade)

**Look:** Golden-green outer meadow at late afternoon; soft pollen; one pale dirt road; the tower-Lightwell still *almost* pure. Beauty first — *Legend*’s forest before the dark fully claims it.

**Story:**  
The crack in the Crystal is still a rumor here. Birds still argue. Then the first **Briar Thralls** push up from the south road — soft, numerous, wrong. The Wardens are young to the oath or newly called. This is the tutorial of fear: the road is simple; the lesson is not.

**Umbrael’s move:** A probing finger. Not the fist.

**Blurb (map select):**  
*“One road through the briars. The Crystal still sings. Learn what the Soft Dark sounds like when it is only whispering.”*

**Tone tags:** wonder, first blood, sunlight that won’t last.

---

### Chapter II — *Where Waters Remember*  
**Map id:** `thorns`  
**Story name:** **Twinveil Crossing** (was Twin River Pass)

**Look:** Two rivers of silver-violet mist braiding into one ford; willows that hang like hair; stepping-stones of pale bone-wood. Dual roads merge near the well.

**Story:**  
Refugees of light (podfolk, moss-sisters’ messengers) flee across the crossing. The Soft Dark sends two columns so the Wardens must **split attention** — co-op’s first real argument. Essence wells sit between the streams like forgotten moon-coins.

**Umbrael’s move:** Divide the keepers; drink them while they quarrel.

**Blurb:**  
*“South and east roads kiss at the Lightwell. Hold both mouths of the river, or the dusk will learn your names.”*

**Tone tags:** urgency, co-op, water-mirror beauty.

---

### Chapter III — *The Split Oak*  
**Map id:** `ruins`  
**Story name:** **Silveroak Wound** (was Silveroak Split)

**Look:** A colossal pale oak struck by old lightning / dark conjunction scar; north and south roads run either side of the bole. Ruins of a Gelfling-like shrine half-swallowed by roots. First **elites** = “titled” thralls wearing scrap-crowns.

**Story:**  
An old ward-stone under the oak fails. The Soft Dark pours through the **wound in the tree** as much as along the roads. Wardens hear the oak *speak* once — a single word: *Remember.* Elites are Umbrael’s minor cousins, testing the line.

**Umbrael’s move:** Corrupt a landmark the land loves.

**Blurb:**  
*“North and south flanks. The Silveroak bleeds starlight. Crown-thieves walk among the thralls.”*

**Tone tags:** melancholy, sacred tree, first named threats.

---

### Chapter IV — *The Soft Marsh*  
**Map id:** `bog`  
**Story name:** **Crosswind Mire** (was Crosswind Bog)

**Look:** *Legend* swamp — black water, white flowers that open at night, will-o-wisps that lie. Diagonal roads share a choke of dry ground. Fog eats silhouette edges. Peat-purple and river-green.

**Story:**  
The mire was once a dancing green. Umbrael’s court **perfumed** it. Nightspawn here are slower, heavier, or winged above the muck. A choke point offers hope and betrayal: hold the crosswind ridge or drown trying to be everywhere.

**Umbrael’s move:** Beauty as bait; choke as knife.

**Blurb:**  
*“Diagonal roads share one dry throat. The flowers open for the dark. Do not trust the lights that smile.”*

**Tone tags:** dread-romance, fog, choke-point tension.

---

### Chapter V — *The Long Dusk*  
**Map id:** `march`  
**Story name:** **Western March** (keep name — it already feels like a campaign of attrition)

**Look:** Endless rolling dusk-heath; two long serpentine roads with little shared coverage; standing stones like broken teeth; sky the color of a bruise under lace. Sparse beauty, long approaches, lonely pads.

**Story:**  
This is the Soft Dark’s **highway**. Umbrael’s processions have used it for ages of the world. Wardens cannot cover everything; they must choose which serpent to starve. Dust is thin. Lives are thinner. The Crystal’s song is almost gone from the wind.

**Umbrael’s move:** Exhaustion. Make the light *tired*.

**Blurb:**  
*“Two long serpents. Little shared cover. The march does not hurry — it only never stops.”*

**Tone tags:** attrition, loneliness, epic scale.

---

### Chapter VI — *Conjunction*  
**Map id:** `conjunction`  
**Story name:** **Nightfall Gate** (keep — perfect)

**Look:** Approach to the Castle of the Well: three portals / three path-throats; violet stone; fire-shaft reflections; banners of the Gloaming Court; the true tower-housing of the Crystal visible as the map’s heart. Maximum Dark Crystal architecture. Three suns almost aligned in a sick halo.

**Story:**  
**Conjunction** begins. Umbrael arrives in earnest — not always as a single boss sprite at first, but as *pressure*: elites, flyers, triple lanes, shorter calm. The Wardens’ only task is **endure** until the Crystal’s tether can drink enough dawn-pressure to seal the black ice for another age.

**Climax line (victory):**  
*The three lights find each other. The Soft Dark recoils, smiling, as if it has only loaned you the morning.*

**Defeat line:**  
*The Gate opens inward. The chamber learns a new name for night.*

**Blurb:**  
*“Three portals. The Court is coming. Hold the Gate until Conjunction passes — or Thren forgets the sun.”*

**Tone tags:** siege, ceremony, final stand, bittersweet hope.

---

## 6. Through-line beats (between maps)

Short interstitial fiction for map select / victory screens (implement later as text cards):

| After… | Beat |
|---|---|
| Briar Glade | A Moss-Sister leaves a thorn-crown: *“You kept one well. The dark has many hands.”* |
| Twinveil Crossing | Podfolk light a lantern of essence; it burns violet by mistake. They apologize to the Crystal. |
| Silveroak Wound | The oak drops one silver leaf that does not fall — it *hovers*. Dust +1 fantasy. |
| Crosswind Mire | Wardens dream of Umbrael offering a rose. Waking, thorns under the fingernails. |
| Western March | Silence. Even the Soft Dark is quiet. That is worse. |
| Nightfall Gate (win) | Crystal song returns, thin. Umbrael’s shadow bows. *“Another dusk, keepers.”* |

---

## 7. Characters (for VO / panels later)

| Character | Function |
|---|---|
| **The Crystal** | Silent protagonist; HP bar is its pulse |
| **Wardens (players)** | Oath-bound; no forced names in v1 — optional later |
| **Lord Umbrael** | Antagonist; velvet hunger; final map presence |
| **Lirien** | Optional Moss-Sister guide (blurbs only at first) |
| **The Gate-Warden** | Old statue that speaks once at Nightfall Gate |

Avoid over-casting. The forest is the other main character.

---

## 8. Themes

1. **Light is a practice, not a prize** — you keep it by work (gather, build, hold).
2. **Beauty can be a weapon** — Soft Dark is lovely; that is the trap (*Legend*).
3. **Order is fragile** — one crack in a crystal unthreads a world (*Dark Crystal*).
4. **Together is the only spell** — co-op as fiction: two lights, one well.
5. **Victory is temporary** — Conjunction returns; Umbrael loans mornings. Sequel space.

---

## 9. Naming sheet (canon)

| Old code name | Story name | id (unchanged) |
|---|---|---|
| Lightwell Glade | **Briar Glade** | `glade` |
| Twin River Pass | **Twinveil Crossing** | `thorns` |
| Silveroak Split | **Silveroak Wound** | `ruins` |
| Crosswind Bog | **Crosswind Mire** | `bog` |
| Western March | **Western March** | `march` |
| Nightfall Gate | **Nightfall Gate** | `conjunction` |

**World:** Thren  
**Antagonist:** Lord Umbrael / the Soft Dark / the Gloaming Court  
**Home structure:** Castle of the Well (Crystal Chamber + Lightwell outposts)

---

## 10. What we build next (story → production)

When you say go on implementation, suggested order:

1. **Wire story names + blurbs** into `campaign.gd` / map select UI.
2. **Per-map visual themes** (palette, props, ground tint, music bed) matching chapters I–VI.
3. **Interstitial cards** (victory / unlock text) using the through-line beats.
4. **Boss / Umbrael presence** on Nightfall Gate (even a silhouette + scripted elite wave).
5. **Title screen copy** aligned to the logline.

---

## 11. Opening crawl (optional title)

> *In the age after the Crystal cracked,*  
> *night learned how to bloom.*  
>  
> *Wardens still walk the roads of Thren,*  
> *binding Lightwells with thorn and dust,*  
> *while Lord Umbrael smiles from the soft dark*  
> *and waits for Conjunction.*  
>  
> *Hold the light.*  
> *The forest is listening.*

---

## 12. Decision log

| Date | Decision |
|---|---|
| 2026-07-17 | Campaign story bible drafted; 6 chapters mapped to existing map ids |
| 2026-07-17 | Antagonist named Lord Umbrael; Soft Dark as hunger-in-beauty |
| 2026-07-17 | World named Thren; Castle of the Well as crystal home |
| 2026-07-17 | Level renames proposed; ids kept for save compatibility |

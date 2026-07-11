# Crystalward

Local co-op **action tower defense** — wardens protect a sacred crystal from the soft dark.

Tone: *The Dark Crystal* × *Legend* (1980s dark fantasy). Pacing: action RTS (high APM).

**Players:** 1–2 local in v0 (pad slots ready for more) · **any player can do any job**  
**Stack:** Godot 4 · isometric-ish 2.5D presentation · shared bank

## Play (macOS)

1. Install [Godot 4.3+](https://godotengine.org/download) (or `brew install --cask godot`).
2. Open this folder in Godot, or from a terminal:

```bash
cd ~/crystalward
godot .   # or: open -a Godot .
```

3. Press **F5** / Play in the editor.

### Controls

| | P1 | P2 |
|---|---|---|
| Move | WASD | Arrows |
| Gather | E (hold) | `.` (hold) |
| Queue tower | Q | `,` |
| Attack | Space | `/` |
| **Pause / help** | **Esc** or **P** or pad **Start** | same |
| Restart | R | R |

In-game: **Esc / Start** opens the full controls panel and pauses. Press again to resume.

Switch Pro / Joy-Cons: device 0 → P1, device 1 → P2 (A gather, B attack, X build — layout may vary by OS mapping).

### v0 loop

- Shared **Essence** bank (start with 40). Hold gather on cyan nodes.
- Stand on green pads → **Q** to queue a tower (**25 Essence**, builds in 2s while you leave).
- Nightspawn surges target the **Crystal**. Towers auto-fire; you can melee too.
- Survive **5 surges** or crystal HP hits 0. **R** restarts.

## Spec

- Living design: [`docs/SPEC.md`](docs/SPEC.md)
- Towers, upgrades, synergies, matchups: [`docs/TOWERS.md`](docs/TOWERS.md)

## Agent notes

See [`AGENTS.md`](AGENTS.md) — default branch `master`, push after meaningful work.

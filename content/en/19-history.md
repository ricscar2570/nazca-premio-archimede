# PART XIX — VERSION HISTORY AND DESIGN DECISIONS

## 19.1  Branch timeline

| Branch | Period | Status | Reason for opening/closing |
|--------|--------|--------|---------------------------|
| v1–v2 (conceptual) | Oct–Dec 2025 | Archived | Initial concept iterations — generic board, unstable mechanics |
| v3.0 | Jan–Mar 2026 | Archived | First simulations. Game Bible v1 written. Parameters uncalibrated. |
| v3.1 "Strings" | Mar–Apr 2026 | ACTIVE | Quercetti board + waxed cords. Game Bible v3 calibrated on 900k simulations. |
| v4-Cardboard | 5–15 May 2026 | ABANDONED | Opened to resolve cord tangling risk. Closed: tangling is not a problem with Quercetti waxed cord. Return to v3.1. |

## 19.2  Why v4-Cardboard was abandoned

On 5 May 2026 the v4-Cardboard branch was opened with the goal of eliminating cord tangling risk by replacing pegs + cords with cardboard tiles on a two-sided board. Band A specifications had been locked.

On 15 May 2026 the branch was closed and v3.1 was restored for two reasons: (1) the waxed Quercetti String Art Mandala thread is natively designed for Pixel Art 4 pegs — the combination is already validated by Quercetti on their own product and tangling risk is low; (2) the peg+cord mechanic is the game's only genuine physical innovation and the core of the QP Trophy candidacy — abandoning it would have eliminated the main differentiator.

## 19.3  Major design decisions — register

| Date | Decision | From | To | Rationale |
|------|----------|------|-----|-----------|
| Mar 2026 | Water sources | Secret (hidden position) | Visible to all on overlay | Simplifies setup, maintains hidden information on combinations |
| Apr 2026 | El Niño | Immediate termination + harvest reset | −3 pt end-game penalty | Termination was anti-climactic; reset too punitive |
| Apr 2026 | Spider bonus | Per-peg (every adjacency = +1) | Flat +1/round | Unstoppable snowball effect in 900k simulations |
| Apr 2026 | Completion threshold | 70% | 72% | Simulation calibration: 70% too easily reachable |
| May 2026 | Board | Custom perforated design | 4× Quercetti Pixel Art 4 (25×33 cm) | Faster prototype, pre-manufactured holes, cost <€35 |
| May 2026 | Rounds | 8 maximum | 6 default / 8 maximum | 6 rounds = ~65 min in Session Zero, compliant with competition |
| May 2026 | Art Bonus | Open voting (verbal announcement) | Blind voting on slip | Eliminates kingmaking |
| May 2026 PATCH | Spider bonus | Flat +1/round (1 peg) | 2+ pegs + odd round [P3v1] | 300k sim: win rate 44.9% → too dominant |
| May 2026 PATCH | El Niño thresholds | 3 / 4 / 5 | 4 / 5 / 6 [P1v1] | 300k sim: triggered 69% at 4P → too frequent |
| May 2026 PATCH | Huarango felling | +2 water | +1 water [P1v1] | 300k sim: felling incentive too high |
| May 2026 PATCH | Orca block | 4 radial holes | 2 directional holes [P4v1] | 300k sim: self-block → win rate 17.3% |
| May 2026 PATCH | Squash maturation | 3 rounds | 2 rounds [P2] | 300k sim: Three Sisters in 6% — irrelevant |
| May 2026 PATCH | Art Bonus | +4 pt to most voted | +2 pt, not to leader [P5] | 300k sim: went to leader 100% of the time |
| May 2026 P3v2 | Spider bonus | 2+ pegs ADJ + odd | 1 peg ADJ + odd | S1: 1 activation/game → double condition too restrictive |
| May 2026 P1v2 | El Niño | 4/5/6 thresholds + +1 water | 3/4/5 + +2 water − 1 pt/felling | S1: 1 felling → El Niño nearly absent. Restoring +2 with deferred cost |
| May 2026 P4v2 | Orca | Block 2 holes only | Block + +1 water ADJ to block | S1: Orca 0 economy, 0 harvests. Structural problem. |
| May 2026 P1v3 | El Niño thresholds | 3/4/5 | 4/5/6 | Sim v2: 76.5% at 4P with 3/4/5. Double disincentive estimated 40–55%. |
| May 2026 P6 | Hummingbird Mobility | Pure movement | Movement + +1 water if dest. is own card source | Sim v2: pure mobility 17.3% → too far below target. P6 adds systematic water income. |
| May 2026 PROP3 | Three Sisters | Mandatory spatial adjacency | Pure set collection — no adjacency | Sim v3: 20.5%→31.8%. Removed excessive spatial puzzle. |
| May 2026 PROP1 | Orca canals | Block + +1 water ADJ | Block + +1 water ADJ + ADJ neutral tiles −1 irrigation | Orca 28%→29.9%. Integrated agricultural engine. |
| May 2026 PROP4 | El Niño felling | Normal action (3/turn) | Free action 1×/game + −1 pt | Free 1×/round→97.3% activation. Corrected to 1×/game. |
| May 2026 v8 CANALS | Orca — CANAL bonus | Discount tied to physical position of field tiles (off board) | Discount tied to border node touched: −1 sow per neutral ADJ to border node. Measurable on board only. | Spatial conflict: field tiles are outside the grid, "adjacent to corridor" was not definable. |
| May 2026 v8 EDGE | Irrigate to Valley — "touching the edge" | Implicit definition (cord hanging over edge) | Explicit definition: peg in the last row/column of grid for the chosen slope. | Table ambiguity eliminated. |

## 19.4  Open questions remaining — post patch

:::twocol
| Issue | Status |
|-------|--------|
| Orca: verify post-patch balance | Directional 2-hole block not simulated. Test 5 games and measure win rate. |
| Spider: verify P3v2 effectiveness | Simulated win rate 33.8% — still above target 25%. Monitor physically before further patches. |
| Hummingbird: Mobility+ — residual canonical gap | Simulated canonical win rate: 22.8% (target 25%). Gap still present. Monitor physically. |
| Condor: every round vs once | Unchanged — every round (canonical) is richer strategically. |
| Sandy terrain: include or remove | Verify in first physical playtest whether it adds decisions or only complexity. |
:::

## 19.5  Patch Notes — 300k PATCHES (May 2026)

> [!NOTE]
> These patches were implemented after 300,000 Monte Carlo simulations on the real 20×27 grid. The previous simulations (900k, Game Bible v3) used a simplified 10×10 grid and did not reveal these imbalances.

| # | System | Problem detected | Solution implemented | Expected effect |
|---|--------|-----------------|---------------------|-----------------|
| P1 | El Niño | Activation 69% at 4P (target 35–45%). Thresholds too low. | P1v1: thresholds 4/5/6 + felling −2→+1 water. P1v2: thresholds 3/4/5 + +2 water + −1 pt. P1v3 (current): thresholds 4/5/6 + +2 water + −1 pt + free 1×/game action. | Estimated activation 40–55% at 4P |
| P2 | Squash / Three Sisters | Three Sisters in 6% of games (target 40–60%). Squash too slow. | Squash: 3 → 2 round maturation. | Estimated triad frequency: 25–45% |
| P3 | Spider | Win rate 44.9% (target 25%). Bonus too easy to activate. | P3v1: 2+ pegs ADJ + odd round. P3v2 (current): 1 peg ADJ + odd round. | Estimated win rate P3v2: 28–34% |
| P4 | Orca | Win rate 17.3% (target 25%). Radial self-block penalises own network. | Directional block: 2 holes in chosen direction instead of 4 radial holes. | Estimated win rate: 20–27% |
| P5 | Art Bonus | Went to leader 100% (structurally correlated with completion). | Reduced from +4 to +2 pt + anti-leader rule. | Estimated leader correlation: <70% |

## 19.6  Digital support tools

:::twocol
| Tool | Description |
|------|-------------|
| Nazca Peg Mapper | HTML/JS app with Claude Vision API. Analyses photos of real geoglyphs and suggests peg placement on the 20×27 grid. Built, to be integrated into the playtesting workflow. |
| Tabletop Simulator (TTS) | Digital implementation with Custom Tokens + Snap Points for pegs, Lua Vector Lines for cords. To be updated with 300k patches before using for digital playtesting. |
| Python/NumPy Monte Carlo v1 | 900,000 games on 10×10 grid. Original calibration Game Bible v3. |
| Python/NumPy Monte Carlo v2 | 300,000 games on real 20×27 grid. First patch generation. Report: NAZCA_SimReport_v2_300k.pdf |
| Python/NumPy Monte Carlo v3 | 300,000 games on 20×27 grid. Design proposals PROP1/3/4. Report: NAZCA_SimReport_v3_300k.pdf |
:::

# NAZCA — Current Competition Sync Boundary

**Project status:** active development for Premio Archimede 2027.

This repository is a substantial working implementation, not an abandoned prototype. It already contains the bilingual Game Bible, geoglyph paths, water/puquio mechanics, scoring, playtest material and the Tabletop Simulator pipeline.

However, the committed rules must **not yet be treated as the final competition submission**.

## Known synchronization boundary

The current committed `content/it/11-rivelazione.md` still resolves the artistic/geoglyph comparison through a blind-vote **Bonus Arte** procedure. The later working design has moved toward a **mandatory geoglyph-similarity evaluation** rather than leaving recognisability primarily to that vote-based procedure.

Until that later evaluation rule is deliberately integrated, playtested and propagated through scoring, examples, TTS automation, English content and the competition rulebook, the existing Revelation procedure should be treated as a **control / historical implementation**, not silently assumed to be the final rule.

## Do not update only one layer

When the new evaluation procedure is frozen, synchronize it atomically across at least:

- `content/it/11-rivelazione.md` and the corresponding English file;
- final scoring sections;
- setup/components where evaluation aids or reference geoglyphs are defined;
- playtest questionnaire and acceptance criteria;
- TTS Revelation/scoring scripts;
- compact jury rulebook / submission text;
- examples and Game Bible references.

Do not change the TTS script or a single chapter independently and then call the repository synchronized.

## Submission gates still visible in the repository

The README also records author/contact placeholders that must be replaced before the competition package is submitted. These are submission-data tasks, not game-design rules, and should remain separate from mechanical iteration.

## Repository policy

Preserve the current implementation until the replacement rule has passed a controlled comparison/playtest. The objective is a reversible, auditable transition with no loss of the existing working build.

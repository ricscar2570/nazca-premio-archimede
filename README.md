# NAZCA — Game Bible Repository

> *Le linee che cercano l'acqua / The lines that seek water*

Automated build pipeline for the **NAZCA** board game manual.  
Write in Markdown → GitHub Actions builds DOCX + PDF in multiple languages.

---

## Repository structure

```
nazca-gamebible/
├── .github/workflows/build-manual.yml   ← CI/CD pipeline
├── content/
│   ├── it/          ← Italian source (complete)
│   │   ├── meta.yml               ← document metadata
│   │   ├── 01-ambientazione.md
│   │   ├── 02-componenti.md
│   │   ├── 03-setup.md
│   │   ├── 04-turno.md
│   │   ├── 05-azioni.md
│   │   ├── 06-clan.md
│   │   ├── 07-acqua.md
│   │   ├── 08-valle.md
│   │   ├── 09-el-nino.md
│   │   ├── 10-obiettivi.md
│   │   ├── 11-rivelazione.md
│   │   └── 12-punteggio.md
│   └── en/          ← English (stubs — translate and fill)
│       ├── meta.yml
│       └── 01-setting.md … 12-scoring.md
└── build/
    ├── package.json
    ├── index.js      ← main build script
    ├── parser.js     ← Markdown → AST
    ├── renderer.js   ← AST → DOCX elements
    └── styles.js     ← NAZCA colour / style constants
```

---

## Build locally

```bash
# Install dependencies
cd build && npm install

# Build Italian PDF (requires LibreOffice for PDF step)
node index.js --lang it --out ../output/
libreoffice --headless --convert-to pdf --outdir ../output/ ../output/NAZCA_GameBible_it.docx

# Build both languages
npm run build:all
```

---

## CI/CD — GitHub Actions

Every push to `main` that touches `content/` or `build/` automatically:

1. Builds DOCX for all languages
2. Converts to PDF via LibreOffice
3. Uploads artifacts (available for 30 days under **Actions → run → Artifacts**)
4. Creates a GitHub Release with all output files

To trigger manually: **Actions → Build Game Bible → Run workflow**.

---

## Markdown syntax guide

### Standard elements

```markdown
# PARTE I — Title                 → Heading 1 (page break before)
## 1.1  Subtitle                  → Heading 2
### Sub-section                   → Heading 3

Regular paragraph text.

- Bullet item one
- Bullet item two

---                               → Horizontal rule / divider
```

### Note boxes

```markdown
> [!NOTE]
> Blue info box — for design notes, rules clarifications.

> [!WARNING]
> Red warning box — for critical rules, breaking changes.

> [!IMPORTANT]
> Same as WARNING visually.
```

### Tables

Standard Markdown tables become styled DOCX tables with a coloured header row:

```markdown
| Column A | Column B | Column C |
|----------|----------|----------|
| value 1  | value 2  | value 3  |
```

### Two-column key-value tables

Wrap with `:::twocol` / `:::` for the compact label-value layout used in action cards and component lists:

```markdown
:::twocol
| Field  | Value            |
|--------|------------------|
| Cost   | 1 action — 0 water |
| Effect | Plant a peg      |
:::
```

### Inline formatting

```markdown
**bold text**
*italic text*
`monospace`
{color:C05A20}coloured run{/color}
{bold}bold run{/bold}
```

---

## Adding a new language

1. `cp -r content/it content/de`
2. Edit `content/de/meta.yml` (title, subtitle, etc.)
3. Translate each `.md` file
4. Add `de` to the `langs` logic in `.github/workflows/build-manual.yml`
5. Add `de` entry to `LANG_DEFAULTS` in `build/styles.js`

---

## License

Content © the author. Build tooling MIT.

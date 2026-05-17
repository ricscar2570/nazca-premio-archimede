# NAZCA — Game Bible Repository

> *Le linee che cercano l'acqua / The lines that seek water*

Pipeline automatizzata per il manuale del gioco **NAZCA** (Premio Archimede 2027, Trofeo QP).  
Scrivi in Markdown → GitHub Actions produce DOCX + PDF (Game Bible) e il mod TTS.

---

## Struttura del repository

```
nazca-gamebible/
├── .github/workflows/
│   ├── build-manual.yml   ← CI/CD Game Bible (Markdown → DOCX → PDF)
│   └── build-tts.yml      ← CI/CD mod Tabletop Simulator
│
├── content/
│   ├── it/                ← Sorgente italiano (completo, 19 parti)
│   │   ├── meta.yml                ← metadati documento
│   │   ├── 01-ambientazione.md … 19-storico.md
│   └── en/                ← Inglese (completo, 19 parti)
│       ├── meta.yml
│       └── 01-setting.md … 19-history.md
│
├── build/                 ← Build pipeline Game Bible (Node.js)
│   ├── package.json
│   ├── index.js           ← script principale
│   ├── parser.js          ← Markdown → AST
│   ├── renderer.js        ← AST → elementi DOCX
│   ├── styles.js          ← palette NAZCA + costanti stile
│   └── output/            ← generato localmente (ignorato da git)
│
└── tts/                   ← Tabletop Simulator mod
    ├── build/
    │   └── bundle.js      ← assembla Lua → TTS JSON + genera PNG asset
    ├── scripts/           ← sorgente Lua (8 file, bundled da bundle.js)
    │   ├── 00-config.lua          costanti: griglia 20×27, sorgenti, colori
    │   ├── 01-state.lua           stato di gioco e turni
    │   ├── 02-grid.lua            BFS connettività, adiacenza 8-dir
    │   ├── 03-actions.lua         8 azioni (Traccia, Puquio, Irriga, Semina…)
    │   ├── 04-clans.lua           poteri clan (Ragno, Orca, Colibrì, Condor)
    │   ├── 05-scoring.lua         punteggio finale
    │   ├── 06-07-08-…lua          Rivelazione, UI, entry points TTS
    │   └── 09-components.lua      tessere campo, colture, traccia punteggio
    ├── template/
    │   ├── save.json       ← template TTS (25 oggetti pre-configurati)
    │   └── README.md       ← istruzioni immagine plancia
    └── assets/             ← PNG generati da bundle.js (committati per GitHub raw URL)
        └── *.png           ← 15 immagini: campi, colture, traccia
```

---

## Build Game Bible — localmente

```bash
cd build
npm install

# Italiano
node index.js --lang it --out ../output/
libreoffice --headless --convert-to pdf --outdir ../output/ ../output/NAZCA_GameBible_it.docx

# Entrambe le lingue
npm run build:all
```

---

## Build mod TTS — localmente

```bash
# Nessuna dipendenza npm (solo Node.js built-in)
REPO_URL=https://raw.githubusercontent.com/TUO_USER/TUO_REPO/main \
  node tts/build/bundle.js --out output/
```

Il file `output/NAZCA_TTS_v8.json` si carica direttamente in TTS:  
**Games → Save & Load → seleziona il file**.

---

## CI/CD — GitHub Actions

### Game Bible (`build-manual.yml`)
Si attiva ad ogni push su `content/**` o `build/**`:
1. Build DOCX per IT e EN
2. Conversione PDF via LibreOffice
3. Upload artefatti (30 giorni)
4. Crea GitHub Release con tutti i file

### Mod TTS (`build-tts.yml`)
Si attiva ad ogni push su `tts/**`:
1. Bundle degli 8 script Lua → script globale TTS
2. Generazione 540 snap points (griglia 20×27)
3. Generazione 15 PNG asset (campi, colture, traccia punteggio)
4. Iniezione URL asset e immagine plancia nel JSON
5. Verifica automatica (snap count, dimensione Lua)
6. Upload artefatti + GitHub Release

**Variabili repository da configurare** (`Settings → Variables → Actions`):
- `BOARD_IMAGE_URL` — URL dell'immagine plancia (opzionale; altrimenti usa il default GitHub raw)

---

## Sintassi Markdown estesa

```markdown
# PARTE I — Titolo          → Heading 1 (interruzione pagina prima)
## 1.1  Sottotitolo          → Heading 2
### Sotto-sezione            → Heading 3

> [!NOTE]
> Riquadro informativo blu.

> [!WARNING]
> Riquadro avviso rosso.

| Col A | Col B |              → tabella DOCX con header colorato
|-------|-------|
| val 1 | val 2 |

:::twocol
| Campo | Valore |          → tabella compatta chiave-valore
|-------|--------|
| Costo | 1 azione |
:::

**grassetto**  *corsivo*  `monospace`
{color:C05A20}testo colorato{/color}
```

---

## Aggiungere una lingua

1. `cp -r content/it content/de`
2. Modifica `content/de/meta.yml`
3. Traduci ogni file `.md`
4. Aggiungi `de` alla logica `langs` in `build-manual.yml`
5. Aggiungi entry `de` in `LANG_DEFAULTS` di `build/styles.js`

---

## Placeholder da compilare prima della spedizione

I seguenti campi in `content/it/meta.yml` e `content/en/meta.yml`  
vanno sostituiti con i dati reali dell'autore:

```yaml
author: "[NOME COGNOME]"   ← sostituire con nome e cognome
phone:  "[TEL]"            ← sostituire con numero di telefono
email:  "[EMAIL]"          ← sostituire con indirizzo email
```

Anche `content/it/17-conformita.md` (e EN) contengono `[NOME][TEL][EMAIL]`  
nella riga relativa ai contatti sulla scatola.

---

## Licenza

Contenuto © l'autore. Build tooling MIT.

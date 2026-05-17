# Istruzioni per l'immagine della plancia

## Specifiche

Il file `board.png` (2048×2048 px) deve essere creato manualmente e committato in questa directory.
Una volta nel repository, il workflow CI lo servirà automaticamente via GitHub raw URL.

## Contenuto da disegnare

- **Sfondo:** texture deserto — sabbia ocra (#C4A46A), toni caldi
- **Griglia 20×27:** 540 cerchi (fori) — raggio 12 px, colore #8A7050, bordo #5A4030
  - Margini: 64 px per lato
  - Area utile: 1920×1920 px... ma la griglia è 20×27 (non quadrata):
    - Larghezza area nodi: 1920 px → passo colonne: 1920/19 ≈ 101 px
    - Altezza area nodi: 1920 px × (26/19) ≈ 2630 px → la plancia deve essere 2048×2780 px
    - Oppure: usare un'immagine rettangolare 2048×2780 px, oppure scalare per stare in 2048×2048

## Soluzione raccomandata (scala proporzionale in 2048×2048)

Con 20 col e 27 righe in uno spazio 1920×1920 px:
- Passo colonne: 1920/19 = 101.1 px
- Passo righe: 1920/26 = 73.8 px

I fori non sono circolari ma le distanze verticali e orizzontali sono diverse — è corretto,
riflette la griglia 20×27 compressa in un quadrato.

## Elementi obbligatori

- 12 sorgenti (S1–S12): cerchio più grande (#3A7BC8 blu acqua), con etichetta
- 6 huarango (H1–H6): simbolo albero verde (#22A022)
- 4 basi clan agli angoli:
  - NW = verde Colibrì · NE = bianco/grigio Condor
  - SW = rosso Ragno · SE = blu Orca
- Logo NAZCA centrato (opzionale)

## Strumenti consigliati

- **Inkscape** (gratuito): crea un SVG 2048×2048, esporta PNG
- **Script Python (Pillow):** genera automaticamente la griglia

## URL risultante (dopo il commit)

```
https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/tts/template/board.png
```

Imposta questa URL come variabile repository in GitHub:
`Settings → Variables → Actions → New repository variable → BOARD_IMAGE_URL`

## Generazione automatica con Python/Pillow (opzionale)

```python
from PIL import Image, ImageDraw
img = Image.new('RGB', (2048, 2048), (196, 164, 106))
draw = ImageDraw.Draw(img)
for row in range(27):
    for col in range(20):
        cx = 64 + col * 101
        cy = 64 + row * 74
        draw.ellipse([cx-12, cy-12, cx+12, cy+12],
                     fill=(138, 112, 80), outline=(90, 64, 48), width=2)
img.save('board.png')
```

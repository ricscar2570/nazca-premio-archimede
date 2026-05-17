# PARTE XIX — STORICO VERSIONI E DECISIONI DI DESIGN

## 19.1  Linea temporale dei branch

| Branch | Periodo | Stato | Motivo apertura/chiusura |
|--------|---------|-------|--------------------------|
| v1–v2 (concettuale) | Ott–Dic 2025 | Archiviato | Iterazioni iniziali del concept — plancia generica, meccaniche non stabili |
| v3.0 | Gen–Mar 2026 | Archiviato | Prime simulazioni. Game Bible v1 scritta. Parametri non calibrati. |
| v3.1 «Corde» | Mar–Apr 2026 | ATTIVO | Plancia Quercetti + fili cerati. Game Bible v3 calibrata su 900k simulazioni. |
| v4-Cartone | 5–15 Maggio 2026 | ABBANDONATO | Aperto per risolvere aggrovigliamento corde. Chiuso: aggrovigliamento non è problema con filo Quercetti cerato. Si torna a v3.1. |

## 19.2  Perché v4-Cartone è stato abbandonato

Il 5 maggio 2026 è stato aperto il branch v4-Cartone con l'obiettivo di eliminare il rischio aggrovigliamento corde sostituendo chiodini+fili con tessere di cartone su plancia bifacciale. La Fascia A era stata bloccata con tutte le specifiche.

Il 15 maggio 2026 il branch è stato chiuso e si è tornati a v3.1 per due ragioni: (1) il filato cerato Quercetti String Art Mandala è progettato nativamente per i chiodini Pixel Art 4 — la combinazione è già validata da Quercetti sul proprio prodotto e il rischio aggrovigliamento è basso; (2) la meccanica chiodini+cordicelle è l'unica innovazione fisica vera del gioco e il cuore della candidatura al Trofeo QP — abbandonarla avrebbe eliminato la differenziazione principale.

## 19.3  Decisioni di design maggiori — registro

| Data | Decisione | Da | A | Motivazione |
|------|-----------|-----|---|-------------|
| Mar 2026 | Sorgenti d'acqua | Segrete (posizione nascosta) | Visibili a tutti sull'overlay | Semplifica setup, mantiene informazione nascosta sulle combinazioni |
| Apr 2026 | El Niño | Terminazione immediata + azzeramento raccolti | Penalità −3 pt fine partita | Terminazione anti-climatica; azzeramento troppo punitivo |
| Apr 2026 | Bonus Ragno | Per-chiodino (ogni adiacenza = +1) | Flat +1/round | Snowball effect inarrestabile su 900k simulazioni |
| Apr 2026 | Soglia completamento | 70% | 72% | Calibrazione simulazioni: 70% troppo raggiungibile |
| Mag 2026 | Plancia | Design custom forata | 4× Quercetti Pixel Art 4 (25×33 cm) | Prototipo più veloce, fori pre-fabbricati, costo <€35 |
| Mag 2026 | Round | 8 massimo | 6 default / 8 massimo | 6 round = ~65 min in Sessione Zero, conforme al bando |
| Mag 2026 | Bonus Arte | Votazione aperta (annuncio verbale) | Votazione cieca su foglietto | Elimina kingmaking |
| Mag 2026 PATCH | Bonus Ragno | Flat +1/round (1 chiodino) | 2+ chiodini + round dispari [P3v1] | 300k sim: win rate 44.9% → troppo dominante |
| Mag 2026 PATCH | El Niño soglie | 3 / 4 / 5 | 4 / 5 / 6 [P1v1] | 300k sim: scattava 69% a 4G → troppo frequente |
| Mag 2026 PATCH | Abbattimento Huarango | +2 acqua | +1 acqua [P1v1] | 300k sim: incentivo taglio troppo alto |
| Mag 2026 PATCH | Orca blocco | 4 fori radiali | 2 fori direzionali [P4v1] | 300k sim: auto-blocco → win rate 17.3% |
| Mag 2026 PATCH | Zucca maturazione | 3 round | 2 round [P2] | 300k sim: Tre Sorelle nel 6% — irrilevante |
| Mag 2026 PATCH | Bonus Arte | +4 pt al più votato | +2 pt, non al leader [P5] | 300k sim: andava al leader nel 100% |
| Mag 2026 P3v2 | Bonus Ragno | 2+ chiodini ADJ + dispari | 1 chiodino ADJ + dispari | S1: 1 attivazione/partita → condizione doppia troppo restrittiva |
| Mag 2026 P1v2 | El Niño | 4/5/6 soglie + +1 acqua | 3/4/5 + +2 acqua − 1pt/abbattimento | S1: 1 abbattimento → El Niño quasi sparita. Ripristino +2 con costo differito |
| Mag 2026 P4v2 | Orca | Solo blocco 2 fori | Blocco + +1 acqua ADJ al blocco | S1: Orca 0 economia, 0 raccolti. Problema strutturale. |
| Mag 2026 P1v3 | El Niño soglie | 3/4/5 | 4/5/6 | Sim v2: 76.5% a 4G con 3/4/5. Doppio disincentivo stima 40–55%. |
| Mag 2026 P6 | Colibrì Mobilità | Spostamento puro | Spostamento + +1 acqua se dest. è sorgente propria carta | Sim v2: Mobilità pura 17.3% → troppo sotto target. P6 aggiunge rendita idrica sistematica. |
| Mag 2026 PROP3 | Tre Sorelle | Adiacenza spaziale obbligatoria | Set collection puro — no adiacenza | Sim v3: 20.5%→31.8%. Rimosso puzzle spaziale eccessivo. |
| Mag 2026 PROP1 | Orca canali | Blocco + +1 acqua ADJ | Blocco + +1 acqua ADJ + terreni ADJ neutri −1 irrigazione | Orca 28%→29.9%. Motore agricolo integrato. |
| Mag 2026 PROP4 | El Niño abbattimento | Azione normale (3/turno) | Azione gratuita 1×/partita + −1pt | Free 1×/round→97.3% attivazione. Corretta a 1×/partita. |
| Mag 2026 v8 CANALI | Orca — bonus CANALI | Sconto legato alla posizione fisica tessere campo (fuori plancia) | Sconto legato al nodo di bordo toccato: −1 semina per neutro ADJ al nodo di bordo. Misurabile solo sulla plancia. | Conflitto spaziale: le tessere campo sono fuori dalla griglia, "adiacente al corridoio" non era definibile. |
| Mag 2026 v8 BORDO | Irrigare a Valle — "toccare il bordo" | Definizione implicita (filo oltre il bordo) | Definizione esplicita: chiodino nell'ultima fila/colonna della griglia per il versante scelto. | Ambiguità al tavolo eliminata. |

## 19.4  Questioni aperte residue — post patch

:::twocol
| Questione | Stato |
|-----------|-------|
| Orca: verificare bilanciamento post-patch | Blocco direzionale 2 fori non è stato simulato. Testare 5 partite e misurare win rate. |
| Ragno: verificare efficacia P3v2 | Win rate simulato 33.8% — ancora sopra target 25%. Monitorare nel fisico prima di ulteriori patch. |
| Colibrì: Mobilità+ — gap canonico residuo | Win rate simulato canonico: 22.8% (target 25%). Gap ancora presente. Monitorare nel fisico. |
| Condor: ogni round vs una volta | Invariato — ogni round (canonico) più ricco strategicamente. |
| Sassoso: incluso o rimosso | Verificare al primo playtest fisico se aggiunge decisioni o solo complessità. |
:::

## 19.5  Patch Note — PATCH 300k (Maggio 2026)

> [!NOTE]
> Queste patch sono state implementate dopo 300.000 simulazioni Monte Carlo su griglia 20×27 reale. Le simulazioni precedenti (900k, Game Bible v3) usavano griglia 10×10 semplificata e non rilevavano questi squilibri.

| # | Sistema | Problema rilevato | Soluzione implementata | Effetto atteso |
|---|---------|-------------------|----------------------|----------------|
| P1 | El Niño | Attivazione 69% a 4G (target 35–45%). Soglie troppo basse. | P1v1: soglie 4/5/6 + abbattimento −2→+1 acqua. P1v2: soglie 3/4/5 + +2 acqua + −1pt. P1v3 (attuale): soglie 4/5/6 + +2 acqua + −1pt + azione gratuita 1×/partita. | Attivazione stimata 40–55% a 4G |
| P2 | Zucca / Tre Sorelle | Tre Sorelle nel 6% delle partite (target 40–60%). Zucca troppo lenta. | Zucca: 3 → 2 round maturazione. | Frequenza triadi stimata: 25–45% |
| P3 | Ragno | Win rate 44.9% (target 25%). Bonus troppo facile da attivare. | P3v1: 2+ chiodini ADJ + round dispari. P3v2 (attuale): 1 chiodino ADJ + round dispari. | Win rate stimato P3v2: 28–34% |
| P4 | Orca | Win rate 17.3% (target 25%). Auto-blocco radiale penalizza la propria rete. | Blocco direzionale: 2 fori nella direzione scelta invece di 4 fori radiali. | Win rate stimato: 20–27% |
| P5 | Bonus Arte | Andava al leader nel 100% (strutturalmente correlato al completamento). | Ridotto da +4 a +2 pt + regola anti-leader. | Correlazione leader stimata: <70% |

## 19.6  Strumenti digitali di supporto

:::twocol
| Strumento | Descrizione |
|-----------|-------------|
| Nazca Peg Mapper | App HTML/JS con Claude Vision API. Analizza foto di geoglifi reali e suggerisce posizionamento chiodini sulla griglia 20×27. Costruita, da integrare nel workflow di playtesting. |
| Tabletop Simulator (TTS) | Implementazione digitale con Custom Tokens + Snap Points per chiodini, Lua Vector Lines per corde. Da aggiornare con le patch 300k prima di usare per playtest digitali. |
| Python/NumPy Monte Carlo v1 | 900.000 partite su griglia 10×10. Calibrazione originale Game Bible v3. |
| Python/NumPy Monte Carlo v2 | 300.000 partite su griglia 20×27 reale. Prima generazione patch. Report: NAZCA_SimReport_v2_300k.pdf |
| Python/NumPy Monte Carlo v3 | 300.000 partite su griglia 20×27. Proposte design PROP1/3/4. Report: NAZCA_SimReport_v3_300k.pdf |
:::

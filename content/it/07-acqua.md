# PARTE VII — SISTEMA DELL'ACQUA

> [!WARNING]
> REDESIGN v8 — due piani geografici: L'acqua nasce sulla pampa (sorgenti sotterranee), viene convogliata attraverso la rete di chiodini-cordicella fino al bordo della plancia (puquio + catena), e scende a valle (fuori dalla plancia) dove irriga i campi. Non c'è più irrigazione sulla plancia.

## 7.1  I tre stati dell'acqua

> [!NOTE]
> Gli stati dell'acqua sono tutti fisicamente rappresentati da token azzurri in posizioni concrete. Non esiste uno stato "in transito" in cui un token vada posizionato fisicamente sulla cordicella — sarebbe instabile e non necessario. Il filo è un indicatore visivo del percorso; il token si muove solo tra il nodo-puquio e la riserva personale.

| Stato | Posizione fisica | Come cambia stato |
|-------|-----------------|-------------------|
| 🔵 BLOCCATA | Token azzurro sul chiodino puquio (nodo-sorgente) — visibile a tutti | La catena raggiunge il bordo del suo versante → il token si sposta nella riserva personale |
| 🟢 DISPONIBILE | Riserva personale dietro lo schermetto | Spendibile subito: 1 acqua (mais/fagioli/zucca) · 2 acqua (cotone) · 0 su argilloso (fagioli) |
| ⚡ PRODOTTA | Generata dalla riserva centrale a fine round — va direttamente in Disponibile | +1 per ogni puquio con catena connessa al bordo |

**Flusso completo:** piazzi il puquio → posi un token sul chiodino terracotta (Bloccata). Tracci verso il bordo. Quando la catena tocca il bordo → sposti il token nella riserva (Disponibile). Ogni fine round: aggiungi 1 token dalla riserva centrale per ogni puquio ancora connesso (Prodotta → Disponibile).

## 7.2  La catena — due funzioni nella stessa cordicella

La cordicella di ogni clan compie due cose contemporaneamente:

- **Parte interna (base → sorgenti):** disegna il geoglifo. Segue il percorso della carta segreta.
- **Parte esterna (puquio → bordo):** costruisce il puquio-acquedotto. Porta l'acqua dal sottosuolo verso la valle.

Non sono due cordicelle diverse — è la stessa. Al momento della Rivelazione si vedono entrambe le funzioni simultaneamente.

## 7.3  Le sorgenti — visibili a tutti, la mappa è asimmetrica

Le 12 sorgenti (S1–S12) sono visibili a tutti sull'overlay. Ma la conoscenza idrologica è asimmetrica: ogni clan conosce solo le sorgenti indicate sulla propria carta geoglifo.

**Vincolo del puquio (regola strutturale):** puoi costruire un puquio SOLO su sorgenti della tua carta geoglifo. Raggiungere fisicamente una sorgente altrui non ti dà diritto di scavarci — non hai la mappa di quel flusso sotterraneo.

Raggiungere una sorgente della tua carta non obbliga a costruire il puquio. Alcune sorgenti non giustificano lo scavo — troppo lontane dal bordo, troppo filo consumato.

## 7.4  Produzione automatica a fine round

Alla fine di ogni round: per ogni puquio con catena ininterrotta fino al bordo, il giocatore riceve 1 token acqua nella riserva personale.

**Efficienza della rete:** avere 3 puquios connessi al bordo = +3 acqua/round automatici. La costruzione iniziale è lenta ma il rendimento è cumulativo e permanente.

## 7.5  Bonus continuità

Se la catena conta 5+ nodi consecutivi tutti sul percorso della carta geoglifo (on-path), il giocatore guadagna +1 acqua a inizio di ogni suo turno. Il bonus decade se il percorso viene interrotto da un blocco avversario.

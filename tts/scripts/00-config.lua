-- ═══════════════════════════════════════════════════════════════
-- NAZCA v8 — TTS Global Script
-- Game Bible v8.0 · Ramo v3.1 «Corde» · Griglia 20×27
-- ═══════════════════════════════════════════════════════════════

-- ─── GRIGLIA ─────────────────────────────────────────────────
COLS = 20   -- colonne A(0) … T(19)
ROWS = 27   -- righe   1(0) … 27(26)
TOTAL_NODES = COLS * ROWS  -- 540

-- Coordinate TTS per ogni nodo (1-indexed)
-- x = -4.75 + col * 0.50  →  da -4.75 a +4.75
-- z = -6.50 + row * 0.50  →  da -6.50 a +6.50
HOLES = {}
for row = 0, ROWS - 1 do
    for col = 0, COLS - 1 do
        local idx = row * COLS + col + 1
        HOLES[idx] = Vector(-4.75 + col * 0.50, 0.12, -6.50 + row * 0.50)
    end
end

function holeIndex(row, col)  return row * COLS + col + 1  end
function holeRow(idx)         return math.floor((idx-1) / COLS)  end
function holeCol(idx)         return (idx-1) % COLS  end

-- ─── BORDI VERSANTE (v8 — definizione esplicita) ──────────────
-- «Toccare il bordo» = chiodino nell'ultima riga/colonna
BORDER = {
    nord  = { axis='row', val=0  },   -- riga 1
    sud   = { axis='row', val=26 },   -- riga 27
    ovest = { axis='col', val=0  },   -- colonna A
    est   = { axis='col', val=19 },   -- colonna T
}

function isBorderNode(idx, versante)
    local b = BORDER[versante]
    if not b then return false end
    if b.axis == 'row' then return holeRow(idx) == b.val end
    return holeCol(idx) == b.val
end

-- ─── SORGENTI S1–S12 ─────────────────────────────────────────
-- Formato: {indice_nodo, nome, zona}
SOURCES = {
    S1  = { idx=holeIndex(2,2),   name='S1',  zone='alto-sx'       },
    S2  = { idx=holeIndex(3,16),  name='S2',  zone='alto-dx'       },
    S3  = { idx=holeIndex(5,9),   name='S3',  zone='alto-centro'   },
    S4  = { idx=holeIndex(10,1),  name='S4',  zone='sx-centrale'   },
    S5  = { idx=holeIndex(9,18),  name='S5',  zone='dx-centrale'   },
    S6  = { idx=holeIndex(13,6),  name='S6',  zone='centro-sx'     },
    S7  = { idx=holeIndex(13,13), name='S7',  zone='centro-dx'     },
    S8  = { idx=holeIndex(17,10), name='S8',  zone='centro-basso'  },
    S9  = { idx=holeIndex(20,3),  name='S9',  zone='basso-sx'      },
    S10 = { idx=holeIndex(21,16), name='S10', zone='basso-dx'      },
    S11 = { idx=holeIndex(24,8),  name='S11', zone='basso-centro-sx'},
    S12 = { idx=holeIndex(25,14), name='S12', zone='basso-centro-dx'},
}

-- Set rapido per lookup
SOURCE_IDX_SET = {}
for _, s in pairs(SOURCES) do SOURCE_IDX_SET[s.idx] = s.name end

-- ─── HUARANGO H1–H6 ──────────────────────────────────────────
HUARANGO_POSITIONS = {
    H1 = holeIndex(6,4),
    H2 = holeIndex(5,15),
    H3 = holeIndex(15,1),
    H4 = holeIndex(16,18),
    H5 = holeIndex(22,6),
    H6 = holeIndex(23,14),
}

-- ─── BASI CLAN ────────────────────────────────────────────────
CLAN_BASES = {
    ragno  = holeIndex(26, 0),   -- SW
    orca   = holeIndex(26, 19),  -- SE
    colibri= holeIndex(0,  0),   -- NW
    condor = holeIndex(0,  19),  -- NE
}

-- ─── COLORI CLAN ─────────────────────────────────────────────
CLAN_COLORS = {
    ragno  = {0.90, 0.15, 0.15, 1},
    orca   = {0.15, 0.40, 0.85, 1},
    colibri= {0.15, 0.75, 0.25, 1},
    condor = {0.95, 0.95, 0.88, 1},
}
CLAN_ORDER = {'ragno','orca','colibri','condor'}

COLOR_TO_CLAN = {
    Red='ragno', Blue='orca', Green='colibri', White='condor',
}

function clanColor(clan) return CLAN_COLORS[clan] or {1,1,1,1} end
function clanTTSColor(clan)
    local map={ragno='Red',orca='Blue',colibri='Green',condor='White'}
    return map[clan] or 'White'
end

-- ─── GUID OGGETTI TTS ─────────────────────────────────────────
-- Devono corrispondere ai GUID nel template save.json
GUID = {
    board          = 'aa0001',
    ui_panel       = 'aa0002',
    bag_ragno      = 'aa0003',
    bag_orca       = 'aa0004',
    bag_colibri    = 'aa0005',
    bag_condor     = 'aa0006',
    bag_puquio     = 'aa0007',
    bag_orca_neutri= 'aa0008',
    counter_acqua  = { ragno='aa0009', orca='aa0010', colibri='aa0011', condor='aa0012' },
    counter_elnino = 'aa0013',
    counter_round  = 'aa0014',
    huarango       = { H1='aa0015', H2='aa0016', H3='aa0017', H4='aa0018', H5='aa0019', H6='aa0020' },
    zone_hidden    = { ragno='aa0021', orca='aa0022', colibri='aa0023', condor='aa0024' },
    card_elnino    = 'aa0027',
    score_track    = 'aa0032',
    -- score_markers: aa0033-aa0036 riservati (i segnalini sono gestiti
    --  dinamicamente via scoreMarkers{} in 09-components.lua)
    -- deck_geoglifi / deck_obiettivi / valley_boards: oggetti facoltativi (aggiungere al template se necessario)
}

-- ─── PARAMETRI DI GIOCO v8 ───────────────────────────────────
PARAMS = {
    acqua_iniziale       = 2,
    round_massimi        = 6,
    soglia_completamento_alto = 0.72,   -- >72% → +5pt
    soglia_completamento_basso= 0.50,   -- <50% → -3pt
    bonus_completamento_alto  = 5,
    penalita_completamento_basso = -3,
    bonus_arte           = 2,
    bonus_farming        = 3,           -- ≥2 campi → +3pt
    bonus_tre_sorelle    = 5,           -- per triade
    bonus_sopravvivenza  = 3,           -- 0 huarango tagliati → +3 a tutti
    penalita_elnino      = -3,          -- tutti se soglia superata
    penalita_huarango    = -1,          -- per abbattimento individuale
    abbattimento_acqua   = 2,           -- +2 acqua per huarango tagliato
    continuita_min_nodi  = 5,           -- ≥5 nodi on-path consecutivi → +1 acqua/turno
    azioni_per_turno     = 3,
    coltura_punti        = { mais=3, fagioli=2, zucca=4, cotone=2 },
    coltura_rounds       = { mais=2, fagioli=1, zucca=2, cotone=2 },
    coltura_costo_acqua  = { mais=1, fagioli=1, zucca=1, cotone=2 },
}

-- ═══════════════════════════════════════════════════════════════
-- SEZIONE 1: STATO DI GIOCO
-- ═══════════════════════════════════════════════════════════════

gameState = nil

function initGameState()
    gameState = {
        round         = 1,
        currentClan   = 'ragno',
        phase         = 'azioni',   -- 'maturazione' | 'azioni' | 'produzione' | 'fine'
        actionsLeft   = PARAMS.azioni_per_turno,
        revealed      = false,
        elNinoThreshold  = math.random(4,6),  -- soglia segreta 4/5/6 (simula estrazione carta)
        elNinoRevealed   = false,
        fellings      = 0,          -- contatore globale abbattimenti

        -- Per clan
        clans = {},
    }

    for _, clan in ipairs(CLAN_ORDER) do
        gameState.clans[clan] = {
            water        = PARAMS.acqua_iniziale,
            score        = 0,
            pegs         = {},      -- set di idx nodi occupati da questo clan
            puquios      = {},      -- idx nodi con puquio attivo
            orca_neutral = {},      -- idx nodi con chiodino neutro (solo Orca)
            versante     = nil,     -- 'nord'|'sud'|'est'|'ovest' scelto nel setup
            hasUsedFelling = false, -- azione gratuita huarango 1×/partita
            colibriUsedThisRound = false,
            condorSpiedThisRound = false,
            ragnoActivatedThisRound = false,

            -- Valle (campi off-board, v8)
            fields = {},            -- {type, irrigated, crop, cropRounds, cropType}
            harvested = {},         -- tessere raccolte per punteggio

            -- Info geoglifo (caricata dalla carta)
            geoglyphPath = {},      -- set di idx nodi on-path
            geoglyphSources = {},   -- set di idx sorgenti della carta
        }
        -- 5 tessere campo: 2 alluvionale, 2 argilloso, 1 sabbioso
        for i = 1,2 do table.insert(gameState.clans[clan].fields,
            {type='alluvionale', irrigated=false, crop=nil, cropRounds=0, cropType=nil}) end
        for i = 1,2 do table.insert(gameState.clans[clan].fields,
            {type='argilloso', irrigated=false, crop=nil, cropRounds=0, cropType=nil}) end
        table.insert(gameState.clans[clan].fields,
            {type='sabbioso', irrigated=false, crop=nil, cropRounds=0, cropType=nil})
    end
end

-- Nota: la produzione acqua avviene in phaseProduzioneAcqua() (02-grid.lua)

-- Fine turno singolo giocatore
function endTurn(clan)
    local cs = gameState.clans[clan]
    cs.colibriUsedThisRound = false
    cs.condorSpiedThisRound = false
    cs.ragnoActivatedThisRound = false
    -- (gameState.actionsLeft aggiornato sotto)

    -- Passa al prossimo clan
    local idx = 1
    for i, c in ipairs(CLAN_ORDER) do if c == clan then idx = i; break end end
    local nextIdx = (idx % #CLAN_ORDER) + 1
    local nextClan = CLAN_ORDER[nextIdx]

    if nextIdx == 1 then
        -- Tutti hanno giocato: fase produzione, poi prossimo round
        phaseProduzioneAcqua()
        gameState.round = gameState.round + 1
        if gameState.round > PARAMS.round_massimi then
            triggerRivelazione()
            return
        end
        phaseMaturazione()
        updateCropVisualsAfterMaturation()  -- aggiorna visivi colture mature
        updateAllScoreMarkers()             -- aggiorna traccia punteggio
        gameState.phase = 'azioni'
        broadcastToAll('═ ROUND ' .. gameState.round .. ' ═', {1,0.9,0.5})
    end

    gameState.currentClan = nextClan
    gameState.actionsLeft = PARAMS.azioni_per_turno

    -- Bonus continuità a inizio turno
    if checkBonusContinuita(nextClan) then
        gameState.clans[nextClan].water = gameState.clans[nextClan].water + 1
        printToColor('+1💧 bonus continuità!', clanTTSColor(nextClan))
    end

    broadcastToAll('Turno di: ' .. nextClan:upper(), clanColor(nextClan))
    updateAllUI()
end

-- Fine partita manuale (cordicella esaurita)
function checkCordellaEsaurita(clan)
    -- Chiamata quando un giocatore passa senza azioni: flag per trigger automatico
    gameState.clans[clan].cordExhausted = true
    local all = true
    for _, c in ipairs(CLAN_ORDER) do
        if not gameState.clans[c].cordExhausted then all=false; break end
    end
    if all then triggerRivelazione() end
end

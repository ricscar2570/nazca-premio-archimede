-- ═══════════════════════════════════════════════════════════════
-- SEZIONE 6: LA RIVELAZIONE
-- ═══════════════════════════════════════════════════════════════

function triggerRivelazione()
    gameState.revealed = true
    gameState.phase = 'fine'

    broadcastToAll('★ ★ ★  LA RIVELAZIONE  ★ ★ ★', {1,0.85,0.2})
    broadcastToAll('Alzatevi in piedi. Guardate la plancia dall\'alto.', {1,1,1})

    -- Passo 1: rivela tutte le carte geoglifo
    Wait.time(function()
        for _, clan in ipairs(CLAN_ORDER) do
            local zone = getObjectFromGUID(GUID.zone_hidden[clan])
            if zone then
                for _, obj in ipairs(zone.getObjects()) do
                    if obj.type=='Card' and obj.is_face_down then obj.flip() end
                end
            end
        end
        broadcastToAll('Carte geoglifo rivelate!', {1,0.9,0.5})
    end, 2)

    -- Passo 2: disegna overlay geoglifi (percorsi ideali in trasparenza)
    Wait.time(function()
        drawGeoglyphOverlays()
        broadcastToAll('Overlay percorsi attivati (trasparenza 30%).', {0.8,0.8,0.8})
    end, 4)

    -- Passo 3: rivela carta El Niño
    Wait.time(function()
        local card = getObjectFromGUID(GUID.card_elnino)
        if card and card.is_face_down then card.flip() end
        gameState.elNinoRevealed = true
        broadcastToAll('Soglia El Niño rivelata: ' ..
            gameState.elNinoThreshold .. ' alberi.', {1,0.6,0.2})
    end, 7)

    -- Passo 4: calcola e mostra punteggi
    Wait.time(function()
        local scores, harvestLeader = calculateFinalScores()
        gameState.cachedHarvestLeader = harvestLeader  -- usato da !arte
        displayFinalScores(scores)
        -- Votazione Arte: gestita via chat (risultato inserito con !arte NOMECLAN)
        broadcastToAll('Votazione Bonus Arte: scrivete in chat  !arte NOMECLAN',
            {0.8,0.8,1})
    end, 10)
end

-- Overlay trasparente dei percorsi ideali
function drawGeoglyphOverlays()
    local lines = Global.getVectorLines() or {}
    for _, clan in ipairs(CLAN_ORDER) do
        local cs = gameState.clans[clan]
        local col = clanColor(clan)
        local path = cs.geoglyphPath  -- array ordinato di idx
        for i = 1, #path-1 do
            if HOLES[path[i]] and HOLES[path[i+1]] then
                table.insert(lines, {
                    points    = {HOLES[path[i]], HOLES[path[i+1]]},
                    color     = {col[1], col[2], col[3], 0.30},
                    thickness = 0.04,
                })
            end
        end
    end
    Global.setVectorLines(lines)
end

-- ═══════════════════════════════════════════════════════════════
-- SEZIONE 7: VECTOR LINES E UI
-- ═══════════════════════════════════════════════════════════════

-- Ridisegna le cordicelle di un clan come Vector Lines TTS
function redrawClanLines(clan)
    local cs = gameState.clans[clan]
    local col = clanColor(clan)
    -- Rimuovi le linee precedenti di questo clan e ridisegna
    -- (TTS non supporta linee per-oggetto nel Global script;
    --  usiamo setVectorLines sull'oggetto plancia)
    local board = getObjectFromGUID(GUID.board)
    if not board then return end

    local allLines = board.getVectorLines() or {}
    -- Rimuovi linee di questo clan (marcate con thickness unica per clan)
    local CLAN_THICKNESS = {ragno=0.08, orca=0.09, colibri=0.10, condor=0.11}
    local kept = {}
    for _, l in ipairs(allLines) do
        if l.thickness ~= CLAN_THICKNESS[clan] then
            table.insert(kept, l)
        end
    end

    -- Rigenera le linee dai pegs (catena di adiacenza)
    -- Semplificazione: collega i pegs nell'ordine in cui sono stati piazzati
    for i = 2, #cs.pegs do
        if HOLES[cs.pegs[i-1]] and HOLES[cs.pegs[i]] then
            table.insert(kept, {
                points    = {HOLES[cs.pegs[i-1]], HOLES[cs.pegs[i]]},
                color     = {col[1], col[2], col[3], 0.85},
                thickness = CLAN_THICKNESS[clan],
            })
        end
    end

    board.setVectorLines(kept)
end

function updateAllUI()
    -- Aggiorna i counter acqua
    for _, clan in ipairs(CLAN_ORDER) do
        local counter = getObjectFromGUID(GUID.counter_acqua[clan])
        if counter then counter.setValue(gameState.clans[clan].water) end
    end
    -- Aggiorna counter round
    local rc = getObjectFromGUID(GUID.counter_round)
    if rc then rc.setValue(gameState.round) end
    -- Aggiorna counter El Niño
    local en = getObjectFromGUID(GUID.counter_elnino)
    if en then en.setValue(gameState.fellings) end
end

function createActionButtons()
    local ui = getObjectFromGUID(GUID.ui_panel)
    if not ui then return end
    ui.clearButtons()

    local btns = {
        {label='Puquio\n(1 azione)',    fn='btn_puquio',   pos={0,0.5,-3.0}},
        {label='Irriga Valle\n(0💧)',   fn='btn_irriga',   pos={0,0.5,-2.4}},
        {label='Semina\nMais -1💧',    fn='btn_mais',     pos={0,0.5,-1.8}},
        {label='Semina\nFagioli -1💧', fn='btn_fagioli',  pos={0,0.5,-1.2}},
        {label='Semina\nZucca -1💧',   fn='btn_zucca',    pos={0,0.5,-0.6}},
        {label='Semina\nCotone -2💧',  fn='btn_cotone',   pos={0,0.5, 0.0}},
        {label='Raccogli',             fn='btn_raccogli', pos={0,0.5, 0.6}},
        {label='Abbatti\nHuarango ★',  fn='btn_abbatti',  pos={0,0.5, 1.2}},
        {label='PASSA',                fn='btn_passa',    pos={0,0.5, 2.0}},
        {label='★ RIVELAZIONE',        fn='btn_rivela',   pos={0,0.5, 3.0}},
    }
    -- Pulsanti poteri clan (fuori azioni)
    local clanBtns = {
        {label='Mobilità+\nColibrì',   fn='btn_colibri',  pos={0,0.5, 3.8}},
        {label='Spia\nCondor',         fn='btn_condor',   pos={0,0.5, 4.4}},
    }

    for _, b in ipairs(btns) do
        ui.createButton({label=b.label, click_function=b.fn,
            position=b.pos, width=280, height=160, font_size=85,
            color={0.15,0.15,0.15,0.85}, font_color={1,1,1}})
    end
    for _, b in ipairs(clanBtns) do
        ui.createButton({label=b.label, click_function=b.fn,
            position=b.pos, width=280, height=130, font_size=80,
            color={0.1,0.1,0.4,0.85}, font_color={1,1,1}})
    end
end

-- Handler pulsanti (chiamano le funzioni azione con il clan del giocatore)
function btn_puquio(obj, playerColor) actionPuquio(COLOR_TO_CLAN[playerColor], lastHoveredNode) end
function btn_irriga(obj, playerColor) actionIrrigaValle(COLOR_TO_CLAN[playerColor], lastSelectedField) end
function btn_mais(obj, playerColor)   actionSemina(COLOR_TO_CLAN[playerColor], lastSelectedField, 'mais') end
function btn_fagioli(obj, playerColor) actionSemina(COLOR_TO_CLAN[playerColor], lastSelectedField, 'fagioli') end
function btn_zucca(obj, playerColor)  actionSemina(COLOR_TO_CLAN[playerColor], lastSelectedField, 'zucca') end
function btn_cotone(obj, playerColor) actionSemina(COLOR_TO_CLAN[playerColor], lastSelectedField, 'cotone') end
function btn_raccogli(obj, playerColor) actionRaccogli(COLOR_TO_CLAN[playerColor], lastSelectedField) end
function btn_abbatti(obj, playerColor) actionAbbatti(COLOR_TO_CLAN[playerColor], lastSelectedHuarango or 'H1') end
function btn_passa(obj, playerColor)  actionPassa(COLOR_TO_CLAN[playerColor]) end
function btn_rivela(obj, playerColor) triggerRivelazione() end
function btn_colibri(obj, playerColor) colibriMovePeg(lastHoveredNode, lastHoveredNodeDest) end
function btn_condor(obj, playerColor)  condorSpyCard(lastSelectedTargetClan) end

-- Variabili di stato per l'interazione UI
lastHoveredNode     = nil
lastHoveredNodeDest = nil
lastSelectedField   = 1
lastSelectedHuarango= 'H1'
lastSelectedTargetClan = 'ragno'

-- ═══════════════════════════════════════════════════════════════
-- SEZIONE 8: ENTRY POINTS — onLoad, onObjectDrop, onChat
-- ═══════════════════════════════════════════════════════════════

function onLoad(savedState)
    if savedState and savedState ~= '' then
        local ok, data = pcall(JSON.decode, savedState)
        if ok and data then
            gameState = data
            Wait.frames(function()
                createActionButtons()
                updateAllUI()
                initAllComponents()  -- ricostruisce componenti da stato salvato
            end, 5)
            return
        end
    end
    initGameState()
    Wait.frames(function()
        createActionButtons()
        initAllComponents()  -- tessere campo, colture, traccia punteggio
        broadcastToAll('NAZCA v8 caricato. Usate !versante CLAN DIREZIONE per scegliere il versante.',{1,1,1})
        broadcastToAll('Buona partita!', {0.8,0.9,1})
    end, 5)
end

function onSave()
    return JSON.encode(gameState)
end

-- Quando un chiodino clan viene posizionato sulla plancia
function onObjectDrop(playerColor, obj)
    if not gameState then return end
    local clan = COLOR_TO_CLAN[playerColor]
    if not clan then return end

    -- Rileva il nodo più vicino allo snap point
    local pos = obj.getPosition()
    local nearest, minDist = nil, 99999
    for i, hole in ipairs(HOLES) do
        local d = (Vector(pos.x,0,pos.z) - Vector(hole.x,0,hole.z)):magnitude()
        if d < minDist then minDist=d; nearest=i end
    end
    if nearest and minDist < 0.4 then
        local tag = obj.getDescription()
        if tag:find('peg_' .. clan) then
            actionTraccia(clan, nearest)
            lastHoveredNode = nearest
        elseif tag:find('puquio') then
            actionPuquio(clan, nearest)
        end
    end
end

-- Chat per versante, spiata Orca, spiata Condor, risultato Arte
function onChat(msg, player)
    local parts = {}
    for w in msg:gmatch('%S+') do table.insert(parts, w) end
    local cmd = parts[1]

    -- !versante ragno nord
    if cmd == '!versante' and parts[2] and parts[3] then
        local clan, dir = parts[2]:lower(), parts[3]:lower()
        if gameState.clans[clan] and BORDER[dir] then
            gameState.clans[clan].versante = dir
            broadcastToAll(clan:upper() .. ' sceglie versante ' ..
                dir:upper() .. '.', clanColor(clan))
            spawnFieldTiles(clan, dir)  -- spawn tessere campo a valle
        end
        return false
    end

    -- !orca EW (blocco direzionale — deve seguire il piazzamento di un chiodino blu)
    if cmd == '!orca' and parts[2] then
        if not lastHoveredNode then
            printToColor('Piazza prima un chiodino, poi usa !orca EW|NS', 'Blue')
        else
            applyOrcaBlock(lastHoveredNode, parts[2]:upper())
        end
        return false
    end

    -- !spia ragno (Condor spia il Ragno)
    if cmd == '!spia' and parts[2] then
        condorSpyCard(parts[2]:lower()); return false end

    -- !arte ragno (votazione Arte — usa harvestLeader già calcolato alla Rivelazione)
    if cmd == '!arte' and parts[2] then
        local winner = parts[2]:lower()
        if gameState.clans[winner] then
            applyArtBonus(winner, gameState.cachedHarvestLeader)
        end
        return false
    end

    -- !campo 2 (seleziona il campo N per le azioni valle)
    if cmd == '!campo' and parts[2] then
        lastSelectedField = tonumber(parts[2]) or 1
        printToColor('Campo ' .. lastSelectedField .. ' selezionato.', player.color)
        return false
    end

    -- !huarango H3
    if cmd == '!huarango' and parts[2] then
        lastSelectedHuarango = parts[2]:upper()
        printToColor('Huarango ' .. lastSelectedHuarango .. ' selezionato.', player.color)
        return false
    end

    -- !geoglifo ragno 45 77 110 ... (imposta il percorso segreto via chat per test)
    if cmd == '!geoglifo' and parts[2] then
        local clan = parts[2]:lower()
        if gameState.clans[clan] then
            gameState.clans[clan].geoglyphPath = {}
            gameState.clans[clan].geoglyphSources = {}
            for i = 3, #parts do
                local idx = tonumber(parts[i])
                if idx then
                    table.insert(gameState.clans[clan].geoglyphPath, idx)
                    if SOURCE_IDX_SET[idx] then
                        table.insert(gameState.clans[clan].geoglyphSources, idx)
                    end
                end
            end
            printToColor('Geoglifo ' .. clan .. ' impostato: ' ..
                #gameState.clans[clan].geoglyphPath .. ' nodi.', player.color)
        end
        return false
    end

    return true
end

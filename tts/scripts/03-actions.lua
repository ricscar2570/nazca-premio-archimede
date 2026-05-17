-- ═══════════════════════════════════════════════════════════════
-- SEZIONE 3: LE 8 AZIONI (v8)
-- 5.1 Tracciare · 5.2 Puquio · 5.3 Irrigare a Valle
-- 5.4 Seminare · 5.5 Raccogliere · 5.6 Ramificare
-- 5.7 Passare  · 5.8 Abbattere Huarango (gratuita 1×/partita)
-- ═══════════════════════════════════════════════════════════════

local function checkTurn(clan)
    if gameState.currentClan ~= clan then
        printToColor('Non è il tuo turno!', clanTTSColor(clan)); return false end
    if gameState.actionsLeft <= 0 then
        printToColor('Nessuna azione rimasta!', clanTTSColor(clan)); return false end
    return true
end

local function useAction(clan)
    gameState.clans[clan].actionsLeft = (gameState.clans[clan].actionsLeft or PARAMS.azioni_per_turno) - 1
    gameState.actionsLeft = gameState.actionsLeft - 1
end

-- ─── 5.1 TRACCIARE ───────────────────────────────────────────
-- Chiamata da onObjectDrop quando un chiodino clan viene posizionato
function actionTraccia(clan, targetIdx)
    if not checkTurn(clan) then return end
    local cs = gameState.clans[clan]

    -- Verifica adiacenza a un peg esistente o alla base
    local base = CLAN_BASES[clan]
    local isAdj = (#cs.pegs == 0 and targetIdx == base)
    if not isAdj then
        for _, p in ipairs(cs.pegs) do
            if isAdjacent(p, targetIdx) then isAdj=true; break end
        end
    end
    if not isAdj then
        printToColor('Nodo non adiacente!', clanTTSColor(clan)); return end

    -- Verifica nodo libero
    for _, c in ipairs(CLAN_ORDER) do
        for _, p in ipairs(gameState.clans[c].pegs) do
            if p == targetIdx then printToColor('Nodo occupato!',clanTTSColor(clan)); return end
        end
        for _, n in ipairs(gameState.clans[c].orca_neutral) do
            if n == targetIdx then printToColor('Nodo bloccato (neutro Orca)!',clanTTSColor(clan)); return end
        end
    end
    -- Controlla puquios di tutti i clan (non solo il proprio)
    for _, c in ipairs(CLAN_ORDER) do
        for _, p in ipairs(gameState.clans[c].puquios) do
            if p == targetIdx then printToColor('Nodo con puquio!',clanTTSColor(clan)); return end
        end
    end

    table.insert(cs.pegs, targetIdx)
    redrawClanLines(clan)
    useAction(clan)

    -- Verifica bonus Ragno P3v2
    checkRagnoBonus(clan, targetIdx)
    updateAllUI()
end

-- ─── 5.2 PUQUIO (NUOVA in v8) ────────────────────────────────
function actionPuquio(clan, sourceIdx)
    if not checkTurn(clan) then return end
    local cs = gameState.clans[clan]

    -- Vincolo: solo sorgenti della carta geoglifo
    local isOnCard = false
    for _, s in ipairs(cs.geoglyphSources) do
        if s == sourceIdx then isOnCard=true; break end
    end
    if not isOnCard then
        printToColor('Sorgente non sulla tua carta geoglifo!', clanTTSColor(clan)); return end

    -- La catena deve aver raggiunto fisicamente la sorgente
    if not isChainConnected(clan, sourceIdx) then
        printToColor('La tua catena non ha raggiunto S' .. (SOURCE_IDX_SET[sourceIdx] or '?'),
            clanTTSColor(clan)); return end

    -- Nessun puquio già presente
    for _, p in ipairs(cs.puquios) do
        if p == sourceIdx then
            printToColor('Puquio già presente su questa sorgente!', clanTTSColor(clan)); return end
    end

    table.insert(cs.puquios, sourceIdx)
    useAction(clan)

    -- Il token acqua rimane bloccato finché la catena non tocca il bordo
    broadcastToAll(clan:upper() .. ' costruisce puquio su ' .. (SOURCE_IDX_SET[sourceIdx] or '?'),
        clanColor(clan))
    updateAllUI()
end

-- ─── 5.3 IRRIGARE A VALLE (v8 — costo 0 acqua) ───────────────
function actionIrrigaValle(clan, fieldIndex)
    if not checkTurn(clan) then return end
    local cs = gameState.clans[clan]

    -- La catena deve toccare il bordo del versante scelto
    local touchesBorder = false
    for _, peg in ipairs(cs.pegs) do
        if isBorderNode(peg, cs.versante) then touchesBorder=true; break end
    end
    if not touchesBorder then
        printToColor('La catena non tocca ancora il bordo del versante ' ..
            (cs.versante or '?') .. '!', clanTTSColor(clan)); return end

    local field = cs.fields[fieldIndex]
    if not field then printToColor('Campo non valido!', clanTTSColor(clan)); return end
    if field.irrigated then printToColor('Campo già irrigato!', clanTTSColor(clan)); return end

    field.irrigated = true
    updateFieldTileVisual(clan, fieldIndex)  -- aggiorna visivo
    useAction(clan)
    -- Bonus Orca CANALI: conta i neutri ADJ al nodo di bordo toccato
    if clan == 'orca' then applyOrcaCanali(clan) end

    printToColor('Campo ' .. fieldIndex .. ' (' .. field.type .. ') irrigato! Costo: 0💧',
        clanTTSColor(clan))
    updateAllUI()
end

-- ─── 5.4 SEMINARE ────────────────────────────────────────────
-- cropType: 'mais'|'fagioli'|'zucca'|'cotone'
function actionSemina(clan, fieldIndex, cropType)
    if not checkTurn(clan) then return end
    local cs = gameState.clans[clan]
    local field = cs.fields[fieldIndex]
    if not field then printToColor('Campo non valido!', clanTTSColor(clan)); return end
    if not field.irrigated then
        printToColor('Campo non irrigato!', clanTTSColor(clan)); return end
    if field.crop then
        printToColor('Campo già seminato!', clanTTSColor(clan)); return end

    -- Costo acqua
    local cost = PARAMS.coltura_costo_acqua[cropType] or 1
    -- Bonus argilloso: fagioli gratis
    if field.type == 'argilloso' and cropType == 'fagioli' then cost = 0 end
    -- Bonus Orca CANALI: sconto dal bordo (v8)
    cost = applyOrcaSowDiscount(clan, cost)

    if cs.water < cost then
        printToColor('Acqua insufficiente (servono ' .. cost .. '💧)!', clanTTSColor(clan)); return end

    cs.water = cs.water - cost
    field.crop = true
    field.cropType = cropType
    field.cropRounds = 0

    -- Rounds fino a maturità (con bonus terreno)
    local roundsNeeded = PARAMS.coltura_rounds[cropType] or 2
    if (cropType=='mais' or cropType=='zucca') and field.type=='alluvionale' then roundsNeeded=1 end
    if cropType=='cotone' and field.type=='sabbioso' then roundsNeeded=1 end
    field.roundsNeeded = roundsNeeded

    spawnCropToken(clan, fieldIndex, cropType, false)  -- tessera seme
    useAction(clan)
    printToColor('Seminato ' .. cropType .. ' su campo ' .. fieldIndex ..
        ' (' .. field.type .. '). Matura in ' .. roundsNeeded .. ' round. -' .. cost .. '💧',
        clanTTSColor(clan))
    updateAllUI()
end

-- ─── 5.5 RACCOGLIERE ─────────────────────────────────────────
function actionRaccogli(clan, fieldIndex)
    if not checkTurn(clan) then return end
    local cs = gameState.clans[clan]
    local field = cs.fields[fieldIndex]
    if not field or not field.crop then
        printToColor('Nessun raccolto in questo campo!', clanTTSColor(clan)); return end
    if not field.mature then
        printToColor('Il raccolto non è ancora maturo!', clanTTSColor(clan)); return end

    local harvestedCropType = field.cropType  -- salva prima del reset
    local pts = PARAMS.coltura_punti[harvestedCropType] or 0
    cs.score = cs.score + pts
    table.insert(cs.harvested, {type=harvestedCropType, fieldType=field.type})

    -- Restituzione acqua: fagioli +1, cotone su sabbioso +1
    if field.cropType=='fagioli' then
        cs.water = cs.water + 1
        printToColor('+1💧 (fagioli)', clanTTSColor(clan))
    elseif field.cropType=='cotone' and field.type=='sabbioso' then
        cs.water = cs.water + 1
        printToColor('+1💧 (cotone su sabbioso)', clanTTSColor(clan))
    end

    removeCropToken(clan, fieldIndex)  -- rimuovi tessera coltura
    Wait.frames(function() updateScoreMarker(clan, cs.score) end, 5)
    -- Reset campo (resta irrigato)
    field.crop = false; field.cropType=nil; field.cropRounds=0
    field.mature = false; field.roundsNeeded = nil

    useAction(clan)
    printToColor('+' .. pts .. 'pt (' .. harvestedCropType .. ')', clanTTSColor(clan))
    updateAllUI()
end

-- ─── 5.6 RAMIFICARE ──────────────────────────────────────────
-- In TTS: l'utente sposta fisicamente il punto di partenza del filo.
-- Lo script semplicemente valida che il nuovo nodo sia adiacente a uno esistente.
function actionRamifica(clan, fromIdx, toIdx)
    if not checkTurn(clan) then return end
    local cs = gameState.clans[clan]
    -- Verifica fromIdx appartiene al clan
    local fromExists = false
    for _, p in ipairs(cs.pegs) do if p==fromIdx then fromExists=true; break end end
    if not fromExists then
        printToColor('Devi ramificare da un tuo chiodino!', clanTTSColor(clan)); return end
    -- toIdx libero e adiacente
    -- (stessa logica di actionTraccia)
    actionTraccia(clan, toIdx)  -- riusa la validazione
end

-- ─── 5.7 PASSARE ─────────────────────────────────────────────
function actionPassa(clan)
    if gameState.currentClan ~= clan then
        printToColor('Non è il tuo turno!', clanTTSColor(clan)); return end
    gameState.actionsLeft = 0
    printToColor('Passa.', clanTTSColor(clan))
    endTurn(clan)
end

-- ─── 5.8 ABBATTERE HUARANGO (gratuita 1×/partita) ────────────
function actionAbbatti(clan, huarangoId)
    if gameState.currentClan ~= clan then
        printToColor('Non è il tuo turno!', clanTTSColor(clan)); return end
    local cs = gameState.clans[clan]

    -- Seconda volta: costa 1 azione normale
    local free = not cs.hasUsedFelling
    if not free and gameState.actionsLeft <= 0 then
        printToColor('Nessuna azione rimasta!', clanTTSColor(clan)); return end

    -- L'huarango deve essere adiacente a un peg del clan
    local hPos = HUARANGO_POSITIONS[huarangoId]
    if not hPos then printToColor('Huarango non trovato!', clanTTSColor(clan)); return end
    local adj = false
    for _, p in ipairs(cs.pegs) do
        if isAdjacent(p, hPos) then adj=true; break end
    end
    if not adj then
        printToColor('Nessun tuo chiodino adiacente a ' .. huarangoId .. '!',
            clanTTSColor(clan)); return end

    -- Rimuovi token fisico
    local token = getObjectFromGUID(GUID.huarango[huarangoId])
    if token then token.destroy() end

    -- Effetti
    cs.water = cs.water + PARAMS.abbattimento_acqua
    gameState.fellings = gameState.fellings + 1
    cs.fellingCount = (cs.fellingCount or 0) + 1

    -- Irriga 1 campo gratis
    for i, f in ipairs(cs.fields) do
        if not f.irrigated then
            f.irrigated = true
            printToColor('Campo ' .. i .. ' irrigato gratis dall\'abbattimento!', clanTTSColor(clan))
            break
        end
    end

    if free then
        cs.hasUsedFelling = true
        broadcastToAll(clan:upper() .. ' abbatte ' .. huarangoId ..
            ' [GRATUITO]. +' .. PARAMS.abbattimento_acqua .. '💧. ' ..
            '⚠ Contatore El Niño: ' .. gameState.fellings, clanColor(clan))
    else
        useAction(clan)
        broadcastToAll(clan:upper() .. ' abbatte ' .. huarangoId ..
            ' [-1azione]. +' .. PARAMS.abbattimento_acqua .. '💧. ' ..
            '⚠ Contatore El Niño: ' .. gameState.fellings, clanColor(clan))
    end
    updateAllUI()
end

-- ─── MATURAZIONE (fase automatica a inizio round) ────────────
function phaseMaturazione()
    for _, clan in ipairs(CLAN_ORDER) do
        local cs = gameState.clans[clan]
        for i, f in ipairs(cs.fields) do
            if f.crop and not f.mature then
                f.cropRounds = (f.cropRounds or 0) + 1
                if f.cropRounds >= (f.roundsNeeded or 2) then
                    f.mature = true
                    printToColor('Raccolto maturo: campo ' .. i ..
                        ' (' .. (f.cropType or '?') .. ')!', clanTTSColor(clan))
                end
            end
        end
    end
end
-- chiamata da endTurn dopo phaseMaturazione()
-- updateCropVisualsAfterMaturation() è in 09-components.lua

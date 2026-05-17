-- ═══════════════════════════════════════════════════════════════
-- SEZIONE 4: POTERI CLAN (v8)
-- ═══════════════════════════════════════════════════════════════

-- ─── RAGNO P3v2: 1 chiodino ADJ + round DISPARI → +1 acqua ───
function checkRagnoBonus(clan, newPegIdx)
    if clan ~= 'ragno' then return end
    local cs = gameState.clans['ragno']
    if cs.ragnoActivatedThisRound then return end -- una sola volta per turno
    if gameState.round % 2 == 0 then return end   -- solo round dispari

    for _, other in ipairs(CLAN_ORDER) do
        if other ~= 'ragno' then
            for _, p in ipairs(gameState.clans[other].pegs) do
                if isAdjacent(p, newPegIdx) then
                    cs.water = cs.water + 1
                    cs.ragnoActivatedThisRound = true
                    printToColor('⚡ RAGNO — La Rete: +1💧 (chiodino ' .. other ..
                        ' adiacente, round dispari)', clanTTSColor('ragno'))
                    return
                end
            end
        end
    end
end

-- ─── ORCA P4v2: blocco direzionale E-W o N-S ─────────────────
-- direction: 'EW' | 'NS'
-- Chiamato quando il giocatore Orca pianta un chiodino blu
function applyOrcaBlock(nodeIdx, direction)
    local r, c = holeRow(nodeIdx), holeCol(nodeIdx)
    local cs = gameState.clans['orca']
    local newNeutri = {}

    if direction == 'EW' then
        -- Blocca i fori E e W — bound-check esplicito su colonne
        if c > 0      then table.insert(newNeutri, holeIndex(r, c-1)) end
        if c < COLS-1 then table.insert(newNeutri, holeIndex(r, c+1)) end
    elseif direction == 'NS' then
        -- Blocca i fori N e S — bound-check esplicito su righe
        if r > 0      then table.insert(newNeutri, holeIndex(r-1, c)) end
        if r < ROWS-1 then table.insert(newNeutri, holeIndex(r+1, c)) end
    end

    -- Bonus idrico (B): controlla neutri PRE-ESISTENTI prima di aggiungere i nuovi
    local bonusIdrico = false
    for _, existing in ipairs(cs.orca_neutral) do
        if isAdjacent(existing, nodeIdx) then bonusIdrico = true; break end
    end

    for _, nIdx in ipairs(newNeutri) do
        -- Non sovrascrivere pegs esistenti
        local occupied = false
        for _, c in ipairs(CLAN_ORDER) do
            for _, p in ipairs(gameState.clans[c].pegs) do
                if p == nIdx then occupied=true; break end
            end
        end
        if not occupied then
            table.insert(cs.orca_neutral, nIdx)
            -- Segna visivamente (chiodino nero)
            local obj = getObjectFromGUID(GUID.bag_orca_neutri)
            if obj then
                local neutro = obj.takeObject({position=HOLES[nIdx] + Vector(0,0.5,0)})
                if neutro then neutro.setName('neutro_' .. nIdx) end
            end
        end
    end

    if bonusIdrico then
        cs.water = cs.water + 1
        printToColor('⚡ ORCA — Bonus Idrico: +1💧 (ADJ a neutro preesistente)', clanTTSColor('orca'))
    end

    broadcastToAll('Orca blocca ' .. direction .. ' da nodo ' .. nodeIdx ..
        '. ' .. #newNeutri .. ' fori soffocati.', clanColor('orca'))
end

-- ─── ORCA CANALI rev. v8: −1 acqua su prossima semina ────────
-- Chiamato quando la catena Orca tocca il bordo
-- Conta i neutri ADJ al nodo di bordo toccato
function applyOrcaCanali(clan)
    if clan ~= 'orca' then return end
    local cs = gameState.clans['orca']
    local discount = 0
    -- Trova il nodo di bordo toccato più recente
    for _, peg in ipairs(cs.pegs) do
        if isBorderNode(peg, cs.versante) then
            local cnt = countNeutriAdjToBorderNode('orca', peg)
            if cnt > discount then discount = cnt end
        end
    end
    if discount > 0 then
        cs.canalDiscount = (cs.canalDiscount or 0) + discount
        printToColor('⚡ ORCA — Canali: −' .. discount .. '💧 sul prossimo seminare!',
            clanTTSColor('orca'))
    end
end

-- Applica lo sconto CANALI alla semina
function applyOrcaSowDiscount(clan, baseCost)
    if clan ~= 'orca' then return baseCost end
    local cs = gameState.clans['orca']
    local disc = cs.canalDiscount or 0
    if disc > 0 then
        local newCost = math.max(0, baseCost - disc)
        cs.canalDiscount = 0  -- usa il bonus una volta
        return newCost
    end
    return baseCost
end

-- ─── COLIBRÌ P6: Mobilità+ ────────────────────────────────────
-- Una volta per round, fuori azioni: sposta un chiodino
-- Se destIdx è sorgente della propria carta: +1 acqua
function colibriMovePeg(fromIdx, toIdx)
    local cs = gameState.clans['colibri']
    if cs.colibriUsedThisRound then
        printToColor('Mobilità già usata questo round!', clanTTSColor('colibri')); return end

    -- Verifica fromIdx appartiene al Colibrì
    local found = false
    for i, p in ipairs(cs.pegs) do
        if p == fromIdx then found=true;
            table.remove(cs.pegs, i); break end
    end
    if not found then
        printToColor('Chiodino non tuo!', clanTTSColor('colibri')); return end

    -- toIdx libero e adiacente a fromIdx
    if not isAdjacent(fromIdx, toIdx) then
        printToColor('Destinazione non adiacente!', clanTTSColor('colibri'));
        table.insert(cs.pegs, fromIdx); return end

    local occupied = false
    for _, clan in ipairs(CLAN_ORDER) do
        for _, p in ipairs(gameState.clans[clan].pegs) do
            if p == toIdx then occupied=true; break end
        end
    end
    if occupied then
        printToColor('Destinazione occupata!', clanTTSColor('colibri'));
        table.insert(cs.pegs, fromIdx); return end

    table.insert(cs.pegs, toIdx)
    cs.colibriUsedThisRound = true

    -- Bonus: se toIdx è sorgente della propria carta
    for _, s in ipairs(cs.geoglyphSources) do
        if s == toIdx then
            cs.water = cs.water + 1
            printToColor('⚡ COLIBRÌ — Mobilità+: +1💧 (sorgente propria carta!)',
                clanTTSColor('colibri'))
            break
        end
    end

    redrawClanLines('colibri')
    updateAllUI()
end

-- ─── CONDOR: Informazione ────────────────────────────────────
-- Una volta per round, fuori azioni: vede la carta geoglifo avversaria per 3 secondi
function condorSpyCard(targetClan)
    local cs = gameState.clans['condor']
    if cs.condorSpiedThisRound then
        printToColor('Spiata già usata questo round!', clanTTSColor('condor')); return end
    if targetClan == 'condor' then
        printToColor('Non puoi spiare te stesso!', clanTTSColor('condor')); return end

    -- Trova la carta nella Hidden Zone del clan target
    local zone = getObjectFromGUID(GUID.zone_hidden[targetClan])
    if not zone then return end

    local cards = zone.getObjects()
    local card = nil
    for _, obj in ipairs(cards) do
        if obj.type == 'Card' then card = obj; break end
    end
    if not card then return end

    card.flip()  -- mostra il fronte
    broadcastToAll('CONDOR guarda la carta di ' .. targetClan:upper() ..
        ' per 3 secondi…', clanColor('condor'))

    Wait.time(function()
        card.flip()
        broadcastToAll('Carta nascosta.', {0.6,0.6,0.6})
    end, 3)

    cs.condorSpiedThisRound = true
end

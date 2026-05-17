-- ═══════════════════════════════════════════════════════════════
-- SEZIONE 5: CALCOLO PUNTEGGIO FINALE (v8)
-- ═══════════════════════════════════════════════════════════════

function calculateFinalScores()
    local scores = {}
    local harvestLeader, harvestLeaderScore = nil, -1

    -- 1. Raccolti maturi (già accumulati in cs.score durante la partita)
    -- + nodi on-path + bonus completamento
    for _, clan in ipairs(CLAN_ORDER) do
        local cs = gameState.clans[clan]
        local s = cs.score  -- include già i punti raccolto accumulati

        -- Nodi on-path
        s = s + countOnPathPegs(clan)

        -- Soglie completamento
        local pct = completionPercent(clan)
        if pct > PARAMS.soglia_completamento_alto then
            s = s + PARAMS.bonus_completamento_alto
        elseif pct < PARAMS.soglia_completamento_basso then
            s = s + PARAMS.penalita_completamento_basso
        end

        -- Bonus Farming (≥2 campi diversi raccolti)
        if #cs.harvested >= 2 then s = s + PARAMS.bonus_farming end

        -- Tre Sorelle (set collection puro — no adiacenza, v8)
        s = s + calcTreSorelle(clan)

        -- Penalità individuale huarango
        s = s - (cs.fellingCount or 0) * math.abs(PARAMS.penalita_huarango)

        scores[clan] = s

        -- Traccia leader per raccolti (per regola anti-leader Arte)
        local harvestPts = 0
        for _, h in ipairs(cs.harvested) do
            harvestPts = harvestPts + (PARAMS.coltura_punti[h.type] or 0)
        end
        if harvestPts > harvestLeaderScore then
            harvestLeader, harvestLeaderScore = clan, harvestPts
        end
    end

    -- El Niño collettivo
    if gameState.fellings >= gameState.elNinoThreshold then
        for _, clan in ipairs(CLAN_ORDER) do
            scores[clan] = scores[clan] + PARAMS.penalita_elnino
        end
        broadcastToAll('⚡ EL NIÑO SCATTA! ' .. PARAMS.penalita_elnino ..
            'pt a tutti. Abbattimenti: ' .. gameState.fellings ..
            ' / Soglia: ' .. gameState.elNinoThreshold, {1,0.4,0.1})
    else
        broadcastToAll('La pampa è salva. Abbattimenti: ' .. gameState.fellings ..
            ' / Soglia: ' .. gameState.elNinoThreshold ..
            ' → NON scattato.', {0.3,0.9,0.3})
    end

    -- Bonus sopravvivenza (0 abbattimenti totali)
    if gameState.fellings == 0 then
        for _, clan in ipairs(CLAN_ORDER) do
            scores[clan] = scores[clan] + PARAMS.bonus_sopravvivenza
        end
        broadcastToAll('+' .. PARAMS.bonus_sopravvivenza ..
            'pt bonus sopravvivenza a tutti (0 huarango tagliati)!', {0.3,0.9,0.3})
    end

    -- Bonus Arte (+2pt, regola anti-leader) — gestito dalla votazione cieca UI
    -- Viene aggiunto separatamente dopo la votazione (vedi revelation.lua)

    return scores, harvestLeader
end

-- Tre Sorelle: ≥1 mais + ≥1 fagioli + ≥1 zucca nell'area punteggio
function calcTreSorelle(clan)
    local cs = gameState.clans[clan]
    local counts = {mais=0, fagioli=0, zucca=0}
    for _, h in ipairs(cs.harvested) do
        if counts[h.type] then counts[h.type] = counts[h.type] + 1 end
    end
    local triads = math.min(counts.mais, counts.fagioli, counts.zucca)
    return triads * PARAMS.bonus_tre_sorelle
end

-- Applica il Bonus Arte dopo la votazione cieca
-- artWinner: clan che ha ricevuto più voti
-- harvestLeader: clan in testa per raccolti
function applyArtBonus(artWinner, harvestLeader)
    local recipient = artWinner
    -- Regola anti-leader: se il vincitore è il leader per raccolti, +2pt al secondo
    if artWinner == harvestLeader then
        local bestVotes, secondClan = -1, nil
        -- Il caller deve passare la classifica completa; qui gestiamo il caso semplice
        broadcastToAll('REGOLA ANTI-LEADER: ' .. artWinner:upper() ..
            ' è in testa per raccolti. Il Bonus Arte va al secondo più votato!',
            {1,0.7,0.2})
        return  -- UI gestisce il secondClan
    end
    gameState.clans[recipient].score = (gameState.clans[recipient].score or 0) +
        PARAMS.bonus_arte
    broadcastToAll('🎨 Bonus Arte +' .. PARAMS.bonus_arte .. 'pt → ' ..
        recipient:upper(), clanColor(recipient))
end

-- Stampa il tabellone finale
function displayFinalScores(scores)
    local msg = '══ PUNTEGGI FINALI ══\n'
    local best, bestScore = nil, -1
    for _, clan in ipairs(CLAN_ORDER) do
        local pct = math.floor(completionPercent(clan)*100)
        msg = msg .. clan:upper() .. ': ' .. scores[clan] ..
            'pt  (completamento ' .. pct .. '%)\n'
        if scores[clan] > bestScore then
            best, bestScore = clan, scores[clan]
        end
    end
    broadcastToAll(msg, {1,1,1})
    Wait.time(function()
        broadcastToAll('🏆 VINCITORE: ' .. best:upper() ..
            ' — ' .. bestScore .. ' punti!', clanColor(best))
    end, 2)
    return best
end

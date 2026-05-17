-- ═══════════════════════════════════════════════════════════════
-- SEZIONE 2: GRIGLIA, CONNETTIVITÀ BFS, ADIACENZA
-- ═══════════════════════════════════════════════════════════════

-- 8 direzioni (ortogonale + diagonale)
local DIRS = {
    {0,1},{0,-1},{1,0},{-1,0},
    {1,1},{1,-1},{-1,1},{-1,-1},
}

function getNeighbors(idx)
    local r, c = holeRow(idx), holeCol(idx)
    local result = {}
    for _, d in ipairs(DIRS) do
        local nr, nc = r + d[1], c + d[2]
        if nr >= 0 and nr < ROWS and nc >= 0 and nc < COLS then
            table.insert(result, holeIndex(nr, nc))
        end
    end
    return result
end

function isAdjacent(idx1, idx2)
    local r1,c1 = holeRow(idx1), holeCol(idx1)
    local r2,c2 = holeRow(idx2), holeCol(idx2)
    return math.abs(r1-r2) <= 1 and math.abs(c1-c2) <= 1 and idx1 ~= idx2
end

-- BFS: la catena del clan è connessa dalla base al nodo-puquio?
function isChainConnected(clan, targetIdx)
    local cs = gameState.clans[clan]
    local pegsSet = {}
    for _, p in ipairs(cs.pegs) do pegsSet[p] = true end
    if not pegsSet[targetIdx] then return false end

    local base = CLAN_BASES[clan]
    local visited = {}
    local queue = {base}
    visited[base] = true

    while #queue > 0 do
        local cur = table.remove(queue, 1)
        if cur == targetIdx then return true end
        for _, nb in ipairs(getNeighbors(cur)) do
            if not visited[nb] and pegsSet[nb] then
                visited[nb] = true
                table.insert(queue, nb)
            end
        end
    end
    return false
end

-- BFS: la catena del clan tocca un nodo di bordo del versante scelto?
function isConnectedToBorder(clan, startIdx)
    local cs = gameState.clans[clan]
    if not cs.versante then return false end
    local pegsSet = {}
    for _, p in ipairs(cs.pegs) do pegsSet[p] = true end
    -- Aggiungi il puquio stesso se presente
    for _, p in ipairs(cs.puquios) do pegsSet[p] = true end
    if not pegsSet[startIdx] then return false end

    local visited = {}
    local queue = {startIdx}
    visited[startIdx] = true
    while #queue > 0 do
        local cur = table.remove(queue, 1)
        if isBorderNode(cur, cs.versante) then return true end
        for _, nb in ipairs(getNeighbors(cur)) do
            if not visited[nb] and pegsSet[nb] then
                visited[nb] = true
                table.insert(queue, nb)
            end
        end
    end
    return false
end

-- Conta nodi on-path consecutivi (per bonus continuità)
function countConsecutiveOnPath(clan)
    local cs = gameState.clans[clan]
    local pathSet = {}
    for _, p in ipairs(cs.geoglyphPath) do pathSet[p] = true end
    local pegsSet = {}
    for _, p in ipairs(cs.pegs) do pegsSet[p] = true end

    -- BFS limitato ai nodi on-path
    local visited = {}
    local maxRun = 0
    for _, peg in ipairs(cs.pegs) do
        if pathSet[peg] and not visited[peg] then
            local run = 0
            local q = {peg}
            visited[peg] = true
            while #q > 0 do
                local cur = table.remove(q, 1)
                run = run + 1
                for _, nb in ipairs(getNeighbors(cur)) do
                    if not visited[nb] and pegsSet[nb] and pathSet[nb] then
                        visited[nb] = true
                        table.insert(q, nb)
                    end
                end
            end
            if run > maxRun then maxRun = run end
        end
    end
    return maxRun
end

function checkBonusContinuita(clan)
    return countConsecutiveOnPath(clan) >= PARAMS.continuita_min_nodi
end

-- Percentuale completamento geoglifo
function completionPercent(clan)
    local cs = gameState.clans[clan]
    if #cs.geoglyphPath == 0 then return 0 end
    local pathSet = {}
    for _, p in ipairs(cs.geoglyphPath) do pathSet[p] = true end
    local count = 0
    for _, peg in ipairs(cs.pegs) do
        if pathSet[peg] then count = count + 1 end
    end
    return count / #cs.geoglyphPath
end

-- Nodi on-path con chiodino (per punteggio +1/nodo)
function countOnPathPegs(clan)
    local cs = gameState.clans[clan]
    local pathSet = {}
    for _, p in ipairs(cs.geoglyphPath) do pathSet[p] = true end
    local count = 0
    for _, peg in ipairs(cs.pegs) do
        if pathSet[peg] then count = count + 1 end
    end
    return count
end

-- Controlla se un nodo è bloccato da un neutro Orca
function isBlockedByOrca(idx)
    for _, clan in ipairs(CLAN_ORDER) do
        for _, neutro in ipairs(gameState.clans[clan].orca_neutral) do
            if neutro == idx then return true end
        end
    end
    return false
end

-- Calcola quanti neutri Orca sono adiacenti al nodo di bordo toccato (per CANALI)
function countNeutriAdjToBorderNode(clan, borderNodeIdx)
    local count = 0
    for _, neutro in ipairs(gameState.clans[clan].orca_neutral) do
        if isAdjacent(neutro, borderNodeIdx) then count = count + 1 end
    end
    return count
end

-- Produzione automatica acqua a fine round
function phaseProduzioneAcqua()
    for _, clan in ipairs(CLAN_ORDER) do
        local cs = gameState.clans[clan]
        local prodotto = 0
        for _, puqIdx in ipairs(cs.puquios) do
            if isConnectedToBorder(clan, puqIdx) then
                prodotto = prodotto + 1
            end
        end
        if prodotto > 0 then
            cs.water = cs.water + prodotto
            printToColor('+' .. prodotto .. '💧 produzione automatica', clanTTSColor(clan))
        end
    end
end

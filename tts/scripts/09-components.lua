-- ═══════════════════════════════════════════════════════════════
-- SEZIONE 9: COMPONENTI FISICI
-- Tessere campo · Tessere coltura · Traccia punteggio
-- ═══════════════════════════════════════════════════════════════

-- ─── URL IMMAGINI ─────────────────────────────────────────────
-- Generati da build.js e deployati come GitHub raw assets.
-- Il bundle.js sostituisce queste costanti con gli URL reali.
local BASE_URL = ASSET_BASE_URL or 'https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/tts/assets'

IMG = {
    field = {
        alluvionale_dry  = BASE_URL .. '/field_alluvionale_dry.png',
        alluvionale_wet  = BASE_URL .. '/field_alluvionale_wet.png',
        argilloso_dry    = BASE_URL .. '/field_argilloso_dry.png',
        argilloso_wet    = BASE_URL .. '/field_argilloso_wet.png',
        sabbioso_dry     = BASE_URL .. '/field_sabbioso_dry.png',
        sabbioso_wet     = BASE_URL .. '/field_sabbioso_wet.png',
    },
    crop = {
        mais_seed     = BASE_URL .. '/crop_mais_seed.png',
        mais_mature   = BASE_URL .. '/crop_mais_mature.png',
        fagioli_seed  = BASE_URL .. '/crop_fagioli_seed.png',
        fagioli_mature= BASE_URL .. '/crop_fagioli_mature.png',
        zucca_seed    = BASE_URL .. '/crop_zucca_seed.png',
        zucca_mature  = BASE_URL .. '/crop_zucca_mature.png',
        cotone_seed   = BASE_URL .. '/crop_cotone_seed.png',
        cotone_mature = BASE_URL .. '/crop_cotone_mature.png',
    },
    track = BASE_URL .. '/score_track.png',
}

-- ─── COLORI DI FALLBACK (se le immagini non caricano) ─────────
FIELD_COLORS = {
    alluvionale = {r=0.77, g=0.64, b=0.42},  -- ocra
    argilloso   = {r=0.55, g=0.47, b=0.37},  -- grigio-marrone
    sabbioso    = {r=0.83, g=0.75, b=0.55},  -- beige
}
FIELD_IRRIGATED_COLOR = {r=0.35, g=0.62, b=0.28}  -- verde

CROP_COLORS = {
    mais    = {seed={r=0.9,g=0.85,b=0.2},  mature={r=0.95,g=0.6,b=0.1}},
    fagioli = {seed={r=0.55,g=0.27,b=0.07}, mature={r=0.20,g=0.55,b=0.20}},
    zucca   = {seed={r=0.90,g=0.50,b=0.10}, mature={r=0.85,g=0.30,b=0.05}},
    cotone  = {seed={r=0.90,g=0.90,b=0.90}, mature={r=0.98,g=0.97,b=0.95}},
}

-- ─── INDICI DI POSIZIONAMENTO ─────────────────────────────────
-- Per il versante "nord/sud": l'offset laterale è su X
-- Per il versante "est/ovest": l'offset laterale è su Z
-- 4 clan × 5 tessere, 1.4 unità tra tessere, 7.5 unità tra clan
CLAN_LATERAL_BASE = {ragno=-14.0, orca=-6.5, colibri=1.0, condor=8.5}

function getFieldTilePos(clan, fieldIdx, versante)
    local lat = CLAN_LATERAL_BASE[clan] + (fieldIdx - 1) * 1.4
    if     versante == 'nord'  then return Vector(lat,  0.6, -16)
    elseif versante == 'sud'   then return Vector(lat,  0.6,  16)
    elseif versante == 'est'   then return Vector( 14,  0.6, lat)
    elseif versante == 'ovest' then return Vector(-14,  0.6, lat)
    end
    return Vector(lat, 0.6, -16)  -- fallback
end

function getCropTokenPos(clan, fieldIdx, versante)
    local base = getFieldTilePos(clan, fieldIdx, versante)
    return base + Vector(0, 0.4, 0)  -- sopra la tessera campo
end

-- ─── TRACCIA PUNTEGGIO ────────────────────────────────────────
-- Posizione x per score 0..60: x = -15 + score * 0.5
-- Traccia a z = -20 (sopra la plancia)
SCORE_TRACK_Z     = -20
SCORE_TRACK_X_MIN = -15
SCORE_TRACK_X_MAX =  15
SCORE_MARKER_Y    =   1.2

function scoreToTrackX(score)
    return SCORE_TRACK_X_MIN + math.min(score, 60) * 0.5
end

-- Segnalini posizionati in file sfalsate per non sovrapporsi
SCORE_MARKER_Z_OFFSET = {ragno=-0.8, orca=-0.27, colibri=0.27, condor=0.80}

-- ─── STATO COMPONENTI ─────────────────────────────────────────
-- spawnedTiles[clan][fieldIdx] = GUID oggetto TTS
-- spawnedCrops[clan][fieldIdx] = GUID oggetto TTS
-- scoreMarkers[clan]           = GUID oggetto TTS
spawnedTiles   = {}
spawnedCrops   = {}
scoreMarkers   = {}

-- ─── SPAWN TESSERE CAMPO ──────────────────────────────────────
function spawnFieldTiles(clan, versante)
    if spawnedTiles[clan] then
        -- Rimuovi tessere precedenti se clan cambia versante
        for _, guid in ipairs(spawnedTiles[clan]) do
            local obj = getObjectFromGUID(guid)
            if obj then obj.destroy() end
        end
    end
    spawnedTiles[clan] = {}

    local cs     = gameState.clans[clan]
    local fields = cs.fields
    for i, field in ipairs(fields) do
        -- Crea copie locali per evitare il closure bug di Lua
        -- (le callback TTS sparano asincronamente, i/field potrebbero essere cambiati)
        local idx      = i
        local fType    = field.type
        local pos      = getFieldTilePos(clan, idx, versante)
        local imgFront = IMG.field[fType .. '_dry']
        local imgBack  = IMG.field[fType .. '_wet']
        local fallback = FIELD_COLORS[fType] or FIELD_COLORS.alluvionale
        local clanName = clan  -- copia locale del clan

        local tile = spawnObject({
            type              = 'Custom_Tile',
            position          = pos,
            rotation          = {x=0, y=0, z=0},
            scale             = {x=1.3, y=0.1, z=1.3},
            sound             = false,
            snap_to_grid      = false,
            callback_function = function(obj)
                obj.setCustomObject({
                    image        = imgFront,
                    image_bottom = imgBack,
                    type         = 2,
                    thickness    = 0.10,
                })
                obj.setName(clanName .. '_campo_' .. idx)
                obj.setDescription(fType)
                obj.setColorTint(fallback)
                obj.setLock(false)
            end,
        })
        table.insert(spawnedTiles[clan], tile.getGUID())
    end
    printToColor('5 tessere campo create per ' .. clan:upper() ..
        ' sul versante ' .. versante:upper(), clanTTSColor(clan))
end

-- ─── AGGIORNA VISIVO TESSERA CAMPO ────────────────────────────
function updateFieldTileVisual(clan, fieldIdx)
    if not spawnedTiles[clan] then return end
    local guid = spawnedTiles[clan][fieldIdx]
    if not guid then return end
    local obj = getObjectFromGUID(guid)
    if not obj then return end

    local field = gameState.clans[clan].fields[fieldIdx]
    if field.irrigated then
        obj.setColorTint(FIELD_IRRIGATED_COLOR)
        if obj.is_face_down then obj.flip() end  -- mostra lato irrigato
    else
        local fallback = FIELD_COLORS[field.type] or FIELD_COLORS.alluvionale
        obj.setColorTint(fallback)
    end
end

-- ─── SPAWN TESSERA COLTURA ────────────────────────────────────
function spawnCropToken(clan, fieldIdx, cropType, isMature)
    -- Rimuovi eventuale coltura precedente
    removeCropToken(clan, fieldIdx)

    local versante = gameState.clans[clan].versante or 'nord'
    local pos      = getCropTokenPos(clan, fieldIdx, versante)
    local state    = isMature and 'mature' or 'seed'
    local imgKey   = cropType .. '_' .. state
    local imgFront = IMG.crop[imgKey]
    local fallback = (CROP_COLORS[cropType] or CROP_COLORS.mais)[state]

    if not spawnedCrops[clan] then spawnedCrops[clan] = {} end

    local token = spawnObject({
        type              = 'Custom_Token',
        position          = pos,
        rotation          = {x=0, y=0, z=0},
        scale             = {x=0.9, y=0.2, z=0.9},
        sound             = false,
        callback_function = function(obj)
            obj.setCustomObject({
                image       = imgFront,
                image_bottom= imgFront,
                thickness   = 0.20,
                merge_distance = 15,
                stackable   = false,
            })
            obj.setName(clan .. '_' .. cropType .. '_' .. (isMature and 'maturo' or 'seme'))
            obj.setDescription('coltura')
            obj.setColorTint(fallback)
        end,
    })
    spawnedCrops[clan][fieldIdx] = token.getGUID()
end

-- ─── MATURA UNA COLTURA ───────────────────────────────────────
function matureCropToken(clan, fieldIdx)
    if not spawnedCrops[clan] then return end
    local guid = spawnedCrops[clan][fieldIdx]
    if not guid then return end
    local obj = getObjectFromGUID(guid)
    if not obj then return end

    local cropType = gameState.clans[clan].fields[fieldIdx].cropType
    if not cropType then return end
    local col = (CROP_COLORS[cropType] or CROP_COLORS.mais).mature
    obj.setColorTint(col)
    obj.setName(clan .. '_' .. cropType .. '_maturo')
    -- Aggiorna immagine al lato maturo
    local newImg = IMG.crop[cropType .. '_mature']
    obj.setCustomObject({
        image       = newImg,
        image_bottom= newImg,
        thickness   = 0.20,
        stackable   = false,
    })
end

-- ─── RIMUOVI TESSERA COLTURA ──────────────────────────────────
function removeCropToken(clan, fieldIdx)
    if not spawnedCrops[clan] then return end
    local guid = spawnedCrops[clan][fieldIdx]
    if not guid then return end
    local obj = getObjectFromGUID(guid)
    if obj then obj.destroy() end
    spawnedCrops[clan][fieldIdx] = nil
end

-- ─── TRACCIA PUNTEGGIO ────────────────────────────────────────
function initScoreTrack()
    -- Crea il tabellone
    local trackObj = getObjectFromGUID(GUID.score_track)
    if not trackObj then
        -- Spawn se non già presente nel template
        spawnObject({
            type     = 'Custom_Board',
            position = Vector(0, 0.2, SCORE_TRACK_Z),
            rotation = {x=0, y=0, z=0},
            scale    = {x=6.0, y=1.0, z=0.6},
            callback_function = function(obj)
                obj.setCustomObject({ image = IMG.track })
                obj.setName('Traccia Punteggio 0-60')
                obj.setLock(true)
            end,
        })
    end

    -- Crea (o recupera) i 4 segnalini
    for _, clan in ipairs(CLAN_ORDER) do
        if not scoreMarkers[clan] then
            -- Copie locali per evitare closure bug
            local clanName = clan
            local col      = clanColor(clan)
            local posZ     = SCORE_TRACK_Z + SCORE_MARKER_Z_OFFSET[clan]
            local marker = spawnObject({
                type     = 'Custom_Token',
                position = Vector(scoreToTrackX(0), SCORE_MARKER_Y, posZ),
                rotation = {x=0, y=0, z=0},
                scale    = {x=0.6, y=0.3, z=0.6},
                callback_function = function(obj)
                    obj.setCustomObject({
                        image     = IMG.track,
                        thickness = 0.3,
                        stackable = false,
                    })
                    obj.setName(clanName:upper() .. ' — Punteggio')
                    obj.setColorTint({r=col[1], g=col[2], b=col[3]})
                    obj.setLock(false)
                end,
            })
            scoreMarkers[clanName] = marker.getGUID()
        end
    end
end

-- ─── AGGIORNA POSIZIONE SEGNALINO ─────────────────────────────
function updateScoreMarker(clan, score)
    local guid = scoreMarkers[clan]
    if not guid then return end
    local obj = getObjectFromGUID(guid)
    if not obj then return end

    local posZ = SCORE_TRACK_Z + SCORE_MARKER_Z_OFFSET[clan]
    obj.setPosition(Vector(scoreToTrackX(score), SCORE_MARKER_Y, posZ))
end

-- ─── AGGIORNAMENTO COMPLETO TRACCIA ───────────────────────────
function updateAllScoreMarkers()
    for _, clan in ipairs(CLAN_ORDER) do
        local score = gameState.clans[clan].score or 0
        updateScoreMarker(clan, score)
    end
end

-- ─── HOOK: phaseMaturazione aggiorna visivi colture ───────────
-- Questa funzione patch viene chiamata DOPO phaseMaturazione()
function updateCropVisualsAfterMaturation()
    for _, clan in ipairs(CLAN_ORDER) do
        local cs = gameState.clans[clan]
        for i, field in ipairs(cs.fields) do
            if field.crop and field.mature then
                matureCropToken(clan, i)
            end
        end
    end
end

-- ─── INIT COMPLETO: ricostruisce tutto da gameState ───────────
function initAllComponents()
    -- Recupera eventuali oggetti già presenti (evita duplicati al reload)
    -- Cerca per nome gli oggetti spawnati in sessioni precedenti
    for _, obj in ipairs(getAllObjects()) do
        local name = obj.getName()
        -- Tessere campo
        for _, c in ipairs(CLAN_ORDER) do
            if not spawnedTiles[c] then spawnedTiles[c] = {} end
            for idx = 1, 5 do
                if name == c .. '_campo_' .. idx then
                    spawnedTiles[c][idx] = obj.getGUID()
                end
            end
            -- Tessere coltura: recupera per nome  c_CROPTYPE_seme/maturo
            if not spawnedCrops[c] then spawnedCrops[c] = {} end
            if obj.getDescription() == 'coltura' and name:sub(1, #c+1) == c .. '_' then
                -- Ricostruisce l'associazione campo→GUID dalla posizione dell'oggetto
                -- rispetto alla tessera campo più vicina
                for idx = 1, 5 do
                    local fieldObj = spawnedTiles[c] and spawnedTiles[c][idx]
                        and getObjectFromGUID(spawnedTiles[c][idx])
                    if fieldObj then
                        local fp = fieldObj.getPosition()
                        local tp = obj.getPosition()
                        if math.abs(fp.x - tp.x) < 0.8 and math.abs(fp.z - tp.z) < 0.8 then
                            spawnedCrops[c][idx] = obj.getGUID()
                            break
                        end
                    end
                end
            end
            -- Segnalini punteggio
            if name == c:upper() .. ' — Punteggio' then
                scoreMarkers[c] = obj.getGUID()
            end
        end
    end

    -- Spawn tessere campo mancanti
    for _, clan in ipairs(CLAN_ORDER) do
        local versante = gameState.clans[clan].versante
        if versante then
            -- Spawna solo le tessere che non esistono già
            local missing = false
            if not spawnedTiles[clan] then missing = true
            else
                for i = 1, 5 do
                    if not spawnedTiles[clan][i] then missing = true; break end
                end
            end
            if missing then
                spawnFieldTiles(clan, versante)
            end
            -- Ripristina stato irrigazione e colture (copia locale di clan)
            local clanForRestore = clan
            Wait.frames(function()
                for i, field in ipairs(gameState.clans[clanForRestore].fields) do
                    if field.irrigated then
                        updateFieldTileVisual(clanForRestore, i)
                    end
                    if field.crop and not spawnedCrops[clanForRestore]
                            or (field.crop and not spawnedCrops[clanForRestore][i]) then
                        spawnCropToken(clanForRestore, i, field.cropType, field.mature)
                    end
                end
            end, 20)
        end
    end

    -- Traccia punteggio
    initScoreTrack()
    Wait.frames(updateAllScoreMarkers, 60)  -- attendi che tutti gli spawn siano completati
end

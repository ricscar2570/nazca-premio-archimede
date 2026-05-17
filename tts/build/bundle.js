#!/usr/bin/env node
'use strict';

/**
 * bundle.js — NAZCA TTS builder
 *
 * Usage (from repo root):
 *   node tts/build/bundle.js [--out output/]
 *   BOARD_IMAGE_URL=https://... node tts/build/bundle.js
 */

const fs   = require('fs');
const path = require('path');

const args   = process.argv.slice(2);
const getArg = (flag, def) => { const i = args.indexOf(flag); return i !== -1 ? args[i+1] : def; };

const OUT_ARG  = getArg('--out', 'output/');
const OUT_DIR  = path.isAbsolute(OUT_ARG) ? OUT_ARG : path.resolve(process.cwd(), OUT_ARG);
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const SCRIPTS_DIR = path.join(REPO_ROOT, 'tts', 'scripts');
const TEMPLATE_FILE = path.join(REPO_ROOT, 'tts', 'template', 'save.json');

const BOARD_IMAGE_URL = process.env.BOARD_IMAGE_URL ||
    'https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/tts/template/board.png';

console.log('Building NAZCA TTS mod...');

// ─── 1. Bundle Lua scripts in order ──────────────────────────

const luaFiles = fs.readdirSync(SCRIPTS_DIR)
    .filter(f => f.endsWith('.lua'))
    .sort()
    .map(f => path.join(SCRIPTS_DIR, f));

console.log(`  Bundling ${luaFiles.length} Lua script(s)...`);

const luaParts = luaFiles.map(f => {
    const name = path.basename(f);
    const code = fs.readFileSync(f, 'utf8');
    return `-- ■■■ ${name} ■■■\n${code}`;
});

const bundledLua = luaParts.join('\n\n');
console.log(`  Bundled: ${Math.round(bundledLua.length / 1024)} KB`);

// ─── 2. Generate 540 snap points (20×27 grid) ─────────────────

const COLS = 20, ROWS = 27;
const snapPoints = [];
for (let row = 0; row < ROWS; row++) {
    for (let col = 0; col < COLS; col++) {
        snapPoints.push({
            Position: {
                x: parseFloat((-4.75 + col * 0.50).toFixed(3)),
                y: 0.12,
                z: parseFloat((-6.50 + row * 0.50).toFixed(3))
            },
            Rotation: { x: 0, y: 0, z: 0 },
            Tags: [`node_r${row}_c${col}`]
        });
    }
}
console.log(`  Generated ${snapPoints.length} snap points`);

// ─── 3. Load and patch template ──────────────────────────────

let template;
try {
    template = JSON.parse(fs.readFileSync(TEMPLATE_FILE, 'utf8'));
} catch (e) {
    console.error('Template not found:', TEMPLATE_FILE);
    process.exit(1);
}

// Inject global Lua script
template.LuaScript = bundledLua;
template.Date = new Date().toISOString().slice(0, 10);
template.SaveName = `NAZCA v8 — Build ${new Date().toISOString().slice(0,10)}`;

// Inject snap points into board object
const board = template.ObjectStates.find(o => o.GUID === 'aa0001');
if (board) {
    board.CustomImage.ImageURL = BOARD_IMAGE_URL;
    board.CustomImage.ImageSecondaryURL = BOARD_IMAGE_URL;
    board.SnapPoints = snapPoints;
    console.log('  Board snap points injected');
} else {
    console.warn('  WARNING: Board object (aa0001) not found in template');
}

// ─── 4. Generate assets (moved before write) ───────────────
// (asset generation happens below, then re-injects into template.LuaScript)
// ─── 5. Write output (after asset URL injection) ─────────────

// ─── GENERA ASSET PNG ────────────────────────────────────────
// Crea PNG 256×256 a colore piatto + label in testo usando solo
// moduli Node.js built-in (nessuna dipendenza npm).

const zlib = require('zlib');

function makePNG(width, height, r, g, b, label) {
    // PNG header + IHDR + IDAT (raw pixels) + IEND
    const buf = Buffer.alloc(width * height * 3);
    for (let i = 0; i < width * height; i++) {
        buf[i*3]=r; buf[i*3+1]=g; buf[i*3+2]=b;
    }
    // Raw image data: filtro 0 (None) prima di ogni riga
    const raw = Buffer.alloc(height * (1 + width * 3));
    for (let y = 0; y < height; y++) {
        raw[y * (1 + width*3)] = 0;  // filter byte
        buf.copy(raw, y * (1+width*3) + 1, y*width*3, (y+1)*width*3);
    }
    const idat = zlib.deflateSync(raw);

    function chunk(type, data) {
        const b = Buffer.alloc(12 + data.length);
        b.writeUInt32BE(data.length, 0);
        b.write(type, 4, 'ascii');
        data.copy(b, 8);
        // CRC32
        let crc = 0xFFFFFFFF;
        for (let i = 4; i < 8 + data.length; i++) {
            crc ^= b[i];
            for (let j = 0; j < 8; j++) crc = (crc >>> 1) ^ (crc & 1 ? 0xEDB88320 : 0);
        }
        b.writeUInt32BE((crc ^ 0xFFFFFFFF) >>> 0, 8 + data.length);
        return b;
    }

    const sig    = Buffer.from([0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A]);
    const ihdr   = Buffer.alloc(13);
    ihdr.writeUInt32BE(width, 0); ihdr.writeUInt32BE(height, 4);
    ihdr[8]=8; ihdr[9]=2; ihdr[10]=0; ihdr[11]=0; ihdr[12]=0;

    return Buffer.concat([sig, chunk('IHDR',ihdr), chunk('IDAT',idat),
        chunk('IEND', Buffer.alloc(0))]);
}

function generateAssets(assetDir, repoUrl) {
    fs.mkdirSync(assetDir, { recursive: true });

    const assets = [
        // Campo: secco
        ['field_alluvionale_dry.png', 196, 164, 106],
        ['field_argilloso_dry.png',   140, 120,  90],
        ['field_sabbioso_dry.png',    212, 192, 140],
        // Campo: irrigato (verde)
        ['field_alluvionale_wet.png',  90, 158,  72],
        ['field_argilloso_wet.png',    70, 140,  55],
        ['field_sabbioso_wet.png',    110, 170,  80],
        // Colture: seme
        ['crop_mais_seed.png',        229, 217,  52],
        ['crop_fagioli_seed.png',     140,  70,  18],
        ['crop_zucca_seed.png',       230, 128,  26],
        ['crop_cotone_seed.png',      230, 230, 230],
        // Colture: maturo
        ['crop_mais_mature.png',      242, 153,  26],
        ['crop_fagioli_mature.png',    52, 140,  52],
        ['crop_zucca_mature.png',     217,  77,  13],
        ['crop_cotone_mature.png',    250, 248, 244],
        // Traccia punteggio (sfondo sabbia neutro)
        ['score_track.png',           180, 155, 110],
    ];

    for (const [name, r, g, b] of assets) {
        const png = makePNG(256, 256, r, g, b);
        fs.writeFileSync(path.join(assetDir, name), png);
    }

    const count = assets.length;
    console.log(`✓ Generated ${count} PNG assets → ${assetDir}`);

    // Restituisce la mappa nome→URL per sostituzione nel Lua
    const urlMap = {};
    for (const [name] of assets) {
        urlMap[name] = `${repoUrl}/tts/assets/${name}`;
    }
    return urlMap;
}

// Genera immagini e inietta ASSET_BASE_URL nel Lua script
const assetDir = path.join(REPO_ROOT, 'tts', 'assets');
const repoUrl  = process.env.REPO_URL ||
    `https://raw.githubusercontent.com/${process.env.GITHUB_REPOSITORY || 'YOUR_USER/YOUR_REPO'}/main`;

generateAssets(assetDir, repoUrl);

// Sostituisce ASSET_BASE_URL nel Lua bundled
const assetBaseUrl = `${repoUrl}/tts/assets`;
const finalLua = bundledLua.replace(
    "ASSET_BASE_URL or 'https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/tts/assets'",
    `'${assetBaseUrl}'`
);

// Re-inject il Lua aggiornato nel template già patchato
template.LuaScript = finalLua;

// ─── 6. Write final output ──────────────────────────────────
fs.mkdirSync(OUT_DIR, { recursive: true });
const outFile = path.join(OUT_DIR, 'NAZCA_TTS_v8.json');
fs.writeFileSync(outFile, JSON.stringify(template, null, 2));
const sizeKb = Math.round(fs.statSync(outFile).size / 1024);
console.log(`✓ ${outFile}  (${sizeKb} KB)`);
console.log('  Load in TTS: File → Load Game → Browse to this file');
const luaOut = path.join(OUT_DIR, 'NAZCA_GlobalScript.lua');
fs.writeFileSync(luaOut, finalLua);
console.log(`✓ ${luaOut}  (Lua only, for debugging)`);

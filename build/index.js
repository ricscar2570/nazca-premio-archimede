#!/usr/bin/env node
'use strict';

const fs   = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  AlignmentType, BorderStyle, WidthType, ShadingType, VerticalAlign,
  LevelFormat, Header, Footer,
} = require('docx');

const { C, FONT, FONT_SERIF, LANG_DEFAULTS } = require('./styles');
const { parse }       = require('./parser');
const { renderNodes } = require('./renderer');

// ─── CLI ──────────────────────────────────────────────────────────────────────
const args   = process.argv.slice(2);
const getArg = (flag, def) => { const i = args.indexOf(flag); return i !== -1 ? args[i+1] : def; };

const LANG    = getArg('--lang', 'it');
const OUT_ARG = getArg('--out',  'output/');
// Resolve from CWD so callers from any directory work correctly
const OUT_DIR = path.isAbsolute(OUT_ARG) ? OUT_ARG : path.resolve(process.cwd(), OUT_ARG);

// ─── PATHS ────────────────────────────────────────────────────────────────────
const REPO_ROOT   = path.resolve(__dirname, '..');
const CONTENT_DIR = path.join(REPO_ROOT, 'content', LANG);
const META_FILE   = path.join(CONTENT_DIR, 'meta.yml');

if (!fs.existsSync(CONTENT_DIR)) {
  console.error('Content directory not found: ' + CONTENT_DIR); process.exit(1);
}

// ─── METADATA ─────────────────────────────────────────────────────────────────
const meta    = fs.existsSync(META_FILE) ? yaml.load(fs.readFileSync(META_FILE, 'utf8')) : {};
const langDef = LANG_DEFAULTS[LANG] || LANG_DEFAULTS.it;
const title    = meta.title    || 'NAZCA';
const subtitle = meta.subtitle || "Le linee che cercano l'acqua";
const version  = meta.version  || '8.0';
const author   = meta.author   || '[NOME COGNOME]';
const phone    = meta.phone    || '[TEL]';
const email    = meta.email    || '[EMAIL]';
const prize    = meta.prize    || 'Premio Archimede 2027';
const players  = meta.players  || '2-4';
const duration = meta.duration || '45-75 min';
const ageMin   = meta.ageMin   || '10+';
const bggW     = meta.bggWeight|| '~2.5 / 5';

// ─── COLLECT MD FILES ─────────────────────────────────────────────────────────
const mdFiles = fs.readdirSync(CONTENT_DIR).filter(f=>f.endsWith('.md')).sort()
  .map(f=>path.join(CONTENT_DIR, f));
if (!mdFiles.length) { console.error('No .md files in '+CONTENT_DIR); process.exit(1); }
console.log('Building '+LANG.toUpperCase()+' — '+mdFiles.length+' section(s)...');

// ─── COVER HELPERS ────────────────────────────────────────────────────────────
const brdSingle = { style: BorderStyle.SINGLE, size: 1, color: C.border };
const BRDALL    = { top:brdSingle, bottom:brdSingle, left:brdSingle, right:brdSingle };

function coverCell(text, opts) {
  return new TableCell({
    borders: BRDALL,
    shading: { fill: opts.fill || 'FFFFFF', type: ShadingType.CLEAR },
    width:   { size: opts.width, type: WidthType.DXA },
    margins: { top:80, bottom:80, left:120, right:120 },
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({ children: [
      new TextRun({ text:String(text), font:FONT, size:20, bold:opts.bold||false, color:opts.color||'222222' })
    ]})]
  });
}

function coverRow(label, value) {
  return new TableRow({ children: [
    coverCell(label, { fill:C.sand, bold:true, color:C.accent, width:3200 }),
    coverCell(value, { fill:'FFFFFF', width:5760 }),
  ]});
}

// ─── ASSEMBLE CHILDREN ────────────────────────────────────────────────────────
const children = [];

// Cover
children.push(
  new Paragraph({ spacing:{before:0,after:80}, children:[] }),
  new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:0,after:80},
    children:[new TextRun({text:title, font:FONT_SERIF, size:96, bold:true, color:C.title})] }),
  new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:0,after:120},
    children:[new TextRun({text:subtitle, font:FONT_SERIF, size:32, italics:true, color:C.gold})] }),
  new Paragraph({ spacing:{before:160,after:160},
    border:{bottom:{style:BorderStyle.SINGLE,size:6,color:C.accent,space:1}}, children:[] }),
  new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:80,after:80},
    children:[new TextRun({text:'GAME BIBLE  \xB7  VERSION '+version, font:FONT, size:26, bold:true, color:C.h2})] }),
  new Paragraph({ alignment:AlignmentType.CENTER, spacing:{before:0,after:400},
    children:[new TextRun({text:prize, font:FONT, size:22, color:'888888'})] }),
  new Table({
    width:{size:8960, type:WidthType.DXA}, columnWidths:[3200,5760],
    rows:[
      coverRow(LANG==='it'?'Autore':'Author',    author),
      coverRow(LANG==='it'?'Telefono':'Phone',   phone),
      coverRow('Email',                          email),
      coverRow(LANG==='it'?'Versione':'Version', version+' — Game Bible v3.1'),
      coverRow(LANG==='it'?'Giocatori':'Players',players),
      coverRow(LANG==='it'?'Durata':'Duration',  duration),
      coverRow(LANG==='it'?'Età':'Age',          ageMin),
      coverRow('BGG weight',                     bggW),
    ]
  })
);

// Sections
for (const file of mdFiles) {
  const nodes = parse(fs.readFileSync(file,'utf8'));
  children.push(...renderNodes(nodes));
}

// ─── DOCUMENT ─────────────────────────────────────────────────────────────────
const doc = new Document({
  numbering: { config: [{ reference:'bullets', levels:[{
    level:0, format:LevelFormat.BULLET, text:'\u2022', alignment:AlignmentType.LEFT,
    style:{paragraph:{indent:{left:600,hanging:300}}}
  }]}]},
  styles: {
    default: { document: { run: { font:FONT, size:22 } } },
    paragraphStyles: [
      { id:'Heading1', name:'Heading 1', basedOn:'Normal', next:'Normal', quickFormat:true,
        run:{size:36,bold:true,font:FONT_SERIF,color:C.h1},
        paragraph:{spacing:{before:400,after:160},outlineLevel:0} },
      { id:'Heading2', name:'Heading 2', basedOn:'Normal', next:'Normal', quickFormat:true,
        run:{size:28,bold:true,font:FONT,color:C.h2},
        paragraph:{spacing:{before:320,after:120},outlineLevel:1} },
      { id:'Heading3', name:'Heading 3', basedOn:'Normal', next:'Normal', quickFormat:true,
        run:{size:24,bold:true,font:FONT,color:C.h3},
        paragraph:{spacing:{before:200,after:80},outlineLevel:2} },
    ]
  },
  sections:[{
    properties:{ page:{ size:{width:11906,height:16838}, margin:{top:1440,right:1280,bottom:1440,left:1280} } },
    headers:{ default: new Header({ children:[
      new Paragraph({ alignment:AlignmentType.RIGHT,
        border:{bottom:{style:BorderStyle.SINGLE,size:4,color:C.gold,space:1}},
        children:[new TextRun({text:'NAZCA \xB7 Game Bible v'+version+' \xB7 '+langDef.headerSuffix, font:FONT,size:16,color:C.gold})]
      })
    ]})},
    footers:{ default: new Footer({ children:[
      new Paragraph({ alignment:AlignmentType.CENTER,
        border:{top:{style:BorderStyle.SINGLE,size:4,color:C.gold,space:1}},
        children:[new TextRun({text:langDef.footer, font:FONT,size:16,color:'888888'})]
      })
    ]})},
    children
  }]
});

// ─── WRITE ────────────────────────────────────────────────────────────────────
fs.mkdirSync(OUT_DIR, {recursive:true});
const outFile = path.join(OUT_DIR, 'NAZCA_GameBible_'+LANG+'.docx');

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync(outFile, buf);
  console.log('\u2713 '+outFile+'  ('+Math.round(buf.length/1024)+' KB)');
}).catch(err => { console.error('Build failed:', err.message); process.exit(1); });

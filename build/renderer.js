'use strict';

const {
  Paragraph, TextRun, Table, TableRow, TableCell,
  HeadingLevel, AlignmentType, BorderStyle, WidthType,
  ShadingType, VerticalAlign,
} = require('docx');

const { C, FONT, FONT_SERIF } = require('./styles');
const { parseInline }         = require('./parser');

// ─── CONSTANTS ────────────────────────────────────────────────────────────────
const TABLE_W     = 8960;  // DXA — matches page margins
const brd         = { style: BorderStyle.SINGLE, size: 1, color: C.border };
const borders     = { top: brd, bottom: brd, left: brd, right: brd };
const noBorder    = { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' };
const noBorders   = { top: noBorder, bottom: noBorder, left: noBorder, right: noBorder };

// ─── INLINE RUNS ─────────────────────────────────────────────────────────────

function makeRun(runObj, defaults = {}) {
  return new TextRun({
    text:    runObj.text,
    font:    runObj.mono ? 'Courier New' : FONT,
    size:    defaults.size  || 22,
    bold:    runObj.bold    || defaults.bold    || false,
    italics: runObj.italic  || defaults.italic  || false,
    color:   runObj.color   || defaults.color   || '222222',
  });
}

function inlineRuns(text, defaults = {}) {
  return parseInline(text).map(r => makeRun(r, defaults));
}

// ─── PARAGRAPH ────────────────────────────────────────────────────────────────

function renderParagraph(node) {
  return new Paragraph({
    spacing: { before: 80, after: 80 },
    children: inlineRuns(node.text),
  });
}

// ─── HEADINGS ─────────────────────────────────────────────────────────────────

function renderH1(node) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 400, after: 160 },
    pageBreakBefore: true,
    children: [new TextRun({ text: node.text, font: FONT_SERIF, size: 36, bold: true, color: C.h1 })],
  });
}

function renderH2(node) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 320, after: 120 },
    children: [new TextRun({ text: node.text, font: FONT, size: 28, bold: true, color: C.h2 })],
  });
}

function renderH3(node) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 200, after: 80 },
    children: [new TextRun({ text: node.text, font: FONT, size: 24, bold: true, color: C.h3 })],
  });
}

// ─── BULLET LIST ──────────────────────────────────────────────────────────────

function renderBullets(node) {
  return node.items.map(item =>
    new Paragraph({
      numbering: { reference: 'bullets', level: 0 },
      spacing: { before: 40, after: 40 },
      children: inlineRuns(item, { size: 21 }),
    })
  );
}

// ─── DIVIDER ──────────────────────────────────────────────────────────────────

function renderDivider() {
  return new Paragraph({
    spacing: { before: 160, after: 160 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: C.accent, space: 1 } },
    children: [],
  });
}

// ─── NOTE BOX ─────────────────────────────────────────────────────────────────

function renderNotebox(node) {
  const isWarn = node.color === 'warning';
  const fill   = isWarn ? 'FDF0F0' : 'EEF4FF';
  const col    = isWarn ? C.warning : C.info;

  const children = node.lines.map(line =>
    new Paragraph({
      spacing: { before: 40, after: 40 },
      children: inlineRuns(line, { size: 21, italic: true, color: col }),
    })
  );

  return new Table({
    width: { size: TABLE_W, type: WidthType.DXA },
    columnWidths: [TABLE_W],
    rows: [new TableRow({ children: [new TableCell({
      borders,
      shading: { fill, type: ShadingType.CLEAR },
      margins: { top: 120, bottom: 120, left: 160, right: 160 },
      children,
    })] })],
  });
}

// ─── STANDARD TABLE ──────────────────────────────────────────────────────────

function makeCell(text, opts = {}) {
  return new TableCell({
    borders,
    shading: opts.bg ? { fill: opts.bg, type: ShadingType.CLEAR } : undefined,
    width: opts.width ? { size: opts.width, type: WidthType.DXA } : undefined,
    verticalAlign: VerticalAlign.CENTER,
    margins: { top: 80, bottom: 80, left: 120, right: 120 },
    children: [new Paragraph({
      children: inlineRuns(String(text), {
        size:  opts.size  || 20,
        bold:  opts.bold  || false,
        color: opts.color || '222222',
      }),
    })],
  });
}

function renderTable(node) {
  const cols   = Math.max(node.headers.length, ...node.rows.map(r => r.length));
  const colW   = Math.floor(TABLE_W / cols);
  const widths = Array(cols).fill(colW);

  const headerRow = new TableRow({
    tableHeader: true,
    children: node.headers.map(h =>
      makeCell(h, { bold: true, color: 'FFFFFF', bg: C.h1, size: 20 })
    ),
  });

  const dataRows = node.rows.map((row, ri) =>
    new TableRow({
      children: row.map((cell, ci) =>
        makeCell(cell, {
          bg:   ci === 0 && ri % 2 === 1 ? C.sand : 'FFFFFF',
          size: 20,
        })
      ),
    })
  );

  return new Table({
    width: { size: TABLE_W, type: WidthType.DXA },
    columnWidths: widths,
    rows: [headerRow, ...dataRows],
  });
}

// ─── TWO-COLUMN KEY-VALUE TABLE ───────────────────────────────────────────────

function renderTwocol(node) {
  const rows = node.rows.map(([label, value]) =>
    new TableRow({
      children: [
        makeCell(label || '', { bg: C.sand, bold: true, color: C.accent, width: 3200, size: 20 }),
        makeCell(value || '', { bg: 'FFFFFF', width: 5760, size: 20 }),
      ],
    })
  );

  return new Table({
    width: { size: TABLE_W, type: WidthType.DXA },
    columnWidths: [3200, 5760],
    rows,
  });
}

// ─── MAIN RENDERER ────────────────────────────────────────────────────────────

function renderNodes(nodes) {
  const elements = [];

  for (const node of nodes) {
    switch (node.type) {
      case 'h1':        elements.push(renderH1(node));            break;
      case 'h2':        elements.push(renderH2(node));            break;
      case 'h3':        elements.push(renderH3(node));            break;
      case 'paragraph': elements.push(renderParagraph(node));     break;
      case 'bullets':   elements.push(...renderBullets(node));    break;
      case 'divider':   elements.push(renderDivider());           break;
      case 'notebox':   elements.push(renderNotebox(node));       break;
      case 'table':     elements.push(renderTable(node));         break;
      case 'twocol':    elements.push(renderTwocol(node));        break;
      default:
        console.warn(`[renderer] Unknown node type: ${node.type}`);
    }
  }

  return elements;
}

module.exports = { renderNodes };

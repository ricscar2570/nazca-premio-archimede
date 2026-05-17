'use strict';

/**
 * parser.js — Markdown → AST
 *
 * Supported syntax:
 *   # H1   ## H2   ### H3
 *   Regular paragraphs
 *   - Bullet items
 *   | Standard | MD | tables |
 *   :::twocol / ::: — two-column key-value table
 *   > [!NOTE] / > [!WARNING] / > [!IMPORTANT] — coloured note boxes
 *   ---  — horizontal rule / divider
 *
 * Inline formatting inside paragraph text:
 *   **bold**   *italic*   `code`
 *   {color:HEXCODE}text{/color}   {bold}text{/bold}
 */

function parse(markdown) {
  const lines   = markdown.split('\n');
  const nodes   = [];
  let   i       = 0;

  while (i < lines.length) {
    const raw  = lines[i];
    const line = raw.trimEnd();

    // ── Blank line ──────────────────────────────────────────────────────────
    if (line.trim() === '') { i++; continue; }

    // ── Heading ─────────────────────────────────────────────────────────────
    const h3 = line.match(/^### (.+)/);
    const h2 = line.match(/^## (.+)/);
    const h1 = line.match(/^# (.+)/);
    if (h1) { nodes.push({ type:'h1', text: h1[1].trim() }); i++; continue; }
    if (h2) { nodes.push({ type:'h2', text: h2[1].trim() }); i++; continue; }
    if (h3) { nodes.push({ type:'h3', text: h3[1].trim() }); i++; continue; }

    // ── Horizontal rule / divider ────────────────────────────────────────────
    if (/^---+$/.test(line.trim())) {
      nodes.push({ type: 'divider' }); i++; continue;
    }

    // ── Note box  > [!NOTE] / > [!WARNING] / > [!IMPORTANT] ─────────────────
    if (/^> \[!(NOTE|WARNING|IMPORTANT|CRITICAL)\]/.test(line)) {
      const kind = line.match(/\[!(NOTE|WARNING|IMPORTANT|CRITICAL)\]/)[1];
      const color = (kind === 'WARNING' || kind === 'CRITICAL') ? 'warning' : 'info';
      const bodyLines = [];
      i++;
      while (i < lines.length && lines[i].startsWith('> ')) {
        bodyLines.push(lines[i].slice(2));
        i++;
      }
      nodes.push({ type: 'notebox', color, lines: bodyLines });
      continue;
    }

    // ── Two-column key-value block  :::twocol ────────────────────────────────
    if (line.trim() === ':::twocol') {
      i++;
      const rows = [];
      while (i < lines.length && lines[i].trim() !== ':::') {
        const trow = parseTableRow(lines[i]);
        if (trow) rows.push(trow);
        i++;
      }
      i++; // consume :::
      nodes.push({ type: 'twocol', rows });
      continue;
    }

    // ── Table  (line starts with |) ──────────────────────────────────────────
    if (line.startsWith('|')) {
      const tableLines = [];
      while (i < lines.length && lines[i].startsWith('|')) {
        tableLines.push(lines[i]);
        i++;
      }
      nodes.push(parseTable(tableLines));
      continue;
    }

    // ── Bullet list ──────────────────────────────────────────────────────────
    if (/^[-*] /.test(line)) {
      const items = [];
      while (i < lines.length && /^[-*] /.test(lines[i].trimEnd())) {
        items.push(lines[i].replace(/^[-*] /, '').trimEnd());
        i++;
      }
      nodes.push({ type: 'bullets', items });
      continue;
    }

    // ── Paragraph ────────────────────────────────────────────────────────────
    {
      const paraLines = [];
      while (
        i < lines.length &&
        lines[i].trim() !== '' &&
        !lines[i].startsWith('#') &&
        !lines[i].startsWith('|') &&
        !lines[i].startsWith('- ') &&
        !lines[i].startsWith('* ') &&
        !lines[i].startsWith('> ') &&
        !/^---+$/.test(lines[i].trim()) &&
        lines[i].trim() !== ':::twocol'
      ) {
        paraLines.push(lines[i].trimEnd());
        i++;
      }
      if (paraLines.length) {
        nodes.push({ type: 'paragraph', text: paraLines.join(' ') });
      }
    }
  }

  return nodes;
}

// ─── TABLE HELPERS ────────────────────────────────────────────────────────────

function parseTableRow(line) {
  if (!line || !line.startsWith('|')) return null;
  return line.split('|')
    .slice(1, -1)                      // drop leading/trailing empty splits
    .map(c => c.trim());
}

function isAlignmentRow(row) {
  return row && row.every(c => /^:?-+:?$/.test(c.trim()));
}

function parseTable(tableLines) {
  const allRows = tableLines
    .map(parseTableRow)
    .filter(Boolean);

  if (!allRows.length) return { type: 'paragraph', text: '' };

  // Split header / alignment / data
  const headerCandidates = [];
  const dataRows         = [];
  let   pastAlign        = false;

  for (const row of allRows) {
    if (!pastAlign && isAlignmentRow(row)) { pastAlign = true; continue; }
    if (!pastAlign) { headerCandidates.push(row); }
    else            { dataRows.push(row); }
  }

  return {
    type:    'table',
    headers: headerCandidates[0] || [],
    rows:    dataRows,
  };
}

// ─── INLINE PARSER ────────────────────────────────────────────────────────────
// Returns array of {text, bold, italic, color} run objects

function parseInline(raw) {
  const runs  = [];
  let   str   = raw;
  const push  = (text, opts = {}) => {
    if (text) runs.push({ text, ...opts });
  };

  // Process left-to-right using a simple token scan
  while (str.length) {
    // {color:HEX}...{/color}
    let m = str.match(/^\{color:([0-9A-Fa-f]{6})\}([\s\S]*?)\{\/color\}/);
    if (m) { push(m[2], { color: m[1] }); str = str.slice(m[0].length); continue; }

    // {bold}...{/bold}
    m = str.match(/^\{bold\}([\s\S]*?)\{\/bold\}/);
    if (m) { push(m[1], { bold: true }); str = str.slice(m[0].length); continue; }

    // **bold**
    m = str.match(/^\*\*(.+?)\*\*/);
    if (m) { push(m[1], { bold: true }); str = str.slice(m[0].length); continue; }

    // *italic*
    m = str.match(/^\*(.+?)\*/);
    if (m) { push(m[1], { italic: true }); str = str.slice(m[0].length); continue; }

    // `code` → bold monospace
    m = str.match(/^`(.+?)`/);
    if (m) { push(m[1], { mono: true }); str = str.slice(m[0].length); continue; }

    // Plain text up to the next special character
    m = str.match(/^([^*`{]+)/);
    if (m) { push(m[1]); str = str.slice(m[0].length); continue; }

    // Fallback: advance one char to avoid infinite loops
    push(str[0]);
    str = str.slice(1);
  }

  return runs;
}

module.exports = { parse, parseInline };

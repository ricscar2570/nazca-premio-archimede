'use strict';

// ─── NAZCA COLOUR PALETTE ────────────────────────────────────────────────────
const C = {
  title:   '7A1A0A',   // deep Nazca red
  h1:      '5C2005',
  h2:      '8B3010',
  h3:      'A04520',
  accent:  'C05A20',
  gold:    '8B6010',
  blue:    '1445A8',
  green:   '156A20',
  gray:    '444444',
  sand:    'F8F2E4',
  warning: 'A02020',
  info:    '0A4080',
  border:  'C8A870',
  // Clan colours
  ragno:   'B52020',
  orca:    '1445A8',
  colibri: '156A20',
  condor:  '666666',
};

const FONT      = 'Calibri';
const FONT_SERIF = 'Georgia';

// ─── DOCUMENT METADATA PER LANGUAGE ─────────────────────────────────────────
const LANG_DEFAULTS = {
  it: {
    headerSuffix: 'v3.1 «Corde»',
    footer:       'Premio Archimede 2027 · Documento riservato',
  },
  en: {
    headerSuffix: 'v3.1 "Strings"',
    footer:       'Premio Archimede 2027 · Confidential document',
  },
};

module.exports = { C, FONT, FONT_SERIF, LANG_DEFAULTS };

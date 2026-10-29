#!/usr/bin/env python3
"""
build_benchmark_docx.py

Convert the FVS-ACD v12.11 benchmark report Markdown into a branded,
journal-formatted Word (.docx) document following CRSF house style.

This is a fork of build_gtr_docx.py (the FVS-ACD GTR pipeline) adapted for
the benchmark-report document type, with two additions required by the
CRSF-Cowork house style rules that the GTR pipeline did not implement:

  1. True docx superscript/subscript runs. House style requires
     run.font.superscript / run.font.subscript for exponents in .docx
     output rather than relying on Unicode glyphs (m2, ha-1, SI50). The
     source Markdown is written with Unicode super/subscript glyphs (the
     correct convention for Markdown per house style); this script detects
     those glyphs, converts them to plain characters, and applies real
     superscript/subscript run formatting so Word's own typography (not a
     shrunken Unicode glyph) renders the exponent.
  2. A page-numbered footer with a thin gold rule, matching the branding
     already used on the prior benchmark-report docx.

Usage:
    python3 build_benchmark_docx.py <input.md> <output.docx> "<footer title>"

Depends on python-docx.
"""

import os
import re
import sys

from docx import Document
from docx.enum.section import WD_ORIENT, WD_SECTION
from docx.enum.table import WD_ALIGN_VERTICAL
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Emu, Inches, Pt, RGBColor

# --------------------------------------------------------------------------
# Brand constants (CRSF house style)
# --------------------------------------------------------------------------

CRSF_GREEN = RGBColor(0x1A, 0x3D, 0x28)
CRSF_BLUE = RGBColor(0x7D, 0xB5, 0xD5)
CRSF_GOLD = RGBColor(0xC5, 0xA5, 0x5A)
BODY_BLACK = RGBColor(0x1A, 0x1A, 0x1A)

BODY_FONT = "Calibri"
HEADING_FONT = "Calibri"

LOGO_DIR = "/sessions/fervent-pensive-goodall/mnt/CRSF-Cowork/Logos_CRSFgraphics"
CRSF_LOGO = os.path.join(LOGO_DIR, "Center Logos", "CRSF", "CRSF logo (2018)",
                          "1. Full Color", "CRSF logo.png")

PAGE_W_PORTRAIT = Inches(8.5)
PAGE_H_PORTRAIT = Inches(11)
MARGIN = Inches(1.0)
TEXT_WIDTH_PORTRAIT = PAGE_W_PORTRAIT - 2 * MARGIN          # 6.5 in
TEXT_WIDTH_LANDSCAPE = PAGE_H_PORTRAIT - 2 * MARGIN          # 9.0 in

FIGURE_DIR_NAME = "figures"

# --------------------------------------------------------------------------
# Unicode super/subscript glyph tables -> (plain char, mode)
# --------------------------------------------------------------------------

SUPER_MAP = {
    '⁰': '0', '¹': '1', '²': '2', '³': '3', '⁴': '4',
    '⁵': '5', '⁶': '6', '⁷': '7', '⁸': '8', '⁹': '9',
    '⁺': '+', '⁻': '-', '⁽': '(', '⁾': ')', 'ⁱ': 'i', 'ⁿ': 'n',
}
SUB_MAP = {
    '₀': '0', '₁': '1', '₂': '2', '₃': '3', '₄': '4',
    '₅': '5', '₆': '6', '₇': '7', '₈': '8', '₉': '9',
    '₊': '+', '₋': '-', '₍': '(', '₎': ')',
}


def split_supersub(text):
    """Split text into (segment, mode) tuples, mode in {'normal','super','sub'},
    converting Unicode super/subscript glyphs to plain characters in the
    'super'/'sub' segments so a real docx vertAlign run can be applied."""
    out = []
    buf = ''
    buf_mode = 'normal'
    for ch in text:
        if ch in SUPER_MAP:
            mode, mapped = 'super', SUPER_MAP[ch]
        elif ch in SUB_MAP:
            mode, mapped = 'sub', SUB_MAP[ch]
        else:
            mode, mapped = 'normal', ch
        if mode != buf_mode:
            if buf:
                out.append((buf, buf_mode))
            buf, buf_mode = mapped, mode
        else:
            buf += mapped
    if buf:
        out.append((buf, buf_mode))
    return out


# ==========================================================================
# Low-level OOXML helpers
# ==========================================================================


def set_cell_border(cell, **kwargs):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcBorders = tcPr.find(qn('w:tcBorders'))
    if tcBorders is None:
        tcBorders = OxmlElement('w:tcBorders')
        tcPr.append(tcBorders)
    for edge in ("top", "left", "bottom", "right"):
        spec = kwargs.get(edge)
        if spec is None:
            continue
        tag = f"w:{edge}"
        el = tcBorders.find(qn(tag))
        if el is None:
            el = OxmlElement(tag)
            tcBorders.append(el)
        el.set(qn('w:val'), spec.get('val', 'single'))
        el.set(qn('w:sz'), str(spec.get('sz', 6)))
        el.set(qn('w:space'), '0')
        el.set(qn('w:color'), spec.get('color', '1A3D28'))


def set_table_outer_borders(table, color="1A3D28", sz_top=10, sz_bottom=10):
    """Table-level borders: single rule top and bottom, no left/right/interior
    rules. House style: rule above header, rule below header, rule below last
    row, no verticals. The rule below the header is applied per-cell below."""
    tbl = table._tbl
    tblPr = tbl.tblPr
    borders = OxmlElement('w:tblBorders')
    for edge, sz in (('top', sz_top), ('bottom', sz_bottom)):
        el = OxmlElement(f'w:{edge}')
        el.set(qn('w:val'), 'single')
        el.set(qn('w:sz'), str(sz))
        el.set(qn('w:space'), '0')
        el.set(qn('w:color'), color)
        borders.append(el)
    for edge in ('left', 'right', 'insideH', 'insideV'):
        el = OxmlElement(f'w:{edge}')
        el.set(qn('w:val'), 'none')
        el.set(qn('w:sz'), '0')
        el.set(qn('w:space'), '0')
        el.set(qn('w:color'), 'auto')
        borders.append(el)
    tblPr.append(borders)


def set_table_fixed_layout(table, total_dxa):
    tbl = table._tbl
    tblPr = tbl.tblPr
    layout = OxmlElement('w:tblLayout')
    layout.set(qn('w:type'), 'fixed')
    tblPr.append(layout)
    tblW = tblPr.find(qn('w:tblW'))
    if tblW is None:
        tblW = OxmlElement('w:tblW')
        tblPr.append(tblW)
    tblW.set(qn('w:type'), 'dxa')
    tblW.set(qn('w:w'), str(int(total_dxa)))


def set_col_widths(table, widths_dxa):
    tbl = table._tbl
    tblGrid = tbl.find(qn('w:tblGrid'))
    if tblGrid is None:
        tblGrid = OxmlElement('w:tblGrid')
        tbl.insert(0, tblGrid)
    for gc in list(tblGrid):
        tblGrid.remove(gc)
    for w in widths_dxa:
        gridCol = OxmlElement('w:gridCol')
        gridCol.set(qn('w:w'), str(int(w)))
        tblGrid.append(gridCol)
    for row in table.rows:
        for idx, cell in enumerate(row.cells):
            if idx >= len(widths_dxa):
                continue
            tcPr = cell._tc.get_or_add_tcPr()
            tcW = tcPr.find(qn('w:tcW'))
            if tcW is None:
                tcW = OxmlElement('w:tcW')
                tcPr.append(tcW)
            tcW.set(qn('w:type'), 'dxa')
            tcW.set(qn('w:w'), str(int(widths_dxa[idx])))


def set_table_cell_margins(table, top_dxa=20, bottom_dxa=20, left_dxa=86, right_dxa=86):
    tbl = table._tbl
    tblPr = tbl.tblPr
    mar = OxmlElement('w:tblCellMar')
    for tag, val in (('top', top_dxa), ('bottom', bottom_dxa), ('left', left_dxa), ('right', right_dxa)):
        el = OxmlElement(f'w:{tag}')
        el.set(qn('w:w'), str(int(val)))
        el.set(qn('w:type'), 'dxa')
        mar.append(el)
    tblPr.append(mar)


def add_paragraph_rule(paragraph, color="1A3D28", sz=18, space=1):
    pPr = paragraph._p.get_or_add_pPr()
    pBdr = OxmlElement('w:pBdr')
    bottom = OxmlElement('w:bottom')
    bottom.set(qn('w:val'), 'single')
    bottom.set(qn('w:sz'), str(sz))
    bottom.set(qn('w:space'), str(space))
    bottom.set(qn('w:color'), color)
    pBdr.append(bottom)
    pPr.append(pBdr)


def set_heading_rule(paragraph, color="1A3D28", sz=6, space=4):
    pPr = paragraph._p.get_or_add_pPr()
    pBdr = OxmlElement('w:pBdr')
    bottom = OxmlElement('w:bottom')
    bottom.set(qn('w:val'), 'single')
    bottom.set(qn('w:sz'), str(sz))
    bottom.set(qn('w:space'), str(space))
    bottom.set(qn('w:color'), color)
    pBdr.append(bottom)
    pPr.append(pBdr)


def add_top_rule(paragraph, color="C5A55A", sz=8, space=4):
    pPr = paragraph._p.get_or_add_pPr()
    pBdr = OxmlElement('w:pBdr')
    top = OxmlElement('w:top')
    top.set(qn('w:val'), 'single')
    top.set(qn('w:sz'), str(sz))
    top.set(qn('w:space'), str(space))
    top.set(qn('w:color'), color)
    pBdr.append(top)
    pPr.append(pBdr)


def add_page_field(paragraph, field_type='PAGE'):
    run = paragraph.add_run()
    fld_begin = OxmlElement('w:fldChar')
    fld_begin.set(qn('w:fldCharType'), 'begin')
    instr = OxmlElement('w:instrText')
    instr.set(qn('xml:space'), 'preserve')
    instr.text = f' {field_type} '
    fld_sep = OxmlElement('w:fldChar')
    fld_sep.set(qn('w:fldCharType'), 'separate')
    fld_end = OxmlElement('w:fldChar')
    fld_end.set(qn('w:fldCharType'), 'end')
    run._r.append(fld_begin)
    run._r.append(instr)
    run._r.append(fld_sep)
    run._r.append(fld_end)


def build_footer(section, title_text):
    footer = section.footer
    footer.is_linked_to_previous = False
    p = footer.paragraphs[0] if footer.paragraphs else footer.add_paragraph()
    p.text = ''
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    add_top_rule(p, color="C5A55A", sz=8, space=4)
    run = p.add_run(title_text + " | CRSF | Page ")
    run.font.name = BODY_FONT
    run.font.size = Pt(8.5)
    run.font.color.rgb = RGBColor(0x59, 0x59, 0x59)
    add_page_field(p, 'PAGE')
    run2 = p.add_run(" of ")
    run2.font.name = BODY_FONT
    run2.font.size = Pt(8.5)
    run2.font.color.rgb = RGBColor(0x59, 0x59, 0x59)
    add_page_field(p, 'NUMPAGES')


def new_section(doc, orientation, footer_title=None):
    section = doc.add_section(WD_SECTION.NEW_PAGE)
    if orientation == 'landscape':
        section.orientation = WD_ORIENT.LANDSCAPE
        section.page_width, section.page_height = PAGE_H_PORTRAIT, PAGE_W_PORTRAIT
    else:
        section.orientation = WD_ORIENT.PORTRAIT
        section.page_width, section.page_height = PAGE_W_PORTRAIT, PAGE_H_PORTRAIT
    section.left_margin = MARGIN
    section.right_margin = MARGIN
    section.top_margin = MARGIN
    section.bottom_margin = MARGIN
    if footer_title:
        build_footer(section, footer_title)
    return section


# ==========================================================================
# Inline text formatting (bold / italic span parsing + true super/subscript)
# ==========================================================================

_INLINE_RE = re.compile(r'\*\*([^*\n]+?)\*\*|\*([^*\n]+?)\*')
_NAME_RE = re.compile(r"^[A-Z][A-Za-z.\s,'()&:-]*$")


def _looks_like_name(s):
    s = s.strip()
    if not s:
        return False
    if len(s) > 70:
        return False
    if re.search(r'[0-9+/=^]', s):
        return False
    if not _NAME_RE.match(s):
        return False
    return True


def add_inline_runs(paragraph, text, size=None, color=None, font_name=BODY_FONT):
    pos = 0
    for m in _INLINE_RE.finditer(text):
        if m.start() > pos:
            _add_run(paragraph, text[pos:m.start()], False, False, size, color, font_name)
        bold_content, ital_content = m.group(1), m.group(2)
        if bold_content is not None:
            _add_run(paragraph, bold_content, True, False, size, color, font_name)
        else:
            if _looks_like_name(ital_content):
                _add_run(paragraph, ital_content, False, True, size, color, font_name)
            else:
                _add_run(paragraph, m.group(0), False, False, size, color, font_name)
        pos = m.end()
    if pos < len(text):
        _add_run(paragraph, text[pos:], False, False, size, color, font_name)


def _add_run(paragraph, text, bold, italic, size, color, font_name):
    if text == "":
        return
    for seg, mode in split_supersub(text):
        if seg == "":
            continue
        run = paragraph.add_run(seg)
        run.bold = bold
        run.italic = italic
        run.font.name = font_name
        if size is not None:
            run.font.size = size
        if color is not None:
            run.font.color.rgb = color
        if mode == 'super':
            run.font.superscript = True
        elif mode == 'sub':
            run.font.subscript = True


# ==========================================================================
# Markdown block parsing helpers
# ==========================================================================

TABLE_SEP_RE = re.compile(r'^\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$')


def is_table_row(line):
    return line.strip().startswith('|')


def split_row(line):
    line = line.strip()
    if line.startswith('|'):
        line = line[1:]
    if line.endswith('|'):
        line = line[:-1]
    return [c.strip() for c in line.split('|')]


def is_image_line(line):
    return re.match(r'^!\[.*?\]\(.*?\)\s*$', line.strip()) is not None


IMAGE_RE = re.compile(r'^!\[(?P<alt>.*?)\]\((?P<path>.*?)\)\s*$')
FIG_PREFIX_RE = re.compile(r'^Figure\s+(\d+)\.\s*(.*)$', re.IGNORECASE)
FIG_CAPTION_PARA_RE = re.compile(r'^\*\*Figure\s+(\d+)\.\*\*\s*(.*)$', re.IGNORECASE | re.DOTALL)


def is_equation_line(line):
    return (line.startswith('    ') or line.startswith('\t')) and line.strip() != ''


def is_heading(line):
    return re.match(r'^#{1,6}\s', line) is not None


def heading_level_text(line):
    m = re.match(r'^(#{1,6})\s+(.*)$', line.strip())
    return len(m.group(1)), m.group(2).strip()


def is_list_item_start(line):
    return re.match(r'^\d+\.\s+\S', line) is not None or re.match(r'^-\s+\S', line) is not None


def is_blank(line):
    return line.strip() == ''


# ==========================================================================
# Document builder
# ==========================================================================


class BenchmarkBuilder:
    def __init__(self, md_path, out_path, footer_title):
        self.md_path = md_path
        self.md_dir = os.path.dirname(os.path.abspath(md_path))
        self.out_path = out_path
        self.footer_title = footer_title
        self.lines = open(md_path, encoding='utf-8').read().split('\n')
        self.n = len(self.lines)
        self.doc = Document()
        self.fig_counter = 1
        self.orientation = 'portrait'
        self._setup_document()

    def _setup_document(self):
        doc = self.doc
        section = doc.sections[0]
        section.page_width = PAGE_W_PORTRAIT
        section.page_height = PAGE_H_PORTRAIT
        section.orientation = WD_ORIENT.PORTRAIT
        section.left_margin = MARGIN
        section.right_margin = MARGIN
        section.top_margin = MARGIN
        section.bottom_margin = MARGIN
        build_footer(section, self.footer_title)

        normal = doc.styles['Normal']
        normal.font.name = BODY_FONT
        normal.font.size = Pt(11)
        normal.font.color.rgb = BODY_BLACK
        normal.paragraph_format.space_after = Pt(8)
        normal.paragraph_format.space_before = Pt(0)

        h1 = doc.styles['Heading 1']
        h1.font.name = HEADING_FONT
        h1.font.size = Pt(16)
        h1.font.bold = True
        h1.font.color.rgb = CRSF_GREEN
        h1.paragraph_format.space_before = Pt(20)
        h1.paragraph_format.space_after = Pt(8)
        h1.paragraph_format.keep_with_next = True

        h2 = doc.styles['Heading 2']
        h2.font.name = HEADING_FONT
        h2.font.size = Pt(13)
        h2.font.bold = True
        h2.font.color.rgb = CRSF_GREEN
        h2.paragraph_format.space_before = Pt(14)
        h2.paragraph_format.space_after = Pt(6)
        h2.paragraph_format.keep_with_next = True

    def build(self):
        i = self._build_front_matter(0)
        self._build_body(i)
        self.doc.save(self.out_path)

    # ---- front matter (title page + TOC) ------------------------------

    def _build_front_matter(self, i):
        doc = self.doc
        lines = self.lines

        # CRSF logo, centered
        if os.path.exists(CRSF_LOGO):
            p = doc.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.add_run().add_picture(CRSF_LOGO, height=Inches(1.15))

        doc.add_paragraph().paragraph_format.space_after = Pt(6)

        bar = doc.add_paragraph()
        bar.paragraph_format.space_after = Pt(28)
        add_paragraph_rule(bar, color="1A3D28", sz=36, space=1)

        assert lines[i].startswith('# '), f"expected H1 title at line {i+1}, got: {lines[i]!r}"
        title_text = lines[i][2:].strip()
        i += 1
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_after = Pt(18)
        add_inline_runs(p, title_text, size=Pt(24), color=CRSF_GREEN, font_name=HEADING_FONT)
        for r in p.runs:
            r.bold = True

        i = self._skip_blank(i)

        while i < self.n and not (is_heading(lines[i]) and heading_level_text(lines[i])[1].strip().lower() == 'table of contents'):
            if is_blank(lines[i]):
                i += 1
                continue
            if is_heading(lines[i]):
                level, text = heading_level_text(lines[i])
                p = doc.add_paragraph()
                p.alignment = WD_ALIGN_PARAGRAPH.LEFT
                p.paragraph_format.space_before = Pt(16)
                p.paragraph_format.space_after = Pt(6)
                add_inline_runs(p, text, size=Pt(13), color=CRSF_GREEN, font_name=HEADING_FONT)
                for r in p.runs:
                    r.bold = True
                i += 1
                continue
            para_lines, i = self._collect_paragraph(i)
            joined = ' '.join(para_lines)
            p = doc.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if joined.startswith('**DRAFT') else WD_ALIGN_PARAGRAPH.LEFT
            size = Pt(11)
            color = None
            if joined.startswith('*') and not joined.startswith('**'):
                size = Pt(10)
                color = RGBColor(0x40, 0x40, 0x40)
            add_inline_runs(p, joined, size=size, color=color, font_name=BODY_FONT)

        doc.add_page_break()

        assert is_heading(lines[i])
        level, text = heading_level_text(lines[i])
        i += 1
        h = doc.add_paragraph()
        add_inline_runs(h, text, size=Pt(16), color=CRSF_GREEN, font_name=HEADING_FONT)
        for r in h.runs:
            r.bold = True
        h.paragraph_format.space_after = Pt(10)
        set_heading_rule(h)
        i = self._skip_blank(i)

        while i < self.n and not is_heading(lines[i]):
            if is_blank(lines[i]):
                i += 1
                continue
            marker, item_lines, i = self._collect_list_item(i)
            joined = ' '.join(item_lines)
            p = doc.add_paragraph()
            p.paragraph_format.left_indent = Inches(0.3)
            p.paragraph_format.first_line_indent = Inches(-0.3)
            p.paragraph_format.space_after = Pt(4)
            run = p.add_run(marker + " ")
            run.bold = True
            run.font.name = BODY_FONT
            run.font.size = Pt(11)
            add_inline_runs(p, joined, size=Pt(11), font_name=BODY_FONT)

        return i

    # ---- body -----------------------------------------------------------

    def _build_body(self, i):
        doc = self.doc
        lines = self.lines
        first_numbered_heading_seen = False

        while i < self.n:
            line = lines[i]

            if is_blank(line):
                i += 1
                continue

            if is_heading(line):
                level, text = heading_level_text(line)
                is_body_h1 = (level == 2) and (re.match(r'^\d+\.\s', text) or re.match(r'^Appendix', text))
                is_body_h2 = (level == 3)

                if is_body_h1:
                    if not first_numbered_heading_seen:
                        if self.orientation != 'portrait':
                            new_section(doc, 'portrait', self.footer_title)
                            self.orientation = 'portrait'
                        else:
                            doc.add_page_break()
                        first_numbered_heading_seen = True
                    p = doc.add_heading(level=1)
                    add_inline_runs(p, text, size=Pt(16), color=CRSF_GREEN, font_name=HEADING_FONT)
                    set_heading_rule(p)
                    i += 1
                    continue
                elif is_body_h2:
                    p = doc.add_heading(level=2)
                    add_inline_runs(p, text, size=Pt(13), color=CRSF_GREEN, font_name=HEADING_FONT)
                    i += 1
                    continue
                else:
                    p = doc.add_heading(level=2)
                    add_inline_runs(p, text, size=Pt(13), color=CRSF_GREEN, font_name=HEADING_FONT)
                    i += 1
                    continue

            if is_equation_line(line):
                block_lines = []
                while i < self.n and (is_equation_line(lines[i]) or lines[i].strip() == ''):
                    if lines[i].strip() == '':
                        j = i + 1
                        if j < self.n and is_equation_line(lines[j]):
                            block_lines.append('')
                            i += 1
                            continue
                        else:
                            break
                    block_lines.append(lines[i][4:] if lines[i].startswith('    ') else lines[i].lstrip('\t'))
                    i += 1
                self._add_equation_block(block_lines)
                continue

            if is_image_line(line):
                i = self._handle_image(i)
                continue

            if is_table_row(line) and i + 1 < self.n and TABLE_SEP_RE.match(lines[i + 1].strip()):
                i = self._handle_table(i)
                continue

            if is_list_item_start(line):
                i = self._handle_list_block(i)
                continue

            para_lines, i = self._collect_paragraph(i)
            joined = ' '.join(para_lines)
            p = doc.add_paragraph()
            add_inline_runs(p, joined, size=Pt(11), font_name=BODY_FONT)
            if joined.startswith('**Table') or joined.startswith('**Figure'):
                p.paragraph_format.space_before = Pt(10)
                p.paragraph_format.space_after = Pt(4)

    # ---- block collectors -------------------------------------------

    def _skip_blank(self, i):
        while i < self.n and is_blank(self.lines[i]):
            i += 1
        return i

    def _collect_paragraph(self, i):
        out = []
        while i < self.n:
            line = self.lines[i]
            if is_blank(line):
                break
            if is_heading(line) or is_table_row(line) or is_image_line(line) or is_equation_line(line):
                break
            if is_list_item_start(line) and out:
                break
            out.append(line.strip())
            i += 1
        return out, i

    def _collect_list_item(self, i):
        first = self.lines[i]
        m = re.match(r'^(\d+\.|-)\s+(.*)$', first)
        marker = m.group(1)
        out = [m.group(2).strip()]
        i += 1
        while i < self.n:
            line = self.lines[i]
            if is_blank(line) or is_list_item_start(line) or is_heading(line):
                break
            out.append(line.strip())
            i += 1
        return marker, out, i

    def _handle_list_block(self, i):
        while i < self.n and is_list_item_start(self.lines[i]):
            numbered = re.match(r'^\d+\.\s', self.lines[i]) is not None
            marker, item_lines, i = self._collect_list_item(i)
            joined = ' '.join(item_lines)
            p = self.doc.add_paragraph(style='List Number' if numbered else 'List Bullet')
            add_inline_runs(p, joined, size=Pt(11), font_name=BODY_FONT)
            i = self._skip_blank(i)
        return i

    # ---- equations -----------------------------------------------------

    def _add_equation_block(self, block_lines):
        text = '\n'.join(block_lines).rstrip('\n')
        if not text.strip():
            return
        p = self.doc.add_paragraph()
        p.paragraph_format.left_indent = Inches(0.3)
        p.paragraph_format.space_before = Pt(4)
        p.paragraph_format.space_after = Pt(8)
        lines = text.split('\n')
        for idx, ln in enumerate(lines):
            run = p.add_run(ln)
            run.font.name = 'Consolas'
            run.font.size = Pt(9.5)
            run.font.color.rgb = BODY_BLACK
            if idx < len(lines) - 1:
                run.add_break()

    # ---- images / figures -----------------------------------------------

    def _handle_image(self, i):
        line = self.lines[i].strip()
        m = IMAGE_RE.match(line)
        alt = m.group('alt').strip()
        rel_path = m.group('path').strip()
        img_path = os.path.join(self.md_dir, rel_path)
        i += 1

        fig_m = FIG_PREFIX_RE.match(alt)
        caption_bold = None
        caption_rest = None
        if fig_m:
            num = int(fig_m.group(1))
            caption_bold = f"Figure {num}."
            caption_rest = fig_m.group(2).strip()
            self.fig_counter = max(self.fig_counter, num + 1)
        else:
            j = self._skip_blank(i)
            if j < self.n and self.lines[j].strip().startswith('**Figure'):
                para_lines, j2 = self._collect_paragraph(j)
                joined = ' '.join(para_lines)
                cap_m = FIG_CAPTION_PARA_RE.match(joined)
                if cap_m:
                    num = int(cap_m.group(1))
                    caption_bold = f"Figure {num}."
                    caption_rest = cap_m.group(2).strip()
                    self.fig_counter = max(self.fig_counter, num + 1)
                    i = j2
            if caption_bold is None:
                caption_bold = f"Figure {self.fig_counter}."
                caption_rest = alt
                self.fig_counter += 1

        p = self.doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(10)
        p.paragraph_format.space_after = Pt(4)
        if os.path.exists(img_path):
            try:
                width = TEXT_WIDTH_PORTRAIT if self.orientation == 'portrait' else TEXT_WIDTH_LANDSCAPE
                p.add_run().add_picture(img_path, width=min(width, Inches(6.5)))
            except Exception as e:
                run = p.add_run(f"[image failed to load: {rel_path} ({e})]")
                run.italic = True
        else:
            run = p.add_run(f"[image not found: {rel_path}]")
            run.italic = True
            run.font.color.rgb = RGBColor(0xB0, 0x00, 0x00)

        cap = self.doc.add_paragraph()
        cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        cap.paragraph_format.space_before = Pt(2)
        cap.paragraph_format.space_after = Pt(12)
        run = cap.add_run(caption_bold + " ")
        run.bold = True
        run.font.name = BODY_FONT
        run.font.size = Pt(10)
        add_inline_runs(cap, caption_rest, size=Pt(10), font_name=BODY_FONT)

        return i

    # ---- tables --------------------------------------------------------

    def _handle_table(self, i):
        header = split_row(self.lines[i])
        ncols = len(header)
        i += 2
        rows = []
        while i < self.n and is_table_row(self.lines[i]):
            row = split_row(self.lines[i])
            if len(row) < ncols:
                row = row + [''] * (ncols - len(row))
            elif len(row) > ncols:
                row = row[:ncols]
            rows.append(row)
            i += 1

        self._render_table(header, rows, ncols)
        return i

    def _render_table(self, header, rows, ncols):
        doc = self.doc

        col_maxlen = []
        for c in range(ncols):
            vals = [header[c]] + [r[c] for r in rows]
            col_maxlen.append(max((len(v) for v in vals), default=1))

        widest = max(col_maxlen)
        needs_landscape = ncols >= 13 or (ncols >= 9 and widest > 16)

        if ncols <= 6:
            font_pt = 10
        elif ncols <= 8:
            font_pt = 9
        elif not needs_landscape:
            font_pt = 8
        elif ncols <= 12:
            font_pt = 8
        elif ncols <= 16:
            font_pt = 7.5
        else:
            font_pt = 7

        if needs_landscape and self.orientation != 'landscape':
            new_section(doc, 'landscape', self.footer_title)
            self.orientation = 'landscape'
        elif not needs_landscape and self.orientation != 'portrait':
            new_section(doc, 'portrait', self.footer_title)
            self.orientation = 'portrait'

        text_width = TEXT_WIDTH_LANDSCAPE if self.orientation == 'landscape' else TEXT_WIDTH_PORTRAIT
        total_dxa = int(round(int(text_width) / 635))

        cell_margin_in = 0.06
        char_w_in = 0.60 * font_pt / 72.0
        col_floor_dxa = [
            int((char_w_in * min(w, 10) + 2 * cell_margin_in) * 1440)
            for w in col_maxlen
        ]
        weights = [max(w, 4) for w in col_maxlen]
        widths = [0.0] * ncols
        remaining_budget = float(total_dxa)
        remaining_cols = list(range(ncols))
        for _ in range(ncols):
            if not remaining_cols:
                break
            weight_sum = sum(weights[c] for c in remaining_cols)
            any_floored_this_round = False
            for c in list(remaining_cols):
                share = remaining_budget * weights[c] / weight_sum
                if share < col_floor_dxa[c]:
                    widths[c] = col_floor_dxa[c]
                    remaining_cols.remove(c)
                    remaining_budget -= col_floor_dxa[c]
                    any_floored_this_round = True
            if not any_floored_this_round:
                for c in remaining_cols:
                    widths[c] = remaining_budget * weights[c] / weight_sum
                break
        if remaining_budget < 0:
            floor_sum = sum(col_floor_dxa)
            widths = [total_dxa * f / floor_sum for f in col_floor_dxa]
        widths = [int(w) for w in widths]
        drift = total_dxa - sum(widths)
        widest_col = max(range(ncols), key=lambda c: weights[c])
        widths[widest_col] += drift

        table = doc.add_table(rows=1 + len(rows), cols=ncols)
        table.autofit = False
        set_table_fixed_layout(table, total_dxa)
        set_col_widths(table, widths)
        set_table_outer_borders(table)
        set_table_cell_margins(table, left_dxa=int(cell_margin_in * 1440), right_dxa=int(cell_margin_in * 1440))

        for c in range(ncols):
            cell = table.rows[0].cells[c]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            add_inline_runs(p, header[c], size=Pt(font_pt), font_name=BODY_FONT)
            for r in p.runs:
                r.bold = True
            set_cell_border(cell, bottom={'sz': 8, 'color': '1A3D28', 'val': 'single'})

        for ridx, row in enumerate(rows):
            for c in range(ncols):
                cell = table.rows[ridx + 1].cells[c]
                cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
                p = cell.paragraphs[0]
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                add_inline_runs(p, row[c], size=Pt(font_pt), font_name=BODY_FONT)

        for row in table.rows:
            for cell in row.cells:
                for p in cell.paragraphs:
                    p.paragraph_format.space_before = Pt(1)
                    p.paragraph_format.space_after = Pt(1)

        spacer = doc.add_paragraph()
        spacer.paragraph_format.space_after = Pt(10)

        if needs_landscape and self.orientation == 'landscape':
            new_section(doc, 'portrait', self.footer_title)
            self.orientation = 'portrait'


# ==========================================================================
# Entry point
# ==========================================================================


def main():
    if len(sys.argv) not in (3, 4):
        print('Usage: python3 build_benchmark_docx.py <input.md> <output.docx> ["<footer title>"]')
        sys.exit(1)
    md_path, out_path = sys.argv[1], sys.argv[2]
    footer_title = sys.argv[3] if len(sys.argv) == 4 else "FVS-ACD v12.11 Benchmark Report"
    builder = BenchmarkBuilder(md_path, out_path, footer_title)
    builder.build()
    print(f"Wrote {out_path}")


if __name__ == '__main__':
    main()

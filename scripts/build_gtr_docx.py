#!/usr/bin/env python3
"""
build_gtr_docx.py

Convert the FVS-ACD (Acadian variant) GTR Markdown draft into a branded,
journal-formatted Word (.docx) document following CRSF/CFRU house style.

Usage:
    python3 build_gtr_docx.py <input.md> <output.docx>

Depends on python-docx (pip install --break-system-packages python-docx).
This is a purpose-built line/block state-machine converter for this specific
document's Markdown conventions (see CRSF-Cowork CLAUDE.md house style and
the GTR pipeline task brief) -- it is not a general Markdown parser.
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
# Brand constants (CRSF / CFRU house style)
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
CFRU_LOGO = os.path.join(LOGO_DIR, "CFRU logo", "CFRU logo (2018)",
                          "2. CFRU - no background", "CFRU logo-no background (2018).png")

PAGE_W_PORTRAIT = Inches(8.5)
PAGE_H_PORTRAIT = Inches(11)
MARGIN = Inches(1.0)
TEXT_WIDTH_PORTRAIT = PAGE_W_PORTRAIT - 2 * MARGIN          # 6.5 in
TEXT_WIDTH_LANDSCAPE = PAGE_H_PORTRAIT - 2 * MARGIN          # 9.0 in (landscape = swapped dims)

FIGURE_DIR_NAME = "figures"

# ==========================================================================
# Low-level OOXML helpers
# ==========================================================================


def set_cell_border(cell, **kwargs):
    """Set individual borders on a table cell.
    kwargs keys: top, bottom, left, right -> dict(sz=int_eighths_pt, color='RRGGBB', val='single')
    Passing None for a side removes/omits that border (leaves default = none).
    """
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
    """Table-level borders: single rule top and bottom, no left/right/interior rules."""
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
    """Force fixed table layout at an explicit total width (dxa = 1/20 pt)."""
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
    """Set explicit DXA widths on the tblGrid and on every cell (per house style,
    both table and per-cell widths are set for cross-renderer reliability)."""
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
    """Set default cell margins at the table level (dxa). Narrower left/right
    margins reclaim horizontal room for wide, many-column tables."""
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
    """Add a bottom border rule under a paragraph (used for title-page accent bars)."""
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
    """Thin accent rule under a heading paragraph."""
    pPr = paragraph._p.get_or_add_pPr()
    pBdr = OxmlElement('w:pBdr')
    bottom = OxmlElement('w:bottom')
    bottom.set(qn('w:val'), 'single')
    bottom.set(qn('w:sz'), str(sz))
    bottom.set(qn('w:space'), str(space))
    bottom.set(qn('w:color'), color)
    pBdr.append(bottom)
    pPr.append(pBdr)


def shade_cell(cell, hexcolor):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'), hexcolor)
    tcPr.append(shd)


def new_section(doc, orientation, first_page_break=True):
    """Start a new section with the given orientation ('portrait'/'landscape')."""
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
    return section


# ==========================================================================
# Inline text formatting (bold / italic span parsing)
# ==========================================================================

_INLINE_RE = re.compile(r'\*\*([^*\n]+?)\*\*|\*([^*\n]+?)\*')
_NAME_RE = re.compile(r"^[A-Z][A-Za-z.\s,'()&:-]*$")


def _looks_like_name(s):
    """Heuristic: only treat single-asterisk spans as italic markup if the
    content plausibly is a taxonomic name / title, not an equation fragment
    where '*' is being used as a multiplication operator (this document mixes
    both conventions). Rejects content with digits or math operators, or
    that doesn't start with a capital letter."""
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
    """Parse **bold** and validated *italic* spans in `text` and add runs to `paragraph`."""
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
                # Not a valid italic span (e.g. equation multiplication) -- keep literal text.
                _add_run(paragraph, m.group(0), False, False, size, color, font_name)
        pos = m.end()
    if pos < len(text):
        _add_run(paragraph, text[pos:], False, False, size, color, font_name)


def _add_run(paragraph, text, bold, italic, size, color, font_name):
    if text == "":
        return
    run = paragraph.add_run(text)
    run.bold = bold
    run.italic = italic
    run.font.name = font_name
    if size is not None:
        run.font.size = size
    if color is not None:
        run.font.color.rgb = color


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


class GTRBuilder:
    def __init__(self, md_path, out_path):
        self.md_path = md_path
        self.md_dir = os.path.dirname(os.path.abspath(md_path))
        self.out_path = out_path
        self.lines = open(md_path, encoding='utf-8').read().split('\n')
        self.n = len(self.lines)
        self.doc = Document()
        self.fig_counter = 1
        self.body_started = False
        self.orientation = 'portrait'
        self._setup_document()

    # ---- setup -----------------------------------------------------

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

    # ---- main entry --------------------------------------------------

    def build(self):
        i = self._build_front_matter(0)
        self._build_body(i)
        self.doc.save(self.out_path)

    # ---- front matter (title page + TOC) ------------------------------

    def _build_front_matter(self, i):
        doc = self.doc
        lines = self.lines

        # --- Title page ---
        # Logos, centered, side by side using a 2-col borderless table.
        logo_table = doc.add_table(rows=1, cols=2)
        logo_table.autofit = False
        set_col_widths(logo_table, [Emu(int(TEXT_WIDTH_PORTRAIT / 2)), Emu(int(TEXT_WIDTH_PORTRAIT / 2))])
        for cell in logo_table.rows[0].cells:
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        if os.path.exists(CRSF_LOGO):
            p = logo_table.rows[0].cells[0].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.add_run().add_picture(CRSF_LOGO, height=Inches(1.15))
        if os.path.exists(CFRU_LOGO):
            p = logo_table.rows[0].cells[1].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.add_run().add_picture(CFRU_LOGO, height=Inches(1.15))

        doc.add_paragraph().paragraph_format.space_after = Pt(6)

        # Green accent bar
        bar = doc.add_paragraph()
        bar.paragraph_format.space_after = Pt(28)
        add_paragraph_rule(bar, color="1A3D28", sz=36, space=1)

        # Expect: # Title
        assert lines[i].startswith('# '), f"expected H1 title at line {i+1}, got: {lines[i]!r}"
        title_text = lines[i][2:].strip()
        i += 1
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_after = Pt(18)
        add_inline_runs(p, title_text, size=Pt(26), color=CRSF_GREEN, font_name=HEADING_FONT)
        for r in p.runs:
            r.bold = True

        i = self._skip_blank(i)

        # Following blocks up to "## Table of Contents" belong on the title page:
        # DRAFT/status bold line, italic scaffold paragraph, "## Authors and
        # Contributors" heading + paragraph, suggested citation.
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
            # paragraph block (join wrapped lines)
            para_lines, i = self._collect_paragraph(i)
            joined = ' '.join(para_lines)
            p = doc.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if joined.startswith('**DRAFT') else WD_ALIGN_PARAGRAPH.LEFT
            size = Pt(11)
            color = None
            if joined.startswith('*') and not joined.startswith('**'):
                # entire italic scaffold paragraph
                size = Pt(10)
                color = RGBColor(0x40, 0x40, 0x40)
            add_inline_runs(p, joined, size=size, color=color, font_name=BODY_FONT)

        # Page break before Table of Contents
        doc.add_page_break()

        # --- Table of Contents ---
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
                is_body_h1 = (level == 2) and (re.match(r'^\d+\.\s', text) or text.startswith('Appendix'))
                is_body_h2 = (level == 3)

                if is_body_h1:
                    if not first_numbered_heading_seen:
                        # page break before Section 1 (start of numbered body)
                        if self.orientation != 'portrait':
                            new_section(doc, 'portrait')
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
                    # Front-matter-style heading appearing in body flow (e.g. "Quick Guide to
                    # Default Settings") -- render as a Heading 2-equivalent.
                    p = doc.add_heading(level=2)
                    add_inline_runs(p, text, size=Pt(13), color=CRSF_GREEN, font_name=HEADING_FONT)
                    i += 1
                    continue

            if is_equation_line(line):
                block_lines = []
                while i < self.n and (is_equation_line(lines[i]) or lines[i].strip() == ''):
                    if lines[i].strip() == '':
                        # allow a single blank line inside an equation block, but stop
                        # if the next non-blank line isn't indented (end of block)
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

            # default: paragraph
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
        """Collect one list item (marker line + indented continuation lines).
        Returns (marker, item_lines, next_i) where marker is e.g. '1.' or '-'."""
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

        # Determine caption + figure number
        fig_m = FIG_PREFIX_RE.match(alt)
        caption_bold = None
        caption_rest = None
        if fig_m:
            num = int(fig_m.group(1))
            caption_bold = f"Figure {num}."
            caption_rest = fig_m.group(2).strip()
            self.fig_counter = max(self.fig_counter, num + 1)
        else:
            # look ahead for a following "**Figure N.** ..." paragraph
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

        # Insert image, centered
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

        # Caption below
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
        i += 2  # skip header + separator row
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

        # column max content length (for width allocation + landscape decision)
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
            new_section(doc, 'landscape')
            self.orientation = 'landscape'
        elif not needs_landscape and self.orientation != 'portrait':
            new_section(doc, 'portrait')
            self.orientation = 'portrait'

        text_width = TEXT_WIDTH_LANDSCAPE if self.orientation == 'landscape' else TEXT_WIDTH_PORTRAIT
        total_dxa = int(round(int(text_width) / 635))  # EMU -> twips (1 twip = 635 EMU)

        # Water-filling column-width allocation: give every column a *content-aware*
        # floor width (enough to hold its own header/short values on one line, so
        # "Code"/"sg"/"PLANTS"-style short headers never wrap), then distribute the
        # remaining budget across the rest proportional to content length, widening
        # text-heavy columns (species/common names) and narrowing numeric ones.
        cell_margin_in = 0.06  # matches set_cell_margins() below
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
            # Pathological case (floors alone exceed total width, e.g. an
            # extremely wide table): fall back to proportional floors.
            floor_sum = sum(col_floor_dxa)
            widths = [total_dxa * f / floor_sum for f in col_floor_dxa]
        widths = [int(w) for w in widths]
        # fix rounding drift on the widest (least width-sensitive) column
        drift = total_dxa - sum(widths)
        widest_col = max(range(ncols), key=lambda c: weights[c])
        widths[widest_col] += drift

        table = doc.add_table(rows=1 + len(rows), cols=ncols)
        table.autofit = False
        set_table_fixed_layout(table, total_dxa)
        set_col_widths(table, widths)
        set_table_outer_borders(table)
        set_table_cell_margins(table, left_dxa=int(cell_margin_in * 1440), right_dxa=int(cell_margin_in * 1440))

        # header row
        for c in range(ncols):
            cell = table.rows[0].cells[c]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            add_inline_runs(p, header[c], size=Pt(font_pt), font_name=BODY_FONT)
            for r in p.runs:
                r.bold = True
            set_cell_border(cell, bottom={'sz': 8, 'color': '1A3D28', 'val': 'single'})

        # body rows
        for ridx, row in enumerate(rows):
            for c in range(ncols):
                cell = table.rows[ridx + 1].cells[c]
                cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
                p = cell.paragraphs[0]
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                add_inline_runs(p, row[c], size=Pt(font_pt), font_name=BODY_FONT)

        # tighten row spacing
        for row in table.rows:
            for cell in row.cells:
                for p in cell.paragraphs:
                    p.paragraph_format.space_before = Pt(1)
                    p.paragraph_format.space_after = Pt(1)

        spacer = doc.add_paragraph()
        spacer.paragraph_format.space_after = Pt(10)

        # Landscape orientation is scoped to this table only -- revert to portrait
        # immediately so unrelated prose/headings that follow don't inherit it.
        if needs_landscape and self.orientation == 'landscape':
            new_section(doc, 'portrait')
            self.orientation = 'portrait'


# ==========================================================================
# Entry point
# ==========================================================================


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 build_gtr_docx.py <input.md> <output.docx>")
        sys.exit(1)
    md_path, out_path = sys.argv[1], sys.argv[2]
    builder = GTRBuilder(md_path, out_path)
    builder.build()
    print(f"Wrote {out_path}")


if __name__ == '__main__':
    main()

import sys
from docx import Document
from docx.shared import Inches, Pt, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

def set_cell_border(cell, **kwargs):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcBorders = tcPr.find(qn('w:tcBorders'))
    if tcBorders is None:
        tcBorders = OxmlElement('w:tcBorders')
        tcPr.append(tcBorders)
    for edge in ('top', 'bottom', 'left', 'right'):
        if edge in kwargs:
            tag = 'w:{}'.format(edge)
            el = tcBorders.find(qn(tag))
            if el is None:
                el = OxmlElement(tag)
                tcBorders.append(el)
            for k, v in kwargs[edge].items():
                el.set(qn('w:{}'.format(k)), str(v))

def style_table(table, header_rows=1, full_width_twips=10500):
    # House style: widen text-heavy columns (long model/species labels),
    # narrow numeric columns, rather than forcing all columns equal width --
    # equal-width forcing on wide first-column tables (7+ model rows with
    # long labels like "FVS-ACD v13.1 (ship18, new)") was found by the 13 Aug
    # 2026 visual pass to wrap the first column into 4-5 lines, which pushed
    # a row's height past a page boundary and caused LibreOffice to split
    # the row mid-word across pages (a genuine corrupted-content bug, not
    # cosmetic) -- caught only by rendering and looking, not by XML
    # inspection. Fixed by (a) giving column 0 a wider share when it looks
    # text-heavy (average cell text length > other columns) and (b) forcing
    # cantSplit on every row so a row can no longer straddle a page break.
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    ncols = len(table.columns)
    # 13 Aug 2026 visual-pass fix: wide tables (many numeric columns) wrap mid-number at
    # the default font size against full_width_twips; shrink font for readability.
    wide_table = ncols >= 7
    cell_font_pt = 9 if wide_table else 11

    # Decide whether column 0 needs extra width: compare its mean text
    # length against the mean of the remaining columns.
    def _mean_len(col_idx):
        vals = [len(row.cells[col_idx].text) for row in table.rows]
        return sum(vals) / max(len(vals), 1)

    col0_len = _mean_len(0)
    other_len = sum(_mean_len(c) for c in range(1, ncols)) / max(ncols - 1, 1) if ncols > 1 else col0_len

    if ncols > 1 and col0_len > other_len * 1.3:
        # widen column 0, narrow the rest, keep total == full_width_twips
        col0_w = min(int(full_width_twips * 0.30), int(full_width_twips * 0.10 * ncols))
        col0_w = max(col0_w, int(full_width_twips / ncols))  # never shrink below equal-share
        rest_w = int((full_width_twips - col0_w) / (ncols - 1))
        colwidths = [col0_w] + [rest_w] * (ncols - 1)
    else:
        colw = int(full_width_twips / ncols)
        colwidths = [colw] * ncols

    tbl = table._tbl
    tblGrid = tbl.find(qn('w:tblGrid'))
    if tblGrid is not None:
        for gc, w in zip(tblGrid.findall(qn('w:gridCol')), colwidths):
            gc.set(qn('w:w'), str(w))
    for row in table.rows:
        for cell, w in zip(row.cells, colwidths):
            cell.width = Inches(w/1440.0)
            for p in cell.paragraphs:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for run in p.runs:
                    run.font.size = Pt(cell_font_pt)
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        # cantSplit: never let a single row's content straddle a page break
        trPr = row._tr.get_or_add_trPr()
        cant_split = trPr.find(qn('w:cantSplit'))
        if cant_split is None:
            cant_split = OxmlElement('w:cantSplit')
            trPr.append(cant_split)
    # repeat header row on each page the table spans
    header_trPr = table.rows[0]._tr.get_or_add_trPr()
    if header_trPr.find(qn('w:tblHeader')) is None:
        th = OxmlElement('w:tblHeader')
        header_trPr.append(th)
    # bold + center header row
    for cell in table.rows[0].cells:
        for p in cell.paragraphs:
            for run in p.runs:
                run.bold = True
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    # minimal ruling: top+bottom of header, bottom of last row, no verticals, no interior
    nrows = len(table.rows)
    border_spec = {"sz": 8, "val": "single", "color": "000000"}
    none_spec = {"sz": 0, "val": "nil", "color": "auto"}
    for ri, row in enumerate(table.rows):
        for cell in row.cells:
            edges = {"left": none_spec, "right": none_spec}
            if ri == 0:
                edges["top"] = border_spec
                edges["bottom"] = border_spec
            elif ri == nrows - 1:
                edges["top"] = none_spec
                edges["bottom"] = border_spec
            else:
                edges["top"] = none_spec
                edges["bottom"] = none_spec
            set_cell_border(cell, **edges)

def add_header_footer(doc, header_text, footer_text_left="University of Maine  |  Center for Research on Sustainable Forests"):
    section = doc.sections[0]
    section.header.is_linked_to_previous = False
    hp = section.header.paragraphs[0]
    hp.text = ""
    run = hp.add_run(header_text)
    run.italic = True
    run.font.size = Pt(9)
    hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    section.footer.is_linked_to_previous = False
    fp = section.footer.paragraphs[0]
    fp.text = ""
    run = fp.add_run(footer_text_left)
    run.font.size = Pt(9)
    fp.alignment = WD_ALIGN_PARAGRAPH.CENTER

def main(path, header_text):
    doc = Document(path)
    for sec in doc.sections:
        sec.left_margin = Inches(0.6); sec.right_margin = Inches(0.6)
        sec.top_margin = Inches(0.75); sec.bottom_margin = Inches(0.75)
    add_header_footer(doc, header_text)
    for t in doc.tables:
        style_table(t)
    doc.save(path)
    print("styled", path, "tables:", len(doc.tables))

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])

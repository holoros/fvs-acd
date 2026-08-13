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

def style_table(table, header_rows=1, full_width_twips=9350):
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    ncols = len(table.columns)
    colw = int(full_width_twips / ncols)
    tbl = table._tbl
    tblGrid = tbl.find(qn('w:tblGrid'))
    if tblGrid is not None:
        for gc in tblGrid.findall(qn('w:gridCol')):
            gc.set(qn('w:w'), str(colw))
    for row in table.rows:
        for cell in row.cells:
            cell.width = Inches(colw/1440.0)
            for p in cell.paragraphs:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
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
    add_header_footer(doc, header_text)
    for t in doc.tables:
        style_table(t)
    doc.save(path)
    print("styled", path, "tables:", len(doc.tables))

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])

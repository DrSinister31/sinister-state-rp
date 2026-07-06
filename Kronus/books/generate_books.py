"""Generate Solis-Grave reference books as standalone HTML files — open in browser, Print → Save as PDF."""
import os, re, json, base64
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
PROMPTS = BASE / "prompts" / "solis_grave"
BOOKS = Path(__file__).resolve().parent

# Parchment-like CSS embedded directly
STYLE = """
body{font-family:Georgia,Times,serif;font-size:11pt;line-height:1.6;color:#2C1810;max-width:8.5in;margin:0 auto;padding:0.5in;background:#F5F0E8}
h1{font-size:24pt;color:#8B0000;text-align:center;text-transform:uppercase;letter-spacing:3px;border-bottom:3px double #8B0000;padding-bottom:12pt;margin-bottom:8pt}
h2{font-size:16pt;color:#8B0000;border-bottom:1px solid #8B0000;padding-bottom:4pt;margin-top:24pt}
h3{font-size:12pt;color:#8B0000;font-variant:small-caps;margin-top:16pt}
h4{font-size:10pt;color:#5C3A1E;font-style:italic;margin-top:8pt}
p{text-align:justify;margin:6pt 0}
strong{color:#5C3A1E}em{color:#8B0000}
.stat-block{background:#F5F0E8;border:2px solid #8B0000;padding:10pt 12pt;margin:12pt 0;font-size:9pt}
.stat-block h3{color:#8B0000;margin-top:0;border-bottom:1px solid #8B0000;padding-bottom:4pt}
table{width:100%;border-collapse:collapse;margin:8pt 0;font-size:9pt}
th{background:#8B0000;color:#F5F0E8;padding:4pt 6pt;text-align:left;font-variant:small-caps}
td{padding:3pt 6pt;border-bottom:1px solid #D4C5B0}
tr:nth-child(even){background:#EDE5D8}
hr{border:none;border-top:1px solid #D4C5B0;margin:8pt 0}
.card{background:#EDE5D8;border:1px solid #D4C5B0;padding:6pt 8pt;margin:8pt 0}
.card-header{color:#8B0000;font-weight:bold;font-size:10pt}
.card-detail{font-size:9pt;color:#5C3A1E}
.cr-badge{display:inline-block;background:#8B0000;color:#F5F0E8;padding:1pt 6pt;border-radius:3pt;font-weight:bold;font-size:9pt}
code{font-family:Courier New,monospace;background:#EDE5D8;padding:1pt 3pt;font-size:9pt}
pre{background:#EDE5D8;border:1px solid #D4C5B0;padding:6pt;font-size:9pt;white-space:pre-wrap}
.page-break{page-break-before:always}
.toctitle{text-align:center;color:#8B0000;font-size:18pt;margin:20pt 0}
.subtitle{text-align:center;color:#5C3A1E;font-style:italic;font-size:12pt;margin-bottom:20pt}
@media print{body{background:white}}
"""

def md_to_html(text: str, title: str) -> str:
    """Convert markdown to a standalone HTML document with auto-generated TOC."""
    lines = text.split('\n')
    out = [f'<h1>{title}</h1>', '<p class="subtitle">Solis-Grave — Official Reference</p>']
    
    # Collect headings for TOC
    toc = []
    in_list = False; in_table = False; in_code = False; first_h2 = True
    
    for line in lines:
        s = line.rstrip()
        if not s:
            if in_list: out.append('</ul>' if '<ul>' in out[-3:] else '</ol>'); in_list = False
            continue
        
        if s.startswith('```'): in_code = not in_code; out.append('</pre>' if not in_code else '<pre>'); continue
        if in_code: out.append(line); continue
        
        if s.startswith('# '): out.append(f'<h1>{_fmt(s[2:])}</h1>'); continue
        if s.startswith('## '):
            anchor = _fmt(s[3:]).replace(' ','_').replace("'",'').lower()
            toc.append(f'<li><a href="#{anchor}">{_fmt(s[3:])}</a></li>')
            out.append(f'<h2 id="{anchor}">{_fmt(s[3:])}</h2>')
            if first_h2: first_h2 = False
            continue
        if s.startswith('### '):
            anchor = _fmt(s[4:]).replace(' ','_').replace("'",'').lower()
            toc.append(f'<li style="padding-left:20px;"><a href="#{anchor}">{_fmt(s[4:])}</a></li>')
            out.append(f'<h3 id="{anchor}">{_fmt(s[4:])}</h3>')
            continue
        if s.startswith('#### '): out.append(f'<h4>{_fmt(s[5:])}</h4>'); continue
        
        if s == '---': out.append('<hr>'); continue
        
        # Tables
        if '|' in s and s.count('|') >= 2:
            cells = [c.strip() for c in s.split('|') if c.strip()]
            if all(c.replace('-','').replace(':','').strip() == '' for c in cells): continue
            if not in_table: out.append('<table>'); in_table = True
            tag = 'th' if not any(c.startswith('<') for c in out[-3:]) else 'td'
            out.append('<tr>' + ''.join(f'<{tag}>{_fmt(c)}</{tag}>' for c in cells) + '</tr>')
            continue
        elif in_table: out.append('</table>'); in_table = False
        
        # Lists
        if s.startswith('- ') or s.startswith('* '):
            if not in_list: out.append('<ul>'); in_list = True
            out.append(f'<li>{_fmt(s[2:])}</li>'); continue
        elif s[0].isdigit() and '. ' in s[:4]:
            if not in_list: out.append('<ol>'); in_list = True
            out.append(f'<li>{_fmt(s[s.index('. ')+2:])}</li>'); continue
        elif in_list: out.append('</ul>' if '<ul>' in out[-5:] else '</ol>'); in_list = False
        
        out.append(f'<p>{_fmt(s)}</p>')
    
    if in_list: out.append('</ul>')
    if in_table: out.append('</table>')
    if in_code: out.append('</pre>')
    
    body = '\n'.join(out)
    
    # Insert TOC after subtitle
    toc_html = '<div class="toc"><h2 class="toctitle">Table of Contents</h2><ul>' + ''.join(toc[:50]) + '</ul></div>'
    body = body.replace('<p class="subtitle">', f'<p class="subtitle">{toc_html}')
    
    return f'<!DOCTYPE html><html><head><meta charset="utf-8"><title>{title}</title><style>{STYLE}\n.toc{{background:#F5F0E8;border:1px solid #D4C5B0;padding:10pt;margin:10pt 0;font-size:10pt}}.toc ul{{list-style:none;padding:0}}.toc li{{padding:2pt 0;border-bottom:1px dotted #D4C5B0}}.toc a{{color:#8B0000;text-decoration:none}}.toc a:hover{{text-decoration:underline}}\n</style></head><body>{body}<hr><p style="text-align:center;color:#8B7355;font-size:9pt">Solis-Grave: Shadows of the Crown</p></body></html>'

def _fmt(s: str) -> str:
    s = re.sub(r'\*\*\*(.+?)\*\*\*', r'<strong><em>\1</em></strong>', s)
    s = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', s)
    s = re.sub(r'\*(.+?)\*', r'<em>\1</em>', s)
    s = re.sub(r'`([^`]+)`', r'<code>\1</code>', s)
    return s

if __name__ == "__main__":
    print("Solis-Grave Reference Books — HTML Generator\n")
    
    books = [
        ("players_handbook.md", "Solis-Grave Player's Handbook"),
        ("monster_manual.md", "Solis-Grave Monster Manual"),
        ("spell_grimoire.md", "Solis-Grave Spell Grimoire"),
        ("dm_guide.md", "Solis-Grave Dungeon Master's Guide"),
        ("item_catalog.md", "Solis-Grave Item Catalog"),
    ]
    
    for filename, title in books:
        src = PROMPTS / filename
        if not src.exists():
            print(f"  ❌ {filename} not found")
            continue
        
        md = src.read_text(encoding='utf-8')
        html = md_to_html(md, title)
        out_name = title.replace("'", "").replace(" ", "_") + ".html"
        out_path = BOOKS / out_name
        out_path.write_text(html, encoding='utf-8')
        size = out_path.stat().st_size
        print(f"  ✅ {out_name} ({size:,} bytes)")
    
    print(f"\n📂 Books saved to: {BOOKS}")
    print("   Open any .html file → Ctrl+P → Save as PDF")

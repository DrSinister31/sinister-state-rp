"""Generate Solis-Grave reference PDFs from markdown sources with D&D layout."""
import os, subprocess, weasyprint, re, json
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
PROMPTS = BASE / "prompts" / "solis_grave"
SEED = BASE / "seed"
BOOKS = Path(__file__).resolve().parent
CSS = str(BOOKS / "style.css")

def md_to_html(md_text: str) -> str:
    """Convert markdown to styled HTML with stat block formatting."""
    # Wrap in HTML with CSS link
    html = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8">
<link rel="stylesheet" href="{CSS}">
</head><body>
{_format_markdown(md_text)}
</body></html>"""
    return html

def _format_markdown(text: str) -> str:
    """Basic markdown → HTML with stat block support."""
    lines = text.split('\n')
    out = []
    in_list = False
    in_table = False
    in_code = False
    
    for line in lines:
        stripped = line.strip()
        
        # Code blocks
        if stripped.startswith('```'):
            in_code = not in_code
            out.append('</pre>' if not in_code else '<pre>')
            continue
        if in_code:
            out.append(line)
            continue
            
        # Headers
        if stripped.startswith('#### '):
            out.append(f'<h4>{_inline(stripped[5:])}</h4>')
            continue
        if stripped.startswith('### '):
            out.append(f'<h3>{_inline(stripped[4:])}</h3>')
            continue
        if stripped.startswith('## '):
            out.append(f'<h2>{_inline(stripped[3:])}</h2>')
            continue
        if stripped.startswith('# '):
            out.append(f'<h1>{_inline(stripped[2:])}</h1>')
            continue
            
        # Horizontal rule
        if stripped == '---':
            out.append('<hr>')
            continue
            
        # Tables
        if '|' in stripped and stripped.count('|') >= 2:
            if not in_table:
                out.append('<table>')
                in_table = True
            cells = [c.strip() for c in stripped.split('|') if c.strip()]
            if all(c.replace('-','').replace(':','').strip() == '' for c in cells):
                continue  # skip separator row
            tag = 'th' if in_table and out[-1].startswith('<table>') else 'td'
            row = ''.join(f'<{tag}>{_inline(c)}</{tag}>' for c in cells)
            out.append(f'<tr>{row}</tr>')
            continue
        elif in_table:
            out.append('</table>')
            in_table = False
            
        # Lists
        if stripped.startswith('- ') or stripped.startswith('* '):
            if not in_list:
                out.append('<ul>')
                in_list = True
            out.append(f'<li>{_inline(stripped[2:])}</li>')
            continue
        elif stripped and stripped[0].isdigit() and '. ' in stripped[:4]:
            if not in_list:
                out.append('<ol>')
                in_list = True
            out.append(f'<li>{_inline(stripped[stripped.index(". ")+2:])}</li>')
            continue
        elif in_list:
            out.append('</ul>' if out[-1].startswith('<li>') and '<ol>' not in out[-5:] else '</ol>')
            in_list = False
            
        # Empty line
        if not stripped:
            if in_list:
                out.append('</ul>' if '<ul>' in out[-10:] else '</ol>')
                in_list = False
            continue
            
        # Regular paragraph
        out.append(f'<p>{_inline(stripped)}</p>')
    
    if in_list: out.append('</ul>')
    if in_table: out.append('</table>')
    if in_code: out.append('</pre>')
    
    return '\n'.join(out)

def _inline(text: str) -> str:
    """Inline formatting: bold, italic, code."""
    text = re.sub(r'\*\*\*(.+?)\*\*\*', r'<strong><em>\1</em></strong>', text)
    text = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', text)
    text = re.sub(r'\*(.+?)\*', r'<em>\1</em>', text)
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    return text

def generate_book(source_path: str, output_name: str, title: str):
    """Generate a single PDF book from markdown source."""
    print(f"  📖 {output_name}...")
    
    src = BASE / source_path
    if not src.exists():
        print(f"    ❌ Source not found: {src}")
        return False
    
    md = src.read_text(encoding='utf-8')
    
    # Add title page
    md = f"# {title}\n\n*Solis-Grave: Shadows of the Crown — Official Reference*\n\n---\n\n" + md
    
    html = md_to_html(md)
    html_path = BOOKS / f"{output_name}.html"
    html_path.write_text(html, encoding='utf-8')
    
    pdf_path = BOOKS / f"{output_name}.pdf"
    try:
        weasyprint.HTML(string=html).write_pdf(str(pdf_path))
        size = pdf_path.stat().st_size
        print(f"    ✅ {size:,} bytes")
        return True
    except Exception as e:
        print(f"    ❌ {e}")
        return False

if __name__ == "__main__":
    print("Solis-Grave Reference Book Generator")
    print("=" * 50)
    
    books = [
        ("prompts/solis_grave/players_handbook.md", "Solis-Grave_Players_Handbook", "Solis-Grave Player's Handbook"),
        ("prompts/solis_grave/monster_manual.md", "Solis-Grave_Monster_Manual", "Solis-Grave Monster Manual"),
        ("prompts/solis_grave/spell_grimoire.md", "Solis-Grave_Spell_Grimoire", "Solis-Grave Spell Grimoire"),
        ("prompts/solis_grave/dm_guide.md", "Solis-Grave_DM_Guide", "Solis-Grave Dungeon Master's Guide"),
        ("prompts/solis_grave/item_catalog.md", "Solis-Grave_Item_Catalog", "Solis-Grave Item Catalog"),
    ]
    
    ok = 0
    for src, name, title in books:
        if generate_book(src, name, title):
            ok += 1
    
    print(f"\n✅ {ok}/{len(books)} PDFs generated in {BOOKS}")

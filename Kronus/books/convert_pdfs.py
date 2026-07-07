"""Convert Solis-Grave HTML books to PDFs using xhtml2pdf."""
import os
from xhtml2pdf import pisa

BOOKS = os.path.dirname(os.path.abspath(__file__))
html_files = [f for f in os.listdir(BOOKS) if f.endswith('.html')]

print(f"Converting {len(html_files)} HTML files to PDF...\n")

for f in sorted(html_files):
    html_path = os.path.join(BOOKS, f)
    pdf_path = os.path.join(BOOKS, f.replace('.html', '.pdf'))

    with open(html_path, 'rb') as src:
        html = src.read().decode('utf-8')

    # Fix CSS for xhtml2pdf compatibility
    html = html.replace('columns: 2;', '')  # xhtml2pdf doesn't support columns well
    html = html.replace('column-span: all;', '')  # Remove unsupported CSS

    with open(pdf_path, 'wb') as dst:
        pisa.CreatePDF(html.encode('utf-8'), dst, encoding='utf-8')

    size_kb = os.path.getsize(pdf_path) / 1024
    print(f"  ✅ {f.replace('.html','.pdf')} ({size_kb:.0f} KB)")

print(f"\nDone! PDFs saved to {BOOKS}")

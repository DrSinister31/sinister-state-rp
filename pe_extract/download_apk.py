import urllib.request
import re
import os

url = "https://apps.evozi.com/apk-downloader/?id=com.miracle.android.pe"
out = r"C:\Users\Dilla\OneDrive\Desktop\Sinister_Project_Master\pe_extract\PocketEmpires.apk"

req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
try:
    resp = urllib.request.urlopen(req, timeout=15)
    html = resp.read().decode("utf-8", errors="ignore")
    print(f"Page loaded: {len(html)} bytes")
    
    # Search for download link
    pattern = r'https?://[^\s<>\"\']+\.apk[^\s<>\"\']*'
    links = re.findall(pattern, html)
    
    if links:
        for link in links[:5]:
            print(f"Found APK link: {link}")
        # Try to download from the first link
        dl_url = links[0]
        req2 = urllib.request.Request(dl_url, headers={"User-Agent": "Mozilla/5.0"})
        apk_data = urllib.request.urlopen(req2, timeout=30).read()
        with open(out, "wb") as f:
            f.write(apk_data)
        print(f"Downloaded APK: {len(apk_data)} bytes to {out}")
    else:
        # Check if app exists
        if "not found" in html.lower() or "unavailable" in html.lower() or "error" in html.lower():
            print("App appears to be unavailable/removed from Google Play")
        else:
            print("No APK links found. Page may require JavaScript.")
            # Print first 500 chars for debugging
            print("Page preview:", html[:500])
except Exception as e:
    print(f"Error: {e}")

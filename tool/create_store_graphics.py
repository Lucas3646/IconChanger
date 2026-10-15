"""Render Play Store graphics from the existing Android vector launcher icon."""
from pathlib import Path
import cairosvg

out = Path(__file__).resolve().parents[1] / 'build/play-store'
out.mkdir(parents=True, exist_ok=True)
star = '<path fill="white" d="M54,29 C57,45 63,51 79,54 C63,57 57,63 54,79 C51,63 45,57 29,54 C45,51 51,45 54,29 Z"/><path fill="white" opacity=".8" d="M74,29 L76,35 L82,37 L76,39 L74,45 L72,39 L66,37 L72,35 Z"/>'
icon = '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 108 108"><rect width="108" height="108" fill="#007AFF"/>' + star + '</svg>'
(out / 'app-icon.svg').write_text(icon)
cairosvg.svg2png(bytestring=icon.encode(), write_to=str(out / 'app-icon-512.png'))
feature = '''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="500" viewBox="0 0 1024 500"><defs><linearGradient id="bg"><stop stop-color="#0b1221"/><stop offset="1" stop-color="#173f75"/></linearGradient></defs><rect width="1024" height="500" fill="url(#bg)"/><circle cx="920" cy="30" r="280" fill="#2687ff" opacity=".13"/><g transform="translate(706 116) scale(2.2)"><rect width="108" height="108" rx="24" fill="#007aff"/>''' + star + '''</g><g font-family="DejaVu Sans, sans-serif" fill="white"><text x="64" y="195" font-size="64" font-weight="700">Icon Studio</text><text x="67" y="257" font-size="27">Créez des icônes à votre image.</text><text x="67" y="317" font-size="21" fill="#c6d7ef">Calques, couleurs et effets lumineux.</text><text x="67" y="352" font-size="21" fill="#c6d7ef">Créations locales · Export PNG</text></g></svg>'''
(out / 'feature-graphic.svg').write_text(feature)
cairosvg.svg2png(bytestring=feature.encode(), write_to=str(out / 'feature-graphic-1024x500.png'))
print('Play Store graphics rendered.')

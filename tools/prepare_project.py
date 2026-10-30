from pathlib import Path
import zipfile, shutil
root=Path(__file__).resolve().parents[1]
game=root/"game"
game.mkdir(exist_ok=True)
with zipfile.ZipFile(root/"MeongRandy_Step23.zip") as z:
    for member in z.infolist():
        parts=Path(member.filename).parts[1:]
        if not parts or member.is_dir(): continue
        if any(p in ("..", ".git", ".godot") for p in parts): continue
        rel=Path(*parts)
        target=game/rel
        if target.exists(): continue
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(z.read(member))
print("Prepared original assets and legacy regression tests without replacing edited files.")

# Bundle the Korean UI font and its license in the source/APK; no runtime download.
import urllib.request
font=game/"assets/kr.ttf"
font.parent.mkdir(parents=True,exist_ok=True)
if not font.exists():
    urllib.request.urlretrieve("https://raw.githubusercontent.com/google/fonts/main/ofl/notosanskr/NotoSansKR%5Bwght%5D.ttf",font)
license_path=game/"assets/FONT-OFL.txt"
if not license_path.exists():
    urllib.request.urlretrieve("https://raw.githubusercontent.com/google/fonts/main/ofl/notosanskr/OFL.txt",license_path)

# Generate original offline music and effects for source and APK.
import subprocess, sys
subprocess.run([sys.executable, str(Path(__file__).resolve().parent / "generate_audio.py")], check=True)

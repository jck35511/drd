from pathlib import Path
import io,base64
from PIL import Image
for path in sorted(Path("build/android-smoke").glob("*.png")):
    if path.stem.startswith(("01","02","04")): continue
    im=Image.open(path)
    im.thumbnail((360,640))
    data=io.BytesIO()
    im.save(data,format="PNG")
    print("ANDROID_PREVIEW_"+path.stem+":"+base64.b64encode(data.getvalue()).decode())

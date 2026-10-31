"""Read-only contact sheets for inspecting atlas regions; source PNGs are unchanged."""
from pathlib import Path
from PIL import Image, ImageDraw
import base64, io
for index in range(8):
    im=Image.open(f"game/assets/sky_atlas_{index}.png").convert("RGBA")
    print(f"ATLAS_SIZE:{index}:{im.size}")
    bg=Image.new("RGBA",im.size,(48,60,83,255))
    bg.alpha_composite(im)
    bg.thumbnail((1024,768))
    d=ImageDraw.Draw(bg)
    for c in range(1,4): d.line((c*bg.width/4,0,c*bg.width/4,bg.height),fill="red",width=2)
    d.line((0,bg.height/2,bg.width,bg.height/2),fill="red",width=2)
    for n in range(8): d.text((n%4*bg.width/4+5,n//4*bg.height/2+5),str(index*8+n),fill="yellow",stroke_width=1,stroke_fill="black")
    out=io.BytesIO();bg.convert("RGB").save(out,format="PNG")
    print(f"ATLAS_PREVIEW_{index}:"+base64.b64encode(out.getvalue()).decode())

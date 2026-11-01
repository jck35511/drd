"""Measure PNG transparency gutters for atlas UVs without altering source artwork."""
from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib
out={}
for name,cols,rows in [("legendary_attack",4,7),("legendary_vfx",3,3)]:
    im=Image.open("game/assets/"+name+".png").convert("RGBA")
    alpha=np.asarray(im)[:,:,3]
    assert np.count_nonzero(alpha==0)>alpha.size*0.05, "Real transparency required"
    def cuts(length,count,projection):
        result=[0]
        for i in range(1,count):
            nominal=length*i/count
            lo=round(nominal-length/count*0.16);hi=round(nominal+length/count*0.16)
            # Prefer transparent gutters; ties stay close to the intended grid.
            cut=min(range(lo,hi+1),key=lambda p:(int(projection[p]),abs(p-nominal)))
            result.append(cut)
        return result+[length]
    xs=cuts(im.width,cols,(alpha>32).sum(axis=0))
    ys=cuts(im.height,rows,(alpha>32).sum(axis=1))
    regions=[]
    for row in range(rows):
        for col in range(cols):
            x0,x1=xs[col],xs[col+1];y0,y1=ys[row],ys[row+1]
            tile=alpha[y0:y1,x0:x1]
            assert np.count_nonzero(tile>32)>tile.size*0.12
            regions.append([x0,y0,x1-x0,y1-y0])
    out[name]={"width":im.width,"height":im.height,"regions":regions}
    print("LEGENDARY_ASSET:"+json.dumps({"name":name,"size":im.size,"x_cuts":xs,"y_cuts":ys,"frames":len(regions)}))
assert len(out["legendary_attack"]["regions"])==28
Path("game/assets/legendary_regions.json").write_text(json.dumps(out),encoding="utf-8")

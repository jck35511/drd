"""Compute per-character atlas rectangles; never modify source illustrations."""
from pathlib import Path
from PIL import Image
import numpy as np
from scipy import ndimage
import json
regions=[]
for sheet in range(8):
    im=Image.open(f"game/assets/sky_atlas_{sheet}.png").convert("RGBA")
    alpha=np.asarray(im)[:,:,3]
    mask=alpha>20
    # Some adjacent weapons touch by one pixel. Split only merged silhouettes.
    for attempt in range(3):
        labels,count=ndimage.label(mask)
        for box in ndimage.find_objects(labels):
            if box is None: continue
            yy,xx=box
            if xx.stop-xx.start>im.width/4*1.5:
                for nominal in [round(im.width*k/4) for k in range(1,4)]:
                    if xx.start+100<nominal<xx.stop-100:
                        candidates=range(max(xx.start,nominal-35),min(xx.stop,nominal+36))
                        cut=min(candidates,key=lambda x:(int(mask[yy,x].sum()),abs(x-nominal)))
                        mask[yy,cut]=False
            if yy.stop-yy.start>im.height/2*1.5:
                nominal=im.height//2
                candidates=range(nominal-35,nominal+36)
                cut=min(candidates,key=lambda y:(int(mask[y,xx].sum()),abs(y-nominal)))
                mask[cut,xx]=False
    labels,count=ndimage.label(mask)
    objects=ndimage.find_objects(labels)
    sizes=np.bincount(labels.ravel())
    groups=[[] for _ in range(8)]
    centers=[]
    for n,box in enumerate(objects,1):
        if box is None or sizes[n]<12: continue
        yy,xx=box
        cx=(xx.start+xx.stop)/2;cy=(yy.start+yy.stop)/2
        col=min(3,int(cx/(im.width/4)));row=min(1,int(cy/(im.height/2)))
        groups[row*4+col].append((int(sizes[n]),n,box))
    for slot,parts in enumerate(groups):
        assert parts,(sheet,slot)
        parts.sort(reverse=True)
        primary=parts[0]
        # The silhouette plus its separate ornaments belong to this character.
        y0=min(p[2][0].start for p in parts);y1=max(p[2][0].stop for p in parts)
        x0=min(p[2][1].start for p in parts);x1=max(p[2][1].stop for p in parts)
        ids=[p[1] for p in parts]
        window=labels[y0:y1,x0:x1]
        foreign=int(np.count_nonzero((window>0)&~np.isin(window,ids)&(sizes[window]>=12)))
        entry={"id":sheet*8+slot,"sheet":sheet,"rect":[x0,y0,x1-x0,y1-y0],"parts":len(parts),"foreign_pixels":foreign,"primary_rect":[primary[2][1].start,primary[2][0].start,primary[2][1].stop-primary[2][1].start,primary[2][0].stop-primary[2][0].start]}
        regions.append(entry)
        print("SPRITE_REGION:"+json.dumps(entry))
Path("game/assets/unit_regions.json").write_text(json.dumps(regions),encoding="utf-8")

from pathlib import Path
import wave,array,math,hashlib,json
report={}
for key in ["normal","boss"]:
    path=Path("game/previews/mixer-"+key+".wav")
    with wave.open(str(path),"rb") as f:
        assert f.getsampwidth()==2
        raw=f.readframes(f.getnframes()); samples=array.array("h",raw)
        rms=math.sqrt(sum(float(x)*x for x in samples)/len(samples))/32768
        report[key]={"seconds":f.getnframes()/f.getframerate(),"rms":rms,"sha256":hashlib.sha256(raw).hexdigest()}
        assert rms>0.003,"Runtime music capture is silent: "+key
assert report["normal"]["sha256"]!=report["boss"]["sha256"]
Path("game/previews/music-playback-report.json").write_text(json.dumps(report,indent=2))
print("AUDIBLE_MUSIC_CAPTURE:"+json.dumps(report))

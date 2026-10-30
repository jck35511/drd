from pathlib import Path
import subprocess, json, sys, time
root=Path(__file__).resolve().parents[1]
report=root/"work/reports";report.mkdir(parents=True,exist_ok=True)
results=[]
for test in sorted((root/"game/tests").glob("check_*.gd")):
    started=time.monotonic()
    proc=subprocess.run(["godot","--headless","--path",str(root/"game"),"--script","res://tests/"+test.name],capture_output=True,text=True,timeout=90)
    log=proc.stdout+proc.stderr
    (report/(test.stem+".log")).write_text(log)
    errors=("SCRIPT ERROR:" in log or "Parse Error:" in log or "ERROR:" in log)
    ok=proc.returncode==0 and not errors
    results.append({"test":test.name,"passed":ok,"exit_code":proc.returncode,"seconds":round(time.monotonic()-started,3)})
    print(("PASS " if ok else "FAIL ")+test.name,flush=True)
    if not ok: print(log[-12000:],flush=True)
(report/"regression.json").write_text(json.dumps(results,indent=2))
sys.exit(0 if all(r["passed"] for r in results) else 1)

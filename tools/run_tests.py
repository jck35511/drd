from pathlib import Path
import subprocess, json, sys, time, selectors
root=Path(__file__).resolve().parents[1]
report=root/"work/reports";report.mkdir(parents=True,exist_ok=True)
results=[]
for test in sorted((root/"game/tests").glob("check_*.gd")):
    started=time.monotonic()
    proc=subprocess.Popen(["godot","--headless","--path",str(root/"game"),"--script","res://tests/"+test.name],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    selector=selectors.DefaultSelector();selector.register(proc.stdout,selectors.EVENT_READ)
    chunks=[];aborted=False
    while True:
        ready=selector.select(timeout=.2)
        if ready:
            chunk=proc.stdout.read1(65536)
            if chunk: chunks.append(chunk)
            elif proc.poll() is not None: break
        text=b"".join(chunks).decode("utf-8","replace")
        # Godot debug assertions stop the script without exiting the engine.
        # Record the failure immediately instead of waiting for a hung SceneTree.
        if any(s in text for s in ["SCRIPT ERROR:","Parse Error:","ERROR:"]) or time.monotonic()-started>90:
            aborted=True
            if time.monotonic()-started>90: chunks.append(b"\nTIMEOUT\n")
            proc.terminate()
            try: tail=proc.communicate(timeout=3)[0]
            except subprocess.TimeoutExpired:
                proc.kill();tail=proc.communicate()[0]
            chunks.append(tail or b"")
            break
        if proc.poll() is not None and not ready:
            chunks.append(proc.stdout.read())
            break
    selector.close()
    proc.wait()
    log=b"".join(chunks).decode("utf-8","replace")
    (report/(test.stem+".log")).write_text(log)
    ok=proc.returncode==0 and not aborted and not any(s in log for s in ["SCRIPT ERROR:","Parse Error:","ERROR:"])
    results.append({"test":test.name,"passed":ok,"exit_code":proc.returncode,"seconds":round(time.monotonic()-started,3)})
    print(("PASS " if ok else "FAIL ")+test.name,flush=True)
    if not ok: print(log[-12000:],flush=True)
(report/"regression.json").write_text(json.dumps(results,indent=2))
sys.exit(0 if all(r["passed"] for r in results) else 1)

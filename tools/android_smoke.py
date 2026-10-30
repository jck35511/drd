"""Smoke test the exported APK, without modifying game rules or the APK."""
from pathlib import Path
import subprocess, time, json, base64, io
from PIL import Image
OUT = Path("build/android-smoke")
OUT.mkdir(parents=True, exist_ok=True)
PKG = "com.jck35511.meongrandy"
def adb(*args):
    return subprocess.check_output(["adb", *args], stderr=subprocess.STDOUT)
def capture(name):
    (OUT / (name + ".png")).write_bytes(adb("exec-out", "screencap", "-p"))
def tap(x, y):
    adb("shell", "input", "tap", str(x), str(y))
adb("shell", "wm", "size", "720x1280")
adb("shell", "wm", "density", "240")
adb("install", "-r", "build/MeongRandy-Step29-debug.apk")
adb("logcat", "-c")
adb("shell", "settings", "put", "secure", "immersive_mode_confirmations", "confirmed")
adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
time.sleep(12)
assert adb("shell", "pidof", PKG).strip(), "App failed to launch"
# Dismiss Android's own first-use fullscreen tutorial if present.
adb("shell","uiautomator","dump","/sdcard/window.xml")
hierarchy = adb("shell","cat","/sdcard/window.xml").decode("utf-8","replace")
if "Got it" in hierarchy or "Viewing full screen" in hierarchy:
    tap(630,285)
    time.sleep(2)
capture("01-difficulty")
# Coordinates follow the actual 720x1280 Godot layout.
tap(360, 500)
time.sleep(2)
capture("02-selected")
for _ in range(4):
    tap(125, 1040)
    time.sleep(0.2)
tap(360, 1040)
time.sleep(15)
capture("03-gameplay")
adb("shell", "input", "keyevent", "KEYCODE_HOME")
time.sleep(2)
adb("shell", "monkey", "-p", PKG, "1")
time.sleep(3)
capture("04-resumed")
save_path = adb("shell","run-as",PKG,"find","files","-name","sky_castle_save.json").decode().strip().splitlines()
assert save_path, "Background save was not created"
state = json.loads(adb("shell","run-as",PKG,"cat",save_path[0]))
assert state["wave"] >= 1 and len(state["dogs"]) >= 1, "Touch did not start a playable run"
(OUT / "saved-run.json").write_text(json.dumps(state,ensure_ascii=False,indent=2))
adb("shell","wm","size","720x1600")
time.sleep(3)
capture("05-tall-screen")
for name in ["03-gameplay","04-resumed","05-tall-screen"]:
    im = Image.open(OUT / (name + ".png"))
    im.thumbnail((360,640))
    buf = io.BytesIO()
    im.save(buf,format="PNG")
    print("ANDROID_PREVIEW_" + name + ":" + base64.b64encode(buf.getvalue()).decode())
logs = adb("logcat", "-d").decode("utf-8", "replace")
(OUT / "logcat.txt").write_text(logs)
log_lines = logs.splitlines()
for i, line in enumerate(log_lines):
    if "godot" in line.lower() and any(word in line for word in ["ERROR", "Error", "OpenGL", "Renderer", "Vulkan"]):
        print("ENGINE_DIAGNOSTIC:" + "\\n".join(log_lines[max(0,i-1):i+5]))
(OUT / "memory.txt").write_bytes(adb("shell", "dumpsys", "meminfo", PKG))
(OUT / "frames.txt").write_bytes(adb("shell", "dumpsys", "gfxinfo", PKG))
assert adb("shell", "pidof", PKG).strip(), "App exited during interaction"
failures = [line for line in logs.splitlines() if "FATAL EXCEPTION" in line or "SCRIPT ERROR:" in line or "Parse Error:" in line or ("godot" in line.lower() and "ERROR:" in line)]
for name in ["03-gameplay","04-resumed","05-tall-screen"]:
    pixels = Image.open(OUT / (name + ".png")).convert("RGB").resize((72,128))
    if len(set(pixels.getdata())) < 100:
        failures.append("Blank or nearly blank rendered image: " + name)
(OUT / "summary.json").write_text(json.dumps({"installed":True,"process_alive":True,"runtime_errors":failures,"physical_device_tested":False},ensure_ascii=False,indent=2))
assert not failures, "\n".join(failures)
print("ANDROID_SMOKE_PASS")

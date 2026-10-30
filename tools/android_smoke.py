"""Smoke test the exported APK, without modifying game rules or the APK."""
from pathlib import Path
import subprocess, time, json, base64
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
adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
time.sleep(12)
assert adb("shell", "pidof", PKG).strip(), "App failed to launch"
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
logs = adb("logcat", "-d").decode("utf-8", "replace")
(OUT / "logcat.txt").write_text(logs)
(OUT / "memory.txt").write_bytes(adb("shell", "dumpsys", "meminfo", PKG))
(OUT / "frames.txt").write_bytes(adb("shell", "dumpsys", "gfxinfo", PKG))
assert adb("shell", "pidof", PKG).strip(), "App exited during interaction"
failures = [line for line in logs.splitlines() if "FATAL EXCEPTION" in line or "SCRIPT ERROR:" in line or "Parse Error:" in line]
(OUT / "summary.json").write_text(json.dumps({"installed":True,"process_alive":True,"runtime_errors":failures,"physical_device_tested":False},ensure_ascii=False,indent=2))
assert not failures, "\n".join(failures)
print("ANDROID_SMOKE_PASS")

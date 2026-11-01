"""Smoke test the exported APK, without modifying game rules or the APK."""
from pathlib import Path
import subprocess, time, json, base64, io, shlex
from PIL import Image, ImageChops
OUT = Path("build/android-smoke")
OUT.mkdir(parents=True, exist_ok=True)
PKG = "com.jck35511.meongrandy"
def adb(*args):
    return subprocess.check_output(["adb", *args], stderr=subprocess.STDOUT)
def capture(name):
    (OUT / (name + ".png")).write_bytes(adb("exec-out", "screencap", "-p"))
layout = json.loads(Path("work/verification/game/previews/audio-layout.json").read_text())
print("CONTROL_LAYOUT:" + json.dumps(layout))
def tap_control(name):
    rect = layout[name]
    tap(round(rect["x"]+rect["width"]/2), round(rect["y"]+rect["height"]/2))
def tap(x, y):
    adb("shell", "input", "tap", str(x), str(y))
adb("shell", "wm", "size", "720x1280")
adb("shell", "wm", "density", "240")
# Keep unrelated stock messaging ANRs out of screenshots on the disposable emulator.
packages = adb("shell","pm","list","packages").decode()
for stock_app in ["com.google.android.apps.messaging","com.android.messaging","com.android.mms"]:
    if ("package:" + stock_app + "\n") in packages:
        adb("shell","pm","disable-user","--user","0",stock_app)
adb("install", "-r", "build/MeongRandy-0.29.4-debug.apk")
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
tap_control("normal_difficulty")
time.sleep(2)
capture("02-selected")
for _ in range(4):
    tap_control("summon")
    time.sleep(0.2)
tap_control("start_wave")
time.sleep(15)
capture("03-gameplay")
tap(615,40) # Pause while inspecting menus.
tap(520,1110)
time.sleep(1)
capture("06-recipes-before")
adb("shell","input","swipe","320","840","320","400","350")
time.sleep(1)
capture("07-recipes-after")
tap_control("recipe_close")
tap(350,1228)
time.sleep(0.5)
tap_control("draw_probability_tab") # Use actual Godot layout, not guessed coordinates.
time.sleep(0.5)
capture("08-draw-before")
adb("shell","input","swipe","330","840","330","400","350")
time.sleep(1)
capture("09-draw-after")
for first, second in [("06-recipes-before","07-recipes-after"),("08-draw-before","09-draw-after")]:
    a = Image.open(OUT / (first + ".png")).convert("RGB").crop((50,350,650,900))
    b = Image.open(OUT / (second + ".png")).convert("RGB").crop((50,350,650,900))
    assert ImageChops.difference(a,b).getbbox(), "Touch swipe did not move " + first
tap_control("draw_close")
tap(675,40)
time.sleep(0.5)
capture("10-audio-settings")
layout = json.loads(Path("work/verification/game/previews/audio-layout.json").read_text())
for channel, value in [("music",0.0),("sfx",0.6)]:
    rect = layout[channel]
    tap(round(rect["x"]+(1 if value == 0.0 else rect["width"]*value)),round(rect["y"]+rect["height"]/2))
    time.sleep(0.3)
capture("11-audio-adjusted")
adb("shell","input","keyevent","KEYCODE_BACK")
time.sleep(0.5)
audio_path = adb("shell","run-as",PKG,"find","files","-name","audio_settings.cfg").decode().strip().splitlines()
assert audio_path, "Volume settings were not saved"
audio_text = adb("shell","run-as",PKG,"cat",audio_path[0]).decode()
(OUT/"audio-settings.cfg").write_text(audio_text)
print("SAVED_AUDIO:" + audio_text.replace("\n","; "))
import re
music_level = float(re.search(r"music=([0-9.]+)",audio_text).group(1))
sfx_level = float(re.search(r"sfx=([0-9.]+)",audio_text).group(1))
assert music_level == 0 and 0.45 < sfx_level < 0.75, f"Volume persistence: music={music_level}, sfx={sfx_level}"
# Restore audible BGM before checking music transitions; mute persistence alone is insufficient.
tap(675,40)
time.sleep(1.0)
rect=layout["music"]
tap(round(rect["x"]+rect["width"]*0.35),round(rect["y"]+rect["height"]/2))
time.sleep(0.6) # Let the slider commit the touch before Android BACK closes the popup.
capture("11b-music-restored")
adb("shell","input","keyevent","KEYCODE_BACK")
time.sleep(1.5)
def audio_runtime():
    paths=adb("shell","run-as",PKG,"find","files","-name","audio_runtime.json").decode().strip().splitlines()
    assert paths, "Runtime music telemetry missing"
    for attempt in range(4):
        try: return json.loads(adb("shell","run-as",PKG,"cat",paths[0]))
        except json.JSONDecodeError: time.sleep(0.1)
    raise AssertionError("Runtime music telemetry unreadable")
normal_audio=audio_runtime()
# Debug telemetry updates once a second; wait for the committed slider value.
for _ in range(10):
    if normal_audio["volume"]["music"]>0: break
    time.sleep(0.5)
    normal_audio=audio_runtime()
print("ANDROID_NORMAL_AUDIO:"+json.dumps(normal_audio))
(OUT/"normal-audio.json").write_text(json.dumps(normal_audio,indent=2))
assert not normal_audio["boss_mode"] and normal_audio["playing"] and normal_audio["volume"]["music"]>0, json.dumps(normal_audio)
assert normal_audio["track"].endswith("sky_theme.wav")


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

# Restore a test-only boss save into the actual APK; all gameplay code remains production.
adb("shell","am","force-stop",PKG)
fixture=Path("work/verification/game/previews/boss-fixture.json").read_bytes()
subprocess.run(["adb","shell","run-as "+PKG+" sh -c "+shlex.quote("cat > "+shlex.quote(save_path[0]))],input=fixture,check=True)
adb("shell","monkey","-p",PKG,"1")
time.sleep(4)
tap(615,40) # Saved games intentionally restore paused.
tap(165,235) # Select a unit: countdown must remain visible.
time.sleep(3)
capture("12-boss-elite-combat")
boss_audio=audio_runtime()
time.sleep(1.2)
boss_audio_later=audio_runtime()
assert boss_audio["boss_mode"] and boss_audio["playing"] and not boss_audio["paused"], "Boss track is not playing"
assert boss_audio["track"].endswith("boss_theme.wav") and boss_audio["volume"]["music"]>0, "Boss track is absent or muted"
assert boss_audio_later["position"]>boss_audio["position"], "Boss music keeps restarting or is stalled"
(OUT/"music-transition.json").write_text(json.dumps({"normal":normal_audio,"boss":boss_audio,"boss_later":boss_audio_later},indent=2))
print("ANDROID_BOSS_MUSIC_PASS:"+json.dumps(boss_audio_later))

adb("shell","input","keyevent","KEYCODE_HOME")
time.sleep(2)
boss_state=json.loads(adb("shell","run-as",PKG,"cat",save_path[0]))
assert boss_state["boss_running"] and 0 < boss_state["wave_time_left"] < 60, "Boss timer did not progress"
assert boss_state["enemies"][0]["hp"] < 10000000, "Elite units did not attack"
(OUT/"boss-run.json").write_text(json.dumps(boss_state,ensure_ascii=False,indent=2))
adb("shell","monkey","-p",PKG,"1")
time.sleep(2)

adb("shell","wm","size","720x1600")
time.sleep(3)
capture("05-tall-screen")
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

from pathlib import Path
import os,json
root=Path(__file__).resolve().parents[1]
settings=Path.home()/".config/godot/editor_settings-4.tres"
settings.parent.mkdir(parents=True,exist_ok=True)
settings_text = ('[gd_resource type="EditorSettings" format=3]\n\n[resource]\nexport/android/android_sdk_path = '+json.dumps(os.environ["ANDROID_HOME"])+'\nexport/android/java_sdk_path = '+json.dumps(os.environ["JAVA_HOME"])+'\nexport/android/debug_keystore = '+json.dumps(str(root/"work/debug.keystore"))+'\nexport/android/debug_keystore_user = "androiddebugkey"\nexport/android/debug_keystore_pass = "android"\n')

for name in ["editor_settings-4.tres","editor_settings-4.5.tres"]:
    (settings.parent/name).write_text(settings_text)

# Windows launcher for the couch-tv bridge, started at logon by the "couch-tv bridge" scheduled task.
# Runs with no console window (so nothing can close it), and restarts the bridge if it ever exits.
import os
import subprocess
import time

ROOT = os.path.dirname(os.path.abspath(__file__))
PY = os.path.join(ROOT, ".venv", "Scripts", "python.exe")
os.makedirs(os.path.join(ROOT, "logs"), exist_ok=True)

env = dict(os.environ, PYTHONUNBUFFERED="1")
npm = os.path.join(os.environ.get("APPDATA", ""), "npm")
if npm not in env.get("PATH", ""):
    env["PATH"] = env.get("PATH", "") + ";" + npm

while True:
    with open(os.path.join(ROOT, "logs", "bridge.log"), "a", encoding="utf-8") as log:
        log.write(time.strftime("%Y-%m-%d %H:%M:%S") + " launcher: starting bridge\n")
        log.flush()
        proc = subprocess.run([PY, os.path.join("bridge", "server.py")], cwd=ROOT, env=env,
                              stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT,
                              creationflags=subprocess.CREATE_NO_WINDOW)
        log.write(time.strftime("%Y-%m-%d %H:%M:%S") + f" launcher: bridge exited ({proc.returncode}), restarting in 5 s\n")
    time.sleep(5)

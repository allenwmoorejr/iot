from flask import Flask, request, jsonify, send_from_directory
import os, time, json
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)
UPLOAD_DIR = os.environ.get("UPLOAD_DIR", "/data")
os.makedirs(UPLOAD_DIR, exist_ok=True)

events = Counter("camera_upload_events_total", "Count of camera uploads", ["source"])

@app.post("/upload")
def upload():
    f = request.files.get("file")
    if not f:
        return ("no file", 400)
    meta = request.form.get("meta","{}")
    try:
        src = json.loads(meta).get("source","uno-r4")
    except Exception:
        src = "uno-r4"

    ts = int(time.time())
    fname = f"frame_{ts}.jpg"
    path = os.path.join(UPLOAD_DIR, fname)
    f.save(path)

    latest = os.path.join(UPLOAD_DIR, "latest.jpg")
    try:
        if os.path.exists(latest):
            os.remove(latest)
    except Exception:
        pass
    try:
        os.link(path, latest)
    except Exception:
        f.save(latest)

    events.labels(source=src).inc()
    return jsonify({"ok": True, "file": fname})

@app.get("/latest.jpg")
def latest():
    return send_from_directory(UPLOAD_DIR, "latest.jpg")

@app.get("/metrics")
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.get("/healthz")
def healthz():
    return {"ok": True}

"""Single-user RenderCV editor, served behind the host's private nginx route."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit


class Editor(BaseHTTPRequestHandler):
    lock = threading.Lock()

    def reply(self, status, body, content_type="application/json"):
        if isinstance(body, dict):
            body = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        route = urlsplit(self.path).path
        if route == "/":
            return self.reply(200, self.server.html.read_bytes(), "text/html; charset=utf-8")
        if route == "/api/cv":
            return self.reply(200, {"yaml": self.server.source.read_text()})
        if route == "/cv.yaml":
            return self.reply(200, self.server.source.read_bytes(), "text/yaml; charset=utf-8")
        if route == "/cv.pdf" and self.server.pdf.exists():
            return self.reply(200, self.server.pdf.read_bytes(), "application/pdf")
        self.reply(404, {"error": "No document here. Render your CV to create a PDF."})

    def do_POST(self):
        if urlsplit(self.path).path != "/api/render":
            return self.reply(404, {"error": "Unknown route"})
        # Custom header forces cross-origin browser requests through a preflight.
        if self.headers.get("X-RenderCV-Editor") != "1":
            return self.reply(403, {"error": "Use the editor to render."})
        try:
            size = int(self.headers.get("Content-Length", "0"))
            if not 0 < size <= 262144:
                return self.reply(413, {"error": "CV must be smaller than 256 KiB."})
            document = json.loads(self.rfile.read(size))["yaml"]
            if not isinstance(document, str):
                raise ValueError("YAML must be text")
        except (ValueError, KeyError, UnicodeError):
            return self.reply(400, {"error": "Expected a JSON object with a yaml string."})
        if not self.lock.acquire(blocking=False):
            return self.reply(409, {"error": "Another render is running. Try again shortly."})
        try:
            with tempfile.TemporaryDirectory(dir=self.server.data) as work:
                work = Path(work)
                source = work / "CV.yaml"
                source.write_text(document)
                result = subprocess.run(
                    [self.server.rendercv, "render", str(source),
                     "--output-folder", "output", "--typst-path", "preview.typ",
                     "--pdf-path", "preview.pdf", "--dont-generate-png",
                     "--dont-generate-markdown", "--dont-generate-html"],
                    cwd=work, capture_output=True, text=True, timeout=90,
                    env={**os.environ, "NO_COLOR": "1", "TERM": "dumb"},
                )
                pdf = work / "preview.pdf"
                if result.returncode or not pdf.exists():
                    return self.reply(422, {"error": (result.stdout + result.stderr)[-16000:]})
                # Keep the previous source and PDF until a new render succeeds.
                if self.server.source.exists():
                    shutil.copyfile(self.server.source, self.server.data / "previous.yaml")
                source.replace(self.server.source)
                pdf.replace(self.server.pdf)
            self.reply(200, {"ok": True})
        except subprocess.TimeoutExpired:
            self.reply(504, {"error": "Rendering exceeded 90 seconds. Your saved CV is unchanged."})
        except OSError as error:
            self.log_error("Render failed: %s", error)
            self.reply(500, {"error": "Could not render or save. Check the service journal."})
        finally:
            self.lock.release()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8047)
    parser.add_argument("--data", type=Path, required=True)
    parser.add_argument("--seed", type=Path, required=True)
    parser.add_argument("--html", type=Path, required=True)
    parser.add_argument("--rendercv", required=True)
    args = parser.parse_args()
    args.data.mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), Editor)
    server.data = args.data
    server.source = args.data / "CV.yaml"
    server.pdf = args.data / "CV.pdf"
    server.html = args.html
    server.rendercv = args.rendercv
    if not server.source.exists():
        shutil.copyfile(args.seed, server.source)
    server.serve_forever()


if __name__ == "__main__":
    main()

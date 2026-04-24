#!/usr/bin/env python3
"""
serve.py — Static HTTP server with range request support

PMTiles uses HTTP byte-range requests to read only the tiles needed for
the current viewport. Python's built-in http.server doesn't support ranges,
so this script provides a minimal handler that does.

Usage:
    python scripts/serve.py [port] [directory]
    python scripts/serve.py 8080 dist
"""

import os
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler


class RangeRequestHandler(SimpleHTTPRequestHandler):

    def do_GET(self):
        if "Range" not in self.headers:
            super().do_GET()
            return
        self._serve_range()

    def _serve_range(self):
        path = self.translate_path(self.path)
        try:
            f = open(path, "rb")
        except OSError:
            self.send_error(404, "File not found")
            return

        with f:
            file_size = os.fstat(f.fileno()).st_size
            raw = self.headers["Range"].replace("bytes=", "")
            start_str, _, end_str = raw.partition("-")
            start = int(start_str) if start_str else 0
            end   = int(end_str)   if end_str   else file_size - 1
            end   = min(end, file_size - 1)
            length = end - start + 1

            f.seek(start)
            data = f.read(length)

        self.send_response(206, "Partial Content")
        self.send_header("Content-Type", self.guess_type(path))
        self.send_header("Content-Range", f"bytes {start}-{end}/{file_size}")
        self.send_header("Content-Length", str(length))
        self.send_header("Accept-Ranges", "bytes")
        self.end_headers()
        self.wfile.write(data)

    # Suppress per-request log spam; keep it readable
    def log_message(self, fmt, *args):
        print(f"  {self.address_string()} — {fmt % args}")


def main():
    port      = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    directory = sys.argv[2]      if len(sys.argv) > 2 else "."
    os.chdir(directory)
    addr = os.path.abspath(".")
    print(f"Serving {addr}")
    print(f"Open   http://localhost:{port}")
    HTTPServer(("", port), RangeRequestHandler).serve_forever()


if __name__ == "__main__":
    main()

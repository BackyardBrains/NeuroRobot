#!/usr/bin/env python3
"""Dev server with Cross-Origin Isolation headers for WASM pthreads (SharedArrayBuffer)."""
import http.server
import sys
import os

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8085
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'web')

class COOPCOEPHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()

print(f"Serving {DIRECTORY} at http://localhost:{PORT}")
print(f"Cross-Origin-Isolation headers enabled (SharedArrayBuffer support)")
print(f"Press Ctrl+C to stop")
http.server.HTTPServer(('', PORT), COOPCOEPHandler).serve_forever()

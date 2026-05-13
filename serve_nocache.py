#!/usr/bin/env python3
"""No-cache HTTP server for Flutter web development.
Serves build/web/ with Cache-Control: no-store headers to prevent
stale main.dart.js from being served during development.
"""
import http.server
import os
import sys

class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8099
    directory = os.path.join(os.path.dirname(__file__), 'build', 'web')
    os.chdir(directory)
    print(f"Serving {directory} on http://localhost:{port} (no-cache)")
    server = http.server.HTTPServer(('', port), NoCacheHandler)
    server.serve_forever()

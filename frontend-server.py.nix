''#!/usr/bin/env python3

import http.server
import socketserver
import os

PORT = ${toString vars.webclient_port}
os.chdir("${vvvoteFrontend}")

class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_custom_headers()
        super().end_headers()

    def send_custom_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")


with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print("serving at port", PORT)
    httpd.serve_forever()
''

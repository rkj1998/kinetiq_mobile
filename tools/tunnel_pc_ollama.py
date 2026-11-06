#!/usr/bin/env python3
"""
Kinetiq Mobile - Local PC Ollama Internet Tunnel with Built-in Proxy
Exposes your local PC Ollama models (Qwen, Llama, DeepSeek) to your phone
ANYWHERE in the world without port forwarding or complex network configuration.

Includes an internal Host-scrubbing reverse proxy so Ollama never throws 403 Forbidden
regardless of how the external tunnel sends Host headers.

Usage:
    python tools/tunnel_pc_ollama.py
"""

import argparse
import http.server
import os
import re
import shutil
import socketserver
import subprocess
import sys
import threading
import time
import urllib.request
import urllib.error

class OllamaProxyHandler(http.server.BaseHTTPRequestHandler):
    ollama_port = 11434

    def log_message(self, format, *args):
        # Quiet proxy logging
        pass

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Content-Length', '0')
        self.end_headers()

    def do_GET(self):
        self._proxy_request('GET')

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else None
        self._proxy_request('POST', body)

    def _proxy_request(self, method, body=None):
        target_url = f"http://127.0.0.1:{self.ollama_port}{self.path}"
        req = urllib.request.Request(target_url, data=body, method=method)
        # Always present as local request to bypass Ollama Host/Origin protection
        req.add_header('Host', f"127.0.0.1:{self.ollama_port}")
        req.add_header('User-Agent', 'Kinetiq-Mobile-Tunnel/1.0')
        req.add_header('Content-Type', self.headers.get('Content-Type', 'application/json'))

        auth = self.headers.get('Authorization')
        if auth:
            req.add_header('Authorization', auth)

        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                self.send_response(resp.status)
                for k, v in resp.getheaders():
                    if k.lower() not in ['content-length', 'connection', 'transfer-encoding']:
                        self.send_header(k, v)
                data = resp.read()
                self.send_header('Content-Length', str(len(data)))
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(data)
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            data = e.read()
            self.send_header('Content-Length', str(len(data)))
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self.send_response(502)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(f'{{"error": "{str(e)}"}}'.encode())

def start_local_proxy(ollama_port=11434, proxy_port=11435):
    OllamaProxyHandler.ollama_port = ollama_port
    server = socketserver.ThreadingTCPServer(('127.0.0.1', proxy_port), OllamaProxyHandler)
    server.allow_reuse_address = True
    t = threading.Thread(target=server.serve_forever, daemon=True)
    t.start()
    return server

def check_local_ollama(port=11434):
    try:
        import json
        req = urllib.request.Request(f"http://127.0.0.1:{port}/api/tags")
        with urllib.request.urlopen(req, timeout=3) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                models = [m.get('name', '') for m in data.get('models', [])]
                return True, models
    except Exception:
        return False, []
    return False, []

def find_cloudflared_binary():
    found = shutil.which("cloudflared")
    if found:
        return found

    candidate_paths = [
        r"C:\Program Files (x86)\cloudflared\cloudflared.exe",
        r"C:\Program Files\cloudflared\cloudflared.exe",
        os.path.expandvars(r"%LOCALAPPDATA%\Programs\cloudflared\cloudflared.exe"),
        os.path.expandvars(r"%LOCALAPPDATA%\Microsoft\WinGet\Packages\Cloudflare.cloudflared_Microsoft.Winget.Source_8wekyb3d8bbwe\cloudflared.exe"),
        os.path.expandvars(r"%USERPROFILE%\bin\cloudflared.exe"),
    ]
    for p in candidate_paths:
        if os.path.isfile(p):
            return p

    return None

def run_cloudflare_tunnel(ollama_port=11434):
    cloudflared = find_cloudflared_binary()
    if not cloudflared:
        print("❌ 'cloudflared' binary not found.")
        print("   Run: winget install --id Cloudflare.cloudflared")
        sys.exit(1)

    # 1. Start host-scrubbing proxy on 11435
    proxy_port = 11435
    print(f"🛡️  Starting local host-scrubbing reverse proxy on port {proxy_port}...")
    proxy_server = start_local_proxy(ollama_port=ollama_port, proxy_port=proxy_port)

    # 2. Point cloudflared at proxy_port
    print(f"🚀 Found cloudflared at: {cloudflared}")
    print(f"🚀 Launching secure Cloudflare Tunnel to port {proxy_port}...")
    cmd = [
        cloudflared,
        "tunnel",
        "--url", f"http://127.0.0.1:{proxy_port}",
    ]
    proc = subprocess.Popen(cmd, stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True)

    tunnel_url = None
    for line in proc.stderr:
        print(line, end="")
        if "trycloudflare.com" in line:
            match = re.search(r"https://[a-zA-Z0-9\-]+\.trycloudflare\.com", line)
            if match:
                tunnel_url = match.group(0)
                break

    if tunnel_url:
        print("\n" + "="*65)
        print("🎉 SUCCESS! YOUR OLLAMA IS ACCESSIBLE WORLDWIDE ON YOUR PHONE")
        print("="*65)
        print(f"\n📱 In Kinetiq Mobile on your phone (Cellular or Any Wi-Fi):")
        print(f"   Base URL: {tunnel_url}/v1")
        print(f"   API Key:  ollama")
        print(f"\n👉 Tap 'Fetch Models' in Kinetiq to automatically load your Qwen models!")
        print("="*65 + "\n")

    try:
        proc.wait()
    except KeyboardInterrupt:
        print("\nStopping tunnel...")
        proc.terminate()
        proxy_server.shutdown()

def main():
    parser = argparse.ArgumentParser(description="Expose PC Ollama to Kinetiq Mobile anywhere in the world.")
    parser.add_argument("--port", type=int, default=11434, help="Local Ollama port (default: 11434)")
    args = parser.parse_args()

    print("="*65)
    print("🛰️  KINETIQ MOBILE - PC OLLAMA ANYWHERE TUNNEL")
    print("="*65)

    is_live, models = check_local_ollama(args.port)
    if is_live:
        print(f"✓ Local Ollama is running on port {args.port}!")
        print(f"  Discovered models: {', '.join(models) if models else 'None'}")
    else:
        print(f"⚠️  Warning: Ollama is not currently detected on 127.0.0.1:{args.port}.")
        print("   Make sure 'ollama serve' or the Ollama app is running on your PC.")

    run_cloudflare_tunnel(args.port)

if __name__ == "__main__":
    main()

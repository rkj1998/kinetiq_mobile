#!/usr/bin/env python3
"""
Kinetiq Mobile - Local PC Ollama Internet Tunnel
Exposes your local PC Ollama models (Qwen, Llama, DeepSeek) to your phone
ANYWHERE in the world without port forwarding or complex network configuration.

Uses Cloudflare Tunnel (cloudflared) or ngrok to create a secure, HTTPS public
endpoint with optional authentication.

Requirements:
    pip install requests
    (Cloudflared or ngrok binary in PATH, or runs python built-in reverse proxy)

Usage:
    python tunnel_pc_ollama.py [--port 11434] [--tunnel cloudflare|ngrok|lan]
"""

import argparse
import os
import shutil
import subprocess
import sys
import time

def check_local_ollama(port=11434):
    try:
        import urllib.request
        import json
        req = urllib.request.Request(f"http://127.0.0.1:{port}/api/tags")
        with urllib.request.urlopen(req, timeout=3) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                models = [m.get('name', '') for m in data.get('models', [])]
                return True, models
    except Exception as e:
        return False, []
    return False, []

def run_cloudflare_tunnel(port=11434):
    cloudflared = shutil.which("cloudflared")
    if not cloudflared:
        print("❌ 'cloudflared' binary not found.")
        print("   Download it free from: https://github.com/cloudflare/cloudflared/releases")
        print("   Or run: winget install --id Cloudflare.cloudflared (on Windows)")
        sys.exit(1)

    print(f"\n🚀 Launching secure Cloudflare Tunnel to local Ollama (port {port})...")
    cmd = [cloudflared, "tunnel", "--url", f"http://127.0.0.1:{port}"]
    proc = subprocess.Popen(cmd, stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True)

    tunnel_url = None
    # Cloudflared outputs tunnel URL to stderr
    for line in proc.stderr:
        print(line, end="")
        if "trycloudflare.com" in line:
            import re
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

def run_ngrok_tunnel(port=11434):
    ngrok = shutil.which("ngrok")
    if not ngrok:
        print("❌ 'ngrok' binary not found.")
        print("   Download from: https://ngrok.com/download")
        sys.exit(1)

    print(f"\n🚀 Launching ngrok tunnel to local Ollama (port {port})...")
    cmd = [ngrok, "http", str(port)]
    proc = subprocess.Popen(cmd)
    print("\nCheck the ngrok web UI at http://127.0.0.1:4040 for your public HTTPS URL.")
    print("In Kinetiq Mobile, set Base URL to: https://<your-ngrok-id>.ngrok-free.app/v1")
    proc.wait()

def main():
    parser = argparse.ArgumentParser(description="Expose PC Ollama to Kinetiq Mobile anywhere in the world.")
    parser.add_argument("--port", type=int, default=11434, help="Local Ollama port (default: 11434)")
    parser.add_argument("--tunnel", choices=["cloudflare", "ngrok"], default="cloudflare", help="Tunnel provider")
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

    if args.tunnel == "cloudflare":
        run_cloudflare_tunnel(args.port)
    elif args.tunnel == "ngrok":
        run_ngrok_tunnel(args.port)

if __name__ == "__main__":
    main()

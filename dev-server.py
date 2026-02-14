#!/usr/bin/env python3
"""
Shader Development Server

Watches shader files for changes and provides:
- Hot reload via Server-Sent Events (SSE)
- Screenshot saving endpoint
- Shader file listing and serving

Usage:
    python3 dev-server.py [--port 8080] [--shader plasma.glsl]
"""

import os
import sys
import json
import time
import base64
import argparse
import threading
import asyncio
import pty
import struct
import fcntl
import termios
import select
from pathlib import Path
from datetime import datetime
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# Try to import websockets (optional dependency for terminal)
try:
    import websockets
    from websockets.asyncio.server import serve as ws_serve
    HAS_WEBSOCKETS = True
except ImportError:
    HAS_WEBSOCKETS = False
    print("Note: 'websockets' not installed. Terminal feature disabled.")
    print("      Install with: pip install websockets")

# Configuration
SHADER_DIR = Path(__file__).parent / "shaders"
SCREENSHOT_DIR = Path(__file__).parent / "screenshots"
STATIC_DIR = Path(__file__).parent

# Global state
file_versions = {}
current_shader = None
clients = []


def get_shader_list():
    """Get list of available shader files."""
    if not SHADER_DIR.exists():
        return []
    return sorted([f.name for f in SHADER_DIR.glob("*.glsl")])


def get_shader_content(name):
    """Read shader file content."""
    path = SHADER_DIR / name
    if path.exists() and path.suffix == ".glsl":
        return path.read_text()
    return None


def get_file_version(name):
    """Get file modification time as version."""
    path = SHADER_DIR / name
    if path.exists():
        return path.stat().st_mtime
    return 0


def save_shader(name, content):
    """Save shader content to file."""
    if not name or not name.endswith(".glsl"):
        return False
    # Sanitize filename
    name = Path(name).name
    path = SHADER_DIR / name
    path.write_text(content)
    print(f"Saved shader: {path}")
    return True


def save_screenshot(name, data_url):
    """Save base64 screenshot to file."""
    SCREENSHOT_DIR.mkdir(exist_ok=True)

    # Parse data URL
    if not data_url.startswith("data:image/png;base64,"):
        return None

    base64_data = data_url.split(",")[1]
    image_data = base64.b64decode(base64_data)

    # Generate filename with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    shader_name = Path(name).stem if name else "unknown"
    filename = f"{shader_name}_{timestamp}.png"
    filepath = SCREENSHOT_DIR / filename

    filepath.write_bytes(image_data)
    print(f"Screenshot saved: {filepath}")
    return filename


class DevServerHandler(SimpleHTTPRequestHandler):
    """Custom handler for shader development."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(STATIC_DIR), **kwargs)

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        query = parse_qs(parsed.query)

        if path == "/api/shaders":
            # List all shaders
            self.send_json({"shaders": get_shader_list()})

        elif path == "/api/shader":
            # Get shader content
            name = query.get("name", [None])[0]
            if name:
                content = get_shader_content(name)
                if content:
                    version = get_file_version(name)
                    self.send_json({"name": name, "content": content, "version": version})
                else:
                    self.send_error(404, "Shader not found")
            else:
                self.send_error(400, "Missing shader name")

        elif path == "/api/events":
            # Server-Sent Events for hot reload
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()

            # Add this connection to clients
            clients.append(self.wfile)

            try:
                while True:
                    # Send keepalive
                    self.wfile.write(b": keepalive\n\n")
                    self.wfile.flush()
                    time.sleep(1)
            except (BrokenPipeError, ConnectionResetError):
                pass
            finally:
                if self.wfile in clients:
                    clients.remove(self.wfile)

        elif path == "/viewer.html" or path == "/":
            # Serve the viewer
            self.path = "/viewer.html"
            super().do_GET()

        else:
            # Serve static files
            super().do_GET()

    def do_POST(self):
        parsed = urlparse(self.path)
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length).decode("utf-8")
        data = json.loads(body) if body else {}

        if parsed.path == "/api/shader/save":
            # Save shader to file
            name = data.get("name", "live.glsl")
            content = data.get("content", "")
            if save_shader(name, content):
                self.send_json({"success": True, "name": name})
            else:
                self.send_error(400, "Invalid shader data")

        elif parsed.path == "/api/screenshot":
            # Save screenshot
            filename = save_screenshot(data.get("shader"), data.get("image"))
            if filename:
                self.send_json({"success": True, "filename": filename})
            else:
                self.send_error(400, "Invalid screenshot data")
        else:
            self.send_error(404)

    def send_json(self, data):
        """Send JSON response."""
        body = json.dumps(data).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", len(body))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        # Quieter logging
        if "/api/events" not in args[0]:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] {args[0]}")


def notify_clients(event, data):
    """Send SSE event to all connected clients."""
    message = f"event: {event}\ndata: {json.dumps(data)}\n\n"
    dead_clients = []

    for client in clients:
        try:
            client.write(message.encode("utf-8"))
            client.flush()
        except (BrokenPipeError, ConnectionResetError, OSError):
            dead_clients.append(client)

    for client in dead_clients:
        clients.remove(client)


def watch_shaders():
    """Watch shader directory for changes."""
    global file_versions

    while True:
        try:
            for shader_file in SHADER_DIR.glob("*.glsl"):
                name = shader_file.name
                version = shader_file.stat().st_mtime

                if name not in file_versions:
                    file_versions[name] = version
                    print(f"Watching: {name}")
                elif file_versions[name] != version:
                    file_versions[name] = version
                    print(f"Changed: {name}")
                    notify_clients("reload", {"shader": name, "version": version})
        except Exception as e:
            print(f"Watch error: {e}")

        time.sleep(0.5)


# ==================== WebSocket Terminal ====================

async def terminal_handler(websocket):
    """Handle WebSocket connection for interactive terminal."""
    print(f"Terminal connected: {websocket.remote_address}")

    # Create PTY
    master_fd, slave_fd = pty.openpty()

    # Start shell
    shell = os.environ.get('SHELL', '/bin/bash')
    pid = os.fork()

    if pid == 0:
        # Child process
        os.close(master_fd)
        os.setsid()
        os.dup2(slave_fd, 0)
        os.dup2(slave_fd, 1)
        os.dup2(slave_fd, 2)
        os.close(slave_fd)

        # Set TERM environment
        env = os.environ.copy()
        env['TERM'] = 'xterm-256color'

        os.execvpe(shell, [shell], env)

    # Parent process
    os.close(slave_fd)

    async def read_pty():
        """Read output from PTY and send to websocket."""
        loop = asyncio.get_event_loop()
        while True:
            try:
                # Check if data available
                r, _, _ = select.select([master_fd], [], [], 0.1)
                if r:
                    data = os.read(master_fd, 4096)
                    if data:
                        await websocket.send(data.decode('utf-8', errors='replace'))
                    else:
                        break
                await asyncio.sleep(0.01)
            except (OSError, asyncio.CancelledError):
                break

    read_task = asyncio.create_task(read_pty())

    try:
        async for message in websocket:
            try:
                data = json.loads(message)

                if data['type'] == 'input':
                    os.write(master_fd, data['data'].encode('utf-8'))

                elif data['type'] == 'resize':
                    cols, rows = data['cols'], data['rows']
                    winsize = struct.pack('HHHH', rows, cols, 0, 0)
                    fcntl.ioctl(master_fd, termios.TIOCSWINSZ, winsize)

            except Exception as e:
                print(f"Terminal message error: {e}")

    except websockets.exceptions.ConnectionClosed:
        pass

    finally:
        print(f"Terminal disconnected: {websocket.remote_address}")
        read_task.cancel()
        os.close(master_fd)
        # Kill child process
        try:
            os.kill(pid, 9)
            os.waitpid(pid, 0)
        except OSError:
            pass


async def run_websocket_server(port):
    """Run WebSocket server for terminal."""
    async with ws_serve(terminal_handler, "localhost", port):
        print(f"WebSocket terminal on ws://localhost:{port}")
        await asyncio.Future()  # Run forever


def run_http_server(port):
    """Run HTTP server in a thread."""
    server = HTTPServer(("", port), DevServerHandler)
    server.serve_forever()


def main():
    parser = argparse.ArgumentParser(description="Shader Development Server")
    parser.add_argument("--port", type=int, default=8080, help="HTTP server port")
    parser.add_argument("--ws-port", type=int, default=8081, help="WebSocket terminal port")
    parser.add_argument("--shader", type=str, help="Initial shader to load")
    args = parser.parse_args()

    global current_shader
    current_shader = args.shader

    # Create directories
    SHADER_DIR.mkdir(exist_ok=True)
    SCREENSHOT_DIR.mkdir(exist_ok=True)

    # Start file watcher
    watcher = threading.Thread(target=watch_shaders, daemon=True)
    watcher.start()

    # Start HTTP server in thread
    http_thread = threading.Thread(target=run_http_server, args=(args.port,), daemon=True)
    http_thread.start()

    print(f"\n{'='*50}")
    print(f"Shader Development Server")
    print(f"{'='*50}")
    print(f"HTTP:        http://localhost:{args.port}")
    if HAS_WEBSOCKETS:
        print(f"Terminal:    ws://localhost:{args.ws_port}")
    else:
        print(f"Terminal:    (disabled - install websockets)")
    print(f"Shaders:     {SHADER_DIR}")
    print(f"Screenshots: {SCREENSHOT_DIR}")
    print(f"{'='*50}")
    print(f"Available shaders: {', '.join(get_shader_list()) or '(none)'}")
    print(f"{'='*50}\n")

    try:
        if HAS_WEBSOCKETS:
            # Run WebSocket server (main event loop)
            asyncio.run(run_websocket_server(args.ws_port))
        else:
            # Just keep running
            while True:
                time.sleep(1)
    except KeyboardInterrupt:
        print("\nShutting down...")


if __name__ == "__main__":
    main()

import http.server
import ssl
import json
import os

# --- CONFIGURATION ---
LISTEN_HOST = '0.0.0.0'
LISTEN_PORT = 10400
SECRET_TOKEN = 'my-super-secret-token' # Must match your GitLab webhook

# Paths to our *new* dev-container certs in the ~/data mount
CERT_DIR = os.path.expanduser('~/data')
CERT_FILE = os.path.join(CERT_DIR, 'dev-container.crt.pem')
KEY_FILE = os.path.join(CERT_DIR, 'dev-container.key.pem')

class WebhookHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        # 1. Verify the Secret Token
        gitlab_token = self.headers.get('X-Gitlab-Token')
        if gitlab_token != SECRET_TOKEN:
            print("⛔ ERROR: Invalid X-Gitlab-Token.")
            self.send_response(403)
            self.end_headers()
            return

        # 2. Read the JSON payload
        content_length = int(self.headers['Content-Length'])
        body = self.rfile.read(content_length)

        # 3. Print the relevant info
        print("\n--- ✅ WEBHOOK RECEIVED! ---")
        try:
            payload = json.loads(body)
            print(f"Project: {payload.get('project', {}).get('path_with_namespace')}")
            print(f"Pusher:  {payload.get('user_name')}")
            print(f"Ref:     {payload.get('ref')}")

            # Print all commits in this push
            for commit in payload.get('commits', []):
                print(f"  - Commit: {commit.get('id')[:8]}")
                print(f"    Author: {commit.get('author', {}).get('name')}")
                print(f"    Msg:    {commit.get('message').strip()}")

        except Exception as e:
            print(f"Error parsing JSON: {e}")

        # 4. Send a 200 OK response
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'Webhook Received')

if __name__ == "__main__":
    print(f"Starting HTTPS server on https://{LISTEN_HOST}:{LISTEN_PORT}...")

    # Create an SSL context using our "dev-container" certs
    context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    context.load_cert_chain(certfile=CERT_FILE, keyfile=KEY_FILE)

    httpd = http.server.HTTPServer((LISTEN_HOST, LISTEN_PORT), WebhookHandler)
    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        httpd.server_close()

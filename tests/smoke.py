import json
import subprocess
from urllib.parse import urlsplit


def run_command(command):
    return subprocess.check_output(
        command,
        text=True
    ).strip()


url = run_command([
    "terraform",
    "-chdir=infra",
    "output",
    "-raw",
    "health_url"
])

hostname = urlsplit(url).hostname

response = run_command([
    "curl",
    "--noproxy", "*",
    "--resolve", f"{hostname}:4566:127.0.0.1",
    "--fail",
    "--silent",
    "--show-error",
    url
])

data = json.loads(response)

assert data.get("status") == "ok", data

print("Deployment health check PASSED")
print(json.dumps(data, indent=2))
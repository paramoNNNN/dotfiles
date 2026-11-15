"""Read a local AFFiNE token and supply it to Codex at runtime."""

import json
from pathlib import Path
import sys


def main():
    token_path = Path(sys.argv[1])
    token = token_path.read_text().strip()
    if not token:
        raise ValueError("Token file is empty")
    print(json.dumps({"Authorization": "Bearer " + token}))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError):
        sys.exit(f"AFFiNE token unavailable. Create a nonempty token file at {sys.argv[1]} with mode 600.")

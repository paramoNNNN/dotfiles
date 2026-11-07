"""Export named nftables counters atomically for node exporter's textfile collector."""

import json
import os
from pathlib import Path
import subprocess
import sys
import time


def render(data, now):
    lines = [
        "# HELP service_network_bytes_total IP bytes on client-facing service ports, excluding loopback.",
        "# TYPE service_network_bytes_total counter",
        "# HELP service_network_packets_total Packets on client-facing service ports, excluding loopback.",
        "# TYPE service_network_packets_total counter",
    ]
    count = 0
    for item in data["nftables"]:
        counter = item.get("counter")
        if not counter or counter.get("table") != "service_traffic":
            continue
        service, network, direction = counter["name"].split("__")
        labels = f'service="{service}",network="{network}",direction="{direction}"'
        for field in ("bytes", "packets"):
            lines.append(f'service_network_{field}_total{{{labels}}} {int(counter[field])}')
        count += 1
    if not count:
        raise ValueError("No service traffic counters found")
    lines.extend([
        "# HELP service_network_collector_timestamp_seconds Last successful collection time.",
        "# TYPE service_network_collector_timestamp_seconds gauge",
        f"service_network_collector_timestamp_seconds {now}",
    ])
    return "\n".join(lines) + "\n"


def main():
    nft, destination = sys.argv[1:]
    result = subprocess.run(
        [nft, "-j", "list", "counters", "table", "inet", "service_traffic"],
        check=True, capture_output=True, text=True, timeout=10,
    )
    content = render(json.loads(result.stdout), time.time())
    target = Path(destination)
    temporary = target.with_suffix(".tmp")
    temporary.write_text(content)
    temporary.chmod(0o644)
    os.replace(temporary, target)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Return the single IAM SAML provider ARN in this AWS account as JSON for data.external."""

import json
import subprocess
import sys


def main() -> int:
    try:
        result = subprocess.run(
            ["aws", "iam", "list-saml-providers", "--output", "json"],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        print("aws CLI is required to discover the IAM SAML provider", file=sys.stderr)
        return 1
    except subprocess.CalledProcessError as exc:
        print(exc.stderr or str(exc), file=sys.stderr)
        return 1

    providers = json.loads(result.stdout).get("SAMLProviderList") or []
    if len(providers) != 1:
        arns = [p.get("Arn") for p in providers]
        print(
            f"Expected exactly one IAM SAML provider, found {len(providers)}: {arns}",
            file=sys.stderr,
        )
        return 1

    # data.external requires a flat map of strings
    print(json.dumps({"arn": providers[0]["Arn"]}))
    return 0


if __name__ == "__main__":
    sys.exit(main())

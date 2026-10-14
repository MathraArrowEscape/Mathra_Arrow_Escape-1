#!/usr/bin/env python3
"""Make the unlock code for a customer's phone.
Usage: python3 tools/make_code.py ABC234
SECRET must equal AppConstants.unlockSecret in lib/core/constants.dart."""
import sys
SECRET = "CHANGE_ME_mathra_2026"

def code_for(device_id: str) -> str:
    h = 2166136261
    for b in (SECRET + device_id.strip().upper() + SECRET).encode("utf-16-le")[::2]:
        h ^= b
        h = (h * 16777619) & 0xFFFFFFFF
    return str((h % 900000) + 100000)

if __name__ == "__main__":
    print(code_for(sys.argv[1]))

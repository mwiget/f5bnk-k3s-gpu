#!/usr/bin/python3

import jwt
from jwt import InvalidTokenError
from pathlib import Path
from datetime import datetime

# Read the token from ~/.jwt
jwt_file = Path.home() / ".jwt"
with jwt_file.open("r") as f:
    token = f.read().strip()

try:
    # Decode without verifying signature (for inspection only)
    payload = jwt.decode(token, options={"verify_signature": False})
    print("Decoded JWT Payload:")

    for k, v in payload.items():
        if k in ["iat", "f5_sat"] and isinstance(v, int):
            # Convert UNIX timestamp to human-readable date
            readable = datetime.utcfromtimestamp(v).strftime('%Y-%m-%d %H:%M:%S UTC')
            print(f"{k}: {v} ({readable})")
        else:
            print(f"{k}: {v}")

except InvalidTokenError as e:
    print(f"Invalid token: {e}")

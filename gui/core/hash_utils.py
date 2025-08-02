import core.logger as logger
import hashlib
from .logger import log

def compute_sha256(path):
    try:
        with open(path, "rb") as f:
            return hashlib.sha256(f.read()).hexdigest()
    except Exception as e:
        log(f"[!] Failed to compute SHA256: {e}")
        return "error"

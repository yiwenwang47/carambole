"""French-grammar content-generation pipeline (dev tooling)."""
import logging

# verbecc logs verbosely (config + per-call "empty conjugation" warnings).
# Keep pipeline runs readable.
logging.getLogger("verbecc").setLevel(logging.ERROR)

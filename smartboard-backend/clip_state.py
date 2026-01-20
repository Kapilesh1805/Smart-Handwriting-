"""
Single source of truth for CLIP model readiness state.

This module manages ONE global flag that tracks whether CLIP is fully initialized:
- CLIP model loaded
- Template embeddings loaded
- Ready to evaluate handwriting

Design principles:
  ✓ ONE global flag (CLIP_READY)
  ✓ Thread-safe with lock
  ✓ NO lazy loading inside routes
  ✓ NO duplicate flags
  ✓ NO local variables checking initialization
  ✓ Routes check this flag ONLY

This module is initialized at startup and used by routes to determine
whether to return 202 (warming up) or 200 (ready).
"""

import threading
import logging

logger = logging.getLogger(__name__)

# ONE GLOBAL FLAG: This is the single source of truth
CLIP_READY = False

# Thread-safe access
_lock = threading.Lock()


def set_ready():
    """
    Mark CLIP as ready. Called exactly once when warm-up completes.
    
    This is called from the background warm-up thread in app.py
    when CLIP model and templates are fully loaded.
    """
    global CLIP_READY
    with _lock:
        CLIP_READY = True
    logger.info("[CLIP_STATE] ✅ CLIP_READY = True (warm-up complete)")


def is_ready() -> bool:
    """
    Check if CLIP is ready to evaluate.
    
    Returns:
        True if CLIP fully initialized, False if still warming up
    
    Called by /handwriting/analyze and /handwriting/analyze-number routes.
    """
    global CLIP_READY
    with _lock:
        return CLIP_READY


def reset():
    """
    Reset CLIP readiness (for testing only).
    
    Do NOT call this in production code.
    """
    global CLIP_READY
    with _lock:
        CLIP_READY = False
    logger.warning("[CLIP_STATE] CLIP_READY reset to False (test only)")

"""
One-time login: opens Playwright Chromium, you complete SSO manually,
then saves cookies to the storage-state file.

Usage:
  QA_CONSOLE_URL=... uv run login_once.py          # opens browser
  # ... log in manually ...
  uv run login_once.py --save                      # saves storage state & closes
"""
import os
import sys
from playwright.sync_api import sync_playwright

PROFILE = os.getenv("QA_BROWSER_PROFILE", "/tmp/qa-pw-profile")
STORAGE = os.getenv("QA_STORAGE_STATE", "/tmp/qa-storage-state.json")
URL = os.getenv("QA_CONSOLE_URL")

if "--save" in sys.argv:
    pw = sync_playwright().start()
    browser = pw.chromium.launch_persistent_context(PROFILE, headless=False)
    page = browser.pages[0] if browser.pages else browser.new_page()
    browser.storage_state(path=STORAGE)
    print(f"Saved to {STORAGE}")
    browser.close()
    pw.stop()
else:
    assert URL, "Set QA_CONSOLE_URL env var"
    pw = sync_playwright().start()
    browser = pw.chromium.launch_persistent_context(
        PROFILE, headless=False, args=["--window-size=1280,720"],
    )
    page = browser.pages[0] if browser.pages else browser.new_page()
    page.goto(URL)
    print(f"Browser open at {URL}")
    print("Log in via SSO, then run:")
    print("  uv run login_once.py --save")
    # Keep alive
    import time
    while True:
        time.sleep(60)

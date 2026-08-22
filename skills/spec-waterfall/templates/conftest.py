"""
E2E test fixtures — instantiate per project and adapt to its API and auth.
API tests: httpx against the project's API endpoint
Browser tests: headless Playwright Chromium + saved storage state (SSO cookies)
"""
import os
import pytest
import httpx
from playwright.sync_api import sync_playwright


# ---------------------------------------------------------------------------
# Config — via env vars
# ---------------------------------------------------------------------------
QA_API_BASE_URL = os.getenv("QA_API_BASE_URL")
QA_CONSOLE_URL = os.getenv("QA_CONSOLE_URL")
QA_API_KEY = os.getenv("QA_API_KEY")


# ---------------------------------------------------------------------------
# API client
# ---------------------------------------------------------------------------
@pytest.fixture(scope="session")
def api():
    """httpx client with auth header."""
    assert QA_API_BASE_URL, "Set QA_API_BASE_URL env var"
    assert QA_API_KEY, "Set QA_API_KEY env var"
    client = httpx.Client(
        base_url=QA_API_BASE_URL,
        headers={
            "Authorization": f"Bearer {QA_API_KEY}",
            "Content-Type": "application/json",
        },
        timeout=60.0,
    )
    yield client
    client.close()


@pytest.fixture(scope="session")
def api_no_auth():
    """httpx client without auth — for testing 401 paths."""
    assert QA_API_BASE_URL, "Set QA_API_BASE_URL env var"
    client = httpx.Client(
        base_url=QA_API_BASE_URL,
        headers={"Content-Type": "application/json"},
        timeout=30.0,
    )
    yield client
    client.close()


# ---------------------------------------------------------------------------
# Browser (headless Playwright Chromium + saved storage state)
# ---------------------------------------------------------------------------
STORAGE_STATE = os.getenv("QA_STORAGE_STATE", "/tmp/qa-storage-state.json")


@pytest.fixture(scope="session")
def browser_context():
    """
    Headless Playwright Chromium with saved storage state (cookies from SSO).
    First-time setup: run `uv run login_once.py`, log in, then save.
    """
    pw = sync_playwright().start()
    browser = pw.chromium.launch(headless=True)
    context = browser.new_context(storage_state=STORAGE_STATE)
    yield context
    context.close()
    browser.close()
    pw.stop()


@pytest.fixture
def page(browser_context):
    """Fresh page in headless context (carries SSO cookies)."""
    p = browser_context.new_page()
    yield p
    p.close()


@pytest.fixture(scope="session")
def console_url():
    assert QA_CONSOLE_URL, "Set QA_CONSOLE_URL env var"
    return QA_CONSOLE_URL

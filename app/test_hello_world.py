from fastapi.testclient import TestClient

from hello_world import app

client = TestClient(app)


def test_root():
    resp = client.get("/")
    assert resp.status_code == 200
    assert resp.json() == {"message": "hello world"}


def test_version():
    resp = client.get("/version")
    assert resp.status_code == 200
    assert "version" in resp.json()


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}

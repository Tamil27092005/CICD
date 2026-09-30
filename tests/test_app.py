import pytest

from app.main import create_app


@pytest.fixture()
def client():
    app = create_app()
    app.config["TESTING"] = True
    return app.test_client()


def test_index(client):
    response = client.get("/")
    assert response.status_code == 200
    data = response.get_json()
    assert "message" in data
    assert "version" in data


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "healthy"}


def test_info(client):
    response = client.get("/info")
    assert response.status_code == 200
    data = response.get_json()
    assert {"hostname", "python_version", "timestamp"} <= data.keys()


def test_not_found(client):
    assert client.get("/does-not-exist").status_code == 404

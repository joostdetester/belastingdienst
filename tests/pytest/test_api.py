from fastapi.testclient import TestClient
import pytest

from app.main import app


client = TestClient(app)


def test_health_endpoint() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_belastingberekening_schijf_2() -> None:
    payload = {"jaarinkomen": 55000, "aftrek": 5000, "aow_leeftijd_bereikt": False}
    response = client.post("/belasting/bereken", json=payload)

    assert response.status_code == 200
    body = response.json()
    assert body["schijf"] == "SCHIJF_2"
    assert body["tariefstype"] == "TOT_AOW"
    assert body["te_betalen_belasting"] > 0
    assert body["belasting_per_schijf"]["schijf_1"] > 0
    assert body["belasting_per_schijf"]["schijf_2"] > 0
    assert body["belasting_per_schijf"]["schijf_3"] == 0
    assert body["te_betalen_belasting"] == pytest.approx(
        body["belasting_per_schijf"]["schijf_1"] + body["belasting_per_schijf"]["schijf_2"]
    )


def test_belastingberekening_schijf_3() -> None:
    payload = {"jaarinkomen": 120000, "aftrek": 10000, "aow_leeftijd_bereikt": False}
    response = client.post("/belasting/bereken", json=payload)

    assert response.status_code == 200
    body = response.json()
    assert body["schijf"] == "SCHIJF_3"
    assert body["tariefstype"] == "TOT_AOW"
    assert body["te_betalen_belasting"] > 0
    assert body["belasting_per_schijf"]["schijf_1"] > 0
    assert body["belasting_per_schijf"]["schijf_2"] > 0
    assert body["belasting_per_schijf"]["schijf_3"] > 0


def test_belastingberekening_aow_schijf_1() -> None:
    payload = {"jaarinkomen": 30000, "aftrek": 0, "aow_leeftijd_bereikt": True}
    response = client.post("/belasting/bereken", json=payload)

    assert response.status_code == 200
    body = response.json()
    assert body["schijf"] == "SCHIJF_1"
    assert body["tariefstype"] == "VANAF_AOW"
    assert body["te_betalen_belasting"] == 5355.0
    assert body["belasting_per_schijf"]["schijf_1"] == 5355.0
    assert body["belasting_per_schijf"]["schijf_2"] == 0
    assert body["belasting_per_schijf"]["schijf_3"] == 0


def test_belastingberekening_ongeldige_aftrek() -> None:
    payload = {"jaarinkomen": 20000, "aftrek": 25000, "aow_leeftijd_bereikt": False}
    response = client.post("/belasting/bereken", json=payload)

    assert response.status_code == 400
    assert response.json()["detail"] == "Aftrek kan niet hoger zijn dan jaarinkomen"

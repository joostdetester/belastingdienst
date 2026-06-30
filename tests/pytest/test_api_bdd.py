"""BDD tests voor inkomstenbelasting berekening via pytest-bdd.

Elke stap (Given/When/Then) koppelt een Gherkin-zin uit belasting.feature
aan Python-code. De FastAPI TestClient simuleert echte API-aanroepen zonder
dat de server apart gestart hoeft te worden.
"""

import pytest
from fastapi.testclient import TestClient
from pytest_bdd import given, parsers, scenarios, then, when

from app.main import app

# Laad alle scenario's uit het .feature bestand in één keer.
scenarios("../features/belasting.feature")

client = TestClient(app)


# ---------------------------------------------------------------------------
# Fixtures – gedeelde toestand per scenario
# ---------------------------------------------------------------------------


@pytest.fixture
def verzoek():
    return {}


@pytest.fixture
def api_response():
    return {}


# ---------------------------------------------------------------------------
# Given-stappen
# ---------------------------------------------------------------------------


@given("de belasting API beschikbaar is")
def api_beschikbaar():
    pass  # TestClient start automatisch samen met de fixture


@given(parsers.parse("een belastingplichtige met jaarinkomen {inkomen:d} en aftrek {aftrek:d}"), target_fixture="verzoek")
def stel_inkomen_in(inkomen, aftrek):
    return {"jaarinkomen": inkomen, "aftrek": aftrek, "aow_leeftijd_bereikt": False}


@given("de belastingplichtige heeft de AOW-leeftijd niet bereikt")
def niet_aow(verzoek):
    verzoek["aow_leeftijd_bereikt"] = False


@given("de belastingplichtige heeft de AOW-leeftijd bereikt")
def wel_aow(verzoek):
    verzoek["aow_leeftijd_bereikt"] = True


# ---------------------------------------------------------------------------
# When-stappen
# ---------------------------------------------------------------------------


@when("de belasting wordt berekend", target_fixture="api_response")
def bereken(verzoek):
    return client.post("/belasting/bereken", json=verzoek)


# ---------------------------------------------------------------------------
# Then-stappen
# ---------------------------------------------------------------------------


@then("is de status \"ok\"")
def check_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


@then("is de te betalen belasting groter dan 0")
def belasting_positief(api_response):
    assert api_response.status_code == 200
    assert api_response.json()["te_betalen_belasting"] > 0


@then(parsers.parse("is de te betalen belasting {bedrag:f}"))
def belasting_exact(api_response, bedrag):
    assert api_response.status_code == 200
    assert api_response.json()["te_betalen_belasting"] == pytest.approx(bedrag)


@then(parsers.parse('valt de berekening in schijf "{verwachte_schijf}"'))
def check_schijf(api_response, verwachte_schijf):
    assert api_response.json()["schijf"] == verwachte_schijf


@then(parsers.parse('is het tariefstype "{verwacht_type}"'))
def check_tariefstype(api_response, verwacht_type):
    assert api_response.json()["tariefstype"] == verwacht_type


@then(parsers.parse('geeft de API een foutmelding "{bericht}"'))
def check_foutmelding(api_response, bericht):
    assert api_response.status_code == 400
    assert api_response.json()["detail"] == bericht


@then(parsers.parse("is het bedrag in schijf {nummer:d} groter dan 0"))
def check_schijf_bedrag_positief(api_response, nummer):
    assert api_response.json()["belasting_per_schijf"][f"schijf_{nummer}"] > 0


@then(parsers.parse("is het bedrag in schijf {nummer:d} gelijk aan {bedrag:f}"))
@then(parsers.parse("is het bedrag in schijf {nummer:d} gelijk aan {bedrag:d}"))
def check_schijf_bedrag_exact(api_response, nummer, bedrag):
    assert api_response.json()["belasting_per_schijf"][f"schijf_{nummer}"] == pytest.approx(bedrag)


@then("is de totale belasting gelijk aan de som van de schijven")
def check_som_schijven(api_response):
    body = api_response.json()
    schijven = body["belasting_per_schijf"]
    totaal = schijven["schijf_1"] + schijven["schijf_2"] + schijven["schijf_3"]
    assert body["te_betalen_belasting"] == pytest.approx(totaal)

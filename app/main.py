"""Belastingdienst demo API.

Korte uitleg:
- Deze API berekent inkomstenbelasting op basis van jaarinkomen en aftrek.
- De API ondersteunt 2 tariefsets voor box 1:
        tot AOW-leeftijd:
            schijf 1: 35,75% t/m EUR 38.883
            schijf 2: 37,56% van EUR 38.883 t/m EUR 78.426
            schijf 3: 49,50% boven EUR 78.426
        vanaf AOW-leeftijd:
            schijf 1: 17,85% t/m EUR 41.123
            schijf 2: 37,56% van EUR 41.123 t/m EUR 78.426
            schijf 3: 49,50% boven EUR 78.426
- Tarieven wijzigen jaarlijks. Pas de constants hieronder aan voor een nieuw jaar.
"""

from typing import Literal

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field


app = FastAPI(title="Belastingdienst Demo API", version="1.0.0")

# Box-1 tarieven tot AOW-leeftijd.
GRENS1_TOT_AOW = 38_883
GRENS2 = 78_426
TARIEF1_TOT_AOW = 0.3575
TARIEF2 = 0.3756
TARIEF3 = 0.4950

# Box-1 tarieven vanaf AOW-leeftijd.
GRENS1_VANAF_AOW = 41_123
TARIEF1_VANAF_AOW = 0.1785


class VerzoekBelasting(BaseModel):
    jaarinkomen: float = Field(gt=0, description="Bruto jaarinkomen in EUR")
    aftrek: float = Field(default=0, ge=0, description="Aftrekposten in EUR")
    aow_leeftijd_bereikt: bool = Field(
        default=False,
        description="True als de AOW-leeftijd is bereikt in het belastingjaar",
    )


class AntwoordBelasting(BaseModel):
    belastbaar_inkomen: float
    te_betalen_belasting: float
    effectief_tarief: float
    schijf: Literal["SCHIJF_1", "SCHIJF_2", "SCHIJF_3"]
    tariefstype: Literal["TOT_AOW", "VANAF_AOW"]
    belasting_per_schijf: dict[str, float]


def bereken_inkomstenbelasting(jaarinkomen: float, aftrek: float, aow_leeftijd_bereikt: bool) -> AntwoordBelasting:
    """Bereken inkomstenbelasting op basis van 3 box-1 schijven en AOW-status."""
    belastbaar_inkomen = max(jaarinkomen - aftrek, 0)

    grens1 = GRENS1_VANAF_AOW if aow_leeftijd_bereikt else GRENS1_TOT_AOW
    tarief1 = TARIEF1_VANAF_AOW if aow_leeftijd_bereikt else TARIEF1_TOT_AOW
    tariefstype = "VANAF_AOW" if aow_leeftijd_bereikt else "TOT_AOW"
    belasting_schijf_1 = 0.0
    belasting_schijf_2 = 0.0
    belasting_schijf_3 = 0.0

    if belastbaar_inkomen <= grens1:
        belasting_schijf_1 = belastbaar_inkomen * tarief1
        schijf = "SCHIJF_1"
    elif belastbaar_inkomen <= GRENS2:
        belasting_schijf_1 = grens1 * tarief1
        belasting_schijf_2 = (belastbaar_inkomen - grens1) * TARIEF2
        schijf = "SCHIJF_2"
    else:
        belasting_schijf_1 = grens1 * tarief1
        belasting_schijf_2 = (GRENS2 - grens1) * TARIEF2
        belasting_schijf_3 = (belastbaar_inkomen - GRENS2) * TARIEF3
        schijf = "SCHIJF_3"

    te_betalen_belasting = belasting_schijf_1 + belasting_schijf_2 + belasting_schijf_3

    effectief_tarief = 0 if jaarinkomen == 0 else round((te_betalen_belasting / jaarinkomen) * 100, 2)
    return AntwoordBelasting(
        belastbaar_inkomen=round(belastbaar_inkomen, 2),
        te_betalen_belasting=round(te_betalen_belasting, 2),
        effectief_tarief=effectief_tarief,
        schijf=schijf,
        tariefstype=tariefstype,
        belasting_per_schijf={
            "schijf_1": round(belasting_schijf_1, 2),
            "schijf_2": round(belasting_schijf_2, 2),
            "schijf_3": round(belasting_schijf_3, 2),
        },
    )


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "service": "belastingdienst-demo-api"}


@app.post("/belasting/bereken", response_model=AntwoordBelasting)
def bereken_belasting(payload: VerzoekBelasting) -> AntwoordBelasting:
    if payload.aftrek > payload.jaarinkomen:
        raise HTTPException(status_code=400, detail="Aftrek kan niet hoger zijn dan jaarinkomen")

    return bereken_inkomstenbelasting(payload.jaarinkomen, payload.aftrek, payload.aow_leeftijd_bereikt)


@app.post("/tax/calculate", response_model=AntwoordBelasting)
def tax_calculate_compat(payload: VerzoekBelasting) -> AntwoordBelasting:
    """Compatibiliteitsroute voor bestaande tests/clients."""
    if payload.aftrek > payload.jaarinkomen:
        raise HTTPException(status_code=400, detail="Aftrek kan niet hoger zijn dan jaarinkomen")

    return bereken_inkomstenbelasting(payload.jaarinkomen, payload.aftrek, payload.aow_leeftijd_bereikt)

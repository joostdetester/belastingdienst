*** Settings ***
Documentation    BDD-stijl API tests voor inkomstenbelasting berekening.
...    Robot Framework ondersteunt BDD native: Given/When/Then worden
...    automatisch als prefix van de keyword-naam genegeerd, waardoor
...    je dezelfde keywords in BDD-zinnen kunt gebruiken.
Resource    resources/api.resource
Library     Collections

Suite Setup    Create API Session

*** Test Cases ***
Gezondheidscheck van de API
    Given de belasting API beschikbaar is
    Then is de status ok

Belasting berekening valt in schijf 1 tot AOW
    Given een belastingplichtige met jaarinkomen 25000 en aftrek 0
    And de belastingplichtige heeft de AOW-leeftijd niet bereikt
    When de belasting wordt berekend
    Then is de te betalen belasting groter dan 0
    And valt de berekening in schijf    SCHIJF_1
    And is het tariefstype    TOT_AOW

Belasting berekening valt in schijf 2 tot AOW
    Given een belastingplichtige met jaarinkomen 55000 en aftrek 5000
    And de belastingplichtige heeft de AOW-leeftijd niet bereikt
    When de belasting wordt berekend
    Then is de te betalen belasting groter dan 0
    And valt de berekening in schijf    SCHIJF_2
    And is het tariefstype    TOT_AOW
    And is het bedrag in schijf 1 groter dan 0
    And is het bedrag in schijf 2 groter dan 0
    And is het bedrag in schijf 3 gelijk aan    0
    And is de totale belasting gelijk aan de som van de schijven

Belasting berekening valt in schijf 3 tot AOW
    Given een belastingplichtige met jaarinkomen 120000 en aftrek 10000
    And de belastingplichtige heeft de AOW-leeftijd niet bereikt
    When de belasting wordt berekend
    Then is de te betalen belasting groter dan 0
    And valt de berekening in schijf    SCHIJF_3
    And is het bedrag in schijf 1 groter dan 0
    And is het bedrag in schijf 2 groter dan 0
    And is het bedrag in schijf 3 groter dan 0

Belasting berekening voor iemand boven de AOW-leeftijd
    Given een belastingplichtige met jaarinkomen 30000 en aftrek 0
    And de belastingplichtige heeft de AOW-leeftijd bereikt
    When de belasting wordt berekend
    Then is de te betalen belasting exact    5355.0
    And valt de berekening in schijf    SCHIJF_1
    And is het tariefstype    VANAF_AOW
    And is het bedrag in schijf 1 gelijk aan    5355.0
    And is het bedrag in schijf 2 gelijk aan    0
    And is het bedrag in schijf 3 gelijk aan    0

Aftrek hoger dan inkomen wordt geweigerd
    Given een belastingplichtige met jaarinkomen 20000 en aftrek 25000
    And de belastingplichtige heeft de AOW-leeftijd niet bereikt
    When de belasting wordt berekend
    Then geeft de API een foutmelding    Aftrek kan niet hoger zijn dan jaarinkomen

*** Keywords ***
De belasting API beschikbaar is
    ${response}=    GET On Session    belasting_api    /health
    Status Should Be    200    ${response}

Is de status ok
    ${response}=    GET On Session    belasting_api    /health
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal    ${body}[status]    ok

Een belastingplichtige met jaarinkomen ${inkomen} en aftrek ${aftrek}
    Set Suite Variable    ${JAARINKOMEN}    ${inkomen}
    Set Suite Variable    ${AFTREK}         ${aftrek}
    Set Suite Variable    ${AOW}            ${False}

De belastingplichtige heeft de AOW-leeftijd niet bereikt
    Set Suite Variable    ${AOW}    ${False}

De belastingplichtige heeft de AOW-leeftijd bereikt
    Set Suite Variable    ${AOW}    ${True}

De belasting wordt berekend
    ${response}=    POST Belasting Berekening    ${JAARINKOMEN}    ${AFTREK}    ${AOW}
    Set Suite Variable    ${RESPONSE}    ${response}

Is de te betalen belasting groter dan 0
    Status Should Be    200    ${RESPONSE}
    Should Be True    ${RESPONSE.json()}[te_betalen_belasting] > 0

Is de te betalen belasting exact
    [Arguments]    ${bedrag}
    Status Should Be    200    ${RESPONSE}
    Should Be Equal As Numbers    ${RESPONSE.json()}[te_betalen_belasting]    ${bedrag}

Valt de berekening in schijf
    [Arguments]    ${verwachte_schijf}
    Should Be Equal    ${RESPONSE.json()}[schijf]    ${verwachte_schijf}

Is het tariefstype
    [Arguments]    ${verwacht_type}
    Should Be Equal    ${RESPONSE.json()}[tariefstype]    ${verwacht_type}

Geeft de API een foutmelding
    [Arguments]    ${bericht}
    Status Should Be    400    ${RESPONSE}
    Should Be Equal    ${RESPONSE.json()}[detail]    ${bericht}

Is het bedrag in schijf 1 groter dan 0
    Should Be True    ${RESPONSE.json()}[belasting_per_schijf][schijf_1] > 0

Is het bedrag in schijf 2 groter dan 0
    Should Be True    ${RESPONSE.json()}[belasting_per_schijf][schijf_2] > 0

Is het bedrag in schijf 3 groter dan 0
    Should Be True    ${RESPONSE.json()}[belasting_per_schijf][schijf_3] > 0

Is het bedrag in schijf 1 gelijk aan
    [Arguments]    ${bedrag}
    Should Be Equal As Numbers    ${RESPONSE.json()}[belasting_per_schijf][schijf_1]    ${bedrag}

Is het bedrag in schijf 2 gelijk aan
    [Arguments]    ${bedrag}
    Should Be Equal As Numbers    ${RESPONSE.json()}[belasting_per_schijf][schijf_2]    ${bedrag}

Is het bedrag in schijf 3 gelijk aan
    [Arguments]    ${bedrag}
    Should Be Equal As Numbers    ${RESPONSE.json()}[belasting_per_schijf][schijf_3]    ${bedrag}

Is de totale belasting gelijk aan de som van de schijven
    ${s1}=    Set Variable    ${RESPONSE.json()}[belasting_per_schijf][schijf_1]
    ${s2}=    Set Variable    ${RESPONSE.json()}[belasting_per_schijf][schijf_2]
    ${s3}=    Set Variable    ${RESPONSE.json()}[belasting_per_schijf][schijf_3]
    ${som}=    Evaluate    ${s1} + ${s2} + ${s3}
    Should Be Equal As Numbers    ${RESPONSE.json()}[te_betalen_belasting]    ${som}

*** Settings ***
Documentation    API tests for Belastingdienst demo service.
Resource    resources/api.resource
Library    Collections

Suite Setup    Create API Session

*** Test Cases ***
Health Endpoint Is Available
    ${response}=    GET On Session    belasting_api    /health
    Status Should Be    200    ${response}
    Dictionary Should Contain Item    ${response.json()}    status    ok

Bereken Belasting Voor Schijf 2
    ${response}=    POST Belasting Berekening    55000    5000    ${False}
    Status Should Be    200    ${response}
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal    ${body}[schijf]    SCHIJF_2
    Should Be Equal    ${body}[tariefstype]    TOT_AOW
    Should Be True    ${body}[belasting_per_schijf][schijf_1] > 0
    Should Be True    ${body}[belasting_per_schijf][schijf_2] > 0
    Should Be Equal As Numbers    ${body}[belasting_per_schijf][schijf_3]    0
    Should Be True    ${body}[te_betalen_belasting] > 0

Bereken Belasting Voor Schijf 3
    ${response}=    POST Belasting Berekening    120000    10000    ${False}
    Status Should Be    200    ${response}
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal    ${body}[schijf]    SCHIJF_3
    Should Be Equal    ${body}[tariefstype]    TOT_AOW
    Should Be True    ${body}[belasting_per_schijf][schijf_1] > 0
    Should Be True    ${body}[belasting_per_schijf][schijf_2] > 0
    Should Be True    ${body}[belasting_per_schijf][schijf_3] > 0
    Should Be True    ${body}[te_betalen_belasting] > 0

Bereken Belasting Vanaf AOW Leeftijd
    ${response}=    POST Belasting Berekening    30000    0    ${True}
    Status Should Be    200    ${response}
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal    ${body}[schijf]    SCHIJF_1
    Should Be Equal    ${body}[tariefstype]    VANAF_AOW
    Should Be Equal As Numbers    ${body}[te_betalen_belasting]    5355.0
    Should Be Equal As Numbers    ${body}[belasting_per_schijf][schijf_1]    5355.0
    Should Be Equal As Numbers    ${body}[belasting_per_schijf][schijf_2]    0
    Should Be Equal As Numbers    ${body}[belasting_per_schijf][schijf_3]    0

Reject Deductible Higher Than Income
    ${response}=    POST Belasting Berekening    20000    25000    ${False}
    Status Should Be    400    ${response}
    ${body}=    Set Variable    ${response.json()}
    Should Be Equal    ${body}[detail]    Aftrek kan niet hoger zijn dan jaarinkomen

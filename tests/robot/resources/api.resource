*** Settings ***
Library    RequestsLibrary
Library    OperatingSystem

*** Keywords ***
Create API Session
    ${base_url}=    Get Environment Variable    BASE_URL    http://127.0.0.1:8001
    Set Suite Variable    ${BASE_URL}    ${base_url}
    Create Session    belasting_api    ${BASE_URL}

POST Belasting Berekening
    [Arguments]    ${jaarinkomen}    ${aftrek}    ${aow_leeftijd_bereikt}=${False}
    ${payload}=    Create Dictionary    jaarinkomen=${jaarinkomen}    aftrek=${aftrek}    aow_leeftijd_bereikt=${aow_leeftijd_bereikt}
    ${response}=    POST On Session    belasting_api    /belasting/bereken    json=${payload}    expected_status=any
    RETURN    ${response}

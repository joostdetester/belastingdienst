Feature: Inkomstenbelasting berekening
  Als belastingplichtige
  Wil ik weten hoeveel belasting ik moet betalen
  Zodat ik mijn belastingaangifte correct kan invullen

  Scenario: Gezondheidscheck van de API
    Given de belasting API beschikbaar is
    Then is de status "ok"

  Scenario: Belasting berekening valt in schijf 1 (tot AOW)
    Given een belastingplichtige met jaarinkomen 25000 en aftrek 0
    And de belastingplichtige heeft de AOW-leeftijd niet bereikt
    When de belasting wordt berekend
    Then is de te betalen belasting groter dan 0
    And valt de berekening in schijf "SCHIJF_1"
    And is het tariefstype "TOT_AOW"

  Scenario: Belasting berekening valt in schijf 2 (tot AOW)
    Given een belastingplichtige met jaarinkomen 55000 en aftrek 5000
    And de belastingplichtige heeft de AOW-leeftijd niet bereikt
    When de belasting wordt berekend
    Then is de te betalen belasting groter dan 0
    And valt de berekening in schijf "SCHIJF_2"
    And is het tariefstype "TOT_AOW"
    And is het bedrag in schijf 1 groter dan 0
    And is het bedrag in schijf 2 groter dan 0
    And is het bedrag in schijf 3 gelijk aan 0
    And is de totale belasting gelijk aan de som van de schijven

  Scenario: Belasting berekening valt in schijf 3 (tot AOW)
    Given een belastingplichtige met jaarinkomen 120000 en aftrek 10000
    And de belastingplichtige heeft de AOW-leeftijd niet bereikt
    When de belasting wordt berekend
    Then is de te betalen belasting groter dan 0
    And valt de berekening in schijf "SCHIJF_3"
    And is het bedrag in schijf 1 groter dan 0
    And is het bedrag in schijf 2 groter dan 0
    And is het bedrag in schijf 3 groter dan 0

  Scenario: Belasting berekening voor iemand boven de AOW-leeftijd
    Given een belastingplichtige met jaarinkomen 30000 en aftrek 0
    And de belastingplichtige heeft de AOW-leeftijd bereikt
    When de belasting wordt berekend
    Then is de te betalen belasting 5355.0
    And valt de berekening in schijf "SCHIJF_1"
    And is het tariefstype "VANAF_AOW"
    And is het bedrag in schijf 1 gelijk aan 5355.0
    And is het bedrag in schijf 2 gelijk aan 0
    And is het bedrag in schijf 3 gelijk aan 0

  Scenario: Aftrek hoger dan inkomen wordt geweigerd
    Given een belastingplichtige met jaarinkomen 20000 en aftrek 25000
    And de belastingplichtige heeft de AOW-leeftijd niet bereikt
    When de belasting wordt berekend
    Then geeft de API een foutmelding "Aftrek kan niet hoger zijn dan jaarinkomen"

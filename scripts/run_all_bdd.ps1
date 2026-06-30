$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$python = Join-Path $projectRoot '.venv\Scripts\python.exe'
$healthUrl = 'http://127.0.0.1:8001/health'
$env:BASE_URL = 'http://127.0.0.1:8001'

New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'results') | Out-Null

# Run only BDD pytest file
& $python -m pytest --junitxml=results/pytest-bdd-junit.xml tests/pytest/test_api_bdd.py
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$apiProcess = Start-Process -FilePath $python -ArgumentList @(
    '-m',
    'uvicorn',
    'app.main:app',
    '--host',
    '127.0.0.1',
    '--port',
    '8001'
) -PassThru

try {
    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        try {
            Invoke-WebRequest -Uri $healthUrl -UseBasicParsing | Out-Null
            break
        }
        catch {
            Start-Sleep -Milliseconds 500
        }
    }

    # Run only Robot BDD file and write BDD-specific reports + xUnit for CI
    & $python -m robot --output results/output-bdd.xml --log results/log-bdd.html --report results/report-bdd.html --xunit results/robot-bdd-xunit.xml tests/robot/api_tax_bdd.robot
    exit $LASTEXITCODE
}
finally {
    if ($apiProcess -and -not $apiProcess.HasExited) {
        Stop-Process -Id $apiProcess.Id
    }
}

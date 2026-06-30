$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$python = Join-Path $projectRoot '.venv\Scripts\python.exe'
$healthUrl = 'http://127.0.0.1:8001/health'
$env:BASE_URL = 'http://127.0.0.1:8001'

New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'results') | Out-Null

& $python -m pytest --junitxml=results/pytest-junit.xml
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

    # Run Robot Framework (all Robot suites) and produce xUnit for CI + html reports
    & $python -m robot --output results/output.xml --log results/log.html --report results/report.html --xunit results/robot-xunit.xml tests/robot
    exit $LASTEXITCODE
}
finally {
    if ($apiProcess -and -not $apiProcess.HasExited) {
        Stop-Process -Id $apiProcess.Id
    }
}

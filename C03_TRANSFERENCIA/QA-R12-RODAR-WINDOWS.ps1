# EXO-MURIM R12 - Run on a Windows PC with Godot 4.6.2 Standard.
# Usage: powershell -ExecutionPolicy Bypass -File .\C03_TRANSFERENCIA\QA-R12-RODAR-WINDOWS.ps1 -GodotExe "C:\path\Godot_v4.6.2-stable_win64.exe"
param(
    [Parameter(Mandatory=$true)] [string]$GodotExe,
    [string]$ProjectPath = ""
)
$ErrorActionPreference = "Continue"
if ($ProjectPath -eq "") { $ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path }
if (-not (Test-Path $GodotExe)) { throw "Nao encontrei Godot em $GodotExe" }
if (-not (Test-Path (Join-Path $ProjectPath "project.godot"))) { throw "Nao encontrei project.godot em $ProjectPath" }
$LogDir = Join-Path $PSScriptRoot "LOGS-R12-NATIVOS"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$jobs = @(
    @{Name="import"; Args=@("--headless", "--editor", "--path", $ProjectPath, "--import", "--rendering-method", "gl_compatibility")},
    @{Name="parser"; Args=@("--headless", "--path", $ProjectPath, "--script", "res://convergence/tests/qa_c03_r12_native.gd")},
    @{Name="terrain_r11"; Args=@("--headless", "--path", $ProjectPath, "--script", "res://convergence/tests/qa_c03_r11_native.gd")},
    @{Name="visual_r10"; Args=@("--headless", "--path", $ProjectPath, "--script", "res://convergence/tests/qa_c03_r10_native.gd")},
    @{Name="martial_r9"; Args=@("--headless", "--path", $ProjectPath, "--script", "res://convergence/tests/qa_c03_r9_native.gd")},
    @{Name="dungeon_r6"; Args=@("--headless", "--path", $ProjectPath, "--script", "res://exo_dungeon/tests/qa_c03_r6_native.gd")}
)
foreach ($job in $jobs) {
    $name = $job.Name
    $log = Join-Path $LogDir "$name.log"
    Write-Host "Executando: $name"
    $callArgs = $job.Args
    & $GodotExe @callArgs *> $log
    $code = $LASTEXITCODE
    Write-Host "$name => exit=$code log=$log"
    if ($code -ne 0) { Write-Warning "Corrigir erros de $name antes de declarar QA aprovado" }
}
Write-Host "Logs: $LogDir"
Write-Host "Ainda e necessario testar F5, saves, region travel e FPS manualmente. Nao apagar dados originais."

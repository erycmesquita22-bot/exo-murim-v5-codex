# EXO-MURIM R13 / Native Godot 4.6.2 Compatibility QA. Run only on an extracted, isolated COPY.
# PowerShell: .\C03_TRANSFERENCIA\QA-R13-RODAR-WINDOWS.ps1 -GodotExe 'C:\Godot\Godot_v4.6.2-stable_win64.exe'
param(
  [Parameter(Mandatory=$true)][string]$GodotExe,
  [string]$ProjectPath = ""
)
$ErrorActionPreference = 'Stop'
if (-not $ProjectPath) { $ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
$GodotExe = (Resolve-Path $GodotExe).Path
if (-not (Test-Path (Join-Path $ProjectPath 'project.godot'))) { throw 'project.godot ausente' }
$cfg = Get-Content (Join-Path $ProjectPath 'project.godot') -Raw
if ($cfg -notmatch 'config/custom_user_dir_name="EXO-Murim-Convergencia-03-ALFA-R13-QA"') { throw 'Namespace de save inseguro ou diferente da R13' }
$logs = Join-Path $PSScriptRoot 'QA-R13-LOGS'
New-Item -ItemType Directory -Force $logs | Out-Null
$version = (& $GodotExe --version 2>&1 | Out-String).Trim()
$version | Out-File -Encoding utf8 (Join-Path $logs 'version.txt')
if ($version -notmatch '^4\.6\.2') { throw "Godot 4.6.2 obrigatoria, encontrado: $version" }
$jobs = @(
  @{Name='01_import'; Args=@('--headless','--editor','--path',$ProjectPath,'--import','--rendering-method','gl_compatibility')},
  @{Name='02_parse_r12'; Args=@('--headless','--path',$ProjectPath,'--script','res://convergence/tests/qa_c03_r12_native.gd','--rendering-method','gl_compatibility')},
  @{Name='03_bootstrap_r13'; Args=@('--headless','--path',$ProjectPath,'--script','res://convergence/tests/qa_c03_r13_bootstrap_native.gd','--rendering-method','gl_compatibility')},
  @{Name='04_core_01p'; Args=@('--headless','--path',$ProjectPath,'--script','res://exo_core/tests/qa_persistence01p.gd','--rendering-method','gl_compatibility')},
  @{Name='05_terrain_r11'; Args=@('--headless','--path',$ProjectPath,'--script','res://convergence/tests/qa_c03_r11_native.gd','--rendering-method','gl_compatibility')},
  @{Name='06_humanoids_r10'; Args=@('--headless','--path',$ProjectPath,'--script','res://convergence/tests/qa_c03_r10_native.gd','--rendering-method','gl_compatibility')},
  @{Name='07_martial_r9'; Args=@('--headless','--path',$ProjectPath,'--script','res://convergence/tests/qa_c03_r9_native.gd','--rendering-method','gl_compatibility')},
  @{Name='08_martial_r8'; Args=@('--headless','--path',$ProjectPath,'--script','res://convergence/tests/qa_c03_r8_native.gd','--rendering-method','gl_compatibility')},
  @{Name='09_forja_r7'; Args=@('--headless','--path',$ProjectPath,'--script','res://exo_monumental/tests/qa_c03_r7_native.gd','--rendering-method','gl_compatibility')},
  @{Name='10_dungeon_r6'; Args=@('--headless','--path',$ProjectPath,'--script','res://exo_dungeon/tests/qa_c03_r6_native.gd','--rendering-method','gl_compatibility')},
  @{Name='11_items_r3'; Args=@('--headless','--path',$ProjectPath,'--script','res://exo_items/tests/qa_atomic_r3_native.gd','--rendering-method','gl_compatibility')}
)
$results = @()
foreach ($job in $jobs) {
  $stdout = Join-Path $logs ($job.Name + '.stdout.log')
  $stderr = Join-Path $logs ($job.Name + '.stderr.log')
  $p = Start-Process -FilePath $GodotExe -ArgumentList $job.Args -PassThru -NoNewWindow -RedirectStandardOutput $stdout -RedirectStandardError $stderr
  $ended = $p.WaitForExit(300000)
  if (-not $ended) { $p.Kill(); $p.WaitForExit() }
  $out = ((Get-Content $stdout -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content $stderr -Raw -ErrorAction SilentlyContinue))
  $engineErrors = [regex]::Matches($out,'(?im)^(?:ERROR|SCRIPT ERROR|Parse Error|Failed to load|E 0:).*').Count
  $result = [ordered]@{suite=$job.Name;exit_code=$p.ExitCode;timeout=(!$ended);engine_error_lines=$engineErrors;status='FAIL_REVIEW'}
  if ($ended -and $p.ExitCode -eq 0 -and $engineErrors -eq 0) {$result.status='PASS_NATIVE_LOG_REVIEW'}
  $results += [pscustomobject]$result
  Write-Host ($job.Name + ' => ' + $result.status + ' exit=' + $p.ExitCode + ' engine_errors=' + $engineErrors)
  if ($result.status -eq 'FAIL_REVIEW') { Write-Warning 'Examine logs e corrija causa-raiz antes de homologar.' }
}
$results | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 (Join-Path $logs 'results.json')
Write-Host 'IMPORTANTE: headless PASS nao comprova F5, gameplay, saves pessoais, shaders GPU ou FPS.'
Write-Host 'Testar manualmente em projeto isolado: F5 -> personagem -> campanha procedural -> movimento -> NPC/combate -> troca de regiao -> salvar/reabrir.'

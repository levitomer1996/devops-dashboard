param(
  [string]$Url = "http://4.209.26.155:3001/health",
  [string]$ExpectedStatus = "ok",
  [string]$Namespace = "devops-dashboard",
  [string]$Deployment = "users-service",
  [int]$TimeoutSec = 8,
  [int]$LogTail = 200,               # how many log lines per pod to print
  [int]$LogSinceSeconds = 0,         # 0 = disabled; otherwise only logs since N seconds
  [string]$LogContainer = "",        # optional specific container name
  [string]$SaveLogsDir = ""          # optional folder path to also save logs
)

$ErrorActionPreference = "Stop"

function Test-Health {
  param([string]$u, [int]$t, [string]$expected)
  try {
    $res = Invoke-RestMethod -Uri $u -TimeoutSec $t -UseBasicParsing
    if ($null -eq $res) {
      Write-Host "FAIL - empty response"
      return $false
    }
    $status = $res.status
    if ($status -eq $expected) {
      Write-Host "OK - users-service healthy ($u) -> status: $status" -ForegroundColor Green
      return $true
    } else {
      Write-Host ("FAIL - users-service not OK ({0}) -> got: {1}" -f $u, ($res | ConvertTo-Json -Compress)) -ForegroundColor Red
      return $false
    }
  } catch {
    Write-Host "FAIL - request failed: $($_.Exception.Message)" -ForegroundColor Red
    return $false
  }
}

function Get-ReplicaInfo {
  param([string]$ns, [string]$dep)
  $info = @{
    desired   = 0
    ready     = 0
    available = 0
    pods      = @()
  }
  try {
    $deploy = kubectl get deployment $dep -n $ns -o json | ConvertFrom-Json
    $info.desired   = $deploy.spec.replicas
    $info.available = $deploy.status.availableReplicas
    $info.ready     = $deploy.status.readyReplicas
    Write-Host ("Deployment replicas -> desired:{0} ready:{1} available:{2}" -f $info.desired, $info.ready, $info.available)

    Write-Host "Pod list:"
    $pods = kubectl get pods -n $ns -l "app=$dep" -o json | ConvertFrom-Json
    foreach ($p in $pods.items) {
      $podName = $p.metadata.name
      $phase   = $p.status.phase
      $info.pods += $podName
      Write-Host (" - {0} ({1})" -f $podName, $phase)
    }
  } catch {
    Write-Host "Could not get replica info: $($_.Exception.Message)"
  }
  return $info
}

function Show-And-Save-Logs {
  param(
    [string]$ns,
    [string[]]$podNames,
    [int]$tail,
    [int]$sinceSec,
    [string]$container,
    [string]$saveDir
  )

  if ($podNames.Count -eq 0) {
    Write-Host "No pods found to fetch logs."
    return
  }

  if ($saveDir -and -not (Test-Path $saveDir)) {
    New-Item -ItemType Directory -Path $saveDir -Force | Out-Null
  }

  Write-Host ""
  Write-Host "===== Service logs (last $tail lines per pod) ====="
  foreach ($pod in $podNames) {
    $args = @("logs", $pod, "-n", $ns, "--tail=$tail")
    if ($sinceSec -gt 0) { $args += "--since=${sinceSec}s" }
    if ($container)      { $args += @("--container", $container) }

    Write-Host ""
    Write-Host "----- $pod -----"
    try {
      $text = & kubectl @args
      $text | Out-String | Write-Host

      if ($saveDir) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $file  = Join-Path $saveDir ("{0}-{1}.log" -f $pod, $stamp)
        $text | Out-File -FilePath $file -Encoding utf8
      }
    } catch {
     Write-Host ("Failed to get logs for {0}: {1}" -f $pod, $_.Exception.Message)

    }
  }
}

# --- main run ---
$ok   = Test-Health -u $Url -t $TimeoutSec -expected $ExpectedStatus
$info = Get-ReplicaInfo -ns $Namespace -dep $Deployment

# Always show logs at the end (your request)
Show-And-Save-Logs -ns $Namespace `
  -podNames $info.pods `
  -tail $LogTail `
  -sinceSec $LogSinceSeconds `
  -container $LogContainer `
  -saveDir $SaveLogsDir

if (-not $ok) { exit 1 }

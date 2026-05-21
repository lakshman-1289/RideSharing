# run-project.ps1
# Smart Ride Sharing System Launcher

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "        SMART RIDE SHARING SYSTEM LAUNCHER               " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Detect Maven
$mvnCmd = "mvn"
$hasGlobalMvn = $false

try {
    $null = Get-Command mvn -ErrorAction SilentlyContinue
    if ($?) {
        $hasGlobalMvn = $true
        Write-Host "[OK] Global Maven detected." -ForegroundColor Green
    }
} catch {}

$localMavenDir = Join-Path $PSScriptRoot ".maven"
$localMvnCmd = Join-Path $localMavenDir "apache-maven-3.9.6\bin\mvn.cmd"

if (-not $hasGlobalMvn) {
    if (-not (Test-Path $localMvnCmd)) {
        Write-Host "[INFO] Maven not found globally. Downloading local Apache Maven 3.9.6..." -ForegroundColor Yellow
        if (-not (Test-Path $localMavenDir)) {
            New-Item -ItemType Directory -Force -Path $localMavenDir | Out-Null
        }
        $zipFile = Join-Path $PSScriptRoot "maven.zip"
        $downloadUrl = "https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip"
        
        Write-Host "Downloading Maven archive..." -ForegroundColor Cyan
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
        
        Write-Host "Extracting Maven archive..." -ForegroundColor Cyan
        Expand-Archive -Path $zipFile -DestinationPath $localMavenDir -Force
        Remove-Item $zipFile -Force
        Write-Host "[OK] Local Maven configured successfully." -ForegroundColor Green
    }
    $mvnCmd = $localMvnCmd
    Write-Host "[OK] Using local Maven at: $mvnCmd" -ForegroundColor Green
}

# 2. Build Services Function
function Start-ServiceWindow {
    param (
        [string]$ServiceName,
        [string]$ServiceFolder,
        [string]$MvnPath,
        [int]$DelaySeconds
    )
    $folderPath = Join-Path $PSScriptRoot $ServiceFolder
    Write-Host ""
    Write-Host "Starting $ServiceName..." -ForegroundColor Cyan
    
    # Run clean install if target folder doesn't exist (first-time run)
    $targetPath = Join-Path $folderPath "target"
    if (-not (Test-Path $targetPath)) {
        Write-Host "Building $ServiceName (first-time compile, this may take a minute)..." -ForegroundColor Yellow
        Start-Process powershell -ArgumentList "-Command", "Write-Host 'Building $ServiceName...'; & '$MvnPath' clean install" -WorkingDirectory $folderPath -Wait
    }
    
    # Launch the Spring Boot service in a new window
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Starting $ServiceName...'; & '$MvnPath' spring-boot:run" -WorkingDirectory $folderPath
    
    if ($DelaySeconds -gt 0) {
        Write-Host "Waiting $DelaySeconds seconds for $ServiceName to initialize..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $DelaySeconds
    }
}

# 3. Start Backend Services sequentially
Start-ServiceWindow -ServiceName "Eureka Discovery Server" -ServiceFolder "eureka-server" -MvnPath $mvnCmd -DelaySeconds 12
Start-ServiceWindow -ServiceName "User Service" -ServiceFolder "user-service" -MvnPath $mvnCmd -DelaySeconds 8
Start-ServiceWindow -ServiceName "Ride Service" -ServiceFolder "ride-service" -MvnPath $mvnCmd -DelaySeconds 8
Start-ServiceWindow -ServiceName "Payment Service" -ServiceFolder "payment-service" -MvnPath $mvnCmd -DelaySeconds 8
Start-ServiceWindow -ServiceName "API Gateway Service" -ServiceFolder "api-gateway-service" -MvnPath $mvnCmd -DelaySeconds 5

# 4. Handle Frontend
Write-Host ""
Write-Host "Checking Frontend..." -ForegroundColor Cyan
$frontendFolder = Join-Path $PSScriptRoot "fronted_ride_share"
$nodeModules = Join-Path $frontendFolder "node_modules"

$hasNpm = $false
try {
    $null = Get-Command npm -ErrorAction SilentlyContinue
    if ($?) {
        $hasNpm = $true
    }
} catch {}

if ($hasNpm) {
    if (-not (Test-Path $nodeModules)) {
        Write-Host "Frontend dependencies not found. Installing node_modules (npm install)..." -ForegroundColor Yellow
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Installing dependencies...'; npm install" -WorkingDirectory $frontendFolder -Wait
    }
    
    Write-Host "Starting Frontend App..." -ForegroundColor Green
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Starting React Frontend...'; npm run dev" -WorkingDirectory $frontendFolder
} else {
    Write-Warning "npm/Node.js is not detected on your system. Please install Node.js (https://nodejs.org) to run the frontend."
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "All startup actions triggered!" -ForegroundColor Green
Write-Host "- Eureka Server: http://localhost:8761" -ForegroundColor Yellow
Write-Host "- React Frontend: http://localhost:5173" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green

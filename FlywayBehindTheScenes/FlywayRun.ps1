<#
.SYNOPSIS
  Auto-generate, validate, and stage Flyway migration scripts in one go. Can be used by developers that do not know Flyway exists but use the migration scripts for review. Not a suggested workflow but can be used when required by the client. Eases cultural changes with an easier learning curve.
.DESCRIPTION
  1. Validates environment and prerequisites.
  2. Ensures you’ve run Flyway_GitSync today (optionally runs it).
  3. Runs Flyway diff/model, stages schema-model updates.
  4. Runs Flyway diff/generate, stages new migration script (“Stating Re-name me”).
  5. Runs Flyway migrate against your shadow DB.
  6. Sends an email notification that scripts are ready for review.
.NOTES
  Requires:
    • flyway.toml in project root
    • Flyway CLI v11 installed
    • Git CLI
    • SMTP server info configured below
#>
[CmdletBinding()]
param()

# ► Capture and enforce project root ◄
$projectPath = (Get-Location).Path
if (-not (Test-Path "$projectPath/flyway.toml")) {
    throw "Run from Flyway project root (missing flyway.toml)."
}
Set-Location $projectPath

#region ► Section 1: Validation checks ◄
try {
    if (-not (Get-Command flyway -ErrorAction SilentlyContinue)) {
        throw "Flyway CLI not found."
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "Git CLI not found."
    }
    $branch = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($branch -notmatch '^Feature[A-Za-z0-9\-]+$') {
        throw "Checkout a Feature-branch first (found '$branch')."
    }
    Write-Host "On branch $branch, project root looks good." -ForegroundColor Green
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
#endregion

#region ► Section 1b: Ensure GitSync ran today ◄
$stampFile = "$PSScriptRoot\.flyway-gitsync-ran"
$today = (Get-Date).Date
$ranToday = (Test-Path $stampFile) -and ((Get-Item $stampFile).LastWriteTime.Date -eq $today)

if (-not $ranToday) {
    $runSync = Read-Host "Flyway_GitSync has not run today. Run it now? (Y/N)"
    if ($runSync -match '^[Yy]') {
        & "$PSScriptRoot\Flyway_GitSync.ps1"
        # update stamp
        New-Item -ItemType File -Path $stampFile -Force | Out-Null
    }
}
#endregion

# Run Flyway auth command
flyway auth -IAgreeToTheEula

Write-Host ""
Write-Host "A web browser should have opened for login. Please complete the authentication."
Write-Host "Once you've finished logging in, type 'Y' and press Enter to continue..."
do {
    $input = Read-Host "Continue? (Y to proceed)"
} until ($input -eq 'Y')

Write-Host "Authentication complete. Continuing with the rest of the script..."

#region ► Section 3: Core Flyway loop ◄
$schemaDir = "schema-model"
$migrationsDir = "migrations"
$devEnv = "development"
$shadowEnv = "shadow"
$ts = Get-Date -Format "yyyyMMddHHmmss"

# 3.1 Diff model → schema-model
Write-Host "Diff model against $devEnv → $schemaDir"
flyway `
    "-configFiles=flyway.toml" `
    diff model `
    "-diff.source=$devEnv" `
    "-diff.target=schemaModel"

# 3.2 Stage schema-model changes
git add $schemaDir
# git commit -m "Update schema model @ $ts" -q

# 3.3 Diff generate → migrations (“Stating Re-name me”)
Write-Host "Diff generate → $migrationsDir"
flyway `
    "-workingDirectory=$projectPath" `
    diff generate `
    "-diff.source=schemaModel" `
    "-diff.target=migrations" `
    "-generate.types=versioned" `
    "-diff.buildEnvironment=$shadowEnv"

# — now find that one new script
$newScript = Get-ChildItem $migrationsDir -Filter '*.sql' |
Where-Object { $_.LastWriteTime -ge $genTime } |
Sort-Object LastWriteTime |
Select-Object -Last 1
#
# Prepend your review comment (commented out for now)
$devName = $env:USERNAME
$reviewComment = "-- This has been reviewed by a $devName before pushing: No`r`n"
$origContent = Get-Content $newScript.FullName
Set-Content $newScript.FullName -Value ($reviewComment + $origContent)

# 3.4 Stage new migration script
git add $migrationsDir
# git commit -m "Add migration script placeholder @ $ts" -q

# 3.5 Migrate against shadow for verification
Write-Host "Migrate against $shadowEnv"
flyway `
    "-workingDirectory=$projectPath" `
    migrate `
    "-environment=$shadowEnv"

# 3.6 Send email notification
# — configure your SMTP server below:
# $smtpServer = 'smtp.yourcompany.com'
# $from       = 'flyway@yourcompany.com'
# $to         = (git config user.email)
# $subject    = "FlywayRun_Update complete for $branch"
# $body       = @"
# Hello,
#
# Your Flyway migration scripts have been generated and staged:
#   • Schema model updated
#   • New migration script placeholder
#
# Please review, rename the script, and commit/push your changes.
#
# – Flyway Automation
# "@
#
# Send-MailMessage `
#   -SmtpServer $smtpServer `
#   -From $from `
#   -To $to `
#   -Subject $subject `
#   -Body $body

Write-Host "🎉 FlywayRun_Update finished. Check your repo for staged changes." -ForegroundColor Green
#endregion
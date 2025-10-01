<#
.SYNOPSIS
  Syncs your Feature branch with origin + applies migrations to dev.
.DESCRIPTION
  1. Validates environment (same as FlywayRun_Update), using the current working directory.
  2. Pulls & pushes via Git.
  3. Restores any local changes in schema-model and migrations to match remote.
  4. Runs Flyway migrate on development DB (if enabled).
  5. Updates stamp file so FlywayRun_Update knows it ran.
.NOTES
  • Requires flyway.toml in your project root.
#>
[CmdletBinding()]
param()

# ► Capture project root up front ◄
$projectPath = (Get-Location).Path
$schemaDir = 'schema-model'
$migrationsDir = 'migrations'

#region ► Validation ◄
try {
    if (-not (Test-Path "$projectPath/flyway.toml")) {
        throw "Run from Flyway project root (missing flyway.toml)."
    }
    if (-not (Get-Command flyway -ErrorAction SilentlyContinue)) {
        throw "Flyway CLI not found."
    }
    if (-not (Get-Command git    -ErrorAction SilentlyContinue)) {
        throw "Git CLI not found."
    }

    # ensure we’re in the project root
    Set-Location $projectPath

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

# Run Flyway auth command
flyway auth -IAgreeToTheEula

Write-Host ""
Write-Host "A web browser should have opened for login. Please complete the authentication."
Write-Host "Once you've finished logging in, type 'Y' and press Enter to continue..."
do {
    $input = Read-Host "Continue? (Y to proceed)"
} until ($input -eq 'Y')

Write-Host "Authentication complete. Continuing with the rest of the script..."

#region ► Git sync ◄
Write-Host "Pulling origin/$branch"
git pull origin $branch
# Force pull feature branch to overwrite remote
# git fetch origin
# git reset --hard origin/FeatureA

Write-Host "Restoring local schema-model & migrations to match origin/$branch"
git fetch origin $branch
git restore --source=origin/$branch -- $schemaDir $migrationsDir

Write-Host "Pushing any local commits"
git push origin $branch
#endregion

#region ► Flyway migrate to dev ◄
# Write-Host "▶Migrate development DB"
# flyway `
#     "-workingDirectory=$projectPath" `
#     migrate `
#     "-environment=development" `
#     "-baselineOnMigrate=true"
#endregion

#region ► Stamp completion ◄
$stampFile = "$PSScriptRoot\.flyway-gitsync-ran"
New-Item -ItemType File -Path $stampFile -Force | Out-Null
Write-Host "Flyway_GitSync complete and stamped." -ForegroundColor Green
#endregion
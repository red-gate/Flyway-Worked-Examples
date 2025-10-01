<#
.SYNOPSIS
    Consolidates Flyway reports by comparing pre- and post-release snapshots.

.DESCRIPTION
    This script generates and compares snapshots of a production database 
    before and after a release. It uses Flyway `check` and `info check` commands 
    to consolidate information about:
        - Schema changes
        - Drift detection
        - Code consistency
    The results help DBAs and DevOps engineers verify what changed during a deployment.

.USECASE
    - Capture a pre-release snapshot of production for baseline comparison.
    - Capture a post-release snapshot after deployment.
    - Run checks to validate changes, detect drift, and consolidate results.
    - Generate reports that can be used in release reviews, audits, or post-mortems.

.NOTES
    - Replace file paths with project-specific snapshot storage locations.
    - The `-dryrun` flag allows safe testing of the report without applying changes.

.FILENAME
    Check_ConsolidateReports_Snapshots.ps1
#>

# -----------------------------
# Step 1: Take snapshots (before and after release)
# -----------------------------
flyway snapshot "-source=production" "-filename=C:\Projects\AdventureWorks\snapshots\snapshot-pre-release.json"
flyway snapshot "-source=production" "-filename=C:\Projects\AdventureWorks\snapshots\snapshot-post-release.json"

# -----------------------------
# Step 2: Run change checks between snapshots
# -----------------------------
# Basic check for schema changes
flyway check -changes -environment="production" -deployedSnapshot="C:\Projects\AdventureWorks\snapshots\snapshot-pre-release.json" -nextSnapshot="C:\Projects\AdventureWorks\snapshots\snapshot-post-release.json"

# -----------------------------
# Step 3: Generate consolidated check reports
# -----------------------------
# Check report with drift, dryrun, changes, and code checks. Control the reports file name and location. Can consolidate reports to one place.
flyway info check -changes -drift -code -dryrun -environment="production" -deployedSnapshot="C:\Projects\AdventureWorks\snapshots\snapshot-pre-release.json" -nextSnapshot="C:\Projects\AdventureWorks\snapshots\snapshot-post-release.json" -reportFilename="flyway_consolidated_reports.html"

# Alternative run using snapshots with relative paths (portable version)
flyway info check -changes -drift -code -dryrun -environment="production" -deployedSnapshot=".\snapshots\snapshot-pre-release.json" -nextSnapshot=".\snapshots\snapshot-post-release.json" -reportFilename="flyway_consolidated_reports.html"
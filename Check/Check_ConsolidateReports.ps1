<#
.SYNOPSIS
    Consolidates Flyway reports to validate schema consistency, drift, and code checks.

.DESCRIPTION
    This script runs `flyway info check` against a schema model and a target environment.
    It consolidates key checks into one command:
        - Schema changes
        - Drift detection
        - Code consistency validation
    The script can optionally output a consolidated HTML report for sharing with 
    stakeholders (e.g., DBAs, QA, or release managers).

.USECASE
    - Ensure production matches the expected schema model before/after a release.
    - Detect drift or inconsistencies introduced outside of Flyway (manual changes, hotfixes).
    - Generate reports for audits, compliance, or deployment reviews.
    - Validate that schema and migration scripts remain in sync across environments.

.NOTES
    - Replace `schema-model` with the correct schema model path for your project.
    - Use `-reportFilename` to generate an HTML file for easier distribution/review.
    - The `-dryrun` flag ensures no changes are applied; this is purely a reporting step.
    - `-check.buildEnvironment` compares the schema model against the specified build environment.

.FILENAME
    Check_ConsolidateReports.ps1
#>

# Consolidate reports for schema changes, drift, and code consistency
# Check report with drift, dryrun, changes, and code checks. Control the reports file name and location. Can consolidate reports to one place.
flyway info check -code -changes -drift -dryrun -schemaModelLocation="schema-model" -environment=Production -check.buildEnvironment=build -reportFilename="flyway_consolidated_reports.html" 

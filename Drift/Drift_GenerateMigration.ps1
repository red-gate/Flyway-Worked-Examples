# Compare Target Database To schemaModel and apply drift to schemaModel
# Use case: Compare a live environment (e.g., QA) against the schema model to check for drift.
# Helpful for identifying differences before deploying migrations.

flyway diff model -diff.source=qa -environments.qa.url="jdbc:postgresql://127.0.0.1:5432/qa" -environments.qa.user="flyway_qa" "-environments.qa.password=Flyway123" -diff.target=schemaModel -environments.qa.schemas="mySchema"
# Note: Ensure that the 'qa' environment is properly configured in your Flyway configuration file or command line.

# Generate Migrations
# Use case: Automatically generate versioned and undo migrations after drift is detected.
# Useful for developers to create migration scripts based on schema changes.

flyway generate "-generate.types=versioned,undo" "-generate.description=dev_updates"

# generate to a specific location
flyway generate -X -generate.types=versioned,undo -generate.description=dev_updates -generate.location=./outputs/drift
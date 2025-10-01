flyway snapshot "-source=development" "-filename=C:\Projects\AdventureWorks\snapshots\snapshot.json"
flyway diff "-source=snapshot:.\snapshots\snapshot.json" "-target=schemaModel" model diffText
flyway generate -X "-generate.types=versioned,undo" "-generate.description=dev_updates" "-generate.location=./outputs/drift"
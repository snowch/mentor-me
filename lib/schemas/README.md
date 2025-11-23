# MentorMe Data Schemas

This directory contains JSON Schema files for each version of the MentorMe data format.

## Purpose

These schemas are used for:

1. **Debugging import issues** - If a user reports a corrupted backup file, you can validate their file against the appropriate schema to identify the problem
2. **Documentation** - Clear specification of what each data version looks like
3. **Validation** - Can be used with JSON Schema validators to check file integrity

## Schema Versions

### v1.json - Schema Version 1
- Original data format
- Structured journal entries may have `null` content field
- Used by app versions before the v1→v2 migration

### v2.json - Schema Version 2
- Structured journal entries **must** have populated `content` field
- Content is auto-generated from `structuredData` during migration
- Format: `emoji name\n\nField: Value`

### v3.json - Schema Version 3 (Current)
- Adds `sortOrder` field to goals and habits for drag-and-drop reordering
- Adds comprehensive wellness app features (Phases 0-3):
  - Clinical assessments (PHQ-9, GAD-7, PSS-10)
  - CBT interventions (thought records, behavioral experiments)
  - Behavioral activation (activity scheduling)
  - Gratitude practice, worry time, self-compassion
  - Values clarification and implementation intentions

## How to Use

### For Users with Import Issues

If a user reports they can't import a backup:

1. Ask them to share the exported JSON file (remind them to remove any sensitive data)
2. Identify the schema version from the `schemaVersion` field
3. Validate against the appropriate schema:

```bash
# Using a JSON Schema validator like ajv-cli
npx ajv-cli validate -s lib/schemas/v2.json -d user-backup.json
```

4. The validator will show exactly what's wrong with the file

### Common Issues

**"schemaVersion missing"**
- File is corrupted or not a valid MentorMe backup
- User may have manually edited the JSON

**"Structured journal missing content (v2)"**
- File was exported from v1 but not migrated
- Migration failed or was skipped
- Solution: Import will auto-migrate, or manually run migration

**"Invalid JSON"**
- File is corrupted
- May have been truncated during transfer
- Check file size and encoding

## Adding New Schemas

When you update the data model:

1. Increment `CURRENT_SCHEMA_VERSION` in `migration_service.dart`
2. Create new migration in `lib/migrations/vX_to_vY_description.dart`
3. Add new schema file `lib/schemas/vY.json`
4. Document changes in the schema's `changelog` section
5. Update this README

## Schema Format

Each schema file includes:

- **$schema** - JSON Schema version (draft-07)
- **$id** - Unique identifier for this schema
- **title** - Human-readable name
- **description** - What this version is for
- **properties** - All expected fields
- **definitions** - Reusable schema fragments
- **examples** - Sample valid data
- **changelog** - What changed from previous version

## Online Validation

Users can also validate their files online at:
- https://www.jsonschemavalidator.net/
- https://json-schema-validator.herokuapp.com/

Just paste the schema and their data to see validation results.

## See Also

- `lib/services/migration_service.dart` - Orchestrates migrations
- `lib/services/schema_validator.dart` - Runtime validation (lightweight)
- `lib/migrations/` - Migration implementations

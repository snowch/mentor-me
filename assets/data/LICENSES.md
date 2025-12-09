# Data Source Licenses

This folder contains food nutrition data from the following sources:

## CoFID - UK Composition of Foods Integrated Dataset

**File:** `cofid_uk_foods.json`

**Source:** McCance and Widdowson's The Composition of Foods Integrated Dataset
**Publisher:** Public Health England / Food Standards Agency
**URL:** https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid

**License:** Open Government Licence v3.0
**License URL:** https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/

### License Summary:
You are free to:
- Copy, publish, distribute and transmit the Information
- Adapt the Information
- Exploit the Information commercially and non-commercially

You must (where you do any of the above):
- Acknowledge the source of the Information in your product or application

### Attribution:
Contains public sector information licensed under the Open Government Licence v3.0.
Source: McCance and Widdowson's Composition of Foods Integrated Dataset, Public Health England.

---

## Open Food Facts (API Integration)

**Note:** Open Food Facts data is accessed via API, not stored in this folder.

**Source:** Open Food Facts
**URL:** https://world.openfoodfacts.org/
**API:** https://world.openfoodfacts.org/data

**License:** Open Database License (ODbL) v1.0
**License URL:** https://opendatacommons.org/licenses/odbl/1.0/

### License Summary:
You are free to:
- Share: copy, distribute and use the database
- Create: produce works from the database
- Adapt: modify, transform and build upon the database

As long as you:
- Attribute: Acknowledge Open Food Facts as the source
- Share-Alike: If you publicly use any adapted version of this database, or works produced from an adapted database, you must also offer that adapted database under the ODbL

### Attribution:
Data from Open Food Facts (https://openfoodfacts.org), available under the Open Database License.

---

## Usage in MentorMe

This application uses the above data sources to provide nutrition information to users:

1. **CoFID data** is embedded in the app for offline access to common UK foods
2. **Open Food Facts** is accessed via API for branded/packaged food products

Both sources are properly attributed in the app UI when displaying nutrition data.

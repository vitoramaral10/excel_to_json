# Contributing

Bug reports and pull requests are welcome.

## Reporting a bug

Open an [issue](https://github.com/vitoramaral10/excel_to_json/issues) with
your `excel_to_json` and Dart versions and, if you can, a small `.xlsx` file
that shows the problem (with no private data).

## Development

```bash
git clone https://github.com/<you>/excel_to_json.git
cd excel_to_json
dart pub get
```

Before opening a pull request, run what CI runs:

```bash
dart format lib test example bin
dart analyze --fatal-infos lib test example bin
dart test
```

CI also requires 90% line coverage and runs the tests with the lowest
`archive` and `xml` versions allowed by `pubspec.yaml`
(`dart pub downgrade archive xml`).

## Pull requests

- Add or update tests for any change in behavior. Build the spreadsheet in the
  test with `package:excel`, or write its XML with `rawXlsx` for what that
  package cannot produce, as `test/excel_to_json_test.dart` does.
- Add an entry to `CHANGELOG.md` for anything users notice.
- Use [Conventional Commits](https://www.conventionalcommits.org/)
  (`fix: ...`, `feat: ...`, `docs: ...`).

## Releasing (maintainers)

1. Bump `version` in `pubspec.yaml` and add the `CHANGELOG.md` section.
2. Merge to `main`.
3. Tag the merge commit and push the tag: `git tag v2.0.1 && git push origin v2.0.1`.

The `Publish` workflow checks that the tag matches `pubspec.yaml`, runs the
checks, publishes to pub.dev and creates the GitHub release.

## Code of Conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md).

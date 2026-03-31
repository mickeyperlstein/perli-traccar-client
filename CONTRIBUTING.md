### Contributing to `traccar_client`

Thank you for contributing to the Traccar Client frontend.

### Versioning scheme (upstream + local patch)

- **Upstream version** comes from the main Traccar project and looks like: `9.7.16+131`.
- We **do not change** the upstream version or build number.
- Local FE changes add a **dot-suffixed patch segment** *before* the `+`, for example:
  - Upstream: `9.7.16+131`
  - First local change: `9.7.16.1+131`
  - Second local change: `9.7.16.2+131`
- In other words:
  - `major.minor.patch[.localPatch]+upstreamBuild`
  - Only `localPatch` is ours; everything else must stay aligned with upstream.

When you make a change that should be visible to users or testers (features, bug fixes, behavior changes, or significant test improvements), **increment the local patch** in `pubspec.yaml` (for example, from `9.7.16.1+131` to `9.7.16.2+131`).

### Version history (`docs/VERSION_HISTORY.md`)

- Human-readable change history for the Flutter app lives in `docs/VERSION_HISTORY.md`.
- For each local patch bump, add a new section **at the top** of the file:
  - Heading with the version and date, for example: `### 9.7.16.1+131 (2026-03-31)`
  - A bulleted list of short, past-tense changes.
- Example section:

```markdown
### 9.7.16.1+131 (2026-03-31)

- Improved Patrol integration tests for the Logs UI to open the screen via the real `Show status` button, avoiding Android notification permission popups.
- Mirrored `StatusScreen` filter behavior in tests so FW/DEBUG/INFO/WARN/ERROR chips and the `X/Y` counter are asserted and remain consistent while toggling filters.
```

### Commit and review

- When you bump a local patch version, always commit **both**:
  - `pubspec.yaml`
  - `docs/VERSION_HISTORY.md`



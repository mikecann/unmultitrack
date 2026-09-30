# Agent guidance for unmultitrack

This is a Windows CLI that splits an OBS/Aitum recording into one file per
video stream. The implementation is Python, with no third-party Python packages.
ffmpeg does the stream copies, and ffprobe is optional.

## Working here

- Keep source files in this clone. `C:\dev\tools` holds generated launchers and
  large binaries, never source files. Never commit `.exe` or `.dll` files.
- Use test-first development for non-trivial changes. Write or update the test
  first, then implement the change. Extract a test seam if needed.
- When behavior or a tested contract changes, update the tests and rerun them.
- Before committing, run `python -m unittest discover -s tests -v` and
  `pwsh -NoProfile -File tests/test-install.ps1`, then run the actual CLI on a
  small recording. Check exit codes and the extracted streams.
- Parse every `.ps1` with
  `[System.Management.Automation.Language.Parser]::ParseFile`. Windows registry
  and Explorer behavior must also be checked on a Windows machine.
- Write `.bat` files as ASCII. Installer-generated launchers must use
  `Set-Content -Encoding ASCII`. Keep paths quoted and pass arguments through.
- Keep the `EXEDIR` binary lookup contract. The installed stub sets it to its
  directory, and the repo batch launcher falls back to `%~dp0` when unset.
- Re-run `install.ps1` after changing installation wiring or moving the clone.
  Source edits alone need no reinstall because launchers point at live files.
- The shared `MikesTools` Explorer submenu belongs to multiple tools. Create it
  if missing, preserve existing settings, and remove only `Unmultitrack` verbs
  on uninstall. Keep the shared icon and PATH entry for other tools.

## Dependency checks

`deps.ps1` must be idempotent, self-contained and usable directly. Print clear
status messages with `Write-Host`. Check before installing anything. Large
manual-download binaries such as ffmpeg should only be checked, with a helpful
message when absent. `install.ps1 -SkipDeps` skips dependency checks.

## Files

- `unmultitrack.py`: stream probing, output planning and ffmpeg execution.
- `unmultitrack.bat`: Windows CLI entry point.
- `install.ps1`, `install-lib.ps1`, `uninstall.ps1`: launchers, icons and Explorer
  integration from this clone.
- `tests/test_unmultitrack.py`: Python unit tests.
- `tests/test-install.ps1`: portable helper checks with a simulated registry.
- `icons/film.png`, `icons/wrench.png`: famfamfam Silk icons by Mark James,
  licensed under CC BY 2.5. Keep the attribution in the README.

## Writing and contributions

Use plain, personal language and no em dashes. Start PR descriptions with
`## Why` and explain what prompted the change. Explain unusual code choices
with comments where helpful.

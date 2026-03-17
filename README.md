# Public GitHub Files

This folder is the minimal public set for hosting the workaround on GitHub.

Contents:
- `Widgit_Print_Workaround_Vanilla_Mac_arm64.zip`
- `install_widgit_workaround_web.sh`
- `installer_web_payload.applescript`

Before publishing:
1. Upload these files to the public repo.
2. Replace the `installerURL` placeholder in `installer_web_payload.applescript` with the final raw GitHub URL for `install_widgit_workaround_web.sh`.
3. Regenerate the final `applescript://` link from that updated AppleScript file.

Notes:
- The payload zip is public in this setup.
- The current payload URL inside `install_widgit_workaround_web.sh` already points to the public zip on your website.
- This package is arm64 only.

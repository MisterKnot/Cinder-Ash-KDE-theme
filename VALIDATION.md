# Cinder Ash 0.01 validation

## Completed

- Bash syntax checks for all five shell entry points; Python syntax validation.
- Parsed all five JSON files and 69 SVG/XML assets; checked SVG ID uniqueness and local paint references.
- Checked package metadata version/creator links, agreed Kvantum/SDDM color literals, and absence of icon, cursor, font or layout overrides in global-theme defaults.
- Rendered real Qt 6 widgets with the Kvantum theme and inspected text, buttons, selections, tabs and toolbar appearance.
- Rendered Plasma components and KSvg frames with the installed theme data; inspected the desktop-component preview.
- Rendered SDDM at 1920×1080, 1366×768 and 800×600. Checked login dispatch, duplicate-submit blocking, failure recovery, manual user entry and password clearing with mocked authentication.
- Loaded the theme in the actual Qt 6 SDDM greeter’s test mode without theme/QML parsing errors.
- Rendered the splash and checked its six-stage progress contract.
- Exercised isolated desktop/SDDM install, repeat install, removal and repeat removal; verified original configuration restoration, unrelated settings preservation, owned Ambinance service-override restoration, foreign-destination refusal and refusal to overwrite later configuration changes.
- Checked final ZIP CRCs, extracted-file equality, safe member paths and executable shell entry points.

## Limits

No theme was installed into the live desktop or system during this build. The sandbox cannot run a complete compositor/login session or real PAM authentication. Live KWin decoration behavior, screen locking/unlocking, multi-monitor behavior and a full native file-picker browsing session remain to be verified on the target KDE system. Aurorae SVGs passed structural checks, but were not exercised by a live KWin compositor. Offscreen rendering does not establish compatibility with every distribution or application.

Cinder Ash is a new theme, so the original Ambinance packages were not modified. Installation tests use an isolated filesystem and mocked desktop services; they do not substitute for a target-system smoke test.

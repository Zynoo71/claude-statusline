# claude-statusline

Configure your Claude Code statusline to show limits, directory and git info. Fork of [@kamranahmedse/claude-statusline](https://github.com/kamranahmedse/claude-statusline) with customizable progress bar styles.

![preview](./.github/preview.png)

## Install

```bash
bunx @zynoo/claude-statusline
```

With a custom bar style:

```bash
bunx @zynoo/claude-statusline --bar-style diamond
```

It backups your old status line if any and copies the status line script to `~/.claude/statusline.sh` and configures your Claude Code settings.

## Requirements

- [jq](https://jqlang.github.io/jq/) — for parsing JSON
- curl — for fetching rate limit data
- git — for branch info

On macOS:

```bash
brew install jq
```

## Configuration

### Bar Style

Use the `--bar-style` flag during install to set the progress bar style:

| Value | Preview |
|-------|---------|
| `diamond` (default) | `▰▰▰▱▱▱▱▱▱▱` |
| `block` | `████░░░░░░` |
| `dot` | `●●●○○○○○○○` |

To change the style later, just re-run the install command:

```bash
bunx @zynoo/claude-statusline --bar-style block
```

You can also set it via environment variable in your `.zshrc` or `.bashrc`:

```bash
export CLAUDE_STATUSLINE_BAR_STYLE=diamond
```

### Color Schemes

Each section uses a distinct color palette for easy visual separation:

| Section | < 50% | 50-70% | 70-90% | > 90% |
|---------|-------|--------|--------|-------|
| **Context window** (amber) | ![](https://img.shields.io/badge/-CDD6F4?style=flat-square&color=CDD6F4) Light grey | ![](https://img.shields.io/badge/-F9E2AF?style=flat-square&color=F9E2AF) Amber | ![](https://img.shields.io/badge/-FAB387?style=flat-square&color=FAB387) Peach | ![](https://img.shields.io/badge/-EF6C57?style=flat-square&color=EF6C57) Orange-red |
| **Current rate** (warm) | ![](https://img.shields.io/badge/-00AF50?style=flat-square&color=00AF50) Green | ![](https://img.shields.io/badge/-FFB055?style=flat-square&color=FFB055) Orange | ![](https://img.shields.io/badge/-E6C800?style=flat-square&color=E6C800) Yellow | ![](https://img.shields.io/badge/-FF5555?style=flat-square&color=FF5555) Red |
| **Weekly rate** (cool) | ![](https://img.shields.io/badge/-94E2D5?style=flat-square&color=94E2D5) Teal | ![](https://img.shields.io/badge/-74C7EC?style=flat-square&color=74C7EC) Sapphire | ![](https://img.shields.io/badge/-CBA6F7?style=flat-square&color=CBA6F7) Mauve | ![](https://img.shields.io/badge/-F5C2E7?style=flat-square&color=F5C2E7) Pink |

Color palettes inspired by [Catppuccin Mocha](https://github.com/catppuccin/catppuccin).

## Uninstall

```bash
bunx @zynoo/claude-statusline --uninstall
```

If you had a previous statusline, it restores it from the backup. Otherwise it removes the script and cleans up your settings.

## Credits

Based on [claude-statusline](https://github.com/kamranahmedse/claude-statusline) by [Kamran Ahmed](https://github.com/kamranahmedse). Thanks for the great work!

## License

MIT — see [LICENSE](./LICENSE) for details.

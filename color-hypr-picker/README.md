# Color (hypr)picker

A color picker plugin that extends Noctalia's base one with hyprpicker. Paste several color codes to your clipboard, 
and browse recent colors list.

![Preview](preview.png "Color (hypr)picker preview")


## Features

- **Screen picker**: Run hyprpicker and select a pixel from screen to get its color code.
- **Noctalia picker**: An instance of Noctalia's base picker and its dialog.
- **Fast action**: Right-click the bar widget to run the screen picker.
- **Palette**: Stores recently picked colors and allows copying them again.
- **Code selector**: A list of different color code conventions to choose from (HEX, RGB, HSL, HSV, CMYK).

## IPC Commands

You can control the plugin via the command line using the Noctalia IPC interface.

### General Usage
```bash
qs -c noctalia-shell ipc call plugin:color-hypr-picker <command>
```

### Available Commands

| Command     | Description                                      | Example                                                         |
|-------------|--------------------------------------------------|-----------------------------------------------------------------|
| `toggle`    | Opens or closes the panel on the current screen  | `qs -c noctalia-shell ipc call plugin:color-hypr-picker toggle` |
| `pick`      | Runs hyprpicker and puts color code to clipboard | `qs -c noctalia-shell ipc call plugin:color-hypr-picker pick`   |


## Settings

There are no settings available for this plugin.

## Dependencies

- **Hyprpicker**: A color picker tool for Hyprland.
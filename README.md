# Way Search

Google's Circle to Search-inspired on-screen searcher for Wayland. Was tested on Hyprland, but will likely work on every DE/WM that Quickshell supports.

## Installation

- Install dependencies.  
  You'll need to install `webkit2gtk`, `rust` and `quickshell`. Other dependecies will probably already be installed.

- Clone this repo to the Quickshell directory:

```bash
git clone https://github.com/gooseDes/way-search ~/.config/quickshell/ws
```

- Cd to that directory:

```bash
cd ~/.config/quickshell/ws
```

- Run ./build.sh:

```bash
./build.sh
```

- Now you can start way-search by running this command:

```bash
qs -c ws
```

- You may notice starting it is not seamless. If that's so, you'll need to disable animations for the way-search window. If you're on Hyprland, you should add this to your config:

```lua
hl.layer_rule({
	match = {
		namespace = "^(way-search)$",
	},
	no_anim = true,
})
```

- And now you can bind it to anything you want. Example for Hyprland:

```lua
hl.bind("SUPER + H", hl.dsp.exec_cmd("qs -c ws"))
```

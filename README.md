# Chemistry Sandbox

<img width=20% src="img/reaction-anim.gif">

Chemistry Sandbox is an in-development interactive video game simulating high school chemistry concepts at the molecular level.

While accuracy to real-world processes was given attention, it stands that this is not the main goal.

Due to time and knowledge constraints, compromises have to be made.

## Quick Links

- [Feature list](FEATURES.md)
- [Contributing guidelines](CONTRIBUTING.md)
	- Please read this if you want to send a bug report, issue, or pull request.

## How to Play

Mobile support is currently low priority. The game still loads, but many features are (and will be) unavailable. Please play on PC for the best experience.

There is a full in-game tutorial, which aside from controls, tries to give some chemistry context. It takes about 10 minutes to complete.

Here is the previous shortened controls tutorial for PC users:

1. Use `Scroll Wheel` or number keys `1` to `4` to select among four elements (hydrogen, carbon, nitrogen, and oxygen). The selected element's symbol appears on the bottom-left.
2. `Left Click` on the gray area (world) to spawn an atom.
	- Drag while holding `Left Click`, then release to launch the spawned atom.
3. `Shift Left Click` on an atom to remove it.
	- Alternatively, press `Delete` or `X`
4. Press `Q` to pause and play the simulation.
5. Camera tools
	- Drag with `Ctrl Right Click` to move the camera.
	- Press `Ctrl +` to zoom in and `Ctrl -` to zoom out.
		- Alternatively, use `Ctrl Scroll Wheel`
	- Press `Ctrl 0` to reset the camera.
6. Selection tools
	- `Right Click` to select an atom.
		- Drag with `Right Click` to select atoms in the selection box.
		- Use `Shift` with above actions to deselect.
	- Pressing the remove action (in #3) also removes selected atoms.
	- Press `Ctrl C` to copy and `Ctrl V` to paste
7. Other tools are on the bottom-right:
	- Clear: Removes all atoms
	- Temp Up: Speeds up atoms
	- Temp Down: Slows down atoms

## Building

You will need [Godot Engine v4.4](https://godotengine.org/download/archive/4.4-stable) installed to build this project.

## License

The source code is licensed under [GPL-3.0-or-later](https://www.gnu.org/licenses/gpl-3.0).

Assets and documentation are licensed under [CC-BY-SA-4.0](https://creativecommons.org/licenses/by-sa/4.0).

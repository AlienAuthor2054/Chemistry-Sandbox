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

For now, here is a basic controls tutorial:

1. Use scroll wheel to select among four elements (hydrogen, carbon, nitrogen, and oxygen). The selected element's symbol appears on the bottom-left.
2. Left click on the gray area (simulation area) to spawn an atom.
	- Drag while holding left click, then release to launch the spawned atom.
3. Right click on an atom to remove it.
4. Press the \` key (left of 1 key) to pause and play the simulation.
5. Other tools are on the bottom-right:
	- Clear: Removes all atoms
	- Temp Up: Speeds up atoms
	- Temp Down: Slows down atoms

Atoms near each other will automatically form and break bonds following an adapted model of Lewis theory.

Beyond this, expect interactive in-game tutorials in the future covering:
- Basic controls
- Atomic bonding
- Bond strength and its determining factors

and other chimistry concepts.

## Building

You will need [Godot Engine v4.4](https://godotengine.org/download/archive/4.4-stable) installed to build this project.

## License

The source code is licensed under [GPL-3.0-or-later](https://www.gnu.org/licenses/gpl-3.0).

Assets and documentation are licensed under [CC-BY-SA-4.0](https://creativecommons.org/licenses/by-sa/4.0).

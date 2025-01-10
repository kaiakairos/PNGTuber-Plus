# Spout GD

[Godot](https://github.com/godotengine/godot) 4.2.1 bindings for [Spout](https://github.com/leadedge/Spout2).

The Godot 3 engine module is located on the `godot-3` branch.

Precompiled builds of the plugin can be found in the [releases](../../releases/tag/latest) section of github.

## Status

The sender/receiver apis have been implemented. Please open an issue if something doesn't seem to work.

## Building

Prerequisites:

* Windows (Spout only works on Windows)
* git
* bash
* scons
* a C++ compiler capable of [compiling Godot](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_windows.html)
* cmake

Clone the repository: `git clone --recurse-submodules https://github.com/you-win/spout-gd.git`

Run `build.sh` in a bash-compatible terminal. This will:

* Compile Spout2
* Compile the gdextension bindings
* Compile spout-gd

Once compilation is finished, the following files should be moved to your project's `addons/spout-gd` folder (create it manually if it does not exist):

* `spout_gd.gdextension`
* `Spout2/Binaries/x64/SpoutLibrary.dll`
* `out/spout_gd.windows.template_debug.dll`
* `out/spout_gd.windows.template_release.dll`

Like this:
```
Godot_project_root
├───addons
│   ├───spout-gd
│   │    ├───SpoutLibrary.dll
│   │    ├───spout_gd.gdextension
│   │    ├───spout_gd.windows.template_debug.dll
│   │    ├───spout_gd.windows.template_release.dll
```

## Basic usage

```gdscript
var spout: Spout
var my_image: Image = load_from_somewhere_idk() # Provide your own image somehow
func _ready():
    spout = Spout.new()
    
    spout.send_image(my_image, image.get_width(), image.get_height())
```

## SpoutTexture - Simple Receiving 

Provided as a convenience is a Texture resource for receiving streams from a Spout sender.  You can use this any place you can use any other kind of Texture, including places like UI elements and Materials on 3D objects.

The sender is polled per render cycle.  

<img src="https://github.com/erodozer/spout-gd/assets/316728/989389ab-23ed-4ae0-8ccc-ca9ba51f6346" width=400>

<img src="https://github.com/erodozer/spout-gd/assets/316728/dab4ed75-e046-4197-be50-5d634216b7c2" width=600>

## SpoutViewport - Simple Sending

By wrapping the scene you wish to render in a SpoutViewport, you can easily send render target contents over Spout.  Simply use it the same way as you would a SubViewport, and assign a sender name for it to assume.

The SpoutViewport is designed to only send during application run time, not within the editor.  This helps prevent creating multiple senders with the same name during testing, allowing for more stable capture.

<img src="https://github.com/erodozer/spout-gd/assets/316728/08a021a6-eaab-408e-9961-51adac31e958" width=800>

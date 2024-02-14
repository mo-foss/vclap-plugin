# CLAP plugin in V
Demonstration of a [CLAP](https://github.com/free-audio/clap) audio plugin in V.

Built on top of [clap](https://github.com/odiroot/clap-lib) library for V language.

Current features:

- Builds a spec-compliant CLAP plugin.
- Shows a barebones GUI based on XCB/X11 (no controls).
- Runs under Bitwig Studio on Linux.

## Quickstart

Ensure you have a working [V language](https://vlang.io/) environment.

On top of that you'd need:

- GNU Make
- GCC
- `libxcb`
- `libxmdcp`
- `libxau`

Start with:
```sh
git clone https://github.com/mo-foss/vclap.git
cd vclap
v install
make
```

To confirm the plugin was built correctly you can use
[this tool](https://github.com/free-audio/clap-info/):
```sh
clap-info build/hello_world.clap
```

To test with your DAW, you have to make it discoverable:
```
make install
```

Here is the plugin being correctly loaded in Bitwig Studio 5.1:
![](./assets/running.png)


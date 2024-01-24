import vclap
// Exposes the plugin to the host (DAW).

@[markused]
__global clap_entry = vclap.plugin_entry
// This requires modification to `clap/entry.h`.
// Remove "const" so you get:
// CLAP_EXPORT extern clap_plugin_entry_t clap_entry;

fn init() {
	$if debug {
		eprintln('VCLAP in debug mode')
	}
}

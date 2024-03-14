import plugin
// Exposes the plugin to the host (DAW).

@[markused]
__global clap_entry = plugin.entry
// This requires modification to `clap/entry.h`.
// Remove "const" so you get:
// CLAP_EXPORT extern clap_plugin_entry_t clap_entry;

fn init() {
	// XXX: MANUAL_GC
	C.GC_disable()

	$if debug {
		plugin.log('VCLAP in debug mode')
		spawn plugin.mem_logger()
	}
}

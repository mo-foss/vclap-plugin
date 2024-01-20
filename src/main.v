import log
// Exposes the plugin to the host (DAW).

// This requires modification to `clap/entry.h`.
// Remove "const" so you get:
// CLAP_EXPORT extern clap_plugin_entry_t clap_entry;
@[markused]
__global clap_entry = plugin_entry

fn init() {
	$if debug {
		log.set_level(log.Level.debug)
	} $else {
		log.set_level(log.Level.info)
	}
}

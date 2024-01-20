import log
import v.vmod

// Only need to change the mod file to update the version.
const manifest = vmod.decode(@VMOD_FILE) or { panic(err) }
const current_version = manifest.version

// Exposes the plugin to the host (DAW).

@[markused]
__global clap_entry = plugin_entry
// This requires modification to `clap/entry.h`.
// Remove "const" so you get:
// CLAP_EXPORT extern clap_plugin_entry_t clap_entry;

fn init() {
	$if debug {
		log.set_level(log.Level.debug)
	} $else {
		log.set_level(log.Level.info)
	}
}

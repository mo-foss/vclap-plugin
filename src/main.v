module plugin

// Exposes the plugin to the host (DAW).

// This requires modification to `clap/entry.h`.
// Remove "const" so you get:
// CLAP_EXPORT extern clap_plugin_entry_t clap_entry;
@[markused]
__global clap_entry = _plugin_entry

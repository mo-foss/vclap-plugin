module plugin

// Features of the CLAP plugin.
// Have to be defined separately here, otherwise wrong C is generated.
const _plugin_features = [
    c'instrument',
    unsafe { nil },
]!

// Plugin information, extracted at load time.
const _plugin_id = 'example.hello.world'
const _plugin_descriptor = C.clap_plugin_descriptor_t{
    id: _plugin_id.str
    name: c'CLAP V Hello World'
    vendor: c'MOFOSS'
    version: c'0.1.0'
    description: c'MVP of a CLAP plugin in V.'
    // voidptr is to fix warning about const char**.
    features: voidptr(unsafe {
        &&char(&_plugin_features[0])
    })
}

const _plugin_entry = C.clap_plugin_entry_t{
    clap_version: C.clap_version_t{}
    init: entry_init
    deinit: entry_deinit
    get_factory: entry_get_factory
}

fn get_plugin_count(factory &C.clap_plugin_factory_t) u32 {
	return 1
}

fn create_plugin(factory &C.clap_plugin_factory_t, host &C.clap_host_t, plugin_id &char) &C.clap_plugin_t {

	// Sanity checks for lib version and correct plugin expected.
	if !C.clap_version_is_compatible(host.clap_version) {
		return unsafe { nil }
	}
	v_plugin_id := unsafe { cstring_to_vstring(plugin_id) }
	if v_plugin_id != _plugin_id {
		return unsafe { nil }
	}

	// Build actual plugin -- our custom structure.
	main_plugin := &MinimalPlugin{}
	// This is the "official" plugin.
	clap_plugin := &C.clap_plugin_t{
		desc: &_plugin_descriptor
		// It always carries a pointer to our custom structure.
		plugin_data: main_plugin
		init: main_plugin.init
		destroy: MinimalPlugin.destroy
		activate: MinimalPlugin.activate
		deactivate: MinimalPlugin.deactivate
		start_processing: MinimalPlugin.start_processing
		stop_processing: MinimalPlugin.stop_processing
		reset: MinimalPlugin.reset
		process: MinimalPlugin.process
		get_extension: MinimalPlugin.get_extension
		on_main_thread: MinimalPlugin.on_main_thread
	}

	return clap_plugin
}

fn get_plugin_descriptor(factory &C.clap_plugin_factory_t, index u32) &C.clap_plugin_descriptor_t {
	if index == 0 {
		return &_plugin_descriptor
	} else {
		return unsafe { nil }
	}
}

fn entry_init(plugin_path &char) bool {
	return true
}

fn entry_deinit() {
}

fn entry_get_factory(factory_id &char) voidptr {
	factory_id_v := unsafe { factory_id.vstring() }

	if factory_id_v == clap_plugin_factory_id {
		factory := C.clap_plugin_factory_t{
			get_plugin_count: get_plugin_count
			get_plugin_descriptor: get_plugin_descriptor
			create_plugin: create_plugin
		}
		return voidptr(&factory)
	}

	return unsafe { nil }
}

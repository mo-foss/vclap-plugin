module plugin

import v.vmod
import odiroot.clap
import odiroot.clap.factory as cfactory
import time

// Only need to change the mod file to update the version.
const manifest = vmod.decode(@VMOD_FILE) or { panic(err) }
const current_version = manifest.version
const plugin_name = 'CLAP V Hello World'

// Features of the CLAP plugin.
// Have to be defined separately here, otherwise wrong C is generated.
const _plugin_features = [
	c'audio-effect',
	c'note-effect',
	c'stereo',
	unsafe { nil },
]!

// Plugin information, extracted at load time.
const _id = 'example.hello.world'
const _descriptor = clap.PluginDescriptor{
	id: _id.str
	name: plugin_name.str
	vendor: c'MOFOSS'
	version: current_version.str
	description: c'MVP of a CLAP plugin in V.'
	// voidptr is to fix warning about const char**.
	features: voidptr(unsafe {
		&&char(&_plugin_features[0])
	})
}

fn create_plugin(factory &cfactory.PluginFactory, host &clap.Host, plugin_id &char) &clap.Plugin {
	// Sanity checks for lib version and correct plugin expected.
	if !clap.version_is_compatible(host.clap_version) {
		return unsafe { nil }
	}
	v_plugin_id := unsafe { cstring_to_vstring(plugin_id) }
	if v_plugin_id != _id {
		return unsafe { nil }
	}

	// Build actual plugin -- our custom structure.
	main_plugin := &MinimalPlugin{
		host: host
	}

	// This is the "official" plugin.
	clap_plugin := &clap.Plugin{
		desc: &plugin._descriptor
		// It always carries a pointer to our custom structure.
		plugin_data: main_plugin
		init: main_plugin.init
		destroy: main_plugin.destroy
		activate: main_plugin.activate
		deactivate: main_plugin.deactivate
		start_processing: main_plugin.start_processing
		stop_processing: main_plugin.stop_processing
		reset: main_plugin.reset
		process: main_plugin.process
		get_extension: main_plugin.get_extension
		on_main_thread: main_plugin.on_main_thread
	}

	return clap_plugin
}

fn entry_get_factory(factory_id &char) voidptr {
	factory_id_v := unsafe { factory_id.vstring() }
	if factory_id_v == cfactory.plugin_factory_id {
		factory := cfactory.PluginFactory{
			get_plugin_count: fn (factory &cfactory.PluginFactory) u32 {
				return 1
			}
			get_plugin_descriptor: fn (factory &cfactory.PluginFactory, index u32) &clap.PluginDescriptor {
				if index == 0 {
					return &plugin._descriptor
				} else {
					return unsafe { nil }
				}
			}
			create_plugin: create_plugin
		}
		return voidptr(&factory)
	}

	return unsafe { nil }
}

fn mem_logger() {
	for {
		mem_use := gc_memory_use() / 1024
		C.fprintf(C.stderr, c'TOTAL MEMORY: %10d KB\n', mem_use)
		// eprint("Heap total bytes: ")
		// heap_use := gc_heap_usage()
		// eprint(heap_use.total_bytes)
		// eprint(". Bytes since GC: ")
		// eprintln(heap_use.bytes_since_gc)
		time.sleep(time.second * 2)
	}
}

pub const entry = clap.PluginEntry{
	clap_version: clap.Version{}
	init: fn (plugin_path &char) bool {
		spawn mem_logger()
		return true
	}
	deinit: fn () {}
	get_factory: entry_get_factory
}

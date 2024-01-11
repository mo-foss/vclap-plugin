module plugin

#flag -I./include
#include "clap/clap.h"

enum ClapProcessStatus {
	clap_process_error = 0
	clap_process_continue = 1
	clap_process_continue_if_not_quiet = 2
	clap_process_tail = 3
	clap_process_sleep = 4
}

@[typedef]
struct C.clap_version_t {
	major    u32 = u32(C.CLAP_VERSION_MAJOR)
	minor    u32 = u32(C.CLAP_VERSION_MINOR)
	revision u32 = u32(C.CLAP_VERSION_REVISION)
}

@[typedef]
struct C.clap_plugin_descriptor_t {
	clap_version C.clap_version_t = C.clap_version_t{}
	id           &char
	name         &char
	vendor       &char
	url          &char = ''.str
	manual_url   &char = ''.str
	support_url  &char = ''.str
	version      &char
	description  &char
	features     &&char
}

@[typedef]
struct C.clap_plugin_t {
	desc        &C.clap_plugin_descriptor_t @[required]
	plugin_data voidptr                     @[required]

	init             fn (&C.clap_plugin_t) bool                @[required]
	destroy          fn (&C.clap_plugin_t)                     @[required]
	activate         fn (&C.clap_plugin_t, f64, u32, u32) bool @[required]
	deactivate       fn (&C.clap_plugin_t)                     @[required]
	start_processing fn (&C.clap_plugin_t) bool
	stop_processing  fn (&C.clap_plugin_t)
	reset            fn (&C.clap_plugin_t)
	process          fn (&C.clap_plugin_t, &C.clap_process_t) ClapProcessStatus
	get_extension    fn (&C.clap_plugin_t, &char) voidptr
	on_main_thread   fn (&C.clap_plugin_t)
}

@[typedef]
struct C.clap_host_t {
	clap_version C.clap_version_t
}

@[typedef]
struct C.clap_plugin_factory_t {
	get_plugin_count      fn (&C.clap_plugin_factory_t) u32
	get_plugin_descriptor fn (&C.clap_plugin_factory_t, u32) &C.clap_plugin_descriptor_t
	create_plugin         fn (&C.clap_plugin_factory_t, &C.clap_host_t, &char) &C.clap_plugin_t
}

@[typedef]
struct C.clap_plugin_entry_t {
	clap_version C.clap_version_t
	init         fn (&char) bool
	deinit       fn ()
	get_factory  fn (&char) voidptr
}

@[typedef]
struct C.clap_process_t

const clap_plugin_factory_id = unsafe { (&char(C.CLAP_PLUGIN_FACTORY_ID)).vstring() }

fn C.clap_version_is_compatible(C.clap_version_t) bool

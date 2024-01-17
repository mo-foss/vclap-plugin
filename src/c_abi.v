module plugin

#flag -I./include
#include "clap/clap.h"

enum ClapProcessStatus {
	error                 = 0
	@continue             = 1
	continue_if_not_quiet = 2
	tail                  = 3
	sleep                 = 4
}

type C.clap_id = u32

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

	init             fn (&C.clap_plugin_t) bool                                 @[required]
	destroy          fn (&C.clap_plugin_t)                                      @[required]
	activate         fn (&C.clap_plugin_t, f64, u32, u32) bool                  @[required]
	deactivate       fn (&C.clap_plugin_t)                                      @[required]
	start_processing fn (&C.clap_plugin_t) bool
	stop_processing  fn (&C.clap_plugin_t)
	reset            fn (&C.clap_plugin_t)
	process          fn (&C.clap_plugin_t, &C.clap_process_t) ClapProcessStatus
	get_extension    fn (&C.clap_plugin_t, &char) voidptr
	on_main_thread   fn (&C.clap_plugin_t)
}

@[heap; typedef]
struct C.clap_host_t {
	clap_version  C.clap_version_t
	get_extension fn (&C.clap_host_t, &char) voidptr
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
struct C.clap_process_t {
	steady_time         i64
	frames_count        u32
	transport           &C.clap_event_transport_t
	audio_inputs        &C.clap_audio_buffer_t
	audio_inputs_count  u32
	audio_outputs_count u32
	in_events           &C.clap_input_events_t
	out_events          &C.clap_output_events_t
mut:
	audio_outputs &C.clap_audio_buffer_t
}

@[typedef]
struct C.clap_event_transport_t {}

@[typedef]
struct C.clap_audio_buffer_t {
	channel_count u32
	latency       u32
	constant_mask u64
mut:
	data32 &&f32
	data64 &&f64
}

@[typedef]
struct C.clap_input_events_t {
	ctx  voidptr
	size fn (&C.clap_input_events_t) u32
	// TODO: How to avoid `voidptr` and use header/event structs instead?
	get fn (&C.clap_input_events_t, u32) voidptr
}

@[typedef]
struct C.clap_event_header_t {
	size     u32
	time     u32
	space_id u16
	@type    u16
	flags    u32
}

// TODO: Why doesn't typedef C structs work here?
struct ClapEventNote {
	C.clap_event_header_t
	note_id    int
	port_index i16
	channel    i16
	key        i16
	velocity   f64
}

enum ClapEventType as u16 {
	note_on             = 0
	note_off            = 1
	note_choke          = 2
	note_end            = 3
	note_expression     = 4
	param_value         = 5
	param_mod           = 6
	param_gesture_begin = 7
	param_gesture_end   = 8
	transport           = 9
	midi                = 10
	midi_sysex          = 11
	midi2               = 12
}

@[typedef]
struct C.clap_output_events_t {}

const clap_plugin_factory_id = unsafe { (&char(C.CLAP_PLUGIN_FACTORY_ID)).vstring() }
const clap_core_event_space_id = u16(C.CLAP_CORE_EVENT_SPACE_ID)

fn C.clap_version_is_compatible(C.clap_version_t) bool

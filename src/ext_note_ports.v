module plugin

const clap_ext_note_ports = unsafe { (&char(C.CLAP_EXT_NOTE_PORTS)).vstring() }

@[typedef]
struct C.clap_note_port_info_t {
mut:
	id                 C.clap_id
	supported_dialects u32
	preferred_dialect  u32
	name               [256]char
}

@[typedef]
struct C.clap_plugin_note_ports_t {
	count fn (&C.clap_plugin_t, bool) u32
	get   fn (&C.clap_plugin_t, u32, bool, &C.clap_note_port_info_t) bool
}

enum ClapNoteDialect as u32 {
	clap     = 1 << 0
	midi     = 1 << 1
	midi_mpe = 1 << 2
	midi2    = 1 << 3
}

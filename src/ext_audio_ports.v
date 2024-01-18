const clap_ext_audio_ports = unsafe { (&char(C.CLAP_EXT_AUDIO_PORTS)).vstring() }
const clap_port_stereo = unsafe { (&char(C.CLAP_PORT_STEREO)).vstring() }
const clap_port_mono = unsafe { (&char(C.CLAP_PORT_MONO)).vstring() }

@[typedef]
struct C.clap_audio_port_info_t {
mut:
	id            C.clap_id
	name          [256]char
	flags         u32
	channel_count u32
	port_type     &char
	in_place_pair C.clap_id
}

@[typedef]
struct C.clap_plugin_audio_ports_t {
	count fn (&C.clap_plugin_t, bool) u32
	get   fn (&C.clap_plugin_t, u32, bool, &C.clap_audio_port_info_t) bool
}

enum ClapAudioPortFlags as u32 {
	is_main                     = 1 << 0
	supports_64_bits            = 1 << 1
	prefers_64_bits             = 1 << 2
	requires_common_sample_size = 1 << 3
}

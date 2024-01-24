module vclap

const clap_ext_latency = unsafe { (&char(C.CLAP_EXT_LATENCY)).vstring() }

@[typedef]
struct C.clap_plugin_latency_t {
	get fn (&C.clap_plugin_t) u32
}

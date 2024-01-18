import log

// This should be the actual implementation of the plugin with
// all the interesting logic like DSP, UI, etc.
struct MinimalPlugin {
	host &C.clap_host_t
mut:
	sample_rate f64
	latency     u32
}

// Extract our actual pluging from CLAP plugin wrapper.
fn from_clap(clap_plugin &C.clap_plugin_t) &MinimalPlugin {
	return unsafe { &MinimalPlugin(clap_plugin.plugin_data) }
}

fn MinimalPlugin.init(clap_plugin &C.clap_plugin_t) bool {
	return true
}

fn MinimalPlugin.destroy(clap_plugin &C.clap_plugin_t) {
	// Cleanup plugin members here.
}

fn MinimalPlugin.activate(clap_plugin &C.clap_plugin_t, sample_rate f64, min_frames_count u32, max_frames_count u32) bool {
	mut p := from_clap(clap_plugin)
	p.sample_rate = sample_rate
	return true
}

fn MinimalPlugin.deactivate(clap_plugin &C.clap_plugin_t) {
}

fn MinimalPlugin.start_processing(clap_plugin &C.clap_plugin_t) bool {
	return true
}

fn MinimalPlugin.stop_processing(clap_plugin &C.clap_plugin_t) {
}

fn MinimalPlugin.reset(clap_plugin &C.clap_plugin_t) {
	// Cleanup plugin members here.
}

fn (mp MinimalPlugin) process_event(header &C.clap_event_header_t) {
	if header.space_id != clap_core_event_space_id {
		return
	}

	match header.@type {
		u16(ClapEventType.note_on) {
			// Handle note playing.
			event := &C.clap_event_note_t(header)
			log.debug('Note ON: ${event.note_id}')
		}
		u16(ClapEventType.note_off) {
			// Handle note stop playing.
			event := &C.clap_event_note_t(header)
			log.debug('Note OFF: ${event.note_id}')
		}
		// And so on...
		else {
			t := unsafe { ClapEventType(header.@type) }
			log.debug('Unsupported event type: ${t}')
		}
	}
}

fn MinimalPlugin.process(clap_plugin &C.clap_plugin_t, mut process C.clap_process_t) ClapProcessStatus {
	p := from_clap(clap_plugin)

	nframes := process.frames_count
	nev := process.in_events.size(process.in_events)

	mut ev_index := u32(0)
	mut next_ev_frame := if nev > 0 { 0 } else { nframes }

	for i := 0; i < nframes; {
		for ev_index < nev && next_ev_frame == i {
			header := process.in_events.get(process.in_events, ev_index)

			if header.time != i {
				next_ev_frame = header.time
				break
			}

			p.process_event(header)
			ev_index++

			if ev_index == nev {
				next_ev_frame = nframes
				break
			}
		}

		for ; i < next_ev_frame; i++ {
			// In general:
			// mut inputs := []C.clap_audio_buffer_t{cap: int(process.audio_inputs_count)}
			// for k := 0; k < process.audio_inputs_count; k++  {
			// 	inputs << unsafe{ process.audio_inputs[k] }
			// }
			input_left := unsafe { process.audio_inputs[0].data32[0][i] }
			input_right := unsafe { process.audio_inputs[0].data32[1][i] }

			// Swap left and right channels.
			unsafe { process.audio_outputs[0].data32[0][i] = input_right }
			unsafe { process.audio_outputs[0].data32[1][i] = input_left }
		}
	}

	return ClapProcessStatus.@continue
}

fn MinimalPlugin.get_extension(clap_plugin &C.clap_plugin_t, id &char) voidptr {
	v_id := unsafe { cstring_to_vstring(id) }

	match v_id {
		clap_ext_latency {
			return &C.clap_plugin_latency_t{
				get: fn (clap_plugin &C.clap_plugin_t) u32 {
					p := from_clap(clap_plugin)
					return p.latency
				}
			}
		}
		clap_ext_audio_ports {
			return &C.clap_plugin_audio_ports_t{
				count: fn (clap_plugin &C.clap_plugin_t, is_input bool) u32 {
					return 1
				}
				get: fn (clap_plugin &C.clap_plugin_t, index u32, is_input bool, mut info C.clap_audio_port_info_t) bool {
					// Just one port.
					if index > 0 {
						return false
					}

					info.id = 0
					info.channel_count = 2
					info.flags = u32(ClapAudioPortFlags.is_main)
					info.port_type = clap_port_stereo.str
					info.in_place_pair = C.CLAP_INVALID_ID

					// Translate string to constant array.
					port_name := 'Example audio port'
					for i, chr in port_name {
						info.name[i] = chr
					}
					info.name[port_name.len] = char(0)

					return true
				}
			}
		}
		clap_ext_note_ports {
			return &C.clap_plugin_note_ports_t{
				count: fn (clap_plugin &C.clap_plugin_t, is_input bool) u32 {
					return 1
				}
				get: fn (clap_plugin &C.clap_plugin_t, index u32, is_input bool, mut info C.clap_note_port_info_t) bool {
					if index > 0 {
						return false
					}

					info.id = 0
					info.supported_dialects = (
						u32(ClapNoteDialect.clap) |
						u32(ClapNoteDialect.midi_mpe) |
						u32(ClapNoteDialect.midi2)
					)
					info.preferred_dialect = u32(ClapNoteDialect.clap)

					port_name := 'Example note port'
					for i, chr in port_name {
						info.name[i] = chr
					}
					info.name[port_name.len] = char(0)

					return true
				}
			}
		}
		else {
			return unsafe { nil }
		}
	}
}

fn MinimalPlugin.on_main_thread(clap_plugin &C.clap_plugin_t) {
}

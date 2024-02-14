module vclap

import vclap.gui { GUI }

const gui_width = 640
const gui_height = 480

// This should be the actual implementation of the plugin with
// all the interesting logic like DSP, UI, etc.
@[heap]
struct MinimalPlugin {
	host &C.clap_host_t
mut:
	sample_rate     f64
	latency         u32
	host_posix_fd   &C.clap_host_posix_fd_support_t = unsafe { nil }
	gui             &gui.GUI = unsafe { nil }
}

// Extract our actual pluging from CLAP plugin wrapper.
fn from_clap(clap_plugin &C.clap_plugin_t) &MinimalPlugin {
	return unsafe { &MinimalPlugin(clap_plugin.plugin_data) }
}

fn (mut mp MinimalPlugin) init(clap_plugin &C.clap_plugin_t) bool {
	mp.host_posix_fd = mp.host.get_extension(mp.host, clap_ext_posix_fd_support.str)
	return true
}

fn (mp MinimalPlugin) destroy(clap_plugin &C.clap_plugin_t) {
	// Cleanup plugin members here.
}

fn (mut mp MinimalPlugin) activate(clap_plugin &C.clap_plugin_t, sample_rate f64, min_frames_count u32, max_frames_count u32) bool {
	mp.sample_rate = sample_rate
	return true
}

fn (mp MinimalPlugin) deactivate(clap_plugin &C.clap_plugin_t) {
}

fn (mp MinimalPlugin) start_processing(clap_plugin &C.clap_plugin_t) bool {
	return true
}

fn (mp MinimalPlugin) stop_processing(clap_plugin &C.clap_plugin_t) {
}

fn (mp MinimalPlugin) reset(clap_plugin &C.clap_plugin_t) {
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
			debug('Note ON: ${event.note_id}')
		}
		u16(ClapEventType.note_off) {
			// Handle note stop playing.
			event := &C.clap_event_note_t(header)
			debug('Note OFF: ${event.note_id}')
		}
		// And so on...
		else {
			t := unsafe { ClapEventType(header.@type) }
			debug('Unsupported event type: ${t}')
		}
	}
}

fn (mp MinimalPlugin) process(clap_plugin &C.clap_plugin_t, mut process C.clap_process_t) ClapProcessStatus {
	frame_count := process.frames_count
	event_count := process.in_events.size(process.in_events)

	mut event_index := u32(0)
	mut next_frame := if event_count > 0 { 0 } else { frame_count }

	for i := 0; i < frame_count; {
		for event_index < event_count {
			// Handle every event at frame i.
			if next_frame != i {
				break
			}

			header := process.in_events.get(process.in_events, event_index)

			if header.time != i {
				next_frame = header.time
				break
			}

			mp.process_event(header)
			event_index++

			// Event list exhausted.
			if event_index == event_count {
				next_frame = frame_count
				break
			}
		}

		for ; i < next_frame; i++ {
			// In general:
			// mut inputs := []C.clap_audio_buffer_t{cap: int(process.audio_inputs_count)}
			// for k := 0; k < process.audio_inputs_count; k++  {
			// 	inputs << unsafe{ process.audio_inputs[k] }
			// }
			input_left := unsafe { process.audio_inputs[0].data32[0][i] }
			input_right := unsafe { process.audio_inputs[0].data32[1][i] }

			// Swap left and right channels.
			unsafe {
				process.audio_outputs[0].data32[0][i] = input_right
			}
			unsafe {
				process.audio_outputs[0].data32[1][i] = input_left
			}
		}
	}

	return ClapProcessStatus.@continue
}

fn (mut mp MinimalPlugin) get_extension(clap_plugin &C.clap_plugin_t, id &char) voidptr {
	v_id := unsafe { cstring_to_vstring(id) }

	match v_id {
		clap_ext_latency {
			return &C.clap_plugin_latency_t{
				get: fn [mp] (clap_plugin &C.clap_plugin_t) u32 {
					return mp.latency
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
					// vfmt off
					info.supported_dialects = (
						u32(ClapNoteDialect.clap) |
						u32(ClapNoteDialect.midi_mpe) |
						u32(ClapNoteDialect.midi2)
					)
					// vfmt on
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
		clap_ext_gui {
			return &C.clap_plugin_gui_t{
				is_api_supported: fn (clap_plugin &C.clap_plugin_t, api &char, is_floating bool) bool {
					if is_floating {
						return false
					}
					v_api := unsafe { cstring_to_vstring(api) }
					// Only X11 for now.
					return v_api == clap_window_api_x11
				}
				get_preferred_api: fn (clap_plugin &C.clap_plugin_t, mut api voidptr, mut is_floating &bool) bool {
					is_floating = false
					api = unsafe { &clap_window_api_x11 }
					return true
				}
				create: fn [mut mp] (clap_plugin &C.clap_plugin_t, api &char, is_floating bool) bool {
					v_api := unsafe { cstring_to_vstring(api) }
					if v_api != clap_window_api_x11 || is_floating {
						return false
					}
					if !isnil(mp.gui) {
						panic('GUI already initialised!')
					}
					mp.gui = GUI.create(vclap.gui_width, vclap.gui_height, plugin_name)
					// Register the file descriptor we'll receive events from.
					if !isnil(mp.host_posix_fd) && !isnil(mp.host_posix_fd.register_fd) {
						mp.host_posix_fd.register_fd(mp.host, mp.gui.fd, ClapPosixFDFlags.read)
					}

					return true
				}
				destroy: fn [mut mp] (clap_plugin &C.clap_plugin_t) {
					if !isnil(mp.host_posix_fd) && !isnil(mp.host_posix_fd.unregister_fd) {
						mp.host_posix_fd.unregister_fd(mp.host, mp.gui.fd)
					}
					if isnil(mp.gui) {
						panic('GUI not initialised!')
					}
					mp.gui.destroy()

					unsafe {
						mp.gui = nil
					}
				}
				set_scale: fn (clap_plugin &C.clap_plugin_t, scale f64) bool {
					return false
				}
				get_size: fn (clap_plugin &C.clap_plugin_t, mut width &u32, mut height &u32) bool {
					width = vclap.gui_width
					height = vclap.gui_height
					return true
				}
				can_resize: fn (clap_plugin &C.clap_plugin_t) bool {
					return false
				}
				get_resize_hints: fn (clap_plugin &C.clap_plugin_t, hints &C.clap_gui_resize_hints_t) bool {
					return false
				}
				adjust_size: fn (clap_plugin &C.clap_plugin_t, mut width &u32, mut height &u32) bool {
					width = vclap.gui_width
					height = vclap.gui_height
					return true
				}
				set_size: fn (clap_plugin &C.clap_plugin_t, width &u32, height &u32) bool {
					return true
				}
				set_parent: fn [mut mp] (clap_plugin &C.clap_plugin_t, window &C.clap_window_t) bool {
					v_wapi := unsafe { (&char(window.api)).vstring() }
					assert v_wapi == clap_window_api_x11, 'Bad GUI API'

					mp.gui.set_parent(window.x11)
					return true
				}
				set_transient: fn (clap_plugin &C.clap_plugin_t, window &C.clap_window_t) bool {
					return false
				}
				suggest_title: fn (clap_plugin &C.clap_plugin_t, title &char) {}
				show: fn [mp] (clap_plugin &C.clap_plugin_t) bool {
					mp.gui.set_visible(true)
					return true
				}
				hide: fn [mp] (clap_plugin &C.clap_plugin_t) bool {
					mp.gui.set_visible(false)
					return true
				}
			}
		}
		clap_ext_posix_fd_support {
			return &C.clap_plugin_posix_fd_support_t{
				on_fd: fn [mp] (clap_plugin &C.clap_plugin_t, fd int, flags ClapPosixFDFlags) {
					mp.gui.on_posix_fd()
				}
			}
		}
		else {
			return unsafe { nil }
		}
	}
}

fn (mp MinimalPlugin) on_main_thread(clap_plugin &C.clap_plugin_t) {
}

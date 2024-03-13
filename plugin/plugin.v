module plugin

import odiroot.clap
import odiroot.clap.ext as cext
import plugin.gui { GUI }
import plugin.vgui

const gui_width = 640
const gui_height = 480

// This should be the actual implementation of the plugin with
// all the interesting logic like DSP, UI, etc.
@[heap]
struct MinimalPlugin {
	host &clap.Host
mut:
	sample_rate   f64
	latency       u32
	host_posix_fd &cext.HostPosixFdSupport = unsafe { nil }
	gui           &gui.GUI = unsafe { nil }
}

// Extract our actual pluging from CLAP plugin wrapper.
fn from_clap(clap_plugin &clap.Plugin) &MinimalPlugin {
	return unsafe { &MinimalPlugin(clap_plugin.plugin_data) }
}

fn (mut mp MinimalPlugin) init(clap_plugin &clap.Plugin) bool {
	mp.host_posix_fd = mp.host.get_extension(mp.host, cext.ext_posix_fd_support.str)
	return true
}

fn (mp MinimalPlugin) destroy(clap_plugin &clap.Plugin) {
	// Cleanup plugin members here.
}

fn (mut mp MinimalPlugin) activate(clap_plugin &clap.Plugin, sample_rate f64, min_frames_count u32, max_frames_count u32) bool {
	mp.sample_rate = sample_rate
	return true
}

fn (mp MinimalPlugin) deactivate(clap_plugin &clap.Plugin) {
}

fn (mp MinimalPlugin) start_processing(clap_plugin &clap.Plugin) bool {
	return true
}

fn (mp MinimalPlugin) stop_processing(clap_plugin &clap.Plugin) {
}

fn (mp MinimalPlugin) reset(clap_plugin &clap.Plugin) {
	// Cleanup plugin members here.
}

fn (mp MinimalPlugin) process_event(header &clap.EventHeader) {
	if header.space_id != clap.core_event_space_id {
		return
	}

	match header.@type {
		u16(clap.event_note_on) {
			// Handle note playing.
			event := unsafe { &clap.EventNote(header) }
			debug('Note ON: ${event.note_id}')
		}
		u16(clap.event_note_off) {
			// Handle note stop playing.
			event := unsafe { &clap.EventNote(header) }
			debug('Note OFF: ${event.note_id}')
		}
		// And so on...
		else {
			t := unsafe { clap.EventType(header.@type) }
			debug('Unsupported event type: ${t}')
		}
	}
}

fn (mp MinimalPlugin) process(clap_plugin &clap.Plugin, mut process clap.Process) clap.ProcessStatus {
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
			// mut inputs := []AudioBuffer{cap: int(process.audio_inputs_count)}
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

	return clap.process_continue
}

fn (mut mp MinimalPlugin) get_extension(clap_plugin &clap.Plugin, id &char) voidptr {
	v_id := unsafe { cstring_to_vstring(id) }

	match v_id {
		cext.ext_latency {
			return &cext.PluginLatency{
				get: fn [mp] (clap_plugin &clap.Plugin) u32 {
					return mp.latency
				}
			}
		}
		cext.ext_audio_ports {
			return &cext.PluginAudioPorts{
				count: fn (clap_plugin &clap.Plugin, is_input bool) u32 {
					return 1
				}
				get: fn (clap_plugin &clap.Plugin, index u32, is_input bool, mut info cext.AudioPortInfo) bool {
					// Just one port.
					if index > 0 {
						return false
					}

					info.id = 0
					info.channel_count = 2
					info.flags = cext.audio_port_is_main
					info.port_type = cext.port_stereo.str
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
		cext.ext_note_ports {
			return &cext.PluginNotePorts{
				count: fn (clap_plugin &clap.Plugin, is_input bool) u32 {
					return 1
				}
				get: fn (clap_plugin &clap.Plugin, index u32, is_input bool, mut info &cext.NotePortInfo) bool {
					if index > 0 {
						return false
					}

					info.id = 0
					// vfmt off
					info.supported_dialects = (
						u32(cext.note_dialect_clap) |
						u32(cext.note_dialect_midi_mpe) |
						u32(cext.note_dialect_midi2)
					)
					// vfmt on
					info.preferred_dialect = u32(cext.note_dialect_clap)

					port_name := 'Example note port'
					for i, chr in port_name {
						info.name[i] = chr
					}
					info.name[port_name.len] = char(0)

					return true
				}
			}
		}
		cext.ext_gui {
			return &cext.PluginGUI{
				is_api_supported: fn (clap_plugin &clap.Plugin, api &char, is_floating bool) bool {
					if is_floating {
						return false
					}
					v_api := unsafe { cstring_to_vstring(api) }
					// Only X11 for now.
					return v_api == cext.window_api_x11
				}
				get_preferred_api: fn (clap_plugin &clap.Plugin, mut api voidptr, mut is_floating &bool) bool {
					is_floating = false
					api = &cext.window_api_x11.str
					return true
				}
				create: fn [mut mp] (clap_plugin &clap.Plugin, api &char, is_floating bool) bool {
					vgui.run()
					v_api := unsafe { cstring_to_vstring(api) }
					if v_api != cext.window_api_x11 || is_floating {
						return false
					}
					if !isnil(mp.gui) {
						panic('GUI already initialised!')
					}
					mp.gui = GUI.create(gui_width, gui_height, plugin_name)
					// Register the file descriptor we'll receive events from.
					if !isnil(mp.host_posix_fd) && !isnil(mp.host_posix_fd.register_fd) {
						mp.host_posix_fd.register_fd(mp.host, mp.gui.fd, cext.posix_fd_read)
					}

					return true
				}
				destroy: fn [mut mp] (clap_plugin &clap.Plugin) {
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
				set_scale: fn (clap_plugin &clap.Plugin, scale f64) bool {
					return false
				}
				get_size: fn (clap_plugin &clap.Plugin, mut width &u32, mut height &u32) bool {
					width = gui_width
					height = gui_height
					return true
				}
				can_resize: fn (clap_plugin &clap.Plugin) bool {
					return false
				}
				get_resize_hints: fn (clap_plugin &clap.Plugin, hints &cext.GUIResizeHints) bool {
					return false
				}
				adjust_size: fn (clap_plugin &clap.Plugin, mut width &u32, mut height &u32) bool {
					width = gui_width
					height = gui_height
					return true
				}
				set_size: fn (clap_plugin &clap.Plugin, width &u32, height &u32) bool {
					return true
				}
				set_parent: fn [mut mp] (clap_plugin &clap.Plugin, window &cext.Window) bool {
					v_wapi := unsafe { (&char(window.api)).vstring() }
					assert v_wapi == cext.window_api_x11, 'Bad GUI API'

					mp.gui.set_parent(window.x11)
					return true
				}
				set_transient: fn (clap_plugin &clap.Plugin, window &cext.Window) bool {
					return false
				}
				suggest_title: fn (clap_plugin &clap.Plugin, title &char) {}
				show: fn [mp] (clap_plugin &clap.Plugin) bool {
					mp.gui.set_visible(true)
					return true
				}
				hide: fn [mp] (clap_plugin &clap.Plugin) bool {
					mp.gui.set_visible(false)
					return true
				}
			}
		}
		cext.ext_posix_fd_support {
			return &cext.PluginPosixFdSupport{
				on_fd: fn [mp] (clap_plugin &clap.Plugin, fd int, flags cext.PosixFdFlags) {
					mp.gui.on_posix_fd()
				}
			}
		}
		else {
			return unsafe { nil }
		}
	}
}

fn (mp MinimalPlugin) on_main_thread(clap_plugin &clap.Plugin) {
}

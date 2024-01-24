module vclap

const clap_ext_gui = unsafe { (&char(C.CLAP_EXT_GUI)).vstring() }
const clap_window_api_x11 = unsafe { (&char(C.CLAP_WINDOW_API_X11)).vstring() }
const clap_window_api_wayland = unsafe { (&char(C.CLAP_WINDOW_API_WAYLAND)).vstring() }

type C.clap_hwnd = voidptr
type C.clap_nsview = voidptr
type C.clap_xwnd = u32

@[typedef]
struct C.clap_window_t {
	api &char
	// union {
	cocoa C.clap_nsview
	x11   C.clap_xwnd
	win32 C.clap_hwnd
	ptr   voidptr
	// }
}

@[typedef]
struct C.clap_gui_resize_hints_t {
	can_resize_horizontally bool
	can_resize_vertically   bool
	preserve_aspect_ratio   bool
	aspect_ratio_width      u32
	aspect_ratio_height     u32
}

@[typedef]
struct C.clap_plugin_gui_t {
	is_api_supported  fn (&C.clap_plugin_t, &char, bool) bool
	// voidptr is &&char in original but used in a weird way.
	get_preferred_api fn (&C.clap_plugin_t, voidptr, &bool) bool
	create            fn (&C.clap_plugin_t, &char, bool) bool
	destroy           fn (&C.clap_plugin_t)
	set_scale         fn (&C.clap_plugin_t, f64) bool
	get_size          fn (&C.clap_plugin_t, &u32, &u32) bool
	can_resize        fn (&C.clap_plugin_t) bool
	get_resize_hints  fn (&C.clap_plugin_t, &C.clap_gui_resize_hints_t) bool
	adjust_size       fn (&C.clap_plugin_t, &u32, &u32) bool
	set_size          fn (&C.clap_plugin_t, &u32, &u32) bool
	set_parent        fn (&C.clap_plugin_t, &C.clap_window_t) bool
	set_transient     fn (&C.clap_plugin_t, &C.clap_window_t) bool
	suggest_title     fn (&C.clap_plugin_t, &char)
	show              fn (&C.clap_plugin_t) bool
	hide              fn (&C.clap_plugin_t) bool
}

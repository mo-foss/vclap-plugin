module gui

#pkgconfig --libs xcb

#include <xcb/xcb.h>

// XCB library
type C.xcb_window_t = u32
type C.xcb_gcontext_t = u32
type C.xcb_visualid_t = u32
type C.xcb_atom_t = u32

@[typedef]
struct C.xcb_connection_t {}

@[typedef]
struct C.xcb_setup_t {}

@[typedef]
struct C.xcb_screen_t {
	root        C.xcb_window_t
	root_visual C.xcb_visualid_t
	white_pixel u32
	black_pixel u32
}

@[typedef]
struct C.xcb_screen_iterator_t {
	data &C.xcb_screen_t
}

@[typedef]
struct C.xcb_gcontext_t {}

@[typedef]
struct C.xcb_rectangle_t {
	x      i16
	y      i16
	width  u16
	height u16
}

@[typedef]
struct C.xcb_generic_event_t {
	response_type u8
}

@[typedef]
struct C.xcb_expose_event_t {
	window C.xcb_window_t
}

fn C.xcb_connect(&char, &int) &C.xcb_connection_t
fn C.xcb_disconnect(&C.xcb_connection_t)
fn C.xcb_flush(&C.xcb_connection_t)

fn C.xcb_get_setup(&C.xcb_connection_t) &C.xcb_setup_t
fn C.xcb_setup_roots_iterator(&C.xcb_setup_t) C.xcb_screen_iterator_t
fn C.xcb_generate_id(&C.xcb_connection_t) u32
fn C.xcb_get_file_descriptor(&C.xcb_connection_t) int

fn C.xcb_create_window(&C.xcb_connection_t, u8, C.xcb_window_t, C.xcb_window_t, i16, i16, u16, u16, u16, u16, C.xcb_visualid_t, u32, voidptr)
fn C.xcb_destroy_window(&C.xcb_connection_t, C.xcb_window_t)
fn C.xcb_configure_window(&C.xcb_connection_t, C.xcb_window_t, u16, voidptr)
fn C.xcb_change_window_attributes(&C.xcb_connection_t, C.xcb_window_t, u32, voidptr)
fn C.xcb_reparent_window(&C.xcb_connection_t, C.xcb_window_t, C.xcb_window_t, i16, i16)
fn C.xcb_map_window(&C.xcb_connection_t, C.xcb_window_t)
fn C.xcb_unmap_window(&C.xcb_connection_t, C.xcb_window_t)

fn C.xcb_create_gc(&C.xcb_connection_t, C.xcb_gcontext_t, C.xcb_window_t, u32, voidptr)
fn C.xcb_free_gc(&C.xcb_connection_t, C.xcb_gcontext_t)
fn C.xcb_change_gc(&C.xcb_connection_t, C.xcb_gcontext_t, u32, voidptr)

fn C.xcb_clear_area(&C.xcb_connection_t, u8, C.xcb_window_t, i16, i16, u16, u16)
fn C.xcb_poly_rectangle(&C.xcb_connection_t, C.xcb_window_t, C.xcb_gcontext_t, u32, &C.xcb_rectangle_t)
fn C.xcb_poly_fill_rectangle(&C.xcb_connection_t, C.xcb_window_t, C.xcb_gcontext_t, u32, &C.xcb_rectangle_t)

fn C.xcb_poll_for_event(&C.xcb_connection_t) &C.xcb_generic_event_t


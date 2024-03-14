module gui

@[heap]
pub struct GUI {
	width      u32
	height     u32
	connection &C.xcb_connection_t
	window     C.xcb_window_t
	gc         C.xcb_gcontext_t
pub:
	fd int
}

pub fn GUI.create(width u32, height u32, title string) &GUI {
	// Open the connection to the X server.
	conn := unsafe { C.xcb_connect(nil, nil) }
	if isnil(conn) {
		panic('Unable to open XCB connection.')
	}

	// Get the first screen.
	screen := C.xcb_setup_roots_iterator(C.xcb_get_setup(conn)).data
	// Create a window.
	window := C.xcb_generate_id(conn)
	C.xcb_create_window(conn, C.XCB_COPY_FROM_PARENT, window, screen.root, 0, 0, width,
		height, 1, C.XCB_WINDOW_CLASS_INPUT_OUTPUT, screen.root_visual, C.XCB_CW_BACK_PIXEL,
		&screen.white_pixel)

	// Select the events the window will receive.
	event_mask := C.XCB_EVENT_MASK_EXPOSURE | C.XCB_EVENT_MASK_POINTER_MOTION | C.XCB_EVENT_MASK_BUTTON_PRESS | C.XCB_EVENT_MASK_BUTTON_RELEASE | C.XCB_EVENT_MASK_KEY_PRESS | C.XCB_EVENT_MASK_KEY_RELEASE | C.XCB_EVENT_MASK_ENTER_WINDOW | C.XCB_EVENT_MASK_LEAVE_WINDOW | C.XCB_EVENT_MASK_BUTTON_MOTION | C.XCB_EVENT_MASK_KEYMAP_STATE | C.XCB_EVENT_MASK_FOCUS_CHANGE
	C.xcb_change_window_attributes(conn, window, C.XCB_CW_EVENT_MASK, &event_mask)

	// Inform a window manager not to tamper with the window
	// Note: doesn't work in standalone.
	C.xcb_change_window_attributes(conn, window, C.XCB_CW_OVERRIDE_REDIRECT, &[1]!)

	// Create a graphic context to paint on.
	gc := C.xcb_generate_id(conn)
	gc_values := [screen.black_pixel, 0]!
	C.xcb_create_gc(conn, gc, window, C.XCB_GC_FOREGROUND | C.XCB_GC_GRAPHICS_EXPOSURES,
		&gc_values)

	C.xcb_flush(conn)

	return &GUI{
		width: width
		height: height
		connection: conn
		window: window
		gc: gc
		fd: C.xcb_get_file_descriptor(conn)
	}
}

pub fn (g &GUI) destroy() {
	C.xcb_free_gc(g.connection, g.gc)
	C.xcb_destroy_window(g.connection, g.window)
	C.xcb_disconnect(g.connection)
}

pub fn (g &GUI) set_parent(parent u32) {
	C.xcb_reparent_window(g.connection, g.window, parent, 0, 0)
	C.xcb_flush(g.connection)
}

pub fn (g &GUI) set_visible(visible bool) {
	// XXX: Doesn't seem to be necessary for embedded window.
	// if visible {
	// 	C.xcb_configure_window(g.connection, g.window, C.XCB_CONFIG_WINDOW_STACK_MODE,
	// 		&[C.XCB_STACK_MODE_ABOVE]!)
	// 	C.xcb_map_window(g.connection, g.window)
	// } else {
	// 	C.xcb_unmap_window(g.connection, g.window)
	// }
	// C.xcb_flush(g.connection)
}

fn (g &GUI) paint() {
	C.xcb_clear_area(g.connection, 0, g.window, 0, 0, g.width, g.height)
	// Parameter "slider".
	C.xcb_change_gc(g.connection, g.gc, C.XCB_GC_FOREGROUND, &[0]!)
	C.xcb_poly_rectangle(g.connection, g.window, g.gc, 1, &C.xcb_rectangle_t{50, 50, 25, 100})
	C.xcb_poly_fill_rectangle(g.connection, g.window, g.gc, 1, &C.xcb_rectangle_t{50, 50, 25, 40})
}

pub fn (g &GUI) on_posix_fd() {
	C.xcb_flush(g.connection)

	for {
		event := C.xcb_poll_for_event(g.connection)
		if isnil(event) {
			break
		}
		t := event.response_type & ~0x80
		match t {
			u8(C.XCB_EXPOSE) {
				expose_ev := &C.xcb_expose_event_t(event)
				if expose_ev.window == g.window {
					g.paint()
				}
			}
			else {}
		}

		C.xcb_flush(g.connection)
		C.free(event)
	}
}

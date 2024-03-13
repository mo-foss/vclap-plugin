module vgui

import ui

struct App {
mut:
	window &ui.Window = unsafe { nil }
}

pub fn run() {
	mut app := &App{}
	app.window = ui.window(
		width: 600
		height: 400
		title: 'V UI for CLAP plugin'
		children: []
	)
	spawn ui.run(app.window)
}

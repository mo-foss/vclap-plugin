module vclap

const clap_ext_posix_fd_support = unsafe { (&char(C.CLAP_EXT_POSIX_FD_SUPPORT)).vstring() }

enum ClapPosixFDFlags as u32 {
	read  = 1 << 0
	write = 1 << 1
	error = 1 << 2
}

@[typedef]
struct C.clap_host_posix_fd_support_t {
	register_fd   fn (&C.clap_host_t, int, ClapPosixFDFlags) bool
	modify_fd     fn (&C.clap_host_t, int, ClapPosixFDFlags) bool
	unregister_fd fn (&C.clap_host_t, int) bool
}

@[typedef]
struct C.clap_plugin_posix_fd_support_t {
	on_fd fn (&C.clap_plugin_t, int, ClapPosixFDFlags)
}

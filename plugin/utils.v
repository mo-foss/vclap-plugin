module plugin
import time

@[if debug]
pub fn debug(s string) {
	eprintln(s)
}

@[inline]
fn log_current_memory() {
	mem_use := gc_memory_use() / 1024
	C.fprintf(C.stderr, c'TOTAL MEMORY: %10d KB\n', mem_use)
}

@[if debug]
pub fn mem_logger() {
	for {
		log_current_memory()
		time.sleep(time.second * 2)
	}
}

fn run_gc_oneshot() {
	debug("ENABLING GC.")
	C.GC_enable()
	debug("COLLECTING GC.")
	log_current_memory()
    C.GC_gcollect()
    debug("DISABLING GC")
    C.GC_disable()
}

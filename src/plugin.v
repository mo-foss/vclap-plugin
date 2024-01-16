module plugin

// This should be the actual implementation of the plugin with
// all the interesting logic like DSP, UI, etc.
struct MinimalPlugin {
}

fn (mp MinimalPlugin) init(clap_plugin &C.clap_plugin_t) bool {
    return true
}

fn MinimalPlugin.destroy(clap_plugin &C.clap_plugin_t) {
    // TODO: Ensure memory clean.
}

fn MinimalPlugin.activate(clap_plugin &C.clap_plugin_t, sample_rate f64, min_frames_count u32, max_frames_count u32) bool {
    // TODO: Store on plugin: sample_rate.
    return false
}

fn MinimalPlugin.deactivate(clap_plugin &C.clap_plugin_t) {
}

fn MinimalPlugin.start_processing(clap_plugin &C.clap_plugin_t) bool {
    return true
}

fn MinimalPlugin.stop_processing(clap_plugin &C.clap_plugin_t) {
}

fn MinimalPlugin.reset(clap_plugin &C.clap_plugin_t)  {
}

fn MinimalPlugin.process(clap_plugin &C.clap_plugin_t, process &C.clap_process_t) ClapProcessStatus {
    return ClapProcessStatus.clap_process_continue
}

fn MinimalPlugin.get_extension(clap_plugin &C.clap_plugin_t, id &char) voidptr {
    // TODO
    return voidptr(0)
}

fn MinimalPlugin.on_main_thread(clap_plugin &C.clap_plugin_t)  {
}

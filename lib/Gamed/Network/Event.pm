module Event;

use NativeCall;

def event_active(struct event *ev, int res, short ncalls) is export is native('libevent.dll') { * }
def event_add(struct event *ev, const struct timeval *timeout) returns Int is export is native('libevent.dll') { * }
def event_assign(struct event *, struct event_base *, evutil_socket_t, short, event_callback_fn, void *) returns Int is export is native('libevent.dll') { * }
def event_base_dispatch(struct event_base *) returns Int is export is native('libevent.dll') { * }
def event_base_dump_events(struct event_base *, FILE *) is export is native('libevent.dll') { * }
def event_base_free(struct event_base *) is export is native('libevent.dll') { * }
def event_base_get_features(const struct event_base *base) returns Int is export is native('libevent.dll') { * }
def event_base_get_method(const struct event_base *) returns OpaquePointer is export is native('libevent.dll') { * }
def event_base_gettimeofday_cached(struct event_base *base, struct timeval *tv) returns Int is export is native('libevent.dll') { * }
def event_base_got_break(struct event_base *) returns Int is export is native('libevent.dll') { * }
def event_base_got_exit(struct event_base *) returns Int is export is native('libevent.dll') { * }
def event_base_init_common_timeout(struct event_base *base, const struct timeval *duration) returns OpaquePointer is export is native('libevent.dll') { * }
def event_base_loop(struct event_base *, int) returns Int is export is native('libevent.dll') { * }
def event_base_loopbreak(struct event_base *) returns Int is export is native('libevent.dll') { * }
def event_base_loopexit(struct event_base *, const struct timeval *) returns Int is export is native('libevent.dll') { * }
def event_base_new (void) returns OpaquePointer is export is native('libevent.dll') { * }
def event_base_new_with_config (const struct event_config *) returns OpaquePointer is export is native('libevent.dll') { * }
def event_base_once(struct event_base *, evutil_socket_t, short, event_callback_fn, void *, const struct timeval *) returns Int is export is native('libevent.dll') { * }
def event_base_priority_init(struct event_base *, int) returns Int is export is native('libevent.dll') { * }
def event_base_set(struct event_base *, struct event *) returns Int is export is native('libevent.dll') { * }
def event_config_avoid_method(struct event_config *cfg, const char *method) returns Int is export is native('libevent.dll') { * }
def event_config_free(struct event_config *cfg) is export is native('libevent.dll') { * }
def event_config_new (void) returns OpaquePointer is export is native('libevent.dll') { * }
def event_config_require_features(struct event_config *cfg, int feature) returns Int is export is native('libevent.dll') { * }
def event_config_set_flag(struct event_config *cfg, int flag) returns Int is export is native('libevent.dll') { * }
def event_config_set_num_cpus_hint(struct event_config *cfg, int cpus) returns Int is export is native('libevent.dll') { * }
def event_debug_unassign(struct event *) is export is native('libevent.dll') { * }
def event_del(struct event *) returns Int is export is native('libevent.dll') { * }
def event_enable_debug_mode(void) is export is native('libevent.dll') { * }
def event_free(struct event *) is export is native('libevent.dll') { * }
def event_get_assignment(const struct event *event, struct event_base **base_out, evutil_socket_t *fd_out, short *events_out, event_callback_fn *callback_out, void **arg_out) is export is native('libevent.dll') { * }
def event_get_base (const struct event *ev) returns OpaquePointer is export is native('libevent.dll') { * }
def event_get_callback (const struct event *ev) returns OpaquePointer is export is native('libevent.dll') { * }
def event_get_callback_arg(const struct event *ev) returns OpaquePointer is export is native('libevent.dll') { * }
def event_get_events (const struct event *ev) returns Int is export is native('libevent.dll') { * }
def event_get_fd (const struct event *ev) returns OpaquePointer is export is native('libevent.dll') { * }
def event_get_struct_event_size (void) returns OpaquePointer is export is native('libevent.dll') { * }
def event_get_supported_methods (void) returns Array[Str] is export is native('libevent.dll') { * }
def event_get_version (void) returns Str is export is native('libevent.dll') { * }
def event_get_version_number (void) returns Int is export is native('libevent.dll') { * }
def event_initialized(const struct event *ev) returns Int is export is native('libevent.dll') { * }
def event_new (struct event_base *, evutil_socket_t, short, event_callback_fn, void *) returns OpaquePointer is export is native('libevent.dll') { * }
def event_pending(const struct event *ev, short events, struct timeval *tv) returns Int is export is native('libevent.dll') { * }
def event_priority_set(struct event *, int) returns Int is export is native('libevent.dll') { * }
def event_reinit(struct event_base *base) returns Int is export is native('libevent.dll') { * }
def event_set_fatal_callback(event_fatal_cb cb) is export is native('libevent.dll') { * }
def event_set_log_callback(event_log_cb cb) is export is native('libevent.dll') { * }
def event_set_mem_functions(void *(*malloc_fn)(size_t sz), void *(*realloc_fn)(void *ptr, size_t sz), void(*free_fn)(void *ptr)) is export is native('libevent.dll') { * }

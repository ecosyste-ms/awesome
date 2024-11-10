/**
 * AppSignal public interface
 *
 * Contact us at support@appsignal.com if you want to integrate this into whichever
 * tool you're using and have any questions or remarks! We'd love to help you.
 *
 * This interface is expected to be stable, but we reserve the right to make changes to
 * it if we have a pressing reason to do so.
 */

/**
 * Representation of a String. buf is expected to contain a valid
 * UTF-8 string with the specified len.
 */
typedef struct {
    size_t len;
    const char* buf;
} appsignal_string_t;

/*
 * Pointer to a transaction instance that's used to gather data on
 * a running transaction.
 */
typedef void appsignal_transaction_t;

/*
 * Pointer to a span instance that's used to gather data on
 * a running request or transcation.
 */
typedef void appsignal_span_t;

/*
 * Pointer to a data instance that's used to build up sample data.
 */
typedef void appsignal_data_t;

/*
 * Put an environment value on the local appsignal configuration set that will
 * be merged with the system environment variables when loading configuration.
 *
 * The key format expected here is a private `_APPSIGNAL_*` prefixed
 * environment variable key.
 *
 * The `appsignal_env_*` functions are only used for integrations with
 * languages that don’t have a reliable way to read and write environment
 * variables, like Elixir/Erlang. These functions are not required to be
 * implemented if that’s not the case.
 *
 * @param key of the configuration
 * @param value of the configuration
 */
void appsignal_env_put(appsignal_string_t, appsignal_string_t);

/*
 * Get a local appsignal environment value.
 *
 * The key format expected here is a private `_APPSIGNAL_*` prefixed
 * environment variable key.
 *
 * @param key of the configuration
 *
 * @return the value of the configuration
 */
appsignal_string_t appsignal_env_get(appsignal_string_t);

/*
 * Delete a local appsignal environment value.
 *
 * The key format expected here is a private `_APPSIGNAL_*` prefixed
 * environment variable key.
 *
 * @param key of the configuration
 */
void appsignal_env_delete(appsignal_string_t);

/*
 * Clear the local appsignal environment.
 */
void appsignal_env_clear();

/*
 * Start appsignal extension
 *
 * This initializes the extension and boots an appsignal agent
 * daemon if it's not already running. Before calling this valid
 * configuration needs to be present in the environment:
 *
 * _APPSIGNAL_ACTIVE: extension starts if value is true
 * _APPSIGNAL_APP_PATH: path to the app we're monitoring
 * _APPSIGNAL_AGENT_PATH: Path to directory where extension and agent are installed
 * _APPSIGNAL_LOG_PATH: Path to write logs to
 * _APPSIGNAL_PUSH_API_ENDPOINT: Endpoint to post data to (https://push.appsignal.com)
 * _APPSIGNAL_PUSH_API_KEY: Key you get in the installation wizard on https://appsignal.com
 * _APPSIGNAL_APP_ENV: Environment we're monitoring (staging, production)
 * _APPSIGNAL_APP_NAME: Name of the application we're monitoring
 * _APPSIGNAL_AGENT_VERSION: Version of the agent we're running
 * _APPSIGNAL_TRANSMISSION_INTERVAL: Optional, amount of time between transmissions. Default is 30
 * _APPSIGNAL_WORKING_DIRECTORY_PATH: Optional, set a specific path to store appsignal tmp files
 * _APPSIGNAL_DIAGNOSE: Optional, run extension and agent in diagnose mode and
 *   exit. Only works in combination with `appsignal_diagnose`.
 *
 * This function needs to be called before calling other functions, otherwise the other
 * functions will fail silently.
 */
void appsignal_start(void);

/*
 * Stops appsignal worker thread and wait for the last data to flush the agent.
 */
void appsignal_stop(void);

/*
 * Starts appsignal extension and agent in diagnose mode and returns result in JSON string.
 * Only works in combination with`_APPSIGNAL_DIAGNOSE` set to `true`.
 */
appsignal_string_t appsignal_diagnose(void);

/*
 * Get state information that the server possibly sent.
 *
 * This currently not used in any of the integrations. It's not required to be implemented.
 *
 * @param key of the state information
 *
 * @return piece of state information
 */
appsignal_string_t appsignal_get_server_state(appsignal_string_t);

/*
 * Start a transaction
 *
 * Call this when a transaction such as a http request or background job starts.
 *
 * @param transaction_id The unique identifier of this transaction
 * @param namespace The namespace of this transaction (http_request, background_job)
 * @param gc_duration_ms The current garbage collection duration in milliseconds
 *
 * @return pointer to this transaction for use with the the other transaction functions
 * store this in a thread or fiber/coroutine local variable
 */
appsignal_transaction_t* appsignal_start_transaction(appsignal_string_t, appsignal_string_t, long long);

/*
 * Start an event
 *
 * Call this when an event within a transaction you want to measure starts, such as
 * an SQL query or http request.
 *
 * @param transaction The pointer to the transaction this event occurred in
 * @param gc_duration_ms The current garbage collection duration in milliseconds
 */
void appsignal_start_event(appsignal_transaction_t*, long long);

/*
 * Finish an event
 *
 * Call this when an event ends.
 *
 * @param transaction The pointer to the transaction this event occurred in
 * @param name Name of the category of the event (sql.query, net.http)
 * @param title Title of the event ('User load', 'Http request to google.com')
 * @param body Body of the event, should not contain unique information per specific event ('select * from users where id=?')
 * @param body_format Format of the event's body which can be used for sanitization, 0 for general and 1 for sql currently.
 * @param gc_duration_ms The current garbage collection duration in milliseconds
 */
void appsignal_finish_event(appsignal_transaction_t*, appsignal_string_t, appsignal_string_t, appsignal_string_t, int, long long);

/*
 * Finish an event with data payload
 *
 * Call this when an event ends.
 *
 * @param transaction The pointer to the transaction this event occurred in
 * @param name Name of the category of the event (sql.query, net.http)
 * @param title Title of the event ('User load', 'Http request to google.com')
 * @param body Body of the event, should not contain unique information per specific event ('select * from users where id=?')
 * @param body_format Format of the event's body which can be used for sanitization, 0 for general and 1 for sql currently.
 * @param gc_duration_ms The current garbage collection duration in milliseconds*
 */
void appsignal_finish_event_data(appsignal_transaction_t*, appsignal_string_t, appsignal_string_t, appsignal_data_t*, int, long long);

/*
 * Record a finished event
 *
 * Call this when an event which you cannot track the start for ends. This function can only be used for events that do not
 * have children such as database queries. GC metrics and allocation counts will be tracked in the parent of this event.
 *
 * @param transaction The pointer to the transaction this event occurred in
 * @param name Name of the category of the event (sql.query, net.http)
 * @param title Title of the event ('User load', 'Http request to google.com')
 * @param body Body of the event, should not contain unique information per specific event ('select * from users where id=?')
 * @param body_format Format of the event's body which can be used for sanitization, 0 for general and 1 for sql currently.
 * @param duration Duration of this event in nanoseconds
 * @param gc_duration_ms The event's total garbage collection duration in milliseconds
 */
void appsignal_record_event(appsignal_transaction_t*, appsignal_string_t, appsignal_string_t, appsignal_string_t, int, long long, long long);

/*
 * Record a finished event with data payload
 *
 * Call this when an event which you cannot track the start for ends. This function can only be used for events that do not
 * have children such as database queries. GC metrics and allocation counts will be tracked in the parent of this event.
 *
 * @param transaction The pointer to the transaction this event occurred in
 * @param name Name of the category of the event (sql.query, net.http)
 * @param title Title of the event ('User load', 'Http request to google.com')
 * @param body Body of the event, should not contain unique information per specific event ('select * from users where id=?')
 * @param body_format Format of the event's body which can be used for sanitization, 0 for general and 1 for sql currently.
 * @param duration Duration of this event in nanoseconds
 * @param gc_duration_ms The current garbage collection duration in milliseconds
 */
void appsignal_record_event_data(appsignal_transaction_t*, appsignal_string_t, appsignal_string_t, appsignal_data_t*, int, long long, long long);

/*
 * Set an error for a transaction
 *
 * Call this when an error occurs within a transaction.
 *
 * @param transaction The pointer to the transaction this event occurred in
 * @param name Name of the error (RuntimeError)
 * @param message Message of the error ('undefined method call for something')
 * @param backtrace backtrace of the error
 */
void appsignal_set_transaction_error(appsignal_transaction_t*, appsignal_string_t, appsignal_string_t, appsignal_data_t*);

/*
 * Set sample data for a transaction
 *
 * Use this to add sample data if finish_transaction returns true.
 *
 * @param transaction The pointer to the transaction this event occurred in
 * @param key Key of this piece of sample data (params, session_data)
 * @param payload This sample data
 */
void appsignal_set_transaction_sample_data(appsignal_transaction_t*, appsignal_string_t, appsignal_data_t*);

/*
 * Set action of a transaction
 *
 * Call this when the identifying action of a transaction is known.
 *
 * @param transaction The pointer to the transaction this event occurred in
 * @param action This transactions action (HomepageController#show)
 */
void appsignal_set_transaction_action(appsignal_transaction_t*, appsignal_string_t);

/*
 * Set namespace of a transaction
 *
 * Override the initially given namespace if you want to customize it later on.
 *
 * @param transaction The pointer to the transaction this event occurred in
 * @param namespace This transactions overridden namespace
 */
void appsignal_set_transaction_namespace(appsignal_transaction_t*, appsignal_string_t);

/*
 * Set queue start time of a transaction
 *
 * Call this when the queue start time in miliseconds is known.
 *
 * @param transaction The pointer to the transaction this event occurred in
 * @param queue_start Transaction queue start time in ms if known, otherwise -1
 */
void appsignal_set_transaction_queue_start(appsignal_transaction_t*, long long);

/*
 * Set metadata for a transaction
 *
 * Call this when an error occurs within a transaction to set more detailed data about the error
 *
 * @param transaction The pointer to the transaction this event occurred in
 * @param key Key of this piece of metadata (user_id, email)
 * @param value Value of this piece of metadata (thijs@appsignal.com)
 */
void appsignal_set_transaction_metadata(appsignal_transaction_t*, appsignal_string_t, appsignal_string_t);

/*
 * Finish a transaction
 *
 * Call this when a transaction such as a http request or background job ends.
 *
 * @param transaction The pointer to the transaction this event occurred in
 * @param gc_duration_ms The current garbage collection duration in milliseconds
 *
 * @return whether or not sample data for this transaction should be collected and added.
 * 1 for true, 0 for false.
 */
int appsignal_finish_transaction(appsignal_transaction_t*, long long);

/*
 * Duplicate a transaction
 *
 * Call this when a transaction should be duplicated to report multiple errors
 * on the same transaction. Duplicate transactions can only be used for
 * error reporting.
 *
 * @param transaction The pointer to the transaction to duplicate
 * @param new_transaction_id The unique identifier of the new transaction
 *
 * @return pointer to the new transaction for use with the the other transaction functions
 * store this in a thread or fiber/coroutine local variable
 */
appsignal_transaction_t* appsignal_duplicate_transaction(appsignal_transaction_t*, appsignal_string_t);

/*
 * Complete a transaction
 *
 * Call this after finishing a transaction (and adding sample data if necessary).
 *
 * @param transaction The pointer to the transaction this event occurred in
 */
void appsignal_complete_transaction(appsignal_transaction_t*);

/*
 * Get content of a transaction in JSON format, intended for testing purposes.
 */
appsignal_string_t appsignal_transaction_to_json(appsignal_transaction_t*);

/*
 * Free a transaction
 *
 * Call this when a transaction will not be used anymore, mostly used as a callback
 * from the host processes' GC.
 *
 * @param transaction The pointer to the transaction this event occurred in
 */
void appsignal_free_transaction(appsignal_transaction_t*);

/*
 * Create new data map
 *
 * The data encoding methods are used to encode non-string data, like stack
 * traces and event payloads. Each integration has a data encoder that takes
 * data to store with the samples.
 */
appsignal_data_t* appsignal_data_map_new(void);

/*
 * Set values on a data map. Warning: These functions are not thread-safe,
 * always call them on a data from a single thread.
 *
 * @param data The pointer to the data object
 * @param key the field's key, always a string
 * @param value the field's value to set, multiple types
 */
void appsignal_data_map_set_string(appsignal_data_t*, appsignal_string_t, appsignal_string_t);
void appsignal_data_map_set_integer(appsignal_data_t*, appsignal_string_t, long long);
void appsignal_data_map_set_float(appsignal_data_t*, appsignal_string_t, double);
void appsignal_data_map_set_boolean(appsignal_data_t*, appsignal_string_t, int);
void appsignal_data_map_set_null(appsignal_data_t*, appsignal_string_t);
void appsignal_data_map_set_data(appsignal_data_t*, appsignal_string_t, appsignal_data_t*);

/*
 * Create new data array object
 */
appsignal_data_t* appsignal_data_array_new(void);

/*
 * Append values to a data array. Warning: These functions are not thread-safe,
 * always call them on a data from a single thread.
 *
 * @param data The pointer to the data object
 * @param value the value to append, multiple types
 */
void appsignal_data_array_append_string(appsignal_data_t*, appsignal_string_t);
void appsignal_data_array_append_integer(appsignal_data_t*, long long);
void appsignal_data_array_append_float(appsignal_data_t*, double);
void appsignal_data_array_append_boolean(appsignal_data_t*, int);
void appsignal_data_array_append_null(appsignal_data_t*);
void appsignal_data_array_append_data(appsignal_data_t*, appsignal_data_t*);

/*
 * Get content of a data in JSON format, intended for testing purposes.
 */
appsignal_string_t appsignal_data_to_json(appsignal_data_t*);

/*
 * Checks whether or not two data objects have equal content.
 */
int appsignal_data_equal(appsignal_data_t*, appsignal_data_t*);

/*
 * Free a data object
 */
void appsignal_free_data(appsignal_data_t*);

/*
 * Track allocation
 *
 * Optional: Call this when an object is allocated, some languages provide hooks for
 * tracking this.
 */
void appsignal_track_allocation(void);

/*
 * Set a gauge
 *
 * Set a gauge for a measurement of some metric.
 *
 * @param key Key of the metric
 * @param value Measured value
 * @param tags for the metric
 */
void appsignal_set_gauge(appsignal_string_t, double, appsignal_data_t*);

/*
 * Increment a counter
 *
 * Increment a counter of some metric.
 *
 * @param key Key of the metric
 * @param value Number to increment with
 * @param tags for the metric
 */
void appsignal_increment_counter(appsignal_string_t, double, appsignal_data_t*);

/*
 * Add a value to a distribution
 *
 * Add a value to the distribution to some metric. Use this to collect multiple
 * data points that will be merged into a graph.
 *
 * @param key Key of the metric
 * @param value Measured value
 * @param tags for the metric
 */
void appsignal_add_distribution_value(appsignal_string_t, double, appsignal_data_t*);

/*
 * Check if the agent is running in a container.
 *
 * Returns 1 if the agent is running in a container, or 0 otherwise.
 */
int appsignal_running_in_container(void);

/*
 * Store environment metadata values to be reported to AppSignal
 *
 * For more information, see our docs:
 * https://docs.appsignal.com/application/environment-metadata.html
 *
 * @param key String key of the metadata
 * @param value String value of the metadata
 */
void appsignal_set_environment_metadata(appsignal_string_t, appsignal_string_t);

/*
 * Import a span from an OpenTelemetry exporter
 *
 * @param span_id
 * @param parent_span_id
 * @param trace_id
 * @param start_time_sec
 * @param start_time_nsec
 * @param end_time_sec
 * @param end_time_nsec
 * @param name
 * @param attributes
 * @param instrumentation_library_name
 */
void appsignal_import_opentelemetry_span(appsignal_string_t, appsignal_string_t, appsignal_string_t, long long, long, long long, long, appsignal_string_t, appsignal_data_t*, appsignal_string_t);

/*
 * Create a span from an OpenTelemetry exporter
 *
 * @param span_id
 * @param parent_span_id
 * @param trace_id
 * @param start_time_sec
 * @param start_time_nsec
 * @param end_time_sec
 * @param end_time_nsec
 * @param name
 * @param attributes
 * @param instrumentation_library_name
 */
appsignal_span_t* appsignal_create_opentelemetry_span(appsignal_string_t, appsignal_string_t, appsignal_string_t, long long, long, long long, long, appsignal_string_t, appsignal_data_t*, appsignal_string_t);

/*
 * Create a new root span.
 *
 * @param namespace Namespace this span is in
 */
appsignal_span_t* appsignal_create_root_span(appsignal_string_t);

/*
 * Create a new root span with a timestamp.
 *
 * @param namespace Namespace this span is in
 * @param sec Seconds since UTC epoch
 * @param nsec Nanoseconds since second-based timestamp
 */
appsignal_span_t* appsignal_create_root_span_with_timestamp(appsignal_string_t, long long, long);

/*
 * Create a new child span span.
 *
 * @param parent Pointer to the parent span
 */
appsignal_span_t* appsignal_create_child_span(appsignal_span_t*);

/*
 * Create a new child span with a timestamp.
 *
 * @param parent Pointer to the parent span
 * @param sec Seconds since UTC epoch
 * @param nsec Nanoseconds since second-based timestamp
 */
appsignal_span_t* appsignal_create_child_span_with_timestamp(appsignal_span_t*, long long, long);

/*
 * Create a span from a traceparent header.
 * Follows specification in https://www.w3.org/TR/trace-context/#traceparent-header
 *
 * @param traceparent Traceparent header
 */
appsignal_span_t* appsignal_create_span_from_traceparent(appsignal_string_t);

/*
 * Whether we are recording the current trace. If we are not is not necessary to
 * create child spans, ony the root span should be created and closed.
 *
 * @param span Pointer to the span
 *
 * Returns 1 if we are tracing, 0 if we are not
 */
int appsignal_record_trace(appsignal_span_t*);

/*
 * Get this span's traceparent, which can be used to create child spans.
 * Follows specification in https://www.w3.org/TR/trace-context/#traceparent-header
 *
 * @param span Pointer to the span
 */
appsignal_string_t appsignal_span_traceparent(appsignal_span_t*);

/*
 * Get the trace id of this span.
 *
 * @param span Pointer to the span
 */
appsignal_string_t appsignal_trace_id(appsignal_span_t*);

/*
 * Get the id of this span
 *
 * @param span Pointer to the span
 */
appsignal_string_t appsignal_span_id(appsignal_span_t*);

/*
 * Get a json representation of this span, intended for testing purposes.
 *
 * @param span Pointer to the span
 */
appsignal_string_t appsignal_span_to_json(appsignal_span_t*);

/*
 * Set a span's name, for example HomepageController#show or sql.query.
 *
 * @param span Pointer to the span
 * @param name The span's name
 */
void appsignal_set_span_name(appsignal_span_t*, appsignal_string_t);

/*
 * Set a span's name if it has not been set before, for example HomepageController#show or sql.query.
 *
 * @param span Pointer to the span
 * @param name The span's name
 */
void appsignal_set_span_name_if_nil(appsignal_span_t*, appsignal_string_t);

/*
 * Set s span's namespace.
 *
 * Override the initially given namespace if you want to customize it later on.
 *
 * @param span Pointer to the span
 * @param namespace This span's new namespace
 */
void appsignal_set_span_namespace(appsignal_span_t*, appsignal_string_t);

/*
 * Add an error to a span. Currently only errors added to root spans are processed.
 *
 * @param span Pointer to the span
 * @param name The error's name
 * @param name The error's message
 * @param name The error's backtrace, should be an array
 */
void appsignal_add_span_error(appsignal_span_t*, appsignal_string_t, appsignal_string_t, appsignal_data_t*);

/*
 * Set sample data on a (root) span, such as parameters, session data,
 * environment (headers), breadcrumbs, tags and custom data.
 *
 * The given `payload` object is filtered if the `key` matches "params" or
 * "session_data" using the `_APPSIGNAL_FILTER_PARAMETERS` or
 * `_APPSIGNAL_FILTER_SESSION_DATA` config options.
 *
 * @param span Pointer to the span
 * @param key Key of this piece of sample data (params, session_data, environment, tags, breadcrumbs, custom_data)
 * @param payload This sample data
 */
void appsignal_set_span_sample_data(appsignal_span_t*, appsignal_string_t, appsignal_data_t*);

/*
 * Set sample data on a (root) span, such as parameters, session data,
 * environment (headers), breadcrumbs, tags and custom data, unless it is
 * already present.
 *
 * The given `payload` object is filtered if the `key` matches "params" or
 * "session_data" using the `_APPSIGNAL_FILTER_PARAMETERS` or
 * `_APPSIGNAL_FILTER_SESSION_DATA` config options.
 *
 * @param span Pointer to the span
 * @param key Key of this piece of sample data (params, session_data, environment, tags, breadcrumbs, custom_data)
 * @param payload This sample data
 */
void appsignal_set_span_sample_data_if_nil(appsignal_span_t*, appsignal_string_t, appsignal_data_t*);

/*
 * Set a string attribute on a span
 *
 * @param span Pointer to the span
 * @param key Key of the attribute
 * @param value Value of the attribute
 */
void appsignal_set_span_attribute_string(appsignal_span_t*, appsignal_string_t, appsignal_string_t);

/*
 * Set a string attribute on a span, where the body is expected to be SQL data
 *
 * @param span Pointer to the span
 * @param key Key of the attribute
 * @param value Value of the attribute
 */
void appsignal_set_span_attribute_sql_string(appsignal_span_t*, appsignal_string_t, appsignal_string_t);

/*
 * Set an integer attribute on a span
 *
 * @param span Pointer to the span
 * @param key Key of the attribute
 * @param value Value of the attribute
 */
void appsignal_set_span_attribute_int(appsignal_span_t*, appsignal_string_t, long long);

/*
 * Set a boolean attribute on a span
 *
 * @param span Pointer to the span
 * @param key Key of the attribute
 * @param value Value of the attribute
 */
void appsignal_set_span_attribute_bool(appsignal_span_t*, appsignal_string_t, int);

/*
 * Set a double attribute on a span
 *
 * @param span Pointer to the span
 * @param key Key of the attribute
 * @param value Value of the attribute
 */
void appsignal_set_span_attribute_double(appsignal_span_t*, appsignal_string_t, double);

/*
 * Close a span. The span will be flushed and functions on it's functions will
 * be noops afterwards.
 *
 * @param span Pointer to the span
 */
void appsignal_close_span(appsignal_span_t*);

/*
 * Close a span with a timestamp.
 *
 * @param span Pointer to the span
 * @param sec Seconds since UTC epoch
 * @param nsec Nanoseconds since second-based timestamp
 */
void appsignal_close_span_with_timestamp(appsignal_span_t*, long long, long);

/*
 * Free a span
 *
 * Call this when a span will not be used anymore, mostly used as a callback
 * from the host processes' GC.
 *
 * @param span Pointer to the span
 */
void appsignal_free_span(appsignal_span_t*);

/*
 * Log something to AppSignal
 *
 * Possible values for severity:
 *
 * unknown = 0
 * trace = 1
 * debug = 2
 * info = 3
 * notice = 4
 * warn = 5
 * error = 6
 * critical = 7
 * alert = 8
 * fatal = 9
 *
 * Possible values for format:
 *
 * plaintext = 0
 * logfmt = 1
 * json = 2
 *
 * @param group Log line's group
 * @param severity Log line's severity
 * @param format Log line's format
 * @param message Log line's message
 * @param attributes Log lines's attributes
 */
void appsignal_log(appsignal_string_t, int, int, appsignal_string_t, appsignal_data_t*);

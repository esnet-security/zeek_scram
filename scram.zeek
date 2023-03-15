##! Add notice action ACTION_SCRAM that will BHR n$src
module SCRAM;

export {
    redef enum Notice::Action += {
        ACTION_SCRAM,
    };

    redef enum Log::ID += { LOG };
    type Info: record {
        ## Timestamp when the log line was finished and written.
        ts:         time   &log;
        ## The address that was blocked
        src:        addr &log;
        ## The reason it was blocked
        why:        string &log;
        ## The duration it was blocked for
        duration:   interval &log;
        ## How long the process took to run
        latency:    interval &log;
    };

    const tool_filename = "/home/zeek/scram_client_venv/bin/scram-zeek" &redef;
    const mode = "queue" &redef; #or block
    const block_types: set[Notice::Type] = {} &redef;
    const default_block_duration: interval = 15mins &redef;
    const block_durations: table[Notice::Type] of interval = {} &redef;
    const country_scaling: table[string] of double = {} &redef;
    const do_country_scaling: bool = F &redef;

}

function get_duration(n: Notice::Info): interval
{
    local duration = default_block_duration;

    if ( n$note in block_durations) {
        duration = block_durations[n$note];
    }

    if (!do_country_scaling)
        return duration;

    local location = lookup_location(n$src);
    if (!location?$country_code)
        return duration;

    local cc = location$country_code;
    if (cc in country_scaling) {
        duration = duration * country_scaling[cc];
    }
    return duration;
}

hook Notice::policy(n: Notice::Info)
{
    if ( n$note !in block_types )
        return;
    if ( Site::is_local_addr(n$src) || Site::is_neighbor_addr(n$src) )
        return;

    local duration = get_duration(n);
    local tool = tool_filename;

    add n$actions[ACTION_SCRAM];

    local nsub = n?$sub ? n$sub : "-";
    local duration_str = cat(interval_to_double(duration));
    local stdin = string_cat(cat(n$src), "\n", cat(n$note), "\n", n$msg, "\n", nsub, "\n", duration_str, "\n");
    local cmd = fmt("%s %s", tool, mode);

    local start_time = current_time();
    piped_exec(cmd, stdin);
    local finish_time = current_time();

    local l: Info;

    l$ts = network_time();
    l$src = n$src;
    l$duration = duration;
    l$why = fmt("%s %s", n$note, n$msg);
    l$latency = finish_time - start_time;

    Log::write(LOG, l);
}

event zeek_init()
{
    Log::create_stream(LOG, [$columns=Info]);
}

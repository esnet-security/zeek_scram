Zeek Integration for SCRAM
=======================

This code was heavily adopted from NCSA's zeek_bhr.

Requires the scram-zeek python module.

Usage
-----

In local.zeek:

    @load ./scram-zeek

    redef SCRAM::block_types += {
        Scan::Port_Scan,
        Scan::Address_Scan,
    };

    #optional
    redef SCRAM::default_block_duration = 60mins;
    redef SCRAM::block_durations += {
        [Scan::Port_Scan]    = 30mins,
    };
    redef SCRAM::do_country_scaling = T;
    redef SCRAM::country_scaling += {
        ["CN"]  = 8.0,
    };

and if your default block time is less than 15 minutes:

    redef Notice::type_suppression_intervals += {
        [Scan::Port_Scan]    = 800sec,
        [Scan::Address_Scan] = 800sec,
    };



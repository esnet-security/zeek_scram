# @TEST-EXEC: zeek ../../../scripts %INPUT
# @TEST-EXEC: zeek-cut note msg src < notice.log > notice.tmp && mv notice.tmp notice.log
# @TEST-EXEC: btest-diff notice.log

module SCRAM_TEST;

export {
        redef enum Notice::Type += {
                SCRAM_TEST::Test_Scram
        };
}

event zeek_init() &priority=-5 {
        local block_ip: addr = 10.1.1.1;

        NOTICE([$note=SCRAM_TEST::Test_Scram, $src=block_ip,
                $msg=fmt("SCRAM Test"),$identifier=fmt("SCRAM")]);
}

redef SCRAM::block_types += {
    SCRAM_TEST::Test_Scram,
};

#optional
redef SCRAM::default_block_duration = 60mins;
redef SCRAM::block_durations += {
    [SCRAM_TEST::Test_Scram]    = 30mins,
};
redef SCRAM::do_country_scaling = T;
redef SCRAM::country_scaling += {
    ["CN"]  = 8.0,
};

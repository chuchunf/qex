\cd qex
\l qex.q

main : {
        .logger.Info ("Starting QEX Engine");
        .qex.seq: .dailyops.ProcessStartOfDay[];
        .qex.ready: 1b;
        .logger.Info ("QEX Engine is ready");
    }

main[]

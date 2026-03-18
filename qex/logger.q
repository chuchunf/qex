/********************************************************/
/ Logger: log all order and trades for SOD and recovery  /
/********************************************************/
\d .logger

/**********************************************************
/ all incoming orders will be log for recovery
logHandler : 0
LogOrder : {[order]
        if[0=logHandler; logHandler :: hopen `.[`ORDERLOG]];
        orderdump : -1 _ raze (string value exec from order) ,' ",";
        logHandler orderdump , "\n";
    }

/**********************************************************
/ log information in the console 
Info : {[msg; arg]
        1 "[" , (string .z.Z) , "] ";
        $[100=type arg; 
            [show msg; show value arg];
            [show msg; show arg]
        ];
    }

\d .

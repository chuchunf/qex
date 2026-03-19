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
Info : {[args]
        1 "[" , (string .z.Z) , "] ";
        $[10h=abs type args; 
            show args;
        2=count args;
            [
                msg: args 0; arg: args 1;
                $[100h=type arg; 
                    show msg, ", ", value arg;
                    show msg, ", ", arg
                ]
            ];
            show args
        ];
    }

\d .

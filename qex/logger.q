/********************************************************/
/ Logger: log all order and trades for SOD and recovery  /
/********************************************************/
\d .logger

/**********************************************************
/ bootstrap of the system
ordercols : `id`mid`sym`side`otype`timeinforce`osize`limitprice`stopprice`effdate`status`time`day`command
Bootstrap : { 
        / get directory for loading
        yesterday   : (`dd$.z.Z-1) + (100*`mm$.z.Z-1) + 10000*`year$.z.Z-1;
        
        / load all orders in previous day        
        orderdata   : `$`.[`DATADIR] , (string yesterday) , "/" , `.[`ORDERDATA]; 
        if[count key orderdata;
            orders      : get orderdata;
            show orders;
             / update order accordingly
            orders: delete from orders where status in `FILLED`FAILED`CANCELLED;
            orders: delete from orders where timeinforce=`GOODFORDAY;
            orders: delete from orders where timeinforce in `GOODAFTER`GOODTILCANCEL, .z.z>effdate+90;
            orders: delete from orders where timeinforce=`GOODTIL, .z.z>effdate;
            orders: update otype=`LIMIT from orders where timeinforce=`GOODAFTER, .z.z>effdate
            / insert into RDB
            `.schema.Orders insert select from orders;
        ];
                                            
        / verify if it is a failure, do recovery by replay all orders in today's log
        if[count key `.[`ORDERLOG];
            {[entry]
                .qex.Submit [entry[`command]] [entry];
            } each flip ordercols ! ("IISSSSIIIISZIS";",") 0: `.[`ORDERLOG];
        ];
        
        /load user data
        if[count key `.[`MEMBERS];
            members: get `.[`MEMBERS];
            `.schema.Members insert select from members;
        ];
        
        / return biggest id of order
        seq : exec max id from .schema.Orders;
        $[seq<=0; :1; :seq];
    }

/**********************************************************
/ all incoming orders will be log for recovery
logHandler : 0
LogOrder : {[order]
        if[0=logHandler; logHandler :: hopen `.[`ORDERLOG]];
        orderdump : -1 _ raze (string value exec from order) ,' ",";
        logHandler orderdump , "\n";
    }

/**********************************************************
/ End of day processing
/ 1. write all pending order to today's order table
/ 2. remove today's order log table
/ 3. EOD will be triggered by an external scheduler
ProcessEndOfDay : {
        / create directory
        value "\\cd " , `.[`QEXDIR] , string `.[`TODAY];
        
        orderdat    : `$`.[`DATADIR] , (string `.[`TODAY]) , "/" , `.[`ORDERDATA]; 
        show string orderdat;
        tradedat    : `$`.[`DATADIR] , (string `.[`TODAY]) , "/" , `.[`TRADEDATA];
        show string tradedat;
        
        orderdat set .schema.Orders;
        tradedat set .schema.Trades;
    
        hdel `.[`ORDERLOG];
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

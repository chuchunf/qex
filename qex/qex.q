/*******************************************************
/ Exchange implemenation                                
/*******************************************************
\cd qex
\l global.q
\l schema.q
\l member.q
\l logger.q

\d .qex

/*******************************************************
/ Utility functions
/ issue: quote not updated when last order being cancelld
rebuildQuotes       : (`ORDERSIDE$()) ! ();
rebuildQuotes[`BUY] : {[order] 
        :`.schema.Quotes upsert 
            select sym, bidprice:max(limitprice), bidsize:sum(osize) from .schema.Orders
                where sym=order[`sym], otype in `MARKET`LIMIT, side=`BUY, status in `NEW`PARTIALFILLED;
    }
rebuildQuotes[`SELL]: {[order]
        :`.schema.Quotes upsert 
            select sym, askprice:max(limitprice), asksize:sum(osize) from .schema.Orders
                where sym=order[`sym], otype in `MARKET`LIMIT, side=`SELL, status in `NEW`PARTIALFILLED;
    }

/ order validation rules
allMandatoryFields              : `sym`osize`side`otype
optionalFields                  : `limitprice`stopprice`effdate
orderMandatoryFields            : (`ORDERTYPE$()) ! ()
orderMandatoryFields[`LIMIT]    : `limitprice
orderMandatoryFields[`STOP]     : `stopprice

validateOrder: {[order]
        if[all null order[allMandatoryFields]; :0b];
        if[(order[`otype]<>`MARKET) and all null order[orderMandatoryFields[order[`otype]]]; :0b];
        if[(order[`timeinforce] in `GOODTILL`GOODAFTER) and null order[`effdate]; :0b];
        :1b;
    }

/*******************************************************
/ Order matching
/ price/time poriory, market order (without limitprice) will be filled first
listMatchableOrder : (`ORDERSIDE$()) ! ();
listMatchableOrder[`BUY] : {[order]
        :`time xasc `limitprice xasc select from .schema.Orders where 
                side=`SELL, status in `NEW`PARTIALFILLED, limitprice<=order[`limitprice];
    }
listMatchableOrder[`SELL] : {[order]
        :`time xasc `limitprice xdesc select from .schema.Orders where 
                side=`BUY, status in `NEW`PARTIALFILLED, (limitprice=0) or limitprice>=order[`limitprice];            
    }

getNewTrade : (`ORDERSIDE$()) ! ();
getNewTrade[`BUY] : {[order; orders]
        :update sym:order[`sym], osize:`int$tradesize, price:max(limitprice,order[`limitprice]), 
            buyorder: order[`id], sellorder:id, time:.z.z, day:`.[`TODAY], buyerid:order[`mid], 
            sellerid:mid from orders;
    }
getNewTrade[`SELL] : {[order; orders]
        :update sym:order[`sym], osize:`int$tradesize, price:max(limitprice,order[`limitprice]), 
            buyorder: id, sellorder:order[`id], time:.z.z, day:`.[`TODAY], buyerid:mid, 
            sellerid:order[`mid] from orders;
    }
    
matchOrder: {[order]
        matching : listMatchableOrder [order[`side]][order];
        if[not count matching; :`OK]
        .logger.Info["matching orders"][count matching];

        matched: update tradesize:0 from delete from matching;

        while[(order[`osize]>0) and 0<count matching;
            row : 1 # matching;
            currentsize: first exec osize from row;
            order[`osize]-:currentsize;

            $[order[`osize]=0; 
                [
                    row : update osize:0i, status:`FILLED, tradesize:currentsize from row;
                    order[`status] : `FILLED;
                ];
                [
                    $[order[`osize]<0;
                        [
                            row : update osize:neg order[`osize], status:`PARTIALFILLED, tradesize:currentsize+order[`osize] from row;
                            order[`osize`status] : (0i;`FILLED) 
                        ];
                        [
                            row : update status:`FILLED, tradesize:osize from row;
                            order[`status]:`PARTIALFILLED 
                        ]
                    ]
                ]
             ];
             matched,:row;

             // remove 1st row
             matching : 1 _ matching;
        ];
        .logger.Info["matched orders"][matched];

        // abort if results in a partial fill for FILLORKILL 
        if[(order[`osize]>0) and (order[`otype]=`LIMIT) and order[`timeinforce]=`FILLORKILL; :`OK];

        // update order table for matched order
        `.schema.Orders upsert delete tradesize from matched;

        // update order table for new order
        update osize:order[`osize], status:order[`status] from `.schema.Orders where id=order[`id];
               
        // insert trades
        trades : getNewTrade [order[`side]] [order] [matched];
        .logger.Info["creating trades"][trades];

        `.schema.Trades insert select sym, osize, price, buyorder, sellorder, time, day from trades;

        // notify matched trade
        .member.UniCast [trades];

        :`OK;
    }

listStopOrder : (`ORDERSIDE$()) ! ();
listStopOrder[`BUY] : {[order]
        :select from .schema.Orders 
            where side=`SELL, status=`NEW, stopprice<=order[`limitprice], otype=`STOP;
    }
listStopOrder[`SELL] : {[order]
        :select from .schema.Orders 
            where side=`BUY, status=`NEW, stopprice>=order[`limitprice], otype=`STOP;
    }

triggerStopOrder:{[order]
        .logger.Info["trigger stop order"][order[`limitprice]];
        matching: listStopOrder[order[`side]][order];
        if[not count matching; :`OK];
        update type=`MARKET from `.schema.Orders where id in select id from matching;
        .logger.Info["number of order triggered"][count matching];
    }

/*******************************************************
/ Factory of exchange functions                         
commandFactory  : (`ORDERCMD$()) ! ()     / factory of commands

/ Sumbit a new order, expect order as a dictionary; return order id for tracking
commandFactory[`NEW] : {[order]
        .logger.Info["new order"][order];

        if[.z.w<>0; order[`mid] : .member.GetMember []];    /recovery will has mid set
        if[not order[`mid]; :`INVALID_MEMBER];
        if[not validateOrder[order]; :`INVALID_ORDER];
    
        if[.z.w<>0; order[`id] : seq+: 1];                  /recovery will has id set
         $[.z.w<>0; [insertts: .z.Z]; [insertts: order[`time]]];
        if[null order[`limitprice]; order[`limitprice] : 0];
        if[null order[`stopproce]; order[`stopprice] : 0];
        if[null order[`effdate]; order[`effdate] : 0];
        if[null order[`timeinforce]; order[`timeinforce] : `NIL];
        .logger.Info["order valided and decorated"][order];
 
        `.schema.Orders insert (order[`id]; order[`mid]; order[`sym]; order[`side]; 
                            order[`otype]; order[`timeinforce]; order[`osize]; 
                            order[`limitprice]; order[`stopprice]; order[`effdate]; 
                            `NEW; insertts; `.[`TODAY]);
        if[.z.w<>0; .logger.LogOrder [update command:`NEW from .schema.Orders where id = .qex.seq]];
        .logger.Info["order logged for session"][.z.w];
        
        if[order[`otype] in `LIMIT`MARKET; 
            if[order[`otype]=`LIMIT;         
                triggerStopOrder[order]];
            matchOrder[order]; 
            rebuildQuotes[order[`side]][order];
            .member.BroadCast [select from .schema.Quotes where sym=order[`sym]];
        ];
        .logger.Info["order done, return sequence"][seq];
        $[.z.w<>0; :seq; :0];
    }

/ Cancel an existing order
commandFactory[`CANCEL] : {[order]
        .logger.Info["cancel order"][order];

        if[.z.w<>0; order[`mid] : .member.GetMember []];    /recovery will has mid set
        dborder : select from .schema.Orders where mid=order[`mid], id=order[`id], status=`NEW;
        if[not count dborder; :`INVALID_ORDER_STATUS];

        order[`otype] : first exec otype from dborder;
        order[`sym] : first exec sym from dborder;
        order[`side] : first exec side from dborder;
        update status: `CANCELED from `.schema.Orders where id=order[`id];
        if[.z.w<>0; .logger.LogOrder [update command:`CANCEL from dborder]];

        if[order[`otype] in `MARKET`LIMIT; 
            rebuildQuotes[order[`side]][order];
            .member.BroadCast [select from .schema.Quotes where sym=order[`sym]]
        ];
        :`OK
    }

/ Modify an existing order    
commandFactory[`MODIFY] : {[order]
        .logger.Info["modify order"][order];

        if[.z.w<>0; order[`mid] : .member.GetMember []];    /recovery will has mid set
        dborder: select from .schema.Orders where mid=order[`mid], id=order[`id], status=`NEW;
        if[not count dborder; :`INVALID_ORDER_STATUS];

        order[`otype] : first exec otype from dborder;
        order[`sym] : first exec sym from dborder;
        order[`side] : first exec side from dborder;
        update osize: order[`osize], limitprice: order[`limitprice]
                , stopprice: order[`stopprice], effdate: order[`effdate] 
                from `.schema.Orders where id=modifyid;
        if[.z.w<>0; .logger.LogOrder [update command:`MODIFY from .schema.Orders where id=order[`id]]];

        if[order[`otype] in `MARKET`LIMIT; 
            rebuildQuotes[order[`side]][order];
            .member.BroadCast [select from .schema.Quotes where sym=order[`sym]];
        ];
        :`OK
    }

/ Quotation by symbol
commandFactory[`QUOTE] : {[sym]
        select from .schema.Quotes where sym=sym;
    }
    
/ Main function; expect order as dictionary; write response to member process
/ All calls through sumbit function are synchonous calls
Submit : {[command; order]
        :commandFactory [command] [order];
    }

/*******************************************************
/ Bootstrap
seq         : .logger.Bootstrap []     / load order and trade, set seq
ready       : 1b

\d .

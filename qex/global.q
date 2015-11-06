/*******************************************************
/ definition of all constants/enumerations              
/*******************************************************

/*******************************************************
/ Configurations                                        
STARTTIME   : 9
ENDTIME     : 23
TODAY       : `int$(`dd$.z.Z) + (100*`mm$.z.Z) + 10000*`year$.z.Z

BASEDIR     : ":/Users/chuchunf/q/m32/"
QEXDIR      : "qex/data/"
DATADIR     : BASEDIR,QEXDIR
ORDERLOG    : `$DATADIR,"orders.log"
ORDERDATA   : "orders.dat"
TRADEDATA   : "trades.dat"
MEMBERS     : `$DATADIR,"user.dat"

/*******************************************************
/ order related enumerations  
ORDERCMD    :   (`NEW;      / place a new order
                `MODIFY;    / modify an existing order
                `CANCEL;    / cancel an existing unfilled order
                `QUOTE);   

ORDERSIDE   :   `BUY`SELL;

ORDERTYPE   :   (`MARKET;       / executed regardless of price
                `LIMIT;         / executed only at required price
                `STOP);         / executed as market order once stop price reached

TIMEINFORCE :   (`GOODFORDAY;       / valid to the day's trading session
                `GOODTILCANCEL;     / good til user manual cancellation (max 90days)
                `IMMEDIATEORCANCEL; / fill immediately or cancel, allow partially fill
                `FILLORKILL;        / fill immediately or cancel, full fill only
                `GOODTILL;          / order effective till specified date
                `GOODAFTER);        / order effective only after specified date

ORDERSTATUS :   (`NEW;          / begining of life cycle
                `PARTIALFILLED; / partially filled
                `FILLED;        / fully filled
                `FAILED;        / failed due to expiration etc
                `CANCELED);     / user or system cancel

/*******************************************************
/ Return code
RETURNCODE  :   (`INVALID_MEMBER;
                `INVALID_ORDER_STATUS;
                `INVALID_ORDER;
                `OK);

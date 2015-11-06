/********************************************************
/ Schema: define tables used by the exchange
/********************************************************
\d .schema

Members: (
        [id        : `int$()]
        name       : `symbol$();
        md5sum     : `symbol$();
        marketmaker: `boolean$()
    )

Orders: (
        [id        : `int$()] 
        mid        : `int$();           / member/broker id
        sym        : `symbol$();
        side       : `ORDERSIDE$();
        otype      : `ORDERTYPE$();
        timeinforce: `TIMEINFORCE$();
        osize      : `int$();
        limitprice : `int$();           / multiply by 100
        stopprice  : `int$();           / multiply by 100
        effdate    : `int$();           / as YYYYMMDD
        status     : `ORDERSTATUS$();
        time       : `datetime$();
        day        : `int$()            / for table partition
    )

Trades: (
        []
        sym         :   `symbol$();
        osize       :   `int$();
        price       :   `int$();          
        buyorder    :   `int$();        / order id of buyer
        sellorder   :   `int$();        / order id of seller
        time        :   `datetime$();
        day         :   `int$()         / for table partition
    )

Quotes: (
        [sym        :   `symbol$()]
        bidsize     :   `int$();
        bidprice    :   `int$();
        asksize     :   `int$();
        askprice    :   `int$()
    )

\d .

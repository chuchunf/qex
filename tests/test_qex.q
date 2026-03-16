h:hopen (`::5000:brokera:password)
h:hopen (`::5000:brokerb:password)

o:(`sym`side`otype`osize) ! (`ABC;`BUY;`MARKET;100)
o:(`sym`side`otype`osize) ! (`ABC;`SELL;`MARKET;10)

o:(`sym`side`otype`timeinforce`osize`limitprice) ! (`ABC;`BUY;`LIMIT;`GOODFORDAY;100;500)
o:(`sym`side`otype`timeinforce`osize`limitprice) ! (`ABC;`SELL;`LIMIT;`GOODFORDAY;10;500)

h(`.qex.Submit; `NEW; o)

o:(`id`sym) ! (2;`ABC)
h(`.qex.Submit; `CANCEL; o)


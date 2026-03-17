## Synopsis

A equity exchange implemented in Q running on KDB+.

## Motivation

The best way of learning something is actually doing it, I'm learning KDB+ and Q by implementing a fully featured exchange. Feactures/TODOs will be changed/udpated as I progress.

## Installation

It is developed and tested on MacOS only at this monment.

Steps for installation and verification:

1. Download and install KDB+ personal edition on default path;
2. Download/Clone the repository;
3. Edit global.q to modify data directories accordingly;
4. Run server from command line: ./q qex/qex.q -p 5000
5. Run client from another command line: ./q
6. Test in KDB+ console
```
h:hopen (`::5000:brokera:password)

o1:(`sym`side`otype`osize) ! (`ABC;`BUY;`MARKET;100)

o2:(`sym`side`otype`timeinforce`osize`limitprice) ! (`ABC;`BUY;`LIMIT;`GOODFORDAY;100;500)

h(`.qex.Submit; `NEW; o1)
h(`.qex.Submit; `NEW; o2)

o:(`id`sym) ! (2;`ABC)
h(`.qex.Submit; `CANCEL; o)

```
7. Open another console as brokerb
```
h:hopen (`::5000:brokerb:password)

o1:(`sym`side`otype`osize) ! (`ABC;`SELL;`MARKET;10)

o2:(`sym`side`otype`timeinforce`osize`limitprice) ! (`ABC;`SELL;`LIMIT;`GOODFORDAY;10;500)

h(`.qex.Submit; `NEW; o1)
h(`.qex.Submit; `NEW; o2)

o:(`id`sym) ! (2;`ABC)
h(`.qex.Submit; `CANCEL; o)
```

## Usage

TO be added.

## Tests

Use qCumber to run the test, assume KX developer is installed at $AXLIBRARIES_HOME and configured in your Q environment.
```
\l $AXLIBRARIES_HOME/qcumber.q_
.qu.runTestFolder `:tests/
```

## Performance Tests

TO be added.

## TODO
[x] 1. Coding style check
[ ] 2. Unit testing
[ ] 3. Refactor code to use vector language style instead of procedure
[ ] 4. More client APIs (Market data)
[ ] 5. A market maker implementation
[ ] 6. A member implementation (algo trading)
[ ] 7. Performance Testing


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
4. Run server from command line
    ./q qex/qex.q -p 5000
5. Run client from another command line
    ./q
6. Test in KDB+ console
    h:hopen (`::5000:brokera:password)
    o:(`sym`side`otype`timeinforce`osize`limitprice) ! (`ABC;`BUY;`LIMIT;`GOODFORDAY;100;500)
    h(`.qex.Submit; `NEW; o)

## Usage

TO be added.

## Tests

TO be added.

## Performance Tests

TO be added.

## TODO
1. Coding style check
2. Unit testing
3. Refactor code to use vector language style instead of procedure
4. More client APIs (Market data)
5. A market maker implementation
6. A member implementation (algo trading)
7. Performance Testing

## Change History

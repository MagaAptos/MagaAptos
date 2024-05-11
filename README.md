# MAGA

### Born with the objective to cast our votes in favor of President Trump's support.

"Vote to Earn" a.k.a. "Proof of Vote" on Aptos.

## What is $MAGA?

Inspired by $DDOS, and the $SPAM, $MAGA introduces a pioneering "platform" enabling users to accumulate rewards in $MAGA for every "vote" transaction they initiate. As users engage in more "vote" transactions, their earnings in $MAGA increase proportionally.

## ELI5

One percent of total supply $MAGA coins are minted in the first day.

Users earn $MAGA simply by sending Aptos transactions.

The more txs you send, the more MAGA you receive.

There is no proof of work, only proof of vote.

## Mining mechanism

12 Aptos "epoch" is roughly equivalent to 1 day.

Users send txs to increase their tx counters during from epoch `N` to epoch `N+12`, register their tx counters during from epoch `N+12` to epoch `N+24`, and mint MAGA anytime from epoch `N+24` to epoch `N+36` based on the voting they did in from epoch `N` to epoch `N+12`:

- The first 12 Epochs: user votes UserCounter.0 (UC.0)
- Next 12 Epochs: user votes UC.1, registers UC.0
- Next 12 Epochs: user votes UC.2, registers UC.1, claims UC.0
- Next 12 Epochs: user votes UC.3, registers UC.2, claims UC.1
- And so on

## Tokenomics

Contract Address:

Total supply: 47,000,000,000

### Token distribution

Treasure allocation: 4,700,000,000 (10%)

Mining allocation: 23,500,000,000 (50%)

LP allocation: 18,800,000,000 (40%)

## MAGA Halving schedule

The event is set to occur following intervals of 4 days, 8 days, 16 days, 32 days, 64 days, and 128 days.

All tokens will be mined to vote for Trump until the day he is elected.

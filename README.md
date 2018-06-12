# MineableToken
> ERC918 (ERC Compatible) Mineable Token with configurable gas limits

## Why?
After launching the KIWI Token we saw the problem with gas racing / gas wars. Because the difficulty of mining at the beginning is very low, solutions are found quickly and so people would set a higher gas price as a way to try and get their solution accepted into the blockchain quicker than other solutions.

This means that with popular tokens the people with the most Ether can afford to up the gas prices. Unfortunately, because of the fact that every transaction has to be paid for in gas even losing transactions have a cost associated with them.

This contract stops people from gas racing.

## How?
It is really quite simple, the first check we do is to make sure that the transaction gas price is below a certain amount. As an example the code below will reject all transactions that are more than 5 Gwei.

```solidity
require(tx.gasprice < 5 * 1000000000);
```

But, we don't want to hardcode the value as we do not know what the _'normal'_ gas price might be in the future. So, we allow the contract owner to change this as and when needed.

## Is this really a problem?
In our observations it is quite a big problem, as mentioned above, a popular token could easily be dominated by a few with deep pockets. The idea of mineable tokens is to be a fairer way of distributing tokens.

The limitation of gas also has practical applications outside of Mineable Tokens. We have seen popular ICO's gas prices go through the roof as people try to outbid each other to ensure that they get some tokens.

There have also been cases of ethereum miners looking at pending transactions and then setting gas prices they know will beat those pending transactions.

There are also cases of gas attacks, where transactions that are constructed to fail are sent to the ethereum network with exceptionally high gas prices. The idea being that they keep the miners busy mining these bad transactions while they can submit good solutions at a much lower gas price to their own ethereum miner.

Any decentralised app (dapp) is a potential victim to these type of gas attacks.

Back to mineable tokens, there are miners out already that will automatically outbid any pending transactions, but only if the person running the miner is running a full node.

So, yes this is a big problem. But one that is fairly easy to solve.

# Alchemy Learn Lesson 6 - Building a staking dApp
You can find the full description of the lesson with detailed step-by-step guide via: https://docs.alchemy.com/docs/how-to-build-a-staking-dapp#challenge-time. This is a fork of https://github.com/scaffold-eth/scaffold-eth-challenges/tree/challenge-1-decentralized-staking.  

But here I will walk through my solution for 2 challenges in the article. 

## 🚩 Challenge 1
### Update the interest mechanism in the `Staker.sol` contract so that you receive a "non-linear" amount of ETH based on the blocks between deposit and withdrawal. 

The staking interest calculation in the example uses $\ y=0.1x$. The equation I am using for this challenge is $\ y=0.001x^2$ , which in our x range of interest is approximately similar to the linear one in the example. 

> Why the quadratic equation? I personally did not want the non-linear interest range to vary too much (as in, go  crazy exponential) as we might not have enough ETH in the contract to pay out. Since $\ x$ range is rather small, I iterated through a few constant values and finally decided on the quadratic above. For example, if we opt for exponential curve, eg $\ 2^x$, we will need to scale down the curve as it rises way to quickly in the $\ x$ range, a good candidate is $\ 1.025^x$, but since Ethereum rounds down the fractional number to an integer, we are merely getting a $\ 1^x$. Therefore this is not feasible.
___


## 🚩🚩 Challenge 3
###  Instead of using the vanilla `ExampleExternalContract` contract, implement a function in `Staker.sol` that allows you to retrieve the ETH locked up in `ExampleExternalContract` and re-deposit it back into the `Staker` contract.

* Make sure to only "white-list" a single address to call this new function to gate its usage!
* Make sure that you create logic/remove existing code to ensure that users are able to interact with the Staker contract over and over again! We want to be able to ping-pong from `Staker` -> `ExampleExternalContract` repeatedly!



In order to achieve this, a few aspects
* We need to refactor such that the timer can restart again after we have completed 1 lifecycle and send ETH back to Staker contract. (`timerInit` in `Staker`) 
* We need to store the address that call the new function and ensures it is checked before allowing execution. (`stakerAddress` in `ExampleExternalContract`)
* We need a new function in Staker which calls another new function in ExampleExternalContract to send over the contract balance. (`getBack` in `Staker`)

Putting all these together, we have a lifecycle of: 


 Deploy contract -> Timer for Withdraw and Claim deadlines starts -> Stake ETH into contract -> Timer for Withdraw deadline is up -> Withdraw after waiting for a period depending on your patience -> Timer for Claim deadline is up -> Claim (Execute button) is enabled and all contract balance to be moved to ExampleExternalContract -> Call `getBack` function in Staker to retrieve contract balance -> Timer for Withdraw and Claim deadline (re)starts -> *Continue the cycle* 

___
## ⬇️ Install

```bash

yarn install

```

🏃‍♂️ To run this, you'll have three terminals up for:

```bash
yarn start   (react app frontend)
yarn chain   (hardhat backend)
yarn deploy  (to compile, deploy, and publish your contracts to the frontend)
```

💻 View your frontend at http://localhost:3000/

👩‍💻 Rerun `yarn deploy --reset` whenever you want to deploy new contracts to the frontend. (whenever you make changes to the contracts)

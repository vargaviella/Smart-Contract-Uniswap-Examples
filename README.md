# Smart Contract: Uniswap Examples
This smart contract facilitates token swapping using Uniswap V3's swap functionality. It provides methods to swap tokens using either exact input or exact output amounts. The contract owner can configure the tokens to be swapped, the pool fee, and execute swaps.

# Features:
Exact Input Single Swap: Swap a specified amount of input tokens for an exact amount of output tokens.
Exact Output Single Swap: Swap for a specified amount of output tokens, with the contract owner specifying the maximum amount of input tokens to be spent.
Token Configuration: Set the input and output tokens for the swaps.
Pool Fee Configuration: Set the pool fee for Uniswap V3 swaps.
Owner Functionality: Certain functions are restricted to the contract owner for security purposes.

# Usage:
Exact Input Single Swap

function swapExactInputSingle(uint256 amountIn) external onlyOwner returns (uint256 amountOut)

Parameters:
amountIn: Amount of input tokens to be swapped.
Description: Swaps a specified amount of input tokens for an exact amount of output tokens.

Steps:
Ensure that input and output tokens are set.
Transfer the specified amountIn of input tokens from the caller to the contract.
Approve the Uniswap router to spend the input tokens.
Define swap parameters including input token, output token, fee, recipient, deadline, and input amount.
Execute the swap using Uniswap router's exactInputSingle method.
Return the amount of output tokens received.

Exact Output Single Swap

function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum) external onlyOwner returns (uint256 amountIn)

Parameters:
amountOut: Exact amount of output tokens desired.
amountInMaximum: Maximum amount of input tokens allowed to be spent.
Description: Swaps for a specified amount of output tokens, with the contract owner specifying the maximum amount of input tokens to be spent.

Steps:
Ensure that input and output tokens are set.
Transfer the specified maximum amountInMaximum of input tokens from the caller to the contract.
Approve the Uniswap router to spend the input tokens.
Define swap parameters including input token, output token, fee, recipient, deadline, output amount, and maximum input amount.
Execute the swap using Uniswap router's exactOutputSingle method.
Return the actual amount of input tokens spent.

Configuration Functions:
setTokenIn(address _tokenIn) external onlyOwner: Set the input token address for the swaps.
setTokenOut(address _tokenOut) external onlyOwner: Set the output token address for the swaps.
setPoolFee(uint24 _poolFee) external onlyOwner: Set the pool fee for Uniswap V3 swaps.

Owner Management
transferOwner(address newOwner) public onlyOwner: Transfer ownership of the contract to a new address.
This specification provides a step-by-step guide on how each function operates, including parameter descriptions and the sequence of actions taken within each function.

# Installation:

Requirements
Solidity compiler version 0.8.0
OpenZeppelin Contracts library
Uniswap V3 Periphery Contracts library

Deployment
Deploy the contract to the Ethereum network.
Set the appropriate token addresses and pool fee using the configuration functions.
The contract is now ready to facilitate token swaps.

# Author: VARGAVIELLA

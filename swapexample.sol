// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.0;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapExamples {
    IERC20 public token;
    ISwapRouter public immutable swapRouter;
    uint24 public poolFee;
    address public tokenIn;
    address public tokenOut;
    address private owner;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
        owner = msg.sender;
        poolFee = 10000; // Default pool fee
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function setTokenIn(address _tokenIn) external onlyOwner {
        tokenIn = _tokenIn;
    }

    function setTokenOut(address _tokenOut) external onlyOwner {
        tokenOut = _tokenOut;
    }

    function setPoolFee(uint24 _poolFee) external onlyOwner {
        poolFee = _poolFee;
    }

    function getTokenBalance(address tokenAddress, address account) public view returns (uint256) {
    IERC20 token = IERC20(tokenAddress);
    return token.balanceOf(account);
    }

    function transferOwner(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Invalid new owner address");
    owner = newOwner;
    }


    function swapExactInputSingle(uint256 amountIn) external onlyOwner returns (uint256 amountOut) {
        require(tokenIn != address(0) && tokenOut != address(0), "Tokens not set");
        
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum) external onlyOwner returns (uint256 amountIn) {
        require(tokenIn != address(0) && tokenOut != address(0), "Tokens not set");
        
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountInMaximum);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = swapRouter.exactOutputSingle(params);

        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
            TransferHelper.safeTransfer(tokenIn, msg.sender, amountInMaximum - amountIn);
        }
    }

    receive() external payable {}
}

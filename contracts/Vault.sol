// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interface/IZapper.sol";
import "./interface/IController.sol";

contract Vault is ERC20 {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    address public governance;
    address public controller;

    IZapper public zapper;
    IERC20 public token;

    uint256 public min = 9500;
    uint256 public constant max = 10000;

    bool public isPairToken;

    constructor(
        address _token,
        bool _isPairToken,
        address _governance,
        address _zapper,
        address _controller
    )
        public
        ERC20(
            string(abi.encodePacked("stakedao ", ERC20(_token).name())),
            string(abi.encodePacked("s", ERC20(_token).symbol()))
        )
    {
        _setupDecimals(ERC20(_token).decimals());
        governance = _governance;
        token = IERC20(_token);
        zapper = IZapper(_zapper);
        controller = _controller;
        isPairToken = _isPairToken;
    }

    function setZapper(address _zapper) external onlyGovernance {
        require(_zapper != address(0), "invalid zapper");
        zapper = IZapper(_zapper);
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this)).add(IController(controller).balanceOf(address(token)));
    }

    function setMin(uint256 _min) external onlyGovernance {
        min = _min;
    }

    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;
    }

    function setController(address _controller) public onlyGovernance {
        controller = _controller;
    }

    function available() public view returns (uint256) {
        return token.balanceOf(address(this)).mul(min).div(max);
    }

    function earn() public {
        uint256 _bal = available();
        token.safeTransfer(controller, _bal);
        IController(controller).earn(address(token), _bal);
    }

    //deposit with eth
    function depositETH() public payable {
        uint256 _outAmount = zapper.ZapInWithEth{value: msg.value}(address(token), isPairToken);
        uint256 _pool = balance();
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _outAmount;
        } else {
            shares = (_outAmount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
    }

    //if a user inputs a random token
    function deposit(address _inToken, uint256 _amount) public {
        if (_inToken == address(token)) deposit(_amount);
        else {
            IERC20(_inToken).safeTransferFrom(msg.sender, address(this), _amount);

            IERC20(_inToken).safeApprove(address(zapper), 0);
            IERC20(_inToken).safeApprove(address(zapper), _amount);
            uint256 _outAmount = zapper.ZapIn(_inToken, address(token), isPairToken, _amount);

            uint256 _pool = balance();
            uint256 shares = 0;
            if (totalSupply() == 0) {
                shares = _outAmount;
            } else {
                shares = (_outAmount.mul(totalSupply())).div(_pool);
            }
            _mint(msg.sender, shares);
        }
    }

    function depositAll() external {
        deposit(token.balanceOf(msg.sender));
    }

    //if a user inputs the want token
    function deposit(uint256 _amount) public {
        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
    }

    function withdraw(uint256 _shares) public {
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IController(controller).withdraw(address(token), _withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        token.safeTransfer(msg.sender, r);
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    function harvest(address reserve, uint256 amount) external {
        require(msg.sender == controller, "!controller");
        require(reserve != address(token), "token");
        IERC20(reserve).safeTransfer(controller, amount);
    }

    function getPricePerFullShare() public view returns (uint256) {
        return balance().mul(1e18).div(totalSupply());
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "only governance is allowed");
        _;
    }
}

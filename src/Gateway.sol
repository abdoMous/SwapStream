// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "./interfaces/ICoWSwapSettlement.sol";
import "./vendored/GPv2Order.sol";
import {ICoWSwapOnchainOrders} from "./vendored/ICoWSwapOnchainOrders.sol";

/*
 * @title Gateway
 * @dev This contract allows users to deposit any token into the smart contract and receive USDC in return.
 * The contract owner can withdraw USDC from the smart contract.
 * The contract uses the Cow Protocol to handle the swap and ensure that the contract only receives USDC.
 */
contract Gateway is IERC1271, ICoWSwapOnchainOrders {
    ///////////////////////
    // Type declarations //
    ///////////////////////
    struct Payment {
        address customer;
        IERC20 token;
        uint256 amount;
    }

    /////////////////////
    // State Variables //
    /////////////////////

    // Address of the Cow Protocol
    ICoWSwapSettlement public immutable i_cowSettlement;

    address private s_usdcAddress;

    // Mapping to store USDC balance for each address
    Payment[] public s_payments;

    ////////////
    // Events //
    ////////////
    event Deposited(address indexed user, uint256 amount, address token);
    event ConvertedToUSDC(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    ///////////////
    // Functions //
    ///////////////

    /////////////////////////
    // External Functions //
    ////////////////////////

    constructor(address _cowProtocolSettlementAddress, address usdcAddress) {
        i_cowSettlement = ICoWSwapSettlement(_cowProtocolSettlementAddress);
        s_usdcAddress = usdcAddress;
    }

    // Allows users to deposit any token into the smart contract
    function depositAssets(address tokenAddress, uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        s_payments.push(Payment(msg.sender, token, amount));
        emit Deposited(msg.sender, amount, tokenAddress); // Update the amount and token address accordingly
    }

    // Allows users or the contract owner to withdraw USDC from the smart contract
    function withdrawUSDC() external {
        // loop through mapping s_payments and convert all tokens to USDC using Cow Protocol
        for (uint256 i = 0; i < s_payments.length; i++) {
            IERC20 buyToken = IERC20(s_usdcAddress);

            // Create order parameters
            GPv2Order.Data memory orderData = GPv2Order.Data({
                buyToken: buyToken,
                sellToken: s_payments[i].token,
                buyAmount: s_payments[i].amount,
                receiver: msg.sender,
                sellAmount: 0,
                validTo: uint32(block.timestamp) + 60 * 60 * 24, // 1 day expiration
                appData: "",
                feeAmount: 0,
                kind: "sell",
                partiallyFillable: false,
                sellTokenBalance: "erc20",
                buyTokenBalance: "erc20"
            });

            // Hash order data
            bytes32 orderHash = GPv2Order.hash(orderData, i_cowSettlement.domainSeparator());

            // Sign hash using ERC1271
            OnchainSignature memory signature =
                OnchainSignature({scheme: OnchainSigningScheme.Eip1271, data: signOrder(orderHash)});

            // Approve settlement contract to spend sell tokens
            s_payments[i].token.approve(address(i_cowSettlement), s_payments[i].amount);

            emit OrderPlacement(address(this), orderData, signature, bytes("hi gateway"));
        }

        emit Withdrawn(msg.sender, 0);
    }

    ///////////////////////////////////////
    // Private & Internal veiw Functions //
    ///////////////////////////////////////
    // Sign order data hash using ERC1271 signature
    function signOrder(bytes32 orderHash) public returns (bytes memory) {
        bytes4 magicValue = bytes4(keccak256("ERC1271"));

        return abi.encodePacked(
            magicValue, // ERC1271 magic value
            orderHash // order hash
        );
    }

    //////////////////////////////////////
    // Public & External View Functions //
    //////////////////////////////////////

    // Fetches the current conversion rate from the Cow Protocol for a specific token to USDC
    function getConversionRate(address token) public view returns (uint256) {
        // TODO: Logic to fetch conversion rate from Cow Protocol
        return 0; // Placeholder value
    }

    // Returns the total amount of USDC currently in the smart contract
    function totalUSDCBalance() public view returns (uint256) {
        // TODO: Logic to return total USDC balance
        return 0; // Placeholder value
    }

    // Provides a list of pending deposits that are waiting to be converted
    function queryPendingDeposits() public view returns (address[] memory) {
        // TODO: Logic to return list of pending deposits
        return new address[](0); // Placeholder value
    }

    // Validate ERC1271 signature
    function isValidSignature(bytes32 hash, bytes memory signature) external view override returns (bytes4) {
        // Check magic value
        bytes4 magicValue = bytes4(signature);
        require(magicValue == IERC1271.isValidSignature.selector, "Invalid magic value");

        // Recover signer from signature
        bytes32 messageHash = bytes32(signature);
        require(hash == messageHash, "Invalid hash");

        // Signature is valid
        return IERC1271.isValidSignature.selector;
    }
}

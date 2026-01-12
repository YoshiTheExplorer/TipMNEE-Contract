// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TipEscrow is EIP712 {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    address public verifier;
    address public owner;

    mapping(bytes32 => address) public payoutOf;
    mapping(bytes32 => uint256) public balanceOf;
    mapping(bytes32 => bool) public usedNonce;

    bytes32 public constant CLAIM_TYPEHASH =
        keccak256("Claim(bytes32 channelIdHash,address payoutAddress,uint256 expiry,bytes32 nonce)");

    event Tipped(bytes32 indexed channelIdHash, address indexed from, uint256 amount, string message);
    event Claimed(bytes32 indexed channelIdHash, address indexed payoutAddress);
    event Withdrawn(bytes32 indexed channelIdHash, address indexed payoutAddress, uint256 amount);
    event VerifierUpdated(address indexed oldVerifier, address indexed newVerifier);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(address tokenAddress, address verifierAddress)
        EIP712("TipMNEE", "1")
    {
        require(tokenAddress != address(0), "bad token");
        require(verifierAddress != address(0), "bad verifier");
        token = IERC20(tokenAddress);
        verifier = verifierAddress;
        owner = msg.sender;
    }

    function channelHash(string calldata channelId) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(channelId));
    }

    function tip(bytes32 channelIdHash, uint256 amount, string calldata message) external {
        require(amount > 0, "amount=0");

        token.safeTransferFrom(msg.sender, address(this), amount);

        balanceOf[channelIdHash] += amount;
        emit Tipped(channelIdHash, msg.sender, amount, message);
    }

    function claim(
        bytes32 channelIdHash,
        address payoutAddress,
        uint256 expiry,
        bytes32 nonce,
        bytes calldata sig
    ) external {
        require(payoutAddress != address(0), "bad payout");
        require(block.timestamp <= expiry, "expired");
        require(payoutOf[channelIdHash] == address(0), "already claimed");

        bytes32 nonceKey = keccak256(abi.encodePacked(channelIdHash, payoutAddress, nonce));
        require(!usedNonce[nonceKey], "nonce used");
        usedNonce[nonceKey] = true;

        bytes32 structHash = keccak256(
            abi.encode(CLAIM_TYPEHASH, channelIdHash, payoutAddress, expiry, nonce)
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, sig);
        require(signer == verifier, "bad sig");

        payoutOf[channelIdHash] = payoutAddress;
        emit Claimed(channelIdHash, payoutAddress);
    }

    function withdraw(bytes32 channelIdHash) external {
        address payout = payoutOf[channelIdHash];
        require(payout != address(0), "not claimed");

        uint256 amt = balanceOf[channelIdHash];
        require(amt > 0, "nothing");

        balanceOf[channelIdHash] = 0;

        token.safeTransfer(payout, amt);
        emit Withdrawn(channelIdHash, payout, amt);
    }

    function setVerifier(address newVerifier) external onlyOwner {
        require(newVerifier != address(0), "bad verifier");
        emit VerifierUpdated(verifier, newVerifier);
        verifier = newVerifier;
    }
}

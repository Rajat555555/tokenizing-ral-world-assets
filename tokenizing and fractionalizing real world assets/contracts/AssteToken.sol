// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Real World Asset (RWA) Fractional Token
 * @notice Implements compliant minting and restricted transfer logic for tokenized assets.
 */
contract AssetToken is ERC20, Ownable {
    
    // Mapping to track KYC/AML verified addresses
    mapping(address => bool) public isWhitelisted;

    // Asset metadata (e.g., IPFS hash pointing to legal property deed and appraisal)
    string public assetDocumentsURI;

    event AddressWhitelisted(address indexed account, bool isWhitelisted);
    event DocumentsUpdated(string newURI);

    modifier onlyWhitelisted(address from, address to) {
        require(isWhitelisted[from], "RWA: Sender is not KYC whitelisted");
        require(isWhitelisted[to], "RWA: Recipient is not KYC whitelisted");
        _;
    }

    constructor(
        string memory name, 
        string memory symbol, 
        uint256 totalSupply,
        string memory _documentsURI
    ) 
        ERC20(name, symbol) 
        Ownable(msg.sender) 
    {
        assetDocumentsURI = _documentsURI;
        
        // Auto-whitelist the deployer (issuer) to allow initial distribution
        isWhitelisted[msg.sender] = true;
        
        // Mint the fractionalized shares to the asset manager/issuer
        _mint(msg.sender, totalSupply * 10 ** decimals());
    }

    /**
     * @notice Updates the compliance whitelist status for an investor account.
     */
    function updateWhitelist(address account, bool status) external onlyOwner {
        isWhitelisted[account] = status;
        emit AddressWhitelisted(account, status);
    }

    /**
     * @notice Updates the reference link to legal documentation if zoning/appraisals change.
     */
    function updateDocuments(string calldata newURI) external onlyOwner {
        assetDocumentsURI = newURI;
        emit DocumentsUpdated(newURI);
    }

    /**
     * @notice Overrides the standard ERC20 transfer hook to enforce regulatory compliance.
     * @dev Ensures tokens cannot be traded to unverified peer-to-peer wallets.
     */
    function transfer(address to, uint256 value) public override onlyWhitelisted(msg.sender, to) returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @notice Overrides the standard ERC20 transferFrom hook for compliance.
     */
    function transferFrom(address from, address to, uint256 value) public override onlyWhitelisted(from, to) returns (bool) {
        return super.transferFrom(from, to, value);
    }
}
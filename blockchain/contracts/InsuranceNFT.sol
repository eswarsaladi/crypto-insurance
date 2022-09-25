// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract InsuranceNFT is ERC721 {
    event InsuranceActive(uint256 indexed tokenId);
    event InsuranceCreated(uint256 indexed tokenId, uint256 premium);

    struct Person {
        string name;
        string ssn;
        uint8 riskFactor;
        uint256 premium;
        address owner;
        address beneficary;
        bool active;
        bool ended;
        uint256 startTime;
    }

    uint256 public TIME_PERIOD = 365 days;
    uint256 public TOTAL_PAY = 5 gwei;

    address admin;
    mapping(uint256 => Person) private tokenToPerson;
    uint256 private s_tokenCounter;

    constructor() ERC721("Insurance NFT", "INFT") {
        admin = msg.sender;
        s_tokenCounter = 0;
    }

    function requestNft(
        string memory _name,
        string memory _ssn,
        address _beneficary
    ) public payable {
        _safeMint(admin, s_tokenCounter);
        tokenToPerson[s_tokenCounter].name = _name;
        tokenToPerson[s_tokenCounter].ssn = _ssn;
        tokenToPerson[s_tokenCounter].beneficary = _beneficary;
        tokenToPerson[s_tokenCounter].riskFactor = 50; // fetch from somewhere

        tokenToPerson[s_tokenCounter].active = false;
        tokenToPerson[s_tokenCounter].ended = false;

        emit InsuranceCreated(
            s_tokenCounter,
            tokenToPerson[s_tokenCounter].premium
        );
        s_tokenCounter = s_tokenCounter + 1;
    }

    function buyInsurance(uint256 tokenId) public payable {
        require(msg.value >= TOTAL_PAY, "Insufficient Funds");
        approve(msg.sender, tokenId);
        safeTransferFrom(admin, msg.sender, tokenId);
    }

    function getRiskFactor(uint256 tokenId) external view returns (uint256) {
        return tokenToPerson[tokenId].riskFactor;
    }

    function getPremium(uint256 tokenId) external view returns (uint256) {
        return tokenToPerson[tokenId].premium;
    }

    function payPremium(uint256 tokenId)
        external
        payable
        isNotEnded(tokenId)
        isInsuranceHolder(tokenId)
    {
        require(
            msg.value >= tokenToPerson[tokenId].premium,
            "Insufficient Funds"
        );

        if (!tokenToPerson[tokenId].active) {
            tokenToPerson[tokenId].active = true;
            emit InsuranceActive(tokenId);
        }
    }

    function declareDeadGetPay(uint256 tokenId)
        external
        isActive(tokenId)
        isNotEnded(tokenId)
    {
        require(
            tokenToPerson[tokenId].beneficary == msg.sender,
            "invalid sender"
        );
        tokenToPerson[tokenId].ended = true;

        (bool sent, ) = msg.sender.call{value: TOTAL_PAY}("eth sent");
        require(sent, "Failed to send Ether");
    }

    modifier isActive(uint256 tokenId) {
        require(tokenToPerson[tokenId].active, "Insurance is not active");
        _;
    }
    modifier isNotEnded(uint256 tokenId) {
        require(!tokenToPerson[tokenId].ended, "Insurance ended");
        _;
    }

    modifier isInsuranceHolder(uint256 tokenId) {
        require(tokenToPerson[tokenId].owner == msg.sender, "");
        _;
    }
}

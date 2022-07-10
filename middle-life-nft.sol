// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract MidLife is ERC721A, Ownable {
    using Strings for uint256;

    bool public _isSaleActive = false;
    bool public _revealed = false;

    // Constants
    uint256 public constant MAX_SUPPLY = 500;
    uint256 public mintPrice = 0.01 ether;
    uint256 public maxMint = 2;

    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";
    bytes32 public merkleRoot = 0xabf0ea6f02025cc1b8d7556e47ebadb30ce1cb70560e650c8d09c0133700b983;

    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint) public balances;

    constructor(string memory initBaseURI, string memory initNotRevealedUri)
        ERC721A("Middle Life", "ML")
    {
        setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
    }

    function mintML(uint256 tokenQuantity, bytes32[] calldata _merkleProof) public payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint senderBalance = balances[msg.sender];

        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Proof");
        require(totalSupply() + tokenQuantity <= MAX_SUPPLY, "Sale would exceed max supply");
        require(_isSaleActive, "Sale must be active to mint Middle Life");
        require(tokenQuantity * mintPrice <= msg.value, "Not enough ether sent");
        require(senderBalance + tokenQuantity <= maxMint, "Can only mint 2 nft per wallet");

        balances[msg.sender] = senderBalance + tokenQuantity;

        _mintML(tokenQuantity);
    }

    function _mintML(uint256 tokenQuantity) internal {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (_revealed == false) {
            return notRevealedUri;
        }

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //only owner
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function withdraw(address payable to) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = to.call{value: balance}("");
        require(success, "wanlequanwanle");
    }
}

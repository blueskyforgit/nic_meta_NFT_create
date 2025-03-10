// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NicMeta is ERC721Enumerable, Ownable {
    using Strings for uint256;

    //是可以可以开始销售开关    function flipSaleActive() public onlyOwner  这个函数触发可以更改_isSaleActive
    bool public _isSaleActive = false;
    // false = 盲盒阶段
    bool public _revealed = false;

    // Constants
    // NFT总数量
    uint256 public constant MAX_SUPPLY = 10;
    // 售卖价格
    uint256 public mintPrice = 0.001 ether;
    // 每个地址可以持有量
    uint256 public maxBalance = 1;
    // 一次可以Mint多少个
    uint256 public maxMint = 1;

    // 正式图片 IPFS URL
    string baseURI;
    // 盲盒 IPFS URL
    string public notRevealedUri;
    // IPFS 中得到的JSON文件？
    string public baseExtension = ".json";

    mapping(uint256 => string) private _tokenURIs;

    // Nic Meta合约名字  NM是代号
    constructor(string memory initBaseURI, string memory initNotRevealedUri)
    
        ERC721("Nic Meta", "NM")
    {
        setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
    }

    // 用户的Minit函数  条件通过后进入内部函数 _mintNicMeta(tokenQuantity);
    // tokenQuantity输入Mint的数量
    // 输入Wei
    // 完成后可以去opensea查看
    function mintNicMeta(uint256 tokenQuantity) public payable {
        require(
            
            totalSupply() + tokenQuantity <= MAX_SUPPLY,
            // 销售额将超过最大供应量
            "Sale would exceed max supply"
        );
        // 销售必须是激活的，以制造NicMetas
        require(_isSaleActive, "Sale must be active to mint NicMetas");
        require(
            balanceOf(msg.sender) + tokenQuantity <= maxBalance,
            // 销售额将超过最大余额
            "Sale would exceed max balance"
        );
        require(
            // 输入的Wei是否大于等于tokenQuantity * mintPrice
            tokenQuantity * mintPrice <= msg.value,
            // 发送的eth不足
            "Not enough ether sent"
        );
        // 一次只能铸造1枚代币
        require(tokenQuantity <= maxMint, "Can only mint 1 tokens at a time");

        _mintNicMeta(tokenQuantity);
    }

    // Mint出来的是NFTtokenId:0,1,2,3,4,5  ，然后在URI + NFTtokenId  + .jpg
    function _mintNicMeta(uint256 tokenQuantity) internal {
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
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //only owner
    // 开启 Mint 功能
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    // 关闭盲盒功能
    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    // 设定盲盒图片 IPFS URI   
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    // 设定NFT正式图片 IPFS URI 最后要有斜线 /  结尾，因为是拼接起来很多图片
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    // 提取合约中的金额
    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}

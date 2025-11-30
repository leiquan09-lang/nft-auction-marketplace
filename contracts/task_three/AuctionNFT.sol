// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AuctionNFT is ERC721, ERC721URIStorage, Ownable {
    // 基础 NFT 合约：
    // - 使用 ERC721 标准
    // - 仅所有者可铸造
    // - 使用 URIStorage 扩展，便于设置每个 Token 的元数据 URI
    uint256 private _nextTokenId;

    // 构造函数：传入初始所有者地址（通常为部署者或后台运营地址）
    constructor(address initialOwner) ERC721("AuctionNFT", "ANFT") Ownable(initialOwner) {}

    // 铸造函数：仅所有者可调用
    // 参数：
    // - to: 接收 NFT 的地址
    // - uri: 该 Token 的元数据 URI（如 ipfs://...）
    function mint(address to, string memory uri) external onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    // 返回指定 Token 的元数据 URI
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // 多重继承下的接口支持声明
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

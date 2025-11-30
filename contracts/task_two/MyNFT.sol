// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MyNFT - 一个简单的 ERC721 NFT 合约
/// @notice 该合约用于演示如何在测试网上发行图文并茂的 NFT
/// @dev 继承自 OpenZeppelin 的 ERC721URIStorage 以支持每个 Token 独立的元数据 URI
contract MyNFT is ERC721, ERC721URIStorage, Ownable {
    /// @dev 用于跟踪下一个 token ID 的计数器
    uint256 private _nextTokenId;

    /// @notice 构造函数，初始化 NFT 集合名称和符号
    /// @param initialOwner 合约的所有者地址，拥有铸造权限
    /// @dev ERC721("MyNFT", "MNFT") 设置了集合名称为 MyNFT，符号为 MNFT
    ///      Ownable(initialOwner) 初始化所有者
    constructor(address initialOwner)
        ERC721("MyNFT", "MNFT")
        Ownable(initialOwner)
    {}

    /// @notice 铸造新的 NFT 并发送给指定接收者
    /// @dev 只有合约所有者可以调用此函数
    /// @param recipient 接收 NFT 的地址
    /// @param _tokenURI NFT 的元数据链接 (IPFS URL)
    /// @return 返回新铸造的 Token ID
    function mintNFT(address recipient, string memory _tokenURI)
        public
        onlyOwner
        returns (uint256)
    {
        uint256 tokenId = _nextTokenId++;
        _mint(recipient, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        return tokenId;
    }

    // 以下函数是 Solidity 要求的重写函数

    /// @notice 获取指定 Token ID 的元数据 URI
    /// @param tokenId Token ID
    /// @return 元数据 URI 字符串
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @notice 检查合约是否支持某个接口
    /// @param interfaceId 接口 ID
    /// @return 如果支持该接口则返回 true
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

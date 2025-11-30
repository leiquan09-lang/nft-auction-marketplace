// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 合约说明（拍卖主仓 + 可升级 + 预言机）：
// - 采用 UUPS 可升级模式（OpenZeppelin）。初始化与授权升级由所有者控制。
// - 支持两种支付方式：原生 ETH 与任意 ERC20 代币。
// - 集成 Chainlink 价格预言机：ETH/USD 与 Token/USD，用于将出价金额统一折算到 18 位精度的美元。
// - 动态手续费：根据美元金额分档计算手续费（基点制），并在结算时将净额付给卖家、手续费付给平台地址。
// - 最小加价规则：要求新出价基于当前最高价至少增加一定比例（默认 5%），防止刷价频繁且幅度过小。
// - 撤单逻辑：仅当没有任何出价时，卖家可撤单，NFT 退还；一旦有出价则不可撤单，保障竞拍公平。
// - 安全：使用 ReentrancyGuardUpgradeable 防重入；所有外部资金转移均带成功检查；避免存储非必要余额。

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract AuctionHouseUpgradeable is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    // 拍卖信息的核心结构体
    struct Auction {
        address seller;
        address nft;
        uint256 tokenId;
        address payToken; // address(0) for ETH
        uint64 endTime;
        uint256 highestBid;
        address highestBidder;
        bool active;
    }

    // 自增的拍卖 ID 与拍卖存储映射
    uint256 public nextAuctionId;
    mapping(uint256 => Auction) public auctions;

    // 价格预言机：ETH/USD 与可配置的 ERC20/USD
    AggregatorV3Interface public ethUsdFeed;
    mapping(address => AggregatorV3Interface) public tokenUsdFeed; // ERC20 -> USD feed

    // 最小加价（基点），例如 500 表示在当前最高价基础上至少加价 5%
    uint16 public minIncrementBps;
    // 费用接收地址（平台收入）
    address public feeRecipient;
    // 动态手续费分档：基于 USD 金额的三档阈值与费率（基点）
    uint256 public feeThreshold1Usd18; // 18 位精度的美元阈值 1
    uint256 public feeThreshold2Usd18; // 18 位精度的美元阈值 2
    uint16 public feeBps1; // 低于阈值 1 的费率
    uint16 public feeBps2; // 介于阈值 1 和阈值 2 的费率
    uint16 public feeBps3; // 高于阈值 2 的费率

    // 事件：上架、出价、结束（含流拍）
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, address indexed nft, uint256 tokenId, address payToken, uint64 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 usdValue);
    event AuctionFinalized(uint256 indexed auctionId, address winner, uint256 amount);

    // 初始化：设置所有者与 ETH/USD 价格喂价，并给出默认业务参数（可后续调整）
    function initialize(address owner_, address ethUsdFeed_) public initializer {
        __Ownable_init(owner_);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        ethUsdFeed = AggregatorV3Interface(ethUsdFeed_);
        // 默认配置：最小加价 5%，费用接收人为所有者；费用分档：< $1,000 => 1%，< $10,000 => 0.5%，其他 0.2%
        minIncrementBps = 500;
        feeRecipient = owner_;
        feeThreshold1Usd18 = 1000 ether; // 以 18 位精度表示的 1000 USD
        feeThreshold2Usd18 = 10000 ether; // 10000 USD
        feeBps1 = 100; // 1%
        feeBps2 = 50;  // 0.5%
        feeBps3 = 20;  // 0.2%
    }

    // UUPS 升级授权：仅所有者可升级实现地址
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // 设置 ETH/USD 预言机地址（链上部署时需要提供真实 Aggregator 地址）
    function setEthUsdFeed(address feed) external onlyOwner {
        ethUsdFeed = AggregatorV3Interface(feed);
    }

    // 设置某个 ERC20 的 USD 预言机地址（用于折算 ERC20 出价的美元值）
    function setTokenUsdFeed(address token, address feed) external onlyOwner {
        tokenUsdFeed[token] = AggregatorV3Interface(feed);
    }

    // 设置最小加价比例（基点）
    function setMinIncrementBps(uint16 bps) external onlyOwner {
        require(bps <= 5000, "bps too high");
        minIncrementBps = bps;
    }

    // 设置平台手续费收款地址
    function setFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "zero recipient");
        feeRecipient = recipient;
    }

    // 设置动态手续费分档阈值与对应费率（基点）
    function setFeeConfig(
        uint256 threshold1Usd18,
        uint256 threshold2Usd18,
        uint16 _feeBps1,
        uint16 _feeBps2,
        uint16 _feeBps3
    ) external onlyOwner {
        require(threshold2Usd18 >= threshold1Usd18, "bad thresholds");
        require(_feeBps1 <= 5000 && _feeBps2 <= 5000 && _feeBps3 <= 5000, "bps too high");
        feeThreshold1Usd18 = threshold1Usd18;
        feeThreshold2Usd18 = threshold2Usd18;
        feeBps1 = _feeBps1;
        feeBps2 = _feeBps2;
        feeBps3 = _feeBps3;
    }

    // 创建拍卖：将 NFT 托管到合约，记录支付资产类型与结束时间
    function createAuction(address nft, uint256 tokenId, address payToken, uint64 durationSecs) external nonReentrant returns (uint256 auctionId) {
        require(durationSecs > 0, "duration=0");
        // transfer NFT to custody
        IERC721(nft).transferFrom(msg.sender, address(this), tokenId);

        auctionId = nextAuctionId++;
        auctions[auctionId] = Auction({
            seller: msg.sender,
            nft: nft,
            tokenId: tokenId,
            payToken: payToken,
            endTime: uint64(block.timestamp + durationSecs),
            highestBid: 0,
            highestBidder: address(0),
            active: true
        });

        emit AuctionCreated(auctionId, msg.sender, nft, tokenId, payToken, uint64(block.timestamp + durationSecs));
    }

    // ETH 出价：支持最小加价规则；如果存在上一位最高价，则先退款给上一位
    function bidEth(uint256 auctionId) external payable nonReentrant {
        Auction storage a = auctions[auctionId];
        require(a.active, "inactive");
        require(a.payToken == address(0), "not eth");
        require(block.timestamp < a.endTime, "ended");
        if (a.highestBid > 0) {
            uint256 minRequired = a.highestBid + (a.highestBid * minIncrementBps) / 10000;
            require(msg.value >= minRequired, "increment too small");
        } else {
            require(msg.value > 0, "zero bid");
        }

        // refund previous
        if (a.highestBidder != address(0)) {
            (bool ok, ) = a.highestBidder.call{value: a.highestBid}("");
            require(ok, "refund failed");
        }

        a.highestBid = msg.value;
        a.highestBidder = msg.sender;

        uint256 usdValue = _ethToUsd(msg.value);
        emit BidPlaced(auctionId, msg.sender, msg.value, usdValue);
    }

    // ERC20 出价：走授权转账，支持最小加价规则与上一位最高价退款
    function bidErc20(uint256 auctionId, uint256 amount) external nonReentrant {
        Auction storage a = auctions[auctionId];
        require(a.active, "inactive");
        require(a.payToken != address(0), "not erc20");
        require(block.timestamp < a.endTime, "ended");
        if (a.highestBid > 0) {
            uint256 minRequired = a.highestBid + (a.highestBid * minIncrementBps) / 10000;
            require(amount >= minRequired, "increment too small");
        } else {
            require(amount > 0, "zero bid");
        }

        IERC20 token = IERC20(a.payToken);
        // take funds from bidder
        require(token.transferFrom(msg.sender, address(this), amount), "transferFrom fail");
        // refund previous
        if (a.highestBidder != address(0)) {
            require(token.transfer(a.highestBidder, a.highestBid), "refund fail");
        }

        a.highestBid = amount;
        a.highestBidder = msg.sender;

        uint256 usdValue = _erc20ToUsd(a.payToken, amount);
        emit BidPlaced(auctionId, msg.sender, amount, usdValue);
    }

    // 结束拍卖：转移 NFT，按动态手续费结算（平台 / 卖家）
    function finalize(uint256 auctionId) external nonReentrant {
        Auction storage a = auctions[auctionId];
        require(a.active, "inactive");
        require(block.timestamp >= a.endTime, "not ended");
        a.active = false;

        if (a.highestBidder == address(0)) {
            // no bids, return NFT
            IERC721(a.nft).transferFrom(address(this), a.seller, a.tokenId);
            emit AuctionFinalized(auctionId, address(0), 0);
            return;
        }

        // transfer NFT to winner
        IERC721(a.nft).transferFrom(address(this), a.highestBidder, a.tokenId);

        // 计算手续费（动态分档，按 USD 金额选择费率），并支付卖家与平台
        uint256 fee;
        if (a.payToken == address(0)) {
            uint256 usdValue = _ethToUsd(a.highestBid);
            uint16 feeBps = _feeBpsForUsd(usdValue);
            fee = (a.highestBid * feeBps) / 10000;
            uint256 sellerAmount = a.highestBid - fee;
            (bool ok1, ) = a.seller.call{value: sellerAmount}("");
            require(ok1, "payout failed");
            (bool ok2, ) = feeRecipient.call{value: fee}("");
            require(ok2, "fee payout failed");
        } else {
            uint256 usdValue = _erc20ToUsd(a.payToken, a.highestBid);
            uint16 feeBps = _feeBpsForUsd(usdValue);
            fee = (a.highestBid * feeBps) / 10000;
            uint256 sellerAmount = a.highestBid - fee;
            IERC20 token = IERC20(a.payToken);
            require(token.transfer(a.seller, sellerAmount), "payout failed");
            require(token.transfer(feeRecipient, fee), "fee payout failed");
        }

        emit AuctionFinalized(auctionId, a.highestBidder, a.highestBid);
    }

    // 卖家撤单：仅当没有任何出价时可撤单，NFT 退回给卖家
    function cancel(uint256 auctionId) external nonReentrant {
        Auction storage a = auctions[auctionId];
        require(a.active, "inactive");
        require(a.seller == msg.sender, "not seller");
        require(a.highestBidder == address(0), "has bids");
        a.active = false;
        IERC721(a.nft).transferFrom(address(this), a.seller, a.tokenId);
        emit AuctionFinalized(auctionId, address(0), 0);
    }

    // ETH -> USD（统一到 18 位精度）
    function _ethToUsd(uint256 weiAmount) internal view returns (uint256) {
        (, int256 answer,,,) = ethUsdFeed.latestRoundData();
        uint8 decimals = ethUsdFeed.decimals();
        // usd with 18 decimals
        return weiAmount * uint256(answer) * (10 ** (18 - decimals)) / 1e18;
    }

    // ERC20 -> USD（统一到 18 位精度）
    function _erc20ToUsd(address token, uint256 amount) internal view returns (uint256) {
        AggregatorV3Interface feed = tokenUsdFeed[token];
        require(address(feed) != address(0), "feed missing");
        (, int256 answer,,,) = feed.latestRoundData();
        uint8 decimals = feed.decimals();
        return amount * uint256(answer) * (10 ** (18 - decimals)) / 1e18;
    }

    // 根据 USD 金额选择费率分档
    function _feeBpsForUsd(uint256 usd18) internal view returns (uint16) {
        if (usd18 < feeThreshold1Usd18) return feeBps1;
        if (usd18 < feeThreshold2Usd18) return feeBps2;
        return feeBps3;
    }
}

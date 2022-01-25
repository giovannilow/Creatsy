// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "./NFT.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    address payable owner;
    uint256 listingPrice = 0.025 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        // address creator;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    // mapping over the id numbers to retrieve the item
    mapping(uint256 => MarketItem) private idToMarketItem;

    // to match the MarketItem struct
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256  indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sol
    );

    // event ProductListed(
    //     uint256 indexed itemId
    // );

    // modifier onlyItemOwner(uint256 id) {
    //     require(
    //         idToMarketItem[id].owner == msg.sender,
    //         "Only product owner can do this operation"
    //     );
    //     _;
    // }

    // pull listing price
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // creating an item and putting it for sale
    function createMarketItem(
        // contract for the nft
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant { // prevent re entry attack
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        // create market itm and set mapping
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)), // no owner yet
            price,
            false // not sold yet
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }
    
    function createMarketSale(
        address nftContract,
        uint256 itemId
    ) public payable nonReentrant {
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        //transfer the value to the seller
        idToMarketItem[itemId].seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId); // transfer the ownership
        idToMarketItem[itemId].owner = payable(msg.sender); // set the local value for owner to sender
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();
        payable(owner).transfer(listingPrice); // tranfer the amt the person listed the item for to contract owner (commission)
    }

    // return all unsold items
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        // looping over all items and increment if we have an empty address (not sold)
        // then populate the array with the unsold item
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i+1].owner == address(0)) {
                uint currentId = idToMarketItem[i+1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId]; 
                items[currentIndex] = currentItem; //insert item into array
                currentIndex += 1;
            }
        }
        return items;
    }

    // return only NFTs user has purchased
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i+1].owner == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i+1].owner == msg.sender) { // similar to return unsold items
                uint currentId = idToMarketItem[i+1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
    // return all items user has created
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i+1].seller == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i+1].seller == msg.sender) { // similar to return unsold items
                uint currentId = idToMarketItem[i+1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // function putItemToResell(address nftContract, uint256 itemId, uint256 newPrice)
    //     public
    //     payable
    //     nonReentrant
    //     onlyItemOwner(itemId)
    // {
    //     uint256 tokenId = idToMarketItem[itemId].tokenId;
    //     require(newPrice > 0, "Price must be at least 1 wei");
    //     require(
    //         msg.value == listingPrice,
    //         "Price must be equal to listing price"
    //     );
    //     //instantiate a NFT contract object with the matching type
    //     NFT tokenContract = NFT(nftContract);
    //     //call the custom transfer token method   
    //     tokenContract.transferToken(msg.sender, address(this), tokenId);

    //     address oldOwner = idToMarketItem[itemId].owner;
    //     idToMarketItem[itemId].owner = payable(address(0));
    //     idToMarketItem[itemId].seller = payable(oldOwner);
    //     idToMarketItem[itemId].price = newPrice;
    //     idToMarketItem[itemId].sold = false;
    //     _itemsSold.decrement();

    //     emit ProductListed(itemId);
    // }
}
pragma solidity ^0.5.16;
import "contracts/Escrow.sol";
contract EcommerceStore {
  enum ProductStatus { Open, Sold, Unsold }
  enum ProductCondition { New,Used }
  uint public productindex;
  mapping (address => mapping(uint => Product)) stores;
  mapping(uint => address) productIdInStore;
  struct Product {
    uint id;
    string name;
    string category;
    string imageLink;
    string desLink;
    uint auctionStartTime;
    uint auctionEndTime;
    uint startPrice;
    address payable highestBidder;
    address payable highestBid;
    address payable secondHighestBid;
    uint totalBids;
    ProductStatus status;
    ProductCondition condition;
    mapping ( address => mapping (bytes32 => Bid)) bids;
    }

    struct Bid {
    address bidder;
    uint productId;
    uint value;
    bool revealed;
    }

    function EcommerceProductStore() public {
    productindex = 0;
    }

    function addProductToStore(string memory _name,string memory _category,string memory _imageLink,string memory _desLink,uint _actionStartTime,uint _auctionEndTime,uint _startPrice,uint _ProductCondition) public {
    require (_actionStartTime < _auctionEndTime);
    productindex+=1;
    Product memory product = Product(productindex,_name,_category,_imageLink,_desLink,_actionStartTime,_auctionEndTime,_startPrice,address(0),address(0),address(0),0,ProductStatus.Open,ProductCondition(_ProductCondition));
    stores[msg.sender][productindex] = product;
    productIdInStore[productindex] = msg.sender;
    }

    function getProduct(uint _productId) view public returns (uint,string memory,string memory,string memory,string memory,uint,uint,uint,ProductStatus,ProductCondition) {
    Product memory product = stores[productIdInStore[_productId]][_productId];
    return (product.id,product.name,product.category,product.imageLink,product.desLink,product.auctionStartTime,product.auctionEndTime,product.startPrice,product.status,product.condition);
    }

    function bid(uint _productId,bytes32 _bid) payable public returns (bool) {
    Product storage product=stores[productIdInStore[_productId]][_productId];
    require (uint(now) >= product.auctionStartTime);
    require (uint(now) >= product.auctionEndTime);
    require (uint(msg.value) > product.startPrice);
    require (product.bids[msg.sender][_bid].bidder == address(0));
    product.bids[msg.sender][_bid] = Bid(msg.sender,_productId,uint(msg.value),false);
    product.totalBids+=1;
    return true;
    }



    function revealBid(uint _productId,string memory _amount,string memory _secret) payable public {
    Product storage product=stores[productIdInStore[_productId]][_productId];
    require (uint(now) >= product.auctionEndTime);
    bytes32 sealedBid = sha256(abi.encodePacked(_amount,_secret));
    Bid memory bidInfo = product.bids[msg.sender][sealedBid];
    require (bidInfo.bidder > address(0));
    require (bidInfo.revealed == false);
    uint refund;
    uint amount= stringToUint(_amount);
    if(bidInfo.value < amount) {
    refund = bidInfo.value;
    }
    else
    {
    if(address(product.highestBidder)==address(0)){
    product.highestBidder=msg.sender;
    product.highestBid=address(amount);
    product.secondHighestBid = address(product.startPrice);
    refund = bidInfo.value - amount;
    }
    else{
    if(address(amount) > address(product.highestBid)){
    product.secondHighestBid = product.highestBid;
    product.highestBidder.transfer(uint(product.highestBid));
    product.highestBidder=msg.sender;
    product.highestBid=address(amount);
    refund=bidInfo.value - amount;
    }
    else if(address(amount) > address(product.secondHighestBid)){
    product.secondHighestBid=address(amount);
    refund=amount;
    }
    else{
    refund=amount;
    }
   }
  }
  product.bids[msg.sender][sealedBid].revealed = true;
  if(refund > 0){
  msg.sender.transfer(refund);
  }
  }
  function finalizeAuction(uint _productId) public {
    // originally product was declared as memory var,
    // however, this will result in copying the object from state store to memory
    // which results in that changes could not be committed back
    Product product = stores[productIdInStore[_productId]][_productId];

    require(now > product.auctionEndTime);
    require(product.status == ProductStatus.Open);
    require(product.highestBidder != msg.sender);
    require(productIdInStore[_productId] != msg.sender);

    if (product.totalBids == 0) {
      product.status = ProductStatus.Unsold;
    } else {
      Escrow escrow = (new Escrow).value(product.secondHighestBid)(
        _productId,
        product.highestBidder,
        productIdInStore[_productId],
        msg.sender);
      productEscrow[_productId] = address(escrow);
      product.status = ProductStatus.Sold;

      uint refund = product.highestBid - product.secondHighestBid;
      product.highestBidder.transfer(refund);
    }
  }

  function releaseAmountToSeller(uint _productId) public {
    Escrow(productEscrow[_productId]).releaseAmountToSeller(msg.sender);
  }

  function refundAmountToBuyer(uint _productId) public {
    Escrow(productEscrow[_productId]).refundAmountToBuyer(msg.sender);
  }

  function escrowAddressForProduct(uint _productId) view public returns (address) {
    return productEscrow[_productId];
  }

  function escrowInfo(uint _productId) view public returns (address, address, address, bool, uint, uint) {
    return Escrow(productEscrow[_productId]).escrowInfo();
  }

    function highestBidderInfo(uint _productid) view public returns (address,address,address) {
    Product memory product = stores[productIdInStore[_productid]][_productid];
    return (product.highestBidder,product.highestBid,product.secondHighestBid);
    } 
    function totalBids(uint _productid) view public returns (uint) {
    Product memory product=stores[productIdInStore[_productid]][_productid];
    return product.totalBids;
    }
    function stringToUint(string memory s) internal pure returns (uint) {
    bytes memory b = bytes(s);
        uint i;
        uint result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
                result = result * 10 + (c - 48);
    }
   }
return result;
}
}
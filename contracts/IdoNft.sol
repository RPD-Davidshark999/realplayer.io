// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILGGNFT {
    function safeMintBlindBox(address to, string memory uri) external;
    function safeMintBlindBox(address to, string memory uri, uint256 tokenId) external;
    function openBlindBox(uint256 tokenId, string memory uri) external;
    function ownerOf(uint256 tokenId) external returns(address);
}

contract IdoNFT is Ownable {

    bool public open;
    bool public done;
    bool public isStartOpen;
    bool public publicSell;
    mapping (address => bool) public whitelist;
    mapping (address => bool) public doneAddress;
    mapping (uint256 => bool) public isOpenBlindBox;
    uint256 public sellcount;
    uint256 public sales;
    uint256 public boxTokenPrices;
    ILGGNFT public token;
    address public beneficiary;
    uint256 public count;

    mapping (uint256 => string) private uris;

    constructor(ILGGNFT _token){
        token = _token;
        sellcount = 888;
        boxTokenPrices = 8 * 10 ** 16;
        beneficiary = msg.sender;
    }

    function buyBox(uint256 _boxesLength) external payable {
        require(open, "No launch");
        require(!done, "Finish");
        require(_boxesLength > 0, "Boxes length must > 0");
        address sender = msg.sender;
        require(!doneAddress[sender], "Purchase only once");
        uint256 price = _boxesLength * boxTokenPrices;
        uint256 amount = msg.value;
        require(amount >= price, "Transfer amount error");
        if(!publicSell){
            require(whitelist[sender], "Account is not already whitelist");
            whitelist[sender] = false;
        }else{
            doneAddress[sender] = true;
        }
        
        for (uint256 i = 0; i < _boxesLength; i++) {
            require(sales < sellcount, "Sell out");
            sales += 1;
            if(sales >= sellcount){
                done = true;
            }
            token.safeMintBlindBox(sender, uris[0]);
        }
            

        payable(beneficiary).transfer(price);
        
        emit Buy(sender, beneficiary, price);

    }

    function openBlindBox(uint256 _tokenId) external payable {
        require(isStartOpen, "Not start");
        require(token.ownerOf(_tokenId) == msg.sender);
        require(!isOpenBlindBox[_tokenId], "Blind box has been opened");
        isOpenBlindBox[_tokenId] = true;
        count++;
        token.openBlindBox(_tokenId, uris[count]);  
    }

    function setWhitelist(address[] memory _accounts, bool _b) public onlyOwner {
        for (uint i = 0; i < _accounts.length; i+=1) {
            whitelist[_accounts[i]] = _b;
        }
    }

    function setSellcount(uint256 _count) public onlyOwner {
        sellcount = _count;
    }

    function setBoxTokenPrices(uint256 _boxTokenPrices) public onlyOwner {
        boxTokenPrices = _boxTokenPrices;
    }

    function setOpen(bool _open) public onlyOwner {
        open = _open;
    }

    function setDone(bool _done) public onlyOwner {
        done = _done;
    }

    function setStartOpen(bool _startOpen) public onlyOwner {
        isStartOpen = _startOpen;
    }

    function setPublicSell(bool _publicSell) public onlyOwner {
        publicSell = _publicSell;
    }

    function setUri(uint _index, string memory _uri) public onlyOwner {
        uris[_index] = _uri;
    }

    function setToken(ILGGNFT _token) public onlyOwner {
        token = _token;
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    receive() external payable {}
    fallback() external payable {}

    /* ========== EMERGENCY ========== */
    /*
        Users make mistake by transferring usdt/busd ... to contract address.
        This function allows contract owner to withdraw those tokens and send back to users.
    */
    function rescueStuckToken(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner(), amount);
    }

    function refund(address _addr, uint256 _amount) external onlyOwner {
        payable(_addr).transfer(_amount);
    }

    /* ========== EVENTS ========== */
    event Buy(address indexed user, address indexed beneficiary, uint256 indexed amount);
}
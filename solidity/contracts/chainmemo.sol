// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract ChainMemoLogic {
	bool notInit;
	address private _owner;
	bytes[] private memos;

	function addFirstMemo(bytes calldata memo) external {
		require(notInit);
		memos.push(memo);
		notInit = false;
	}
	function addMemo(bytes calldata memo) external {
		require(msg.sender == _owner, "not-owner");
		memos.push(memo);
	}
	function deleteMemo(uint i) external {
		require(msg.sender == _owner, "not-owner");
		uint last = memos.length - 1;
		if(i != last) {
			memos[i] = memos[last];
		}
		memos.pop();
	}
	function memoCount() external view returns (uint) {
		return memos.length;
	}
	function getMemo(uint i) external view returns (bytes memory memo) {
		memo = memos[i];
	}
}

contract ChainMemoProxy {
	bool notInit;
	address private _owner;
	bytes[] private memos;
	
	constructor(address owner) {
		_owner = owner;
		notInit = true;
	}
	
	receive() external payable {}
	fallback() payable external {
		uint impl=uint(uint160(bytes20(address(0x43AAc745E175327C8318DAd817947342b12CC9a8))));
		assembly {
			let ptr := mload(0x40)
			calldatacopy(ptr, 0, calldatasize())
			let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
			let size := returndatasize()
			returndatacopy(ptr, 0, size)
			switch result
			case 0 { revert(ptr, size) }
			default { return(ptr, size) }
		}
	}
}

contract ChainMemoFactory {
	event MemoContractCreated(address indexed owner, address indexed addr);

	function getAddress(address _owner) public view returns (address) {
		bytes memory bytecode = type(ChainMemoProxy).creationCode;
		bytes32 codeHash = keccak256(abi.encodePacked(bytecode, abi.encode(_owner)));
		bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), bytes32(0), codeHash));
		return address(uint160(uint(hash)));
	}

	function create(bytes calldata memo) external {
		address proxy = address(new ChainMemoProxy{salt: 0}(msg.sender));
		ChainMemoLogic(proxy).addFirstMemo(memo);
		emit MemoContractCreated(msg.sender, proxy);
	}
}

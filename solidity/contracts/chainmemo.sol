// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

//contract ChainMemoLogic {
//	bool notInit;
//	address private _owner;
//	bytes[] private memos;
//
//	function addFirstMemo(bytes calldata memo) external {
//		require(notInit);
//		memos.push(memo);
//		notInit = false;
//	}
//	function addMemo(bytes calldata memo) external {
//		require(msg.sender == _owner, "not-owner");
//		memos.push(memo);
//	}
//	function deleteMemo(uint i) external {
//		require(msg.sender == _owner, "not-owner");
//		uint last = memos.length - 1;
//		if(i != last) {
//			memos[i] = memos[last];
//		}
//		memos.pop();
//	}
//	function memoCount() external view returns (uint) {
//		return memos.length;
//	}
//	function getMemo(uint i) external view returns (bytes memory memo) {
//		memo = memos[i];
//	}
//}

contract ChainMemoLogic {
	bool notInit;
	address private _owner;
	uint public memoCount;
	address constant SEP101Contract = address(bytes20(uint160(0x2712)));

	function saveMemo(uint sn, bytes memory memo) internal {
		bytes memory snBz = abi.encode(sn);
		(bool success, bytes memory _notUsed) = SEP101Contract.delegatecall(
			abi.encodeWithSignature("set(bytes,bytes)", snBz, memo));
		require(success, "sep101-set-fail");
	}

	function getMemo(uint sn) public returns (bytes memory) {
		bytes memory snBz = abi.encode(sn);
		(bool success, bytes memory data) = SEP101Contract.delegatecall(
			abi.encodeWithSignature("get(bytes)", snBz));
		require(success && data.length >= 32*2, "sep101-get-fail");
		bytes memory memo;
		assembly { memo := add(data, 64) }
		return memo;
	}

	function removeMemo(uint sn) internal {
		bytes memory snBz = abi.encode(sn);
		bytes memory memo = new bytes(0);
		(bool success, bytes memory _notUsed) = SEP101Contract.delegatecall(
			abi.encodeWithSignature("set(bytes,bytes)", snBz, memo));
		require(success, "sep101-del-fail");
	}

	//==========================================================

	function addFirstMemo(bytes calldata memo) external {
		require(notInit);
		saveMemo(0, memo);
		memoCount = 1;
		notInit = false;
	}

	function addMemo(bytes calldata memo) external {
		require(msg.sender == _owner, "not-owner");
		saveMemo(memoCount, memo);
		memoCount = memoCount + 1;
	}

	function deleteMemo(uint i) external {
		require(msg.sender == _owner, "not-owner");
		uint last = memoCount - 1;
		if(i != last) {
			bytes memory memo = getMemo(last);
			saveMemo(i, memo);
		}
		removeMemo(last);
		memoCount = last;
	}
}

contract ChainMemoProxy {
	bool notInit;
	address private _owner;
	
	constructor(address owner) {
		_owner = owner;
		notInit = true;
	}
	
	receive() external payable {}
	fallback() payable external {
		uint impl=uint(uint160(bytes20(address(0x5fccE607FeDe87b9b33277EAd171aA4877b6274f))));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//////////////////////////////////
//  ____   ____  _____ _____
// |    \ /    |/ ___// ___/
// |  o  )  o  (   \_(   \_ 
// |   _/|     |\__  |\__  |
// |  |  |  _  |/  \ |/  \ |
// |  |  |  |  |\    |\    |
// |__|  |__|__| \___| \___|                       
//                                                                            
//////////////////////////////////

// HolderPass is ERC1155.

import { ERC165, IERC165, ERC165Storage }  from "@solidstate/contracts/introspection/ERC165.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { AccessControl } from "@solidstate/contracts/access/access_control/AccessControl.sol";
import { AccessControlStorage } from "@solidstate/contracts/access/access_control/AccessControlStorage.sol";
import { EnumerableSet } from "@solidstate/contracts/utils/EnumerableSet.sol";
import { ERC1155MetadataStorage } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol";
import { ERC1155EnumerableStorage } from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableStorage.sol";
import "@solidstate/contracts/token/ERC1155/SolidStateERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HolderPass is SolidStateERC1155, AccessControl {
    using ERC165Storage for ERC165Storage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;


    // Token informations
    string public name;
    string public symbol;
    uint256 public MAX_TOKEN = 3;
    mapping(uint256 => address[]) public indexedAccounts;
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _bsaeURI
    ) {
        ERC165Storage.layout().setSupportedInterface(
            type(IERC165).interfaceId,
            true
        );
        ERC165Storage.layout().setSupportedInterface(
            type(IERC1155).interfaceId,
            true
        );

        ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage.layout();
        l.baseURI = _bsaeURI;
        name = _name;
        symbol = _symbol;
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @notice mint new 1 token by tokenId, the amount is up to MAX_TOKEN.
     * @param account: account to mint a token, uint256: tokenid
     */
    function mintPass(
        address account,
        uint256 id
    ) external onlyRole(MINTER_ROLE)  {
        if(totalSupply(id) >= MAX_TOKEN) {
            address secondPassHolder = indexedAccounts[id][1];
            _burn(secondPassHolder, id, 1); 
        }
        _mint(account, id, 1, '');
    }
    
    /**
     * @notice get indexed_accounts_list who owns token id
     * @param id: token id
     * @return indexed_accounts_list
     */
    function indexedAccountsByToken(uint256 id)
        external
        view
        returns (address[] memory)   
    {
        address[] storage accounts = indexedAccounts[id];
        return accounts;
    }
    
    function accountByIndex(uint256 id, uint256 index)
        external
        view
        returns (address)   
    {
        return _accountByIndex(id, index);
    }

    function indexOfIndexedAccounts(uint256 id, address addr)
        external
        view
        returns (uint256)
    {
        address[] memory accounts = indexedAccounts[id];
        return _indexOf(accounts, addr);
    }

    function indexOfAddr(uint256 id, address addr)
        external
        view
        returns (uint256)
    {
        // TODO: if accounts is the list of account, not index.
        EnumerableSet.AddressSet storage accounts = ERC1155EnumerableStorage
            .layout()
            .accountsByToken[id];

        // checker: contains 
        // value => index
        require(accounts.contains(addr), "Invalid Index");
        return accounts.indexOf(addr);
    }

    /**
     * @notice ERC1155 hook: update aggregate values
     * @inheritdoc ERC1155BaseInternal
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != to) {
            for (uint256 i; i < ids.length; ) {
                uint256 amount = amounts[i];

                // Assumption: Amount should be 1.
                if (amount > 0) {
                    uint256 tokenId = ids[i];

                    if (from == address(0)) {
                        // Mint
                        indexedAccounts[tokenId].push(to);
                    } else if (to == address(0)){
                        // Burn
                        uint256 indexOfFrom = _indexOf(indexedAccounts[tokenId], from);
                        _removeAccounts(tokenId, indexOfFrom);
                    } else {
                        // all Transfer cases
                        uint256 indexOfFrom = _indexOf(indexedAccounts[tokenId], from);
                        indexedAccounts[tokenId][indexOfFrom] = to;
                    }
                }

                unchecked {
                    i++;
                }
            }
        }
    }

    /**
     *  Internal functions
     */
    function _indexOf(address[] memory arr, address addr)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == addr) {
                return i;
            }
        }
        revert("Index doesn't exist");
    }
    
    function _removeAccounts(uint256 id, uint256 index) internal {
        address[] storage accounts = indexedAccounts[id];
        if (index >= accounts.length) return;

        for (uint i = index; i<accounts.length-1; i++){
            accounts[i] = accounts[i+1];
        }
        accounts.pop();
    }
    
    /**
     * @notice query idx of account who owns token id
     * @param id: token id, addr: address
     * @return index of Account
     */
    function _accountByIndex(uint256 id, uint256 index)
        internal
        view
        returns (address)
    {
        EnumerableSet.AddressSet storage accounts = ERC1155EnumerableStorage
            .layout()
            .accountsByToken[id];

        // value => index
        require(accounts.length() > index, "Invalid index");
        return accounts.at(index);
    }

    /**
     * House keeping
     */
    function setBaseURI(string calldata _uri) external onlyRole(MINTER_ROLE) {
        ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage.layout();
        l.baseURI = _uri;
    }

    function setMaxToken(uint256 n) external onlyRole(AccessControlStorage.DEFAULT_ADMIN_ROLE) {
        MAX_TOKEN = n;
    }

}
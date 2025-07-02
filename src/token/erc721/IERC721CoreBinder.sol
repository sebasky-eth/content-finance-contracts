// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IBinder} from "../common/bindable/IBinder.sol";
import {IERC721Bindable} from "./IERC721Bindable.sol";
import {IBindableToken} from "../common/bindable/IBindableToken.sol";
import {IERC721Mirrorable} from "./IERC721Mirrorable.sol";

/**
 * @title Binder that has all tokens and control inter-collectional binding mechanism {see IBindableToken}.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @notice If last active binder of token is unbinded, IERC721CentralBinder will bind to it.
 */
interface IERC721CoreBinder is IBinder, IERC721Bindable {
    /**
     * @notice Returns all active binders for 'tokenId'.
     */
    function activeBinders(uint256 tokenId) external view returns (IBindableToken[] memory);

    /**
     * @notice Returns all binders for 'tokenId' that mirror transfers.
     * @dev Include activeBinders and binders that bind by mirror.
     */
    function mirroredBinders(uint256 tokenId) external view returns (IBindableToken[] memory);
}

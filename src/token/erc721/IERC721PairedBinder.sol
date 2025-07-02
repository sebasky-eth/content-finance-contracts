// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IERC721Bindable} from "./IERC721Bindable.sol";
import {IBinder} from "../common/bindable/IBinder.sol";
import {IBindableByIdentity} from "../common/bindable/IBindableByIdentity.sol";
import {IBindableGroup} from "../common/bindable/IBindableGroup.sol";

/**
 * @title Cross-collectional tokens that can exist in two collections max.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @notice Smaller collection. Many PairedBinders can connect with bigger one: {IERC721MultipairedBinder}
 */
interface IERC721PairedBinder is IERC721Bindable, IBinder, IBindableByIdentity, IBindableGroup {}

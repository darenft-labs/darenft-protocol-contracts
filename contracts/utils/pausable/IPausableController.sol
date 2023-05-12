

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

interface IPausableController {
  function pause() external;
  function unpause() external;
}
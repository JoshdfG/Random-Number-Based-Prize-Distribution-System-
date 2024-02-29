// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

error ZERO_ADDRESS_NOT_ALLOWED();
error YOU_HAVE_ALREADY_REGISTERED();
error AIRDROP_HAS_ENDED();
error YOU_HAVE_ALREADY_FOLLOWED();
error YOU_HAVE_ALREADY_LIKED();
error YOU_HAVE_ALREADY_MADE_A_POST();

contract AirdropDistribution {
    bool hasAirdropEnded;

    struct User {
        uint256 id;
        address userAddress;
        bool hasLiked;
        uint8 userPoints;
        bool hasPosted;
        bool hasFollowed;
        bool hasRegistered;
        bool entryPointReached;
    }

    mapping(address => User) public userData;

    uint[] winners;
    uint userID;

    uint8 constant followPoints = 10;
    uint8 constant likePoints = 10;
    uint8 constant sharedPostPoint = 30;

    function register() external {
        if (hasAirdropEnded) {
            revert AIRDROP_HAS_ENDED();
        }
        if (msg.sender == address(0)) {
            revert ZERO_ADDRESS_NOT_ALLOWED();
        }

        if (userData[msg.sender].hasRegistered == true) {
            revert YOU_HAVE_ALREADY_REGISTERED();
        }

        uint256 id = userID + 1;
        userData[msg.sender] = User(
            id,
            msg.sender,
            false,
            0,
            false,
            false,
            false,
            false
        );

        userID = id + userID;
    }

    function doesUserExists() private view {
        if (userData[msg.sender].hasRegistered == true) {
            revert YOU_HAVE_ALREADY_REGISTERED();
        }
    }

    function followUs() external {
        if (msg.sender == address(0)) {
            revert ZERO_ADDRESS_NOT_ALLOWED();
        }

        doesUserExists();

        if (userData[msg.sender].hasFollowed == true) {
            revert YOU_HAVE_ALREADY_FOLLOWED();
        }

        userData[msg.sender].hasFollowed = true;

        userData[msg.sender].userPoints =
            userData[msg.sender].userPoints +
            followPoints;

        checkAndUpdateEntryPoint();
    }

    function posted() external {
        if (msg.sender == address(0)) {
            revert ZERO_ADDRESS_NOT_ALLOWED();
        }

        doesUserExists();

        if (userData[msg.sender].hasPosted == true) {
            revert YOU_HAVE_ALREADY_MADE_A_POST();
        }

        userData[msg.sender].hasPosted = true;

        userData[msg.sender].userPoints =
            userData[msg.sender].userPoints +
            sharedPostPoint;

        checkAndUpdateEntryPoint();
    }

    function likedPinnedPosts() external {
        if (msg.sender == address(0)) {
            revert ZERO_ADDRESS_NOT_ALLOWED();
        }

        doesUserExists();

        if (userData[msg.sender].hasLiked = true) {
            revert YOU_HAVE_ALREADY_LIKED();
        }

        userData[msg.sender].hasLiked = true;

        userData[msg.sender].userPoints =
            userData[msg.sender].userPoints +
            likePoints;

        checkAndUpdateEntryPoint();
    }

    function checkAndUpdateEntryPoint() private {
        if (userData[msg.sender].entryPointReached == false) {
            if (userData[msg.sender].userPoints == 50) {
                userData[msg.sender].entryPointReached = true;

                winners.push(userData[msg.sender].id);
            }
        }
    }

    function distributeAirdrop() private {
        if (winners.length == 20) {
            hasAirdropEnded = true;
        }
    }
}

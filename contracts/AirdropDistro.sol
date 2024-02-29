// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

error ZERO_ADDRESS_NOT_ALLOWED();
error YOU_HAVE_ALREADY_REGISTERED();
error AIRDROP_HAS_ENDED();
error YOU_HAVE_ALREADY_FOLLOWED();
error YOU_HAVE_ALREADY_LIKED();
error YOU_HAVE_ALREADY_MADE_A_POST();

import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AirdropDistribution is VRFConsumerBaseV2 {
    IERC20 tokenA;
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 immutable keyHash;
    address public immutable linkToken;

    uint32 callbackGasLimit = 150000;

    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    uint256 public randomWordsNum;

    uint256[] participantsId;
    address[] participantsAddress;

    constructor(
        uint64 subscriptionId,
        address _linkToken,
        address _tokenA
    ) VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D) {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
        );
        s_subscriptionId = subscriptionId;

        keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15; // we alread set this
        linkToken = _linkToken;
        tokenA = IERC20(_tokenA);
    }

    //

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
        doesUserExists();
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

    function requestRandomWords() public returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId; // requestID is a uint.
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        randomWordsNum = _randomWords[0]; // Set array-index to variable
        emit RequestFulfilled(_requestId, _randomWords);
    }

    // to check the request status of random number call.
    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}

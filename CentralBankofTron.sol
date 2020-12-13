// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.9 <0.8.0;

/* @author Laxman Rai */

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract CentralBankofTron {
    using SafeMath for uint256;
    address payable owner;

    // variables
    struct User{
        uint256 dividend;
        uint256 compoundAsset;
        uint256 referralBonus;
        mapping (uint8 => address) referralLevel;
        uint256 totalInvested;
        uint256 totalReferralBonus;
        uint256 lastWithdrawedAt;
    }
    
    mapping (address => User) public users;
    
    uint256 investorCount;
    uint256 totalInvestment;
    uint256 totalReferralBonus;
    uint256 totalDividends;
    
    // events
    
    
    // modifiers
    modifier validateNullAddress(address _addressToValidate) {
        require(_addressToValidate != address(0x0), 'Address can not be null!');
        _;
    }
    
    
    // functions
    
    // invest without referral
    function investWithoutReferral() public payable{
        require(msg.value >= 50000000000000000000, 'Minimum investment is 50TRX');
        
        uint256 _roi = msg.value.mul(7).div(100);
        
        // this admin fee is also distributed to 15% where 5% to UD, 10% to Hash Group
        uint256 _adminFee = _roi.mul(10).div(100);
        
        // this 18% referarral is for hash tech where 8% is for Nirdesh dai and 10% for hash
        uint256 _nonReferralFee = _roi.mul(18).div(100);
        
        
        // setting the user data
        User storage user = users[msg.sender];
        
        user.dividend = _roi - _adminFee - _nonReferralFee;
        
        // convert the trx to cbt here- Note: only dividend is converted
        
        user.compoundAsset = user.dividend + msg.value;
        
        user.referralBonus = 0;
        
        // user.referralLevel(1) = hash address here
        user.referralLevel[1] = address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        
        user.totalInvested = user.compoundAsset;
        
        user.totalReferralBonus = 0;
        
        user.lastWithdrawedAt = 0;
    }
    
    //---------------------------------------------------------------------------------------------------------
    
    // invest with referral
    function investWithReferral(address _referralAddress) validateNullAddress(_referralAddress) public payable{
        require(msg.value >= 50000000000000000000, 'Minimum investment is 50TRX');
        
        uint256 _roi = msg.value.mul(7).div(100);
        
        // this admin fee is also distributed to 15% where 5% to UD, 10% to Hash Group
        uint256 _adminFee = _roi.mul(10).div(100);
        
        // this 18% referarral is distributed to referral people if there is empty referral level than remained bonus is transferred to hash
        uint256 _nonReferralFee = _roi.mul(18).div(100);

        // setting the user data
        User storage user = users[msg.sender];
        
        user.dividend = _roi - _adminFee - _nonReferralFee;
        
        // convert the trx to cbt here- Note: only dividend is converted
        
        user.compoundAsset = user.dividend + msg.value;
        
        user.referralBonus = 0;
        
        // here we need to make the algo to set the levels
        for(uint8 i = 1; i <= 3; i++){
            
        }
        
        user.totalInvested = user.compoundAsset;
        
        user.totalReferralBonus = 0;
        
        user.lastWithdrawedAt = 0;
    }
    
    //---------------------------------------------------------------------------------------------------------
    
    // reinvest
    // function reinvestment() private payable{}
    
    // withdraw
    // function wiwithdraw() pubico payable{}
    
    
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.9 <0.8.0;

/* @author Laxman Rai */

/* @dev SafeMath library to minimize the unsigned/mathematical/overflow errors */
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
}

contract CentralBankofTron {
    using SafeMath for uint256;
    
    /* @dev Public Addresses of Admins of Central Bank of Tron */
    address payable adminLevelOne = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address payable adminLevelTwo = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address payable adminLevelThree = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address payable adminLevelFour = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;

    /* @dev User Model/Struct to store specific data */
    struct User{
        uint256 dividend;
        uint256 compoundAsset;
        uint256 withdrawableAt;
    }
    
    mapping (address => User) public users;
    mapping (address => mapping(uint8 => address payable)) public referralLevel;
    mapping (address => uint256) public referralBonus;
    mapping (address => uint256) public adminFees;
    
    // events
    event investmentWithoutReferral(uint256 investedAmount, uint256 dividend, uint256 compoundAsset, address investedBy);
    event investmentWithReferral(address referralAddress, uint256 investedAmount, uint256 dividend, uint256 compoundAsset, address investedBy);
    event withdrawedDividend(uint256 withdrawedAmount, uint256 reinvestedAmount, uint256 compoundAsset, address withdwared);
    
    //---------------------------------------------------------------------------------------------------------
    // functions
    //---------------------------------------------------------------------------------------------------------
    
    /* @dev Function to Invest without referral */
    /* @dev 10% of ROI is deducted as admin fee */
    function _adminFee(uint256 _tempRoiWithoutDeduction) public payable {
        uint256 _totalAdminFeeToDeduct = _tempRoiWithoutDeduction.mul(10).div(100);
        
        /* @dev 15% of Admin Fee is deducted to low level admins */
        adminLevelTwo.transfer(_totalAdminFeeToDeduct.mul(5).div(100));
        adminLevelOne.transfer(_totalAdminFeeToDeduct.mul(10).div(100));
        
        /* @dev 85% of Admin Fee is deducted to high level admin */
        adminLevelFour.transfer(_totalAdminFeeToDeduct.mul(85).div(100));
    }
    
    /* @dev 18% of ROI is deducted as Referral Level fee */
    function _nonReferralFee(uint256 _tempRoiWithoutDeduction) public payable {
        adminLevelThree.transfer(_tempRoiWithoutDeduction.mul(8).div(100));
        adminLevelOne.transfer(_tempRoiWithoutDeduction.mul(10).div(100));
    }
    
    function investWithoutReferral() public payable{
        require(msg.value >= 50000000000000000000, 'Minimum investment is 50TRX'); //note: TRX is 8 decimals
    
        /* @dev ROI is 7% of Total Investment */
        uint256 _tempRoiWithoutDeduction = msg.value.mul(7).div(100);
        
        /* @dev admin fee is deducted as 10% of ROI */
        _adminFee(_tempRoiWithoutDeduction);

        /* @dev non referral fee is deducted as 18% of ROI */
        _nonReferralFee(_tempRoiWithoutDeduction);
        
        User storage user = users[msg.sender];
        
        /* @dev _tempAdminFee & _tempNonReferralFee has been used to set the dividend */
        uint256 _tempAdminFee = _tempRoiWithoutDeduction.mul(10).div(100);
        uint256 _tempNonReferralFee = _tempRoiWithoutDeduction.mul(18).div(100);
        
        /* @dev 72% of ROI without deduction is an dividend */
        uint256 _tempDividend = _tempRoiWithoutDeduction - _tempAdminFee - _tempNonReferralFee;
        
        user.dividend = _tempDividend;
        user.compoundAsset = user.dividend + msg.value;
        
        /* @dev User can only withdraw te ROI after 1 day of Investment */
        // user.withdrawableAt = block.timestamp.add(86400);
        
        referralLevel[msg.sender][1] = adminLevelOne;
        
        /* @dev staking the TRX */
        adminLevelFour.transfer(_tempDividend);
        adminLevelFour.transfer(msg.value.mul(93).div(100));
    }
    
    //---------------------------------------------------------------------------------------------------------
    
    function _referralFee(uint256 _tempRoiWithoutDeduction) public payable {
        /* @dev here 18% is deducted to different referral persons */
        if(referralLevel[msg.sender][3] != address(0x0)){
            referralBonus[adminLevelOne] = _tempRoiWithoutDeduction.mul(10).div(100);
            referralBonus[referralLevel[msg.sender][2]] = _tempRoiWithoutDeduction.mul(5).div(100);
            referralBonus[referralLevel[msg.sender][3]] = _tempRoiWithoutDeduction.mul(3).div(100);
        } else{
            if(referralLevel[msg.sender][2] != address(0x0)){
                referralBonus[adminLevelOne] += _tempRoiWithoutDeduction.mul(13).div(100);
                referralBonus[referralLevel[msg.sender][2]] = _tempRoiWithoutDeduction.mul(5).div(100);
            }else{
                referralBonus[adminLevelOne] += _tempRoiWithoutDeduction.mul(18).div(100);
            }
        }
        
    }
    
    function _setReferralLevel(address payable _referralAddress) private {
        /* @dev setting the referral level */
        if(referralLevel[_referralAddress][3] != address(0x0)){
            referralLevel[msg.sender][1] = adminLevelOne;
            referralLevel[msg.sender][2] = _referralAddress;
            referralLevel[msg.sender][3] = address(0x0);
        }
        else{
            if(referralLevel[_referralAddress][2] != address(0x0)){
                referralLevel[msg.sender][1] = adminLevelOne;
                referralLevel[msg.sender][2] = referralLevel[_referralAddress][2];
                referralLevel[msg.sender][3] = _referralAddress;
            }else{
                referralLevel[msg.sender][1] = adminLevelOne;
                referralLevel[msg.sender][2] = _referralAddress;
                referralLevel[msg.sender][3] = address(0x0);
            }
        }
    }
    
    modifier validateNullAddress(address _addressToValidate) {
        require(_addressToValidate != address(0x0), 'Address can not be null!');
        _;
    }
    
    /* @dev Function to Invest without referral */
    function investWithReferral(address payable _referralAddress) validateNullAddress(_referralAddress) public payable{
        require(msg.value >= 50000000000000000000, 'Minimum investment is 50TRX'); //note: TRX is 8 decimals
    
        /* @dev ROI is 7% of Total Investment */
        uint256 _tempRoiWithoutDeduction = msg.value.mul(7).div(100);
        
         /* @dev admin fee is deducted as 10% of ROI */
        _adminFee(_tempRoiWithoutDeduction);
        
        User storage user = users[msg.sender];
        
        /* @dev _tempAdminFee & _tempNonReferralFee has been used to set the dividend */
        uint256 _tempAdminFee = _tempRoiWithoutDeduction.mul(10).div(100);
        uint256 _tempReferralFee = _tempRoiWithoutDeduction.mul(18).div(100);
        
        uint256 _tempDividend = _tempRoiWithoutDeduction - _tempAdminFee - _tempReferralFee;
        
        /* @dev _tempDividend is converted to CBT then saved as CBT to dividend & compound asset */
        user.dividend = _tempDividend;
        user.compoundAsset = user.dividend + msg.value;
        
        /* @dev User can only withdraw te ROI after 1 day of Investment */
        user.withdrawableAt = block.timestamp.add(86400);
        
        _setReferralLevel(_referralAddress);
        
        /* @dev referral fee is deducted as 18% of ROI */
        _referralFee(_tempRoiWithoutDeduction);
        adminLevelFour.transfer(_tempReferralFee);
        
        /* @dev staking the TRX */
        adminLevelFour.transfer(_tempDividend);
        adminLevelFour.transfer(msg.value.mul(93).div(100));
    }
    
    //---------------------------------------------------------------------------------------------------------
    // function for reinvestment
    //---------------------------------------------------------------------------------------------------------
    function _reinvestment(uint256 _reinvestmentAmount, uint256 _prevDividend) private{
        uint256 _tempAdminFee = _reinvestmentAmount.mul(10).div(100);
        adminFees[adminLevelOne] += _tempAdminFee.mul(10).div(100);
        adminFees[adminLevelTwo] += _tempAdminFee.mul(5).div(100);
        adminFees[adminLevelFour] += _tempAdminFee.mul(85).div(100);
        
        _referralFee(_reinvestmentAmount);
        
        users[msg.sender].dividend = _reinvestmentAmount.mul(72).div(100);
        users[msg.sender].compoundAsset = users[msg.sender].compoundAsset.sub(_prevDividend).add(users[msg.sender].dividend);
        
        /* @dev User can only withdraw te ROI after 1 day of Investment */
        users[msg.sender].withdrawableAt = block.timestamp.add(21600);
    }
    
    function _convertToken(uint256 _trxAmount) public payable{
        // first convert and then transfer the trc20 token
        // msg.sender.transfer(_trxAmount);
    }
    
    modifier _withdrawDividend(){
        require(users[msg.sender].dividend > 0, 'User has no dividend left to withdraw!');
        require(users[msg.sender].withdrawableAt < block.timestamp, 'Dividend withdrawing request before time!');
        _;
    }
    
    function withdrawDividend() _withdrawDividend public payable{
        /* Only 30% is withdrawable */
        // _convertToken(users[msg.sender].dividend.mul(30).div(100));
        
        // 70% is reinvested
        _reinvestment(users[msg.sender].dividend.mul(70).div(100), users[msg.sender].dividend);
    }
}
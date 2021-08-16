// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.6;


import "./SafeMath.sol";
import "./Context.sol";     
import "./IERC20.sol";      // Need this to withdraw certain tokens
import "./SafeERC20.sol";   // withdraw airdropped token




/*

HOW TO USE THE AIRDROP SYSTEM

- Normal Airdrop

You can initialize a normal airdrop with this contract.

0. Set fees, taxes, transfer limits, etc. for the AirDrop contract address to be excluded - Do this in your currency contract.
1. Get the address of the Token you want to Airdrop
2. Get the list of Addresses as well as the Amounts they should be airdropped.
3. Set them in Array Form, using something like Google Sheets or Excel.
4. The amount should be multiplied by your decimal number. For example 9 decimals, multiply amounts by 10^9 to get the correct amount.
5. Use function InitializeTokenAirDropAddressesAndAmounts to initialize them.
6. Send the Token directly to the AirDrop Contract.
7. Enable the AirDrop using EnableAirdrop function.
8. Give instructions or create a dApp for your customers to use so that they can claim
9. The claim function is AirDropClaim, they will need to use the token address for the token.




Notes: 
- Reciepients can check their AirDrop they should get by calling BalanceOfAirdropTokenForUserAddress
- You can disable the AirDrop system at any time by using function DisableAirdrop
- The Contract must have enough tokens in the contract to airdrop, use CurrentAirdropTokenSupplyInContract to find the amount currently in the contract.
- Once an airdrop is claimed an event will happen to prove that they claimed their airdrop.








- Time System Airdrop

This time system will allow you to set airdrop "cycles". Meaning each Cycle someone can claim up to a max percentage of AirDrop.
For example if you an airdrop has 3 cycles. Then during the first cycle they can claim up to 33%, then 66%, then 100%(99%).
If someone misses the first two cycles they can just claim it later.

The cycles can have a time set between, the duration between cycles.
So if there are 3 cycles you can set them each 1 hour apart.

You can also set a start time if you want to have the airdrop activate at a later date.

To get started let's follow the steps.

0. Set fees, taxes, transfer limits, etc. for the AirDrop contract address to be excluded - Do this in your currency contract.
1. Get the address of the Token you want to Airdrop
2. Get the list of Addresses as well as the Amounts they should be airdropped.
3. Set them in Array Form, using something like Google Sheets or Excel.
4. The amount should be multiplied by your decimal number. For example 9 decimals, multiply amounts by 10^9 to get the correct amount.
5. Use function InitializeTokenAirDropAddressesAndAmountsTimerSystem to initialize them.
6. Send the Token directly to the AirDrop Contract.
7. Set the number of Cycles for your AirDrop using SetCyclesOfAirdropForTimeSystem
8. Set the Duration between the Cycles of the AirDrop by using SetDurationBetweenCycles (this is in seconds, use https://www.unixtimestamp.com/)
9. Set the AirDrop Start Time by using SetAirDropStartTime, this will be from where the cycles and durations are measured, so make sure the time is correct.
NOTE KEEP IN MIND THAT THE AIRDROP KICKS IN AFTER
AFTERRRRR 
THE CYCLE ELAPSES
SO AFTER 1 CYCLE HAS ELAPSED THEY CAN GET THEIR AIRDROP PARTIAL AMOUNT
10. Enable the AirDrop by using EnableAirdrop function.
11. Enable the AirDrop using EnableTimeSystemForAirdrop function.
NOTE - you do need to do both Enables in steps 10 and 11
12. Give instructions or create a dApp for your customers to use so that they can claim
13. The claim function is AirDropClaimTimerSystem, they will need to use the token address for the token.

Notes:
- You can disable the AirDrop system at any time by using function DisableAirdrop
- You can disable the AirDrop system at any time by using function DisableTimeSystemForAirdrop

- Reciepients can check their Total AirDrop Amount by calling TotalBalanceOfAirdropTokenForUserAddressTimeSystem
- Reciepients can check their Remaining Airdrop Amount by calling LeftBalanceOfAirdropTokenForUserAddressTimeSystem
- Reciepients can check their Claimed AirDrop Amount by calling ClaimedBalanceOfAirdropTokenForUserAddressTimeSystem
- Reciepients can check if they have fully claimed their airdrop by calling isFullyClaimedAirDrop

- Anyone can see their specific amount available to claim to them by calling AmountOfAirdropAvailableToClaim
- Anyone can see what percent of the AirDrop is currently available to claim by using the function PercentOfAirdropAvailableToClaim
- Anyone can see how long the AirDrop has been going by using function ElapsedAirDropTime
- Anyone can see how elapsed Cycles of the AirDrop by using function ElapsedCyclesOfAirdrop


- Anyone check the Number of Cycles for the Airdrop by using function cyclesOfAirdropForTimeSystem
- Anyone check the Duration between Cycles for the Airdrop by using function durationBetweenCyclesOfAirdrop
- Anyone check the Start Time for the Airdrop by using function startTimeOfAirdrop

- Check the time to next cycle by using TimeUntilNextAirdropCycle








- Token Managers

You can manage your own tokens to airdrop.
The manager must be initialized by the director.
After getting initalized the Manager can initialize AirDrops as well as withdraw tokens from the airdrop contract.
So if the manager makes a mistake, it's on him.

*/


contract AirDrop is Context {

    //////////////////////////// USING STATEMENTS ////////////////////////////
    using SafeMath for uint256;
    using SafeERC20 for IERC20; // this is for IERC20 tokens that you can store in the airdrop contract
    //////////////////////////// USING STATEMENTS ////////////////////////////










    //////////////////////////// AIRDROP CONTRACT INFO VARS ////////////////////////////
    uint256 public releaseDateUnixTimeStamp = block.timestamp;     // Version 2 Release Date
    //////////////////////////// AIRDROP CONTRACT INFO VARS ////////////////////////////


    //////////////////////////// DEAD ADDRESSES ////////////////////////////
    address public deadAddressZero = 0x0000000000000000000000000000000000000000; 
    address public deadAddressOne = 0x0000000000000000000000000000000000000001; 
    address public deadAddressdEaD = 0x000000000000000000000000000000000000dEaD; 
    //////////////////////////// DEAD ADDRESSES ////////////////////////////


    //////////////////////////// ACCESS CONTROL VARS ////////////////////////////
    address public directorAccount = 0x8C7Ad6F014B46549875deAD0f69919d643a50bA3;      // CHANGEIT - get the right director account

    // This will keep track of who is the manager of a token. 
    // Managers can initialize arrays and give people airdrops for a specific address
    mapping(address => address) public tokenAddressToManagerAddress;       
    //////////////////////////// ACCESS CONTROL VARS ////////////////////////////

    
    //////////////////////////// AIRDROP VARS ////////////////////////////  
    mapping(address => mapping(address => uint256)) public userAddressToTokenAddressToAmount;
    mapping(address => bool) public isAirdropEnabled;
    //////////////////////////// AIRDROP VARS ////////////////////////////  


    //////////////////////////// AIRDROP TIMER VARS ////////////////////////////
    mapping(address => mapping(address => uint256)) public userAddressToTokenAddressToTotalAmountTimerSystem;
    mapping(address => mapping(address => uint256)) public userAddressToTokenAddressToClaimedAmount;    // the amount of token the user has currently claimed
    mapping(address => mapping(address => uint256)) public userAddressToTokenAddressToLeftToClaim;    // the amount of token the user has currently claimed
    mapping(address => mapping(address => bool)) public userAddressToTokenAddressToIsFullyClaimed;    // has the user fully claimed his amount of Airdrop?

    mapping(address => bool) public isTimerSystemForAirdropEnabled;     // sets up the timer system
    mapping(address => uint256) public cyclesOfAirdropForTimeSystem;      // how many times should the airdrop happen.
    mapping(address => uint256) public durationBetweenCyclesOfAirdrop;     // how long between each period, in seconds
    mapping(address => uint256) public startTimeOfAirdrop;     // when does the airdrop start for each cycle calculation
    mapping(address => bool) public isClaiming;     // reentrancy guard
    //////////////////////////// AIRDROP TIMER VARS ////////////////////////////











    //////////////////////////// EVENTS ////////////////////////////
    event AirdropEnabled(address indexed tokenAddress, address indexed enablerAddress, uint256 currentBlockTime);
    event AirdropDisabled(address indexed tokenAddress, address indexed disablerAddress, uint256 currentBlockTime);

    event TimeSystemForAirdropEnabled(address indexed tokenAddress, address indexed enablerAddress, uint256 currentBlockTime);
    event TimeSystemForAirdropDisabled(address indexed tokenAddress, address indexed disablerAddress, uint256 currentBlockTime);

    event InitilizationOfAirdrops(address indexed tokenAddress, address indexed initializerAddress, uint256 currentBlockTime);
    event AirDropClaimed(address indexed tokenForAirdrop, address indexed claimer, uint256 indexed amountOfAirdropTokenToClaim, uint256 currentBlockTime);

    event InitilizationOfAirdropsTimerSystem(address indexed tokenAddress, address indexed initializerAddress, uint256 currentBlockTime);
    event AirDropClaimedTimerSystem(address indexed tokenForAirdrop, address indexed claimer, uint256 indexed amountOfAirdropTokenToClaim, uint256 currentBlockTime);

    event ETHwithdrawnRecovered(address indexed claimerWalletOwner, uint256 indexed ethClaimedRecovered, uint256 currentBlockTime);
    event ERC20tokenWithdrawnRecovered(address indexed tokenAddress, address indexed claimerWalletOwner, uint256 indexed balanceClaimedRecovered, uint256 currentBlockTime);

    event TransferedDirectorAccount(address indexed oldDirectorAccount, address indexed newDirectorAccount, uint256 currentBlockTime);
    event ManagerInitialized(address indexed tokenAddress, address indexed managerAddress, uint256 currentBlockTime);

    event CyclesSetForTimeSystemOfAirDrop(address indexed tokenForAirdrop, address indexed setterAddress, uint256 currentBlockTime, uint256 cyclesForAirdrop);
    event DurationSetForTimeSystemOfAirDrop(address indexed tokenForAirdrop, address indexed setterAddress, uint256 currentBlockTime, uint256 durationBetweenCycles);
    event StartTimeSetForTimeSystemOfAirDrop(address indexed tokenForAirdrop, address indexed setterAddress, uint256 currentBlockTime, uint256 startTime);
    //////////////////////////// EVENTS ////////////////////////////










    //////////////////////////// ACCESS CONTROL MODIFIERS ////////////////////////////
    modifier OnlyDirector() {
        require(directorAccount == _msgSender(), "Caller must be the Director");
        _;
    }

    modifier OnlyStaff(address tokenAddress) {
        address managerAddress = tokenAddressToManagerAddress[tokenAddress];
        require(managerAddress == _msgSender() || directorAccount == _msgSender(), "Caller must be Director or Manager");
        _;
    }
    //////////////////////////// ACCESS CONTROL MODIFIERS ////////////////////////////












    //////////////////////////// ACCESS CONTROL FUNCTIONS ////////////////////////////
    function TransferDirectorAccount(address newDirectorAccount) public virtual OnlyDirector() {
        address oldDirectorAccount = directorAccount;
        directorAccount = newDirectorAccount;
        emit TransferedDirectorAccount(oldDirectorAccount, newDirectorAccount, GetCurrentBlockTime());
    }

    function InitializeManagerForToken(address tokenAddress, address managerAddress) external OnlyDirector() { 
        tokenAddressToManagerAddress[tokenAddress] = managerAddress;
        emit ManagerInitialized(tokenAddress, managerAddress, GetCurrentBlockTime());
    }
    //////////////////////////// ACCESS CONTROL FUNCTIONS ////////////////////////////











    //////////////////////////// AIRDROP FUNCTIONS ////////////////////////////  
    function InitializeTokenAirDropAddressesAndAmounts(address tokenAddress, address[] memory addressesToAirDrop, uint256[] memory amountsToAirDrop) external OnlyStaff(tokenAddress) { 
        for(uint i = 0; i < addressesToAirDrop.length; i++){
            userAddressToTokenAddressToAmount[addressesToAirDrop[i]][tokenAddress] = amountsToAirDrop[i];
        }
        emit InitilizationOfAirdrops(tokenAddress, _msgSender(), GetCurrentBlockTime());
    }

    function CurrentAirdropTokenSupplyInContract(IERC20 tokenForAirdrop) public view returns (uint256) {
        return tokenForAirdrop.balanceOf(address(this));
    }

    function BalanceOfAirdropTokenForUserAddress(address account, address tokenForAirdrop) public view returns (uint256) {
        uint256 airdropBalance = userAddressToTokenAddressToAmount[account][tokenForAirdrop];
        return airdropBalance;  
    }

    function EnableAirdrop(address tokenForAirdrop) public OnlyStaff(tokenForAirdrop) {
        isAirdropEnabled[tokenForAirdrop] = true;
        emit AirdropEnabled(tokenForAirdrop, _msgSender(), GetCurrentBlockTime());
    }

    function DisableAirdrop(address tokenForAirdrop) public OnlyStaff(tokenForAirdrop) {
        isAirdropEnabled[tokenForAirdrop] = false;
        emit AirdropDisabled(tokenForAirdrop, _msgSender(), GetCurrentBlockTime());
    }

    function AirDropClaim(address tokenForAirdrop) public {    

        address claimer = _msgSender();

        require(!isClaiming[claimer], "Claim one at a time");
        isClaiming[claimer] = true;

        require(isAirdropEnabled[tokenForAirdrop], "AirDrop must be enabled. It is currently disabled. Contact the Director or the Manager of this Token.");  

        uint256 amountOfAirdropTokenToClaim = userAddressToTokenAddressToAmount[claimer][tokenForAirdrop];  // get it into a uint256 var for ease of use
        userAddressToTokenAddressToAmount[claimer][tokenForAirdrop] = 0;    // set to zero, more can be initialized later if needed

        // this address is not valid to claim so return it. Needs to have an amount over 0 to claim
        require(amountOfAirdropTokenToClaim > 0,"You have no airdrop to claim.");   
        
        // There needs to be enough token in the contract for the airdrop to be claimed 
        require(CurrentAirdropTokenSupplyInContract(IERC20(tokenForAirdrop)) >= amountOfAirdropTokenToClaim,"Not enough Airdrop Token in Contract");   

        IERC20(tokenForAirdrop).safeTransfer(PayableInputAddress(claimer), amountOfAirdropTokenToClaim );

        emit AirDropClaimed(tokenForAirdrop, claimer, amountOfAirdropTokenToClaim, GetCurrentBlockTime());

        isClaiming[claimer] = false;

    }
    //////////////////////////// AIRDROP FUNCTIONS ////////////////////////////  







    //////////////////////////// AIRDROP TIMER FUNCTIONS ////////////////////////////


    function InitializeTokenAirDropAddressesAndAmountsTimerSystem(address tokenAddress, address[] memory addressesToAirDrop, uint256[] memory amountsToAirDrop) external OnlyStaff(tokenAddress) { 
        for(uint i = 0; i < addressesToAirDrop.length; i++){
            userAddressToTokenAddressToTotalAmountTimerSystem[addressesToAirDrop[i]][tokenAddress] = amountsToAirDrop[i];
            if(userAddressToTokenAddressToClaimedAmount[addressesToAirDrop[i]][tokenAddress] != 0){
                userAddressToTokenAddressToClaimedAmount[addressesToAirDrop[i]][tokenAddress] = 0;      // resets claimed amount to 0
            }
            if(userAddressToTokenAddressToIsFullyClaimed[addressesToAirDrop[i]][tokenAddress] != false){
                userAddressToTokenAddressToIsFullyClaimed[addressesToAirDrop[i]][tokenAddress] = false; // resets total claim to false
            }
            userAddressToTokenAddressToLeftToClaim[addressesToAirDrop[i]][tokenAddress] = amountsToAirDrop[i];  // resets to total amount as none has been claimed
        }
        emit InitilizationOfAirdropsTimerSystem(tokenAddress, _msgSender(), GetCurrentBlockTime());
    }

    function TotalBalanceOfAirdropTokenForUserAddressTimeSystem(address account, address tokenForAirdrop) public view returns (uint256) {
        uint256 airdropBalance = userAddressToTokenAddressToTotalAmountTimerSystem[account][tokenForAirdrop];
        return airdropBalance;  
    }

    function LeftBalanceOfAirdropTokenForUserAddressTimeSystem(address account, address tokenForAirdrop) public view returns (uint256) {
        uint256 airdropLeftBalance = userAddressToTokenAddressToLeftToClaim[account][tokenForAirdrop];
        return airdropLeftBalance;  
    }

    function ClaimedBalanceOfAirdropTokenForUserAddressTimeSystem(address account, address tokenForAirdrop) public view returns (uint256) {
        uint256 airdropClaimedBalance = userAddressToTokenAddressToClaimedAmount[account][tokenForAirdrop];
        return airdropClaimedBalance;  
    }

    function isFullyClaimedAirDrop(address account, address tokenForAirdrop) public view returns (bool) {
        bool isFullyClaimed = userAddressToTokenAddressToIsFullyClaimed[account][tokenForAirdrop];
        return isFullyClaimed;  
    }

    function PercentOfAirdropAvailableToClaim(address tokenForAirdrop) public view returns (uint256) {

        uint256 cyclesOfAirdrop = cyclesOfAirdropForTimeSystem[tokenForAirdrop];
        uint256 durationBetweenCycles = durationBetweenCyclesOfAirdrop[tokenForAirdrop];
        uint256 elapsedAirdropTime = ElapsedAirDropTime(tokenForAirdrop);
        uint256 cyclesElapsed = elapsedAirdropTime.div(durationBetweenCycles);
        uint256 percentOfAirDropAvailable = cyclesElapsed.mul(100).div(cyclesOfAirdrop);

        return percentOfAirDropAvailable;
    }

    function AmountOfAirdropAvailableToClaim(address account, address tokenForAirdrop) public view returns (uint256) {
        uint256 cyclesOfAirdrop = cyclesOfAirdropForTimeSystem[tokenForAirdrop];
        uint256 durationBetweenCycles = durationBetweenCyclesOfAirdrop[tokenForAirdrop];
        uint256 elapsedAirdropTime = ElapsedAirDropTime(tokenForAirdrop);
        uint256 cyclesElapsed = elapsedAirdropTime.div(durationBetweenCycles);
        uint256 percentOfAirDropAvailable = cyclesElapsed.mul(100).div(cyclesOfAirdrop);

        uint256 claimedBalance = ClaimedBalanceOfAirdropTokenForUserAddressTimeSystem(account, tokenForAirdrop);

        uint256 totalBalance =  TotalBalanceOfAirdropTokenForUserAddressTimeSystem(account, tokenForAirdrop);
        uint256 amountOfAirdropAvailableToClaim = (totalBalance.mul(percentOfAirDropAvailable).div(100)).sub(claimedBalance);

        return amountOfAirdropAvailableToClaim;
    }


    function ElapsedAirDropTime(address tokenForAirdrop) public view returns (uint256) {
        uint256 startTime = startTimeOfAirdrop[tokenForAirdrop];
        uint256 elapsedAirdropTime = GetCurrentBlockTime().sub(startTime);
        return elapsedAirdropTime;
    }

    function ElapsedCyclesOfAirdrop(address tokenForAirdrop) public view returns (uint256) {
        uint256 durationBetweenCycles = durationBetweenCyclesOfAirdrop[tokenForAirdrop];
        uint256 elapsedAirdropTime = ElapsedAirDropTime(tokenForAirdrop);
        uint256 cyclesElapsed = elapsedAirdropTime.div(durationBetweenCycles);
        return cyclesElapsed;
    }


    function TimeUntilNextAirdropCycle(address tokenForAirdrop) public view returns (uint256) {
        uint256 durationBetweenCycles = durationBetweenCyclesOfAirdrop[tokenForAirdrop];
        uint256 elapsedAirdropTime = ElapsedAirDropTime(tokenForAirdrop);
        uint256 timeLeftToNextCycle = durationBetweenCycles.sub(elapsedAirdropTime);
        return timeLeftToNextCycle;
    }

    function EnableTimeSystemForAirdrop(address tokenForAirdrop) public OnlyStaff(tokenForAirdrop) {
        isTimerSystemForAirdropEnabled[tokenForAirdrop] = true;
        emit TimeSystemForAirdropEnabled(tokenForAirdrop, _msgSender(), GetCurrentBlockTime());
    }

    function DisableTimeSystemForAirdrop(address tokenForAirdrop) public OnlyStaff(tokenForAirdrop) {
        isTimerSystemForAirdropEnabled[tokenForAirdrop] = true;
        emit TimeSystemForAirdropDisabled(tokenForAirdrop, _msgSender(), GetCurrentBlockTime());
    }

    function SetCyclesOfAirdropForTimeSystem(address tokenForAirdrop, uint256 cyclesForAirdrop) public OnlyStaff(tokenForAirdrop) {
        require(cyclesForAirdrop <= 100, "Must be less than or equeal to 100 cycles.");
        cyclesOfAirdropForTimeSystem[tokenForAirdrop] = cyclesForAirdrop;
        emit CyclesSetForTimeSystemOfAirDrop(tokenForAirdrop, _msgSender(), GetCurrentBlockTime(), cyclesForAirdrop);
    }

    function SetDurationBetweenCycles(address tokenForAirdrop, uint256 durationBetweenCycles) public OnlyStaff(tokenForAirdrop) {
        durationBetweenCyclesOfAirdrop[tokenForAirdrop] = durationBetweenCycles;
        emit DurationSetForTimeSystemOfAirDrop(tokenForAirdrop, _msgSender(), GetCurrentBlockTime(), durationBetweenCycles);
    }

    function SetAirDropStartTime(address tokenForAirdrop, uint256 startTime) public OnlyStaff(tokenForAirdrop) {
        startTimeOfAirdrop[tokenForAirdrop] = startTime;
        emit StartTimeSetForTimeSystemOfAirDrop(tokenForAirdrop, _msgSender(), GetCurrentBlockTime(), startTime);
    }

    function AirDropClaimTimerSystem(address tokenForAirdrop) public {    

        address claimer = _msgSender();

        require(!isClaiming[claimer], "Claim one at a time");
        isClaiming[claimer] = true;

        require(isAirdropEnabled[tokenForAirdrop], "AirDrop must be enabled. It is currently disabled. Contact the Director or the Manager of this Token.");  
        require(isTimerSystemForAirdropEnabled[tokenForAirdrop],"Timer system must be enabled for this Token.");   

        uint256 cyclesOfAirdrop = cyclesOfAirdropForTimeSystem[tokenForAirdrop];
        require(cyclesOfAirdrop > 0, "Cycles must be set up for the Airdrop if the Timer System is Enabled. Contact the Director or the Manager of this Token.");

        uint256 durationBetweenCycles = durationBetweenCyclesOfAirdrop[tokenForAirdrop];
        require(durationBetweenCycles > 0, "Duration between Cycles must be set up for the Airdrop if the Timer System is Enabled. Contact the Director or the Manager of this Token.");

        uint256 startTime = startTimeOfAirdrop[tokenForAirdrop];
        require(startTime > 0, "Start Time must be set up for the Airdrop if the Timer System is Enabled. Contact the Director or the Manager of this Token.");

        uint256 amountOfAirdropTokenToClaimTotal = userAddressToTokenAddressToTotalAmountTimerSystem[claimer][tokenForAirdrop];  // get it into a uint256 var for ease of use
        require(amountOfAirdropTokenToClaimTotal > 0,"You have no airdrop to claim.");   

        require(!userAddressToTokenAddressToIsFullyClaimed[claimer][tokenForAirdrop], "You have fully claimed your AirDrop.");

        require(GetCurrentBlockTime() > startTime, "AirDrop has not started for this Token yet.");

        uint256 elapsedAirdropTime = ElapsedAirDropTime(tokenForAirdrop);

        uint256 cyclesElapsed = elapsedAirdropTime.div(durationBetweenCycles);

        uint256 amountOfAirDropToGive = amountOfAirdropTokenToClaimTotal.mul(cyclesElapsed).div(cyclesOfAirdrop);      // gets the amount by doing simple divison of cycles elapsed divided by the total cycles
        uint256 amountOfAirDropClaimedSoFar = userAddressToTokenAddressToClaimedAmount[claimer][tokenForAirdrop];
        userAddressToTokenAddressToClaimedAmount[claimer][tokenForAirdrop] = 0;     // setting to 0 for reentrancy
        
        amountOfAirDropToGive = amountOfAirDropToGive.sub(amountOfAirDropClaimedSoFar);
        require(amountOfAirDropToGive > 0, "You currently have no AirDrop left to claim.");

        // There needs to be enough token in the contract for the airdrop to be claimed 
        require(CurrentAirdropTokenSupplyInContract(IERC20(tokenForAirdrop)) >= amountOfAirDropToGive,"Not enough Airdrop Token in Contract");   

        userAddressToTokenAddressToClaimedAmount[claimer][tokenForAirdrop] = userAddressToTokenAddressToClaimedAmount[claimer][tokenForAirdrop].add(amountOfAirDropToGive).add(amountOfAirDropClaimedSoFar); 

        if(userAddressToTokenAddressToClaimedAmount[claimer][tokenForAirdrop] == amountOfAirdropTokenToClaimTotal){
             userAddressToTokenAddressToIsFullyClaimed[claimer][tokenForAirdrop] = true;    // has fully claimed
        }

        userAddressToTokenAddressToLeftToClaim[claimer][tokenForAirdrop] = amountOfAirdropTokenToClaimTotal.sub(userAddressToTokenAddressToClaimedAmount[claimer][tokenForAirdrop]);
 
        IERC20(tokenForAirdrop).safeTransfer(PayableInputAddress(claimer), amountOfAirDropToGive);

        emit AirDropClaimedTimerSystem(tokenForAirdrop, claimer, amountOfAirDropToGive, GetCurrentBlockTime());


        isClaiming[claimer] = false;
    }

    //////////////////////////// AIRDROP TIMER FUNCTIONS ////////////////////////////

 
    








    








    //////////////////////////// RESCUE FUNCTIONS ////////////////////////////
    function RescueAllETHSentToContractAddress() external OnlyDirector()  {   
        uint256 balanceOfContract = address(this).balance;
        PayableInputAddress(directorAccount).transfer(balanceOfContract);
        emit ETHwithdrawnRecovered(directorAccount, balanceOfContract, GetCurrentBlockTime());
    }

    function RescueAmountETHSentToContractAddress(uint256 amountToRescue) external OnlyDirector()  {   
        PayableInputAddress(directorAccount).transfer(amountToRescue);
        emit ETHwithdrawnRecovered(directorAccount, amountToRescue, GetCurrentBlockTime());
    }

    function RescueAllTokenSentToContractAddressAsDirector(IERC20 tokenToWithdraw) external OnlyDirector() {
        uint256 balanceOfContract = tokenToWithdraw.balanceOf(address(this));
        tokenToWithdraw.safeTransfer(PayableInputAddress(directorAccount), balanceOfContract);
        emit ERC20tokenWithdrawnRecovered(address(tokenToWithdraw), directorAccount, balanceOfContract, GetCurrentBlockTime());
    }

    function RescueAmountTokenSentToContractAddressAsDirector(IERC20 tokenToWithdraw, uint256 amountToRescue) external OnlyDirector() {
        tokenToWithdraw.safeTransfer(PayableInputAddress(directorAccount), amountToRescue);
        emit ERC20tokenWithdrawnRecovered(address(tokenToWithdraw), directorAccount, amountToRescue, GetCurrentBlockTime());
    }

    function RescueAllTokenSentToContractAddressAsManager(IERC20 tokenToWithdraw) external OnlyStaff(address(tokenToWithdraw)) {
        address tokenAddress = address(tokenToWithdraw);
        address managerOfToken = tokenAddressToManagerAddress[tokenAddress];
        uint256 balanceOfContract = tokenToWithdraw.balanceOf(address(this));
        tokenToWithdraw.safeTransfer(PayableInputAddress(directorAccount), balanceOfContract);
        emit ERC20tokenWithdrawnRecovered(address(tokenToWithdraw), managerOfToken, balanceOfContract, GetCurrentBlockTime());
    }

    function RescueAmountTokenSentToContractAddressAsManager(IERC20 tokenToWithdraw, uint256 amountToRescue) external OnlyStaff(address(tokenToWithdraw)) {
        address tokenAddress = address(tokenToWithdraw);
        address managerOfToken = tokenAddressToManagerAddress[tokenAddress];
        tokenToWithdraw.safeTransfer(PayableInputAddress(directorAccount), amountToRescue);
        emit ERC20tokenWithdrawnRecovered(address(tokenToWithdraw), managerOfToken, amountToRescue, GetCurrentBlockTime());
    }
    //////////////////////////// RESCUE FUNCTIONS ////////////////////////////








    //////////////////////////// MISC INFO FUNCTIONS ////////////////////////////  
    function PayableInputAddress(address inputAddress) internal pure returns (address payable) {   // gets the sender of the payable address
        address payable payableInAddress = payable(address(inputAddress));
        return payableInAddress;
    }

    function GetCurrentBlockTime() public view returns (uint256) {
        return block.timestamp;     // gets the current time and date in Unix timestamp
    }

    function GetCurrentBlockDifficulty() public view returns (uint256) {
        return block.difficulty;  
    }

    function GetCurrentBlockNumber() public view returns (uint256) {
        return block.number;      
    }

    function GetCurrentBlockStats() public view returns (uint256,uint256,uint256) {
        return (block.number, block.difficulty, block.timestamp);      
    }
    //////////////////////////// MISC INFO FUNCTIONS ////////////////////////////  









    receive() external payable { }      // oh it's payable alright
}


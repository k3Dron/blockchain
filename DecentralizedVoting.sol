// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DecentralizedLoan {
    struct Loan {
        address borrower;
        address provider;
        uint256 amount;
        uint256 validity;
        uint256 collateral;
        uint256 repaymentAmount;
        bool repaid;
    }
    
    uint256 public loanIdCounter;

    mapping(uint256 => Loan) public loans;
    mapping(address => mapping(uint256 => uint256)) public balances;
    mapping(address => mapping(uint256 => uint256)) public collaterals;

    function getLoanAmount(uint256 _loanId) public view returns (uint256) {
        require(_loanId < loanIdCounter, "Loan does not exist");
        return loans[_loanId].amount;
    }

    function getCollateral(uint256 _loanId) public view returns (uint256) {
        require(_loanId < loanIdCounter, "Loan does not exist");
        return loans[_loanId].collateral;
    }

    function isLoanRepaid(uint256 _loanId) public view returns (bool) {
        require(_loanId < loanIdCounter, "Loan does not exist");
        return loans[_loanId].repaid;
    }

    event LoanRequested(uint256 loanId, address borrower ,uint256 amount, uint256 collateral, uint256 repaymentAmount);
    event LoanRepaid(uint256 loanId, address borrower, uint256 repaymentAmount);
    event CollateralWithdrawn(address borrower, uint256 amount);

    // function requestLoan(uint256 _amount, uint256 _interestRate, uint256 _time) public payable {
    //     require(msg.value > 0, "Collateral needed");
    //     uint256 collateral = msg.value;
    //     uint256 repaymentAmount = _amount + (_amount * _interestRate) / 100;
    //     loans[loanIdCounter].borrower = msg.sender;
    //     loans[loanIdCounter].amount = _amount;
    //     loans[loanIdCounter].validity = block.timestamp + _time*24*60*60;
    //     loans[loanIdCounter].collateral = msg.value;
    //     loans[loanIdCounter].repaymentAmount = repaymentAmount;
    //     loans[loanIdCounter].repaid = false;

    //     emit LoanRequested(loanIdCounter, msg.sender, _amount, collateral, repaymentAmount);
    //     loanIdCounter++;
    // }

    function requestLoan(uint256 _amount, uint256 _interestRate) public payable {
        require(msg.value > 0, "Collateral needed");
        uint256 collateral = msg.value;
        uint256 repaymentAmount = _amount + (_amount * _interestRate) / 100;
        loans[loanIdCounter].borrower = msg.sender;
        loans[loanIdCounter].amount = _amount;
        loans[loanIdCounter].collateral = msg.value;
        loans[loanIdCounter].repaymentAmount = repaymentAmount;
        loans[loanIdCounter].repaid = false;

        emit LoanRequested(loanIdCounter, msg.sender, _amount, collateral, repaymentAmount);
        loanIdCounter++;
    }

    function provideLoan(uint _loanId) public payable {
        Loan storage loan = loans[_loanId];
        require(loan.borrower != address(0), "Loan does not exist.");
        require(!loan.repaid, "Loan is already repaid.");
        require(msg.value == loan.amount, "Incorrect loan amount provided.");
        loans[_loanId].provider = msg.sender;
        collaterals[loan.provider][_loanId] += loan.collateral;
        payable(loan.borrower).transfer(loan.amount);
    }

    function repayLoan(uint256 _loanId) public payable {
        Loan storage loan = loans[_loanId];
        require(loan.borrower == msg.sender, "Only the borrower can repay the loan.");
        //require(block.timestamp <= loan.validity, "Validity of loan has already expired");
        require(!loan.repaid, "Loan has already been repayed.");
        require(msg.value == loan.repaymentAmount, "Incorrect repayment amount.");
        payable(loan.provider).transfer(loan.repaymentAmount);
        loan.repaid = true;
        collaterals[loan.provider][_loanId] -= loan.collateral;
        balances[msg.sender][_loanId] += loan.collateral;
        emit LoanRepaid(_loanId, msg.sender, msg.value);
    }

    function withdrawCollateral(uint256 _loanId) public {
        require(loans[_loanId].repaid, "Loan must be repaid to withdraw collateral");
        uint256 amount = balances[msg.sender][_loanId];
        require(amount > 0, "No collateral to withdraw");
        balances[msg.sender][_loanId] = 0;
        payable(msg.sender).transfer(amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }

    function claimCollateral(uint256 _loanId) public {
        //require(block.timestamp > loans[_loanId].validity, "Validity of loan has still not expired");
        require(!loans[_loanId].repaid, "Loan must be repaid to withdraw collateral");
        uint256 amount = collaterals[msg.sender][_loanId];
        require(amount > 0, "No collateral to Claim");
        collaterals[msg.sender][_loanId] = 0;
        payable(msg.sender).transfer(amount);
        emit CollateralWithdrawn(msg.sender, amount);
    }

}
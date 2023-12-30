// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Employer.sol";

contract Dfreelancer is Employers { 
bool private reentrancyGuard;

modifier nonReentrant() {
    require(!reentrancyGuard, "Reentrant call detected");
    reentrancyGuard = true;
    _;
    reentrancyGuard = false;
}


     /// @notice retrieves freelancer by address
    /// @param _freelancer, address
    /// @return props
    function getFreelancerByAddress(address _freelancer) external view returns(Freelancer memory props){
        props = freelancers[_freelancer];
    }

    /// @notice process freelancer registration
    /// @param _name , @param _skills
    function registerFreelancer
    (string memory _name, string memory _skills, string memory _country,
    string memory _gigTitle, string memory _gigDesc, string[] memory _images, uint256 _starting_price) public {
        require(freelancers[msg.sender].registered == false, 'AR'); // already registered
        require(bytes(_name).length > 0);
        require(bytes(_skills).length > 0);
        totalFreelancers++;
        freelancers[msg.sender] = Freelancer(msg.sender, _name, _skills, 0,_country, 
        _gigTitle,_gigDesc,_images,0,true,block.timestamp,_starting_price);
        
         // Add the freelancer address to the array
        allFreelancerAddresses.push(msg.sender);

        emit FreelancerRegistered(msg.sender, _images, _starting_price);
        
    }

         /// @notice return all freelancers
    function getAllFreelancers() public view returns (Freelancer[] memory) {
        Freelancer[] memory allFreelancers = new Freelancer[](totalFreelancers);

        for (uint256 i = 0; i < totalFreelancers; i++) {
            allFreelancers[i] = freelancers[allFreelancerAddresses[i]];
        }

        return allFreelancers;
    }

    
        /// @notice process employer funds deposit for a specific job
        /// @param jobId , job id
    /**
 * @notice Process employer funds deposit for a specific job.
 * @param jobId Job ID.
 */
function depositFunds(uint jobId) public payable nonReentrant {
    require(jobId <= totalJobs && jobId > 0, "Invalid job ID");
    Job storage job = jobs[jobId];
    require(job.employer == msg.sender, "Not the job owner");
    require(!job.completed, "Job already completed");
    require(msg.value > 0, "Invalid deposit amount"); // Ensure a positive deposit

    // Update employer balance and escrow funds
    employers[msg.sender].balance += msg.value;
    escrowFunds[msg.sender][jobId] += msg.value;

    emit FundsDeposited(jobId, msg.sender, msg.value);
}


        /// @notice release escrow fund after successful completion of the job
        /// @param jobId , @param freelancerAddress
    function releaseEscrow(uint jobId, address freelancerAddress) public onlyEmployer(msg.sender){
        require(jobId <= totalJobs && jobId > 0, "JDE."); // job does not exist
        Job storage job = jobs[jobId];
        require(msg.sender == job.employer);
        require(job.completed = true, "JNC"); // Job is not completed by freelancer

        uint escrowAmount = escrowFunds[msg.sender][jobId];

        require(escrowAmount > 0, "NFE"); // No funds in escrow
        require(escrowAmount >= job.budget, "IF"); // insufficient funds
        escrowFunds[msg.sender][jobId] = 0;        
        // Implement logic to release funds from escrow to the freelancer's address
        Freelancer storage freelancer = freelancers[freelancerAddress];
        freelancer.balance += escrowAmount;
        // update employer balance
         Employer storage employer = employers[msg.sender];
         employer.balance -= escrowAmount;
         
        emit FundsReleased(jobId, freelancerAddress, escrowAmount);
    }

    /**
 * @notice Gets all jobs the freelancer has applied for.
 * @return appliedJobs Array of jobs applied by the freelancer.
 */
function getFreelancerApplications() public view returns (Job[] memory appliedJobs) {
    Freelancer storage freelancer = freelancers[msg.sender];
    appliedJobs = new Job[](freelancer.jobsCompleted);
    uint index = 0;

    for (uint i = 0; i < totalJobs; i++) {
        if (isFreelancerApplied(jobs[i + 1], msg.sender)) {
            appliedJobs[index] = jobs[i + 1];
            index++;
        }
    }

    return appliedJobs;
}

/**
 * @notice Gets all completed jobs by the freelancer.
 * @return completedJobs Array of completed jobs by the freelancer.
 */
function getFreelancerCompletedJobs() public view returns (Job[] memory completedJobs) {
    Freelancer storage freelancer = freelancers[msg.sender];
    completedJobs = new Job[](freelancer.jobsCompleted);
    uint index = 0;

    for (uint i = 0; i < totalJobs; i++) {
        if (jobCompletedByFreelancer(jobs[i + 1], msg.sender)) {
            completedJobs[index] = jobs[i + 1];
            index++;
        }
    }

    return completedJobs;
}



    /// @notice process funds withdrawal to the freelancer after successful completion of a job
    function withdrawEarnings() public onlyFreelancer(msg.sender) nonReentrant {
    Freelancer storage freelancer = freelancers[msg.sender];
    require(freelancer.balance > 0, "No balance to withdraw");

    uint withdrawAmount = (freelancer.balance * 95) / 100; // 95% of balance
    freelancer.balance = 0;

    (bool success, ) = msg.sender.call{value: withdrawAmount}("");
    require(success, "Transfer failed");

    emit WithdrawFund(msg.sender, withdrawAmount);
}

}

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

    function editFreelancerProfile(
        string memory _newSkills,
        string memory _newGigTitle,
        string memory _newGigDesc,
        string[] memory _newImages
    ) public onlyFreelancer(msg.sender) {
        Freelancer storage freelancer = freelancers[msg.sender];
        freelancer.skills = _newSkills;
        freelancer.gigTitle = _newGigTitle;
        freelancer.gigDescription = _newGigDesc;
        freelancer.images = _newImages;
    }

    function getFreelancerApplications() public view returns (Job[] memory) {
        Freelancer storage freelancer = freelancers[msg.sender];
        Job[] memory appliedJobs = new Job[](freelancer.jobsCompleted);
        uint index = 0;

        for (uint i = 0; i < totalJobs; i++) {
            if (isFreelancerApplied(jobs[i + 1], msg.sender)) {
                appliedJobs[index] = jobs[i + 1];
                index++;
            }
        }

        return appliedJobs;
    }

    function isFreelancerApplied(Job storage job, address freelancerAddress) internal view returns (bool) {
        for (uint i = 0; i < job.applicants.length; i++) {
            if (job.applicants[i] == freelancerAddress) {
                return true;
            }
        }
        return false;
    }

    function getFreelancerCompletedJobs() public view returns (Job[] memory) {
        Freelancer storage freelancer = freelancers[msg.sender];
        Job[] memory completedJobs = new Job[](freelancer.jobsCompleted);
        uint index = 0;

        for (uint i = 0; i < totalJobs; i++) {
            if (jobCompletedByFreelancer(jobs[i + 1], msg.sender)) {
                completedJobs[index] = jobs[i + 1];
                index++;
            }
        }

        return completedJobs;
    }

    function jobCompletedByFreelancer(Job storage job, address freelancerAddress) internal view returns (bool) {
        return job.completed && job.hiredFreelancer == freelancerAddress;
    }

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

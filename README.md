# FitQuest Smart Contract  

## Overview  
**FitQuest** is a blockchain-powered fitness challenge smart contract that allows users to join challenges, track progress, and earn rewards for meeting fitness goals. It ensures transparency, fairness, and secure reward distribution through Clarity smart contracts.

## Features  
- **Create Fitness Challenges:** Users can define goals, duration, and invite participants.  
- **Join Challenges:** Participants can enroll in active challenges.  
- **Submit Progress:** Users log their achievements (e.g., steps, calories burned).  
- **Claim Rewards:** Users meeting challenge goals receive token rewards.  
- **Immutable and Transparent:** Challenge records and progress tracking are secure and tamper-proof.  

## Contract Functions  

### 1. `create-challenge (goal uint, start-time uint, end-time uint) → (response uint err)`  
Creates a new fitness challenge with a specified goal and timeframe.  
- **Goal:** The target progress value (e.g., steps).  
- **Start-time / End-time:** Defines challenge duration.  
- **Returns:** Challenge ID.  

### 2. `join-challenge (challenge-id uint) → (response bool err)`  
Allows users to participate in an active challenge.  
- **Validation:** Ensures the challenge is ongoing and the user has not already joined.  

### 3. `submit-progress (challenge-id uint, progress uint) → (response bool err)`  
Logs the participant’s fitness progress towards the challenge goal.  
- **Validation:** Ensures user is part of the challenge and the timeframe is valid.  

### 4. `claim-reward (challenge-id uint) → (response bool err)`  
Distributes rewards to users who have met the challenge goal.  
- **Validation:** Ensures the challenge has ended and the participant has reached the goal.  
- **Transfers tokens** from the reward contract to the participant.  

## Error Codes  
- **ERR_NOT_STARTED (u1):** Challenge has not started.  
- **ERR_ENDED (u2):** Challenge has ended.  
- **ERR_ALREADY_JOINED (u3):** User has already joined the challenge.  
- **ERR_NOT_PARTICIPANT (u4):** User is not a participant.  
- **ERR_GOAL_NOT_MET (u5):** User has not reached the goal.  

## How It Works  
1. A user creates a **challenge** with a goal (e.g., 10,000 steps in 7 days).  
2. Participants **join** before the challenge starts.  
3. Participants **submit progress** throughout the challenge duration.  
4. After the challenge ends, eligible participants **claim rewards** in tokens.  

## Deployment & Usage  
- Ensure the **reward token contract** address is correctly set.  
- Deploy the contract on the **Stacks blockchain**.  
- Interact via a Clarity-supported wallet or front-end UI.  

## Future Enhancements  
- **NFT Badges** for achievements.  
- **Leaderboard system** for top performers.  
- **Customizable rewards** per challenge.  

### License  
FitQuest is an open-source smart contract licensed under the **MIT License**.
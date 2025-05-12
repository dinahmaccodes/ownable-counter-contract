# Ownable Counter Contract

## Overview
This project implements a set of interconnected smart contracts on StarkNet to manage ownership, counters, and a kill switch mechanism. The contracts are modular and interact with each other to provide functionality such as counting, ownership management, and a safety mechanism to disable operations.

## Contracts

### 1. **Aggregator**
The `Aggregator` contract acts as the central hub, coordinating interactions between the `Counter`, `KillSwitch`, and `Ownable` contracts. Key features include:
- **Increase Count**: Increases the internal count while ensuring only the owner can perform this action.
- **Increase Counter Count**: Interacts with the `Counter` contract to increase its count, ensuring the kill switch is active.
- **Activate Switch**: Activates the kill switch by interacting with the `KillSwitch` contract.
- **Ownership Enforcement**: Ensures only the owner can perform sensitive operations.

### 2. **Counter**
The `Counter` contract manages a simple count. Key features include:
- **Increase Count**: Increases the count by a specified amount.
- **Decrease Count by One**: Decreases the count by one, ensuring it does not go below zero.
- **Get Count**: Retrieves the current count.

### 3. **KillSwitch**
The `KillSwitch` contract provides a safety mechanism to enable or disable operations. Key features include:
- **Switch**: Toggles the kill switch status.
- **Get Status**: Retrieves the current status of the kill switch.

### 4. **Ownable**
The `Ownable` contract manages ownership of the system. Key features include:
- **Set Owner**: Updates the owner of the contract.
- **Get Owner**: Retrieves the current owner.
- **Ownership Enforcement**: Ensures only the owner can perform sensitive operations.

## Tests

The project includes comprehensive tests to ensure the functionality of each contract. All tests are passing, verifying the correctness of the implementation.

### Test Highlights
- **Aggregator Tests**:
  - Verify count increase and decrease operations.
  - Ensure only the owner can activate the kill switch or modify counts.
  - Validate event emissions for operations like count increase and kill switch activation.

- **Counter Tests**:
  - Validate initial count.
  - Test count increase and decrease operations.
  - Ensure zero-value operations are handled correctly.

- **KillSwitch Tests**:
  - Verify the toggle functionality of the kill switch.
  - Ensure the status is correctly retrieved.

- **Ownable Tests**:
  - Validate ownership transfer.
  - Ensure only the owner can perform restricted actions.
  - Test edge cases like setting the owner to a zero address.

## Deployment
The `deploy_contract` function in the test library deploys all the contracts and sets up their interactions. It ensures:
- The `Counter`, `KillSwitch`, and `Ownable` contracts are deployed first.
- The `Aggregator` contract is deployed with references to the other contracts.

## How to Run Tests
To run the tests, use the following command:
```sh
snforge test
```
OR 

```bash
scarb test 
```

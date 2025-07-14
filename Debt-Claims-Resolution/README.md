# Decentralized Debt Resolution Protocol

A comprehensive blockchain-based smart contract for facilitating transparent debt resolution and multi-party financial settlements on the Stacks network.

## Overview

This protocol enables secure, transparent, and automated debt management through blockchain technology, providing a decentralized alternative to traditional debt resolution processes.

## Key Features

- **Transparent Debt Management**: Register and track debt claims with immutable blockchain records
- **Automated Interest Calculation**: Built-in compound interest calculation with configurable rates
- **Multi-Party Settlement**: Batch processing for complex debt resolution scenarios (2, 3, or 5-party settlements)
- **Dispute Resolution System**: Decentralized arbitration with authorized arbitrators
- **Consent-Based Settlements**: Creditor approval workflow for debt consolidation
- **Comprehensive Analytics**: Query interface for debt tracking and protocol metrics
- **Audit Trail**: Immutable record of all financial settlement transactions

## Architecture

### Core Components

1. **Participant Registry**: Registration system for creditors and debtors
2. **Debt Claims Management**: Creation and tracking of individual debt claims
3. **Interest Calculation Engine**: Automated interest accrual based on configurable rates
4. **Settlement Processing**: Individual and batch settlement execution
5. **Dispute Resolution**: Multi-party arbitration system
6. **Governance**: Protocol administration and arbitrator management

### Data Structures

- **Debt Claims**: Individual debt records with interest tracking
- **Participant Registry**: Creditor and debtor registration
- **Settlement Consent Matrix**: Approval tracking for settlements
- **Dispute Records**: Comprehensive dispute management
- **Arbitrator Pool**: Authorized arbitrator management

## Getting Started

### Prerequisites

- Stacks blockchain environment
- STX tokens for transaction fees
- Clarity smart contract deployment tools

### Deployment

1. Deploy the smart contract to the Stacks network
2. Initialize the protocol using `initialize-debt-resolution-protocol`
3. Set up authorized arbitrators using `add-arbitrator`

## Usage Guide

### For Creditors

#### 1. Register as a Creditor
```clarity
(register-new-creditor)
```

#### 2. Create a Debt Claim
```clarity
(register-debt-claim-with-interest debtor-address amount interest-rate)
```

#### 3. Grant Settlement Consent
```clarity
(grant-settlement-consent debtor-address)
```

#### 4. File a Dispute (if needed)
```clarity
(file-dispute defendant-address dispute-type amount claim-id)
```

### For Debtors

#### 1. Register as a Debtor
```clarity
(register-new-debtor)
```

#### 2. Execute Individual Settlement
```clarity
(execute-individual-settlement creditor-address settlement-amount)
```

#### 3. Execute Batch Settlement
```clarity
;; For 2 creditors
(execute-two-party-batch-settlement 
  creditor1 amount1 
  creditor2 amount2)

;; For 3 creditors
(execute-three-party-batch-settlement 
  creditor1 amount1 
  creditor2 amount2 
  creditor3 amount3)

;; For 5 creditors
(execute-five-party-batch-settlement 
  creditor1 amount1 
  creditor2 amount2 
  creditor3 amount3 
  creditor4 amount4 
  creditor5 amount5)
```

### For Administrators

#### 1. Add Arbitrator
```clarity
(add-arbitrator arbitrator-address)
```

#### 2. Assign Arbitrator to Dispute
```clarity
(assign-arbitrator dispute-id arbitrator-address)
```

### For Arbitrators

#### 1. Resolve Dispute
```clarity
(resolve-dispute dispute-id resolution-details award-amount)
```

## Interest Calculation

The protocol uses a sophisticated interest calculation system:

- **Default Rate**: 5% annual (500 basis points)
- **Maximum Rate**: 20% annual (2000 basis points)
- **Calculation**: Based on Stacks block height with ~10 minute blocks
- **Compounding**: Interest is calculated and can be updated periodically

### Update Interest
```clarity
(update-debt-interest debtor-address creditor-address claim-id)
```

## Query Functions

### Check Balances and Claims
```clarity
(get-creditor-outstanding-claims creditor-address)
(get-debtor-total-obligations debtor-address)
(get-debt-claim-details debtor-address creditor-address claim-id)
```

### Settlement Information
```clarity
(check-settlement-consent-status debtor-address creditor-address)
(get-total-protocol-settlement-volume)
```

### Dispute and Arbitration
```clarity
(get-dispute-details dispute-id)
(get-arbitrator-info arbitrator-address)
(get-active-disputes-count)
```

### Calculate Total Debt
```clarity
(calculate-total-debt-with-interest debtor-address creditor-address claim-id)
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR-UNAUTHORIZED-ACCESS | Unauthorized access attempt |
| u101 | ERR-INSUFFICIENT-BALANCE | Insufficient balance for operation |
| u102 | ERR-DEBT-RECORD-NOT-FOUND | Debt record not found |
| u103 | ERR-SETTLEMENT-ALREADY-APPROVED | Settlement already approved |
| u104 | ERR-CREDITOR-NOT-REGISTERED | Creditor not registered |
| u105 | ERR-PARAMETER-MISMATCH | Parameter mismatch |
| u106 | ERR-APPROVAL-REQUIRED | Approval required for operation |
| u107 | ERR-INVALID-AMOUNT | Invalid amount specified |
| u108 | ERR-SETTLEMENT-FAILED | Settlement execution failed |
| u109 | ERR-INVALID-PRINCIPAL-ADDRESS | Invalid principal address |
| u110 | ERR-DEBTOR-NOT-REGISTERED | Debtor not registered |
| u111 | ERR-DISPUTE-NOT-FOUND | Dispute not found |
| u112 | ERR-DISPUTE-ALREADY-RESOLVED | Dispute already resolved |
| u113 | ERR-INVALID-DISPUTE-STATUS | Invalid dispute status |
| u114 | ERR-ARBITRATOR-NOT-AUTHORIZED | Arbitrator not authorized |
| u115 | ERR-INTEREST-CALCULATION-FAILED | Interest calculation failed |
| u116 | ERR-INVALID-INTEREST-RATE | Invalid interest rate |
| u117 | ERR-DEBT-CLAIM-NOT-FOUND | Debt claim not found |

## Security Features

### Access Control
- Protocol administrator controls
- Authorized arbitrator system
- Participant registration requirements

### Financial Safety
- Overflow protection in calculations
- Balance validation before settlements
- Consent-based settlement approval

### Dispute Resolution
- Multi-party arbitration system
- Reputation-based arbitrator scoring
- Transparent dispute tracking

## Governance

### Protocol Administration
- Single protocol administrator (initially deployer)
- Arbitrator pool management
- System parameter configuration

### Arbitrator Management
- Active/inactive status tracking
- Performance metrics and reputation scoring
- Case resolution tracking

## Best Practices

### For Creditors
1. Always register before creating claims
2. Set appropriate interest rates (≤20% annual)
3. Grant settlement consent for legitimate debtors
4. Monitor debt claims regularly

### For Debtors
1. Register before engaging in settlements
2. Ensure sufficient balance before settlement attempts
3. Use batch settlements for efficiency
4. Keep track of total obligations

### For Arbitrators
1. Maintain high reputation scores
2. Provide detailed resolution explanations
3. Process disputes in a timely manner
4. Follow protocol guidelines

## Limitations

- Maximum 10 arbitrators in the pool
- Interest rates capped at 20% annual
- Batch settlements limited to 2, 3, or 5 parties
- Single protocol administrator model
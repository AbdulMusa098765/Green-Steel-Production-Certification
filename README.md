A blockchain-based certification system for sustainable steel production with IoT integration and supply chain traceability.

## 🎯 Features

- 🏭 **Producer Registration & Verification**: Register steel producers and verify their sustainability credentials
- 🔋 **Energy Source Tracking**: Monitor and verify renewable energy sources used in production
- 📊 **IoT Sensor Integration**: Real-time monitoring of production processes through IoT sensors
- 📜 **Certificate Issuance**: Generate blockchain certificates for green steel batches
- 🔗 **Supply Chain Traceability**: Track steel from production to end consumer
- 💰 **Premium Tokens**: Reward green steel buyers with tokenized premiums
- ✅ **Verification System**: Multi-layer verification for producers, certificates, and supply chain steps
- 🚫 **Certificate Revocation**: Admin ability to revoke invalid certificates for enhanced integrity
- 🛡️ **Dispute Resolution**: Allow certificate owners to file disputes and admins to resolve them for enhanced trust
- 🔒 **Producer Staking System**: Enable producers to stake STX for reputation boosts and enhanced trust signals

## 🚀 Quick Start

### Register as a Producer
```clarity
(contract-call? .green-steel-certification register-producer "EcoSteel Corp" "Pittsburgh, PA")
```

### Register Energy Source (Admin only)
```clarity
(contract-call? .green-steel-certification register-energy-source "SOLAR001" "Solar" u25)
```

### Issue Certificate
```clarity
(contract-call? .green-steel-certification issue-certificate u1 "BATCH001" u1000 "SOLAR001" u75)
```

### Add Supply Chain Step
```clarity
(contract-call? .green-steel-certification add-supply-chain-step u1 u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 "Distribution Center")
```

## 📖 Contract Functions

### Producer Management
- `register-producer(name, location)` - Register a new steel producer
- `verify-producer(producer-id)` - Verify producer credentials (admin only)
- `get-producer(producer-id)` - View producer details

### Energy Source Management  
- `register-energy-source(source-id, type, carbon-intensity)` - Register renewable energy source (admin only)
- `get-energy-source(source-id)` - View energy source details

### IoT Integration
- `register-iot-sensor(sensor-id, producer-id, type, location)` - Register IoT sensor
- `update-iot-reading(sensor-id, reading)` - Update sensor readings
- `validate-production(certificate-id, readings)` - Validate production using IoT data (admin only)

### Certificate Management
- `issue-certificate(producer-id, batch-id, quantity, energy-source, carbon-footprint)` - Issue green steel certificate
- `verify-certificate(certificate-id)` - Verify certificate authenticity (admin only)
- `transfer-certificate(certificate-id, new-owner)` - Transfer certificate ownership
- `get-certificate(certificate-id)` - View certificate details
- `is-green-certified(certificate-id)` - Check if steel meets green standards
- `revoke-certificate(certificate-id)` - Revoke certificate (admin only)

### Supply Chain
- `add-supply-chain-step(certificate-id, step, entity, location)` - Add supply chain step
- `verify-supply-chain-step(certificate-id, step)` - Verify supply chain step (admin only)
- `get-certificate-chain(certificate-id)` - View complete supply chain

### Premium System
- `claim-premium(certificate-id)` - Claim premium tokens for green steel
- `withdraw-premium(amount)` - Withdraw premium tokens
- `get-premium-balance(owner)` - Check premium balance

### Certificate Marketplace
- `list-certificate(certificate-id, price)` - List a verified certificate for sale at specified STX price
- `buy-certificate(certificate-id)` - Purchase a listed certificate and transfer ownership
### Dispute Resolution
- `file-dispute(certificate-id, reason)` - File a dispute against a certificate
- `resolve-dispute(certificate-id)` - Resolve a dispute (admin only)
- `get-dispute(certificate-id)` - View dispute details
- `get-certificate-listing(certificate-id)` - View marketplace listing details

## 🌿 Green Certification Criteria

Steel qualifies as "green certified" when:
- ✅ Carbon footprint ≤ 150 kg CO2/ton
- ✅ Energy source carbon intensity ≤ 100 kg CO2/MWh
- ✅ Producer is verified
- ✅ Certificate is verified by admin and not revoked

## 💎 Premium Calculation

Premium rates are calculated based on carbon footprint and energy source:

| Carbon Footprint | Low-Carbon Energy (≤50) | Medium-Carbon Energy (>50) |
|-------------------|-------------------------|----------------------------|
| Excellent (≤100)  | 200 tokens/ton          | 150 tokens/ton             |
| Good (101-200)    | 100 tokens/ton          | 75 tokens/ton              |
| Standard (>200)   | 25 tokens/ton           | 25 tokens/ton              |

## 🛠️ Development

```bash
# Install dependencies
npm install

# Run tests
clarinet test

# Deploy contract
clarinet deploy
```

## 📋 Contract Constants

- `certification-fee`: 1,000,000 microSTX (adjustable by admin)
- Initial reputation score: 100 points
- Reputation bonus per verified certificate: 10 points

## 🔐 Security Features

- Dispute resolution mechanism for certificate integrity
- Role-based access control (admin vs producers vs buyers)
- Certificate verification requirements
- IoT sensor validation
- Supply chain step verification
- Balance checks for premium withdrawals

## 🏪 Certificate Marketplace

- **List Certificate**: Allow certificate owners to list their verified green steel certificates for sale on the blockchain marketplace
- **Buy Certificate**: Enable buyers to purchase listed certificates directly through the contract with automatic STX transfers
- **View Listings**: Check current marketplace listings and pricing for available certificates

### List a Certificate for Sale
```clarity
(contract-call? .green-steel-certification list-certificate u1 u5000000)
```

### Purchase a Listed Certificate
```clarity
(contract-call? .green-steel-certification buy-certificate u1)
```

### Check Certificate Listing Details
```clarity
(contract-call? .green-steel-certification get-certificate-listing u1)
```

## 🌍 Enhanced Environmental Impact

- 🛡️ Dispute resolution system for handling certificate disputes and maintaining trust
This system enables:
- 📈 Transparent carbon footprint tracking
- 🔄 Incentivized sustainable production methods
- 📱 Real-time monitoring through IoT integration
- 🏆 Market premiums for green steel producers
- 🔍 Full supply chain transparency
- 🏪 Liquid marketplace for green certificates, promoting wider adoption and trading of sustainable steel assets


## 🛡️ Dispute Resolution System

- **File Dispute**: Certificate owners can file disputes against their certificates if they suspect inaccuracies or issues
- **Resolve Dispute**: Admin can resolve disputes to maintain system integrity
- **View Dispute**: Check dispute details for transparency

### File a Dispute on a Certificate
```clarity
(contract-call? .green-steel-certification file-dispute u1 "Incorrect carbon footprint data")
```

### Resolve a Dispute (Admin only)
```clarity
(contract-call? .green-steel-certification resolve-dispute u1)
```

### Check Dispute Details
```clarity
(contract-call? .green-steel-certification get-dispute u1)
```

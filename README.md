# EventHorizon: Beyond Attendance
## A Next-Generation Proof of Attendance Protocol

EventHorizon is a sophisticated Proof of Attendance Protocol (POAP) built on blockchain technology that goes beyond simple attendance tracking. It creates an engaging ecosystem where participation is rewarded with unique NFTs and reputation points, fostering a rich community-driven environment for events of all types.

## 🌟 Key Features

- **Smart NFT Minting**: Automatic NFT generation upon verified event attendance
- **Reputation System**: Dynamic scoring based on participation and verification
- **Flexible Event Management**: Support for both public and private events
- **Multi-tier Organization**: Event creators and organizers with different permission levels
- **Economic Integration**: Built-in support for paid events with platform fees
- **Comprehensive Verification**: Multiple verification methods for attendance validation

## 📋 Core Functionalities

### Event Creation
```clarity
create-event(name, date, max-participants, entry-fee, is-private, description, event-type, location)
```
- Create events with customizable parameters
- Set attendance limits and entry fees
- Toggle private/public access
- Include detailed event information and location

### Attendance Management
```clarity
check-in(event-id)
verify-attendance(event-id, participant, verification-method)
```
- Secure check-in process
- Multi-step verification
- Automated NFT minting upon successful check-in
- Reputation points distribution

### Organization & Administration
```clarity
add-organizer(event-id, organizer)
cancel-event(event-id)
set-platform-fee(new-fee)
```
- Multiple organizer support (up to 5 per event)
- Event cancellation capabilities
- Dynamic platform fee adjustment

## 🏆 Reputation System

The protocol includes a comprehensive reputation system that:
- Awards points for verified attendance
- Tracks user participation history
- Maintains user roles and statistics
- Records total events and rewards

## 📊 Data Structures

### Event Data
```clarity
{
    name: string-ascii,
    date: uint,
    max-participants: uint,
    current-participants: uint,
    creator: principal,
    entry-fee: uint,
    is-private: bool,
    is-cancelled: bool,
    description: string-ascii,
    event-type: string-ascii,
    location: optional string-ascii
}
```

### Participation Data
```clarity
{
    claimed: bool,
    timestamp: uint,
    verified: bool,
    verification-method: string-ascii,
    attendance-duration: uint
}
```

### User Statistics
```clarity
{
    total-events: uint,
    total-rewards: uint,
    reputation-score: uint,
    roles: list,
    last-active: uint
}
```

## 🔒 Security Features

- Owner-only administrative functions
- Input validation for all parameters
- Protection against double-claiming
- Whitelist support for private events
- Verification requirements for attendance

## 💡 Use Cases

1. **Conferences & Workshops**
   - Track attendance
   - Distribute participation certificates as NFTs
   - Build attendee reputation over multiple events

2. **Virtual Events**
   - Secure proof of participation
   - Automated reward distribution
   - Engagement tracking

3. **Community Gatherings**
   - Member participation tracking
   - Reputation-based privileges
   - Historical involvement records

4. **Educational Programs**
   - Course completion verification
   - Achievement tracking
   - Credential issuance

## 📋 Error Handling

The contract includes comprehensive error handling for:
- Invalid inputs
- Unauthorized actions
- Event capacity limits
- Duplicate claims
- Invalid dates
- Insufficient funds
- And more

## 🚀 Getting Started

1. Deploy the contract to your blockchain network
2. Set initial platform fees using `set-platform-fee`
3. Create your first event using `create-event`
4. Add organizers if needed using `add-organizer`
5. Begin accepting check-ins via `check-in`

## 📈 Future Enhancements

- Integration with external reward systems
- Advanced analytics and reporting
- Mobile app integration
- Enhanced verification methods
- Community governance features

## ⚠️ Important Notes

- All fees are handled in the network's native currency
- Events cannot exceed 1000 participants
- Private events require whitelist management
- Organizer limit is 5 per event
- Event names are limited to 50 characters
- Descriptions are limited to 500 characters


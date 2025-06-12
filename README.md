# Tokenized Logistics Last-Mile Delivery Optimization

A comprehensive blockchain-based system for optimizing last-mile delivery operations using Clarity smart contracts on the Stacks blockchain.

## Overview

This system provides a complete solution for managing last-mile delivery operations with the following key features:

- **Provider Verification**: Secure registration and verification of delivery providers
- **Route Optimization**: Intelligent route planning and optimization algorithms
- **Capacity Management**: Real-time capacity allocation and tracking
- **Customer Notifications**: Automated customer communication system
- **Performance Analytics**: Comprehensive performance tracking and analytics

## Architecture

The system consists of five main smart contracts:

### 1. Delivery Provider Verification (`delivery-provider-verification.clar`)
- Provider registration and verification
- Status management (pending, verified, suspended)
- Provider statistics tracking
- Verification workflow management

### 2. Route Optimization (`route-optimization.clar`)
- Route creation and management
- Delivery assignment to routes
- Route optimization algorithms
- Efficiency scoring

### 3. Capacity Management (`capacity-management.clar`)
- Provider capacity allocation
- Real-time capacity tracking
- Daily usage analytics
- Capacity utilization metrics

### 4. Customer Notification (`customer-notification.clar`)
- Customer preference management
- Automated notification system
- Delivery tracking updates
- Multi-channel communication support

### 5. Performance Analytics (`performance-analytics.clar`)
- Provider performance metrics
- Route performance tracking
- SLA compliance monitoring
- System-wide analytics

## Key Features

### Provider Management
- Secure provider registration process
- Verification workflow with admin controls
- Performance-based provider ratings
- Capacity and service area management

### Smart Route Optimization
- Multi-waypoint route planning
- Distance and time optimization
- Priority package handling
- Real-time route adjustments

### Dynamic Capacity Management
- Real-time capacity allocation
- Multiple capacity types (weight, volume, packages)
- Peak usage tracking
- Efficiency scoring

### Customer Experience
- Customizable notification preferences
- Real-time delivery tracking
- Multi-channel notifications (email, SMS, push)
- Delivery status updates

### Analytics & Insights
- Provider performance dashboards
- Route efficiency metrics
- SLA compliance tracking
- System-wide performance indicators

## Smart Contract Functions

### Provider Verification Contract
\`\`\`clarity
;; Register a new provider
(register-provider name contact service-area capacity)

;; Verify provider (admin only)
(verify-provider provider-id)

;; Update provider status
(update-provider-status provider-id new-status)

;; Check if provider is verified
(is-provider-verified provider-id)
\`\`\`

### Route Optimization Contract
\`\`\`clarity
;; Create optimized route
(create-route provider-id start-location end-location waypoints estimated-distance estimated-time)

;; Assign deliveries to route
(assign-deliveries-to-route route-id delivery-ids priority-count)

;; Optimize existing route
(optimize-route route-id)

;; Calculate route efficiency
(calculate-route-efficiency route-id)
\`\`\`

### Capacity Management Contract
\`\`\`clarity
;; Set provider capacity
(set-provider-capacity provider-id total-capacity capacity-type)

;; Allocate capacity for route
(allocate-capacity provider-id route-id amount)

;; Release allocated capacity
(release-capacity allocation-id)

;; Get capacity utilization
(get-capacity-utilization provider-id)
\`\`\`

### Customer Notification Contract
\`\`\`clarity
;; Set notification preferences
(set-customer-preferences email-enabled sms-enabled push-enabled frequency time-start time-end)

;; Create notification
(create-notification customer-id delivery-id notification-type message delivery-method)

;; Update delivery tracking
(update-delivery-tracking delivery-id customer-id provider-id current-status estimated-delivery location)
\`\`\`

### Performance Analytics Contract
\`\`\`clarity
;; Update provider performance
(update-provider-performance provider-id period total-deliveries successful-deliveries average-time on-time-count rating)

;; Record route performance
(record-route-performance route-id planned-time actual-time planned-distance actual-distance delay-incidents)

;; Track SLA compliance
(track-delivery-sla delivery-id promised-time actual-time delay-reason)

;; Calculate system performance score
(calculate-system-performance-score period)
\`\`\`

## Installation & Deployment

### Prerequisites
- Stacks CLI
- Clarinet (for testing)
- Node.js (for testing framework)

### Setup
1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts: \`clarinet deploy\`

### Testing
The system includes comprehensive tests using Vitest:
\`\`\`bash
npm test
\`\`\`

## Usage Examples

### 1. Register a Delivery Provider
\`\`\`clarity
(contract-call? .delivery-provider-verification register-provider
"FastDelivery Inc"
"contact@fastdelivery.com"
"Downtown Area"
u100)
\`\`\`

### 2. Create an Optimized Route
\`\`\`clarity
(contract-call? .route-optimization create-route
'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECNP
"Warehouse A"
"Distribution Center B"
(list "Stop 1" "Stop 2" "Stop 3")
u50
u120)
\`\`\`

### 3. Allocate Delivery Capacity
\`\`\`clarity
(contract-call? .capacity-management allocate-capacity
'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX17ECNP
u1
u25)
\`\`\`

### 4. Set Customer Notification Preferences
\`\`\`clarity
(contract-call? .customer-notification set-customer-preferences
true
true
false
u0
u8
u18)
\`\`\`

## Benefits

### For Logistics Companies
- Reduced operational costs through route optimization
- Improved capacity utilization
- Enhanced customer satisfaction
- Real-time performance monitoring
- Automated compliance tracking

### For Delivery Providers
- Fair and transparent verification process
- Performance-based reputation system
- Optimized route assignments
- Capacity management tools
- Analytics and insights

### for Customers
- Real-time delivery tracking
- Customizable notifications
- Improved delivery reliability
- Transparent communication
- Better service quality

## Security Features

- Role-based access control
- Provider verification system
- Secure data storage on blockchain
- Immutable performance records
- Transparent operations

## Future Enhancements

- Integration with IoT devices for real-time tracking
- Machine learning for predictive analytics
- Cross-chain compatibility
- Mobile application development
- API gateway for third-party integrations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the GitHub repository or contact the development team.


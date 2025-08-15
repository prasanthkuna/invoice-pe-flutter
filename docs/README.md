# InvoicePe API Documentation

## Overview

This documentation provides comprehensive information about InvoicePe's backend architecture, API endpoints, and system components.

## Architecture Overview

InvoicePe follows a modern serverless architecture with the following components:

- **Frontend**: Flutter mobile application
- **Backend**: Supabase PostgreSQL database with Edge Functions
- **Payment Gateway**: PhonePe SDK integration
- **Authentication**: Supabase Auth with JWT tokens

## Database Schema

### Core Tables

#### Users (`profiles`)
- `id`: UUID primary key
- `phone`: User phone number
- `created_at`: Timestamp
- `updated_at`: Timestamp

#### Vendors (`vendors`)
- `id`: UUID primary key
- `user_id`: Foreign key to profiles
- `name`: Vendor name
- `upi_id`: UPI identifier
- `account_number`: Bank account number
- `ifsc_code`: Bank IFSC code

#### Transactions (`transactions`)
- `id`: UUID primary key
- `user_id`: Foreign key to profiles
- `vendor_id`: Foreign key to vendors
- `amount`: Transaction amount
- `status`: Transaction status (initiated, success, failure)
- `phonepe_transaction_id`: PhonePe transaction reference

#### Invoices (`invoices`)
- `id`: UUID primary key
- `user_id`: Foreign key to profiles
- `vendor_id`: Foreign key to vendors
- `amount`: Invoice amount
- `status`: Invoice status (draft, sent, paid)

## API Endpoints

### Authentication
All API requests require authentication via Supabase JWT tokens.

### Edge Functions

#### Payment Processing
**Endpoint**: `/functions/v1/initiate-payment`
**Method**: POST
**Purpose**: Initiate PhonePe payment

```json
{
  "vendor_id": "uuid",
  "amount": 1000,
  "description": "Payment description"
}
```

**Response**:
```json
{
  "success": true,
  "transaction_id": "phonepe_transaction_id",
  "payment_url": "phonepe_payment_url"
}
```

#### Payment Verification
**Endpoint**: `/functions/v1/verify-phonepe-payment`
**Method**: POST
**Purpose**: Verify payment status

```json
{
  "transaction_id": "phonepe_transaction_id"
}
```

**Response**:
```json
{
  "success": true,
  "status": "SUCCESS",
  "amount": 1000
}
```

#### Create PhonePe Order
**Endpoint**: `/functions/v1/create-phonepe-order`
**Method**: POST
**Purpose**: Create payment order

#### PhonePe Authentication
**Endpoint**: `/functions/v1/phonepe-auth`
**Method**: POST
**Purpose**: Authenticate with PhonePe

## Security

### Row Level Security (RLS)
All tables implement Row Level Security policies to ensure users can only access their own data.

### Data Encryption
- Sensitive data encrypted using AES-256-GCM
- Payment credentials stored securely in environment variables
- No PCI data stored in application database

### Compliance
- PCI DSS SAQ-A compliant
- All payment processing outsourced to certified processors
- No cardholder data storage

## Development Resources

- **[Setup Guide](SETUP.md)**: Installation and configuration
- **[Architecture Blueprint](ARCHITECTURE_BLUEPRINT.md)**: Detailed system design
- **[Troubleshooting](TROUBLESHOOTING_MATRIX.md)**: Common issues and solutions

## Support

For technical support and questions:
- Review the troubleshooting guide
- Check the architecture documentation
- Consult the setup guide for configuration issues
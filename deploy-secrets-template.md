# 🚀 InvoicePe Production Secrets Deployment Template

## **ELON-LEVEL DEPLOYMENT COMMANDS (SAFE VERSION)**

### **1. Deploy All Secrets to Supabase Edge Functions**

```bash
# Navigate to project root
cd c:\Users\kunap\samples\invoice-pe-flutter

# Deploy all secrets from Edge Functions .env file
supabase secrets set --env-file supabase/functions/.env

# Verify deployment
supabase secrets list
```

### **2. Individual Secret Deployment Template**

```bash
# Backend Secrets (REPLACE WITH ACTUAL VALUES)
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
supabase secrets set JWT_SECRET=your_jwt_secret_here
supabase secrets set DATABASE_PASSWORD=your_database_password_here

# PhonePe Secrets (REPLACE WITH ACTUAL VALUES)
supabase secrets set PHONEPE_MERCHANT_ID=your_merchant_id_here
supabase secrets set PHONEPE_SALT_KEY=your_salt_key_here
supabase secrets set PHONEPE_SALT_INDEX=1
supabase secrets set PHONEPE_ENVIRONMENT=UAT

# Twilio Secrets (REPLACE WITH ACTUAL VALUES)
supabase secrets set TWILIO_ACCOUNT_SID=your_account_sid_here
supabase secrets set TWILIO_AUTH_TOKEN=your_auth_token_here
supabase secrets set TWILIO_MESSAGE_SERVICE_SID=your_message_service_sid_here
```

### **3. Deploy Edge Functions**

```bash
# Deploy all Edge Functions to production
supabase functions deploy

# Deploy specific function
supabase functions deploy initiate-payment
supabase functions deploy process-payment
supabase functions deploy export-ledger
```

### **4. Verification Commands**

```bash
# List all deployed secrets
supabase secrets list

# Test Edge Function with secrets
curl -X POST https://your-project-id.supabase.co/functions/v1/initiate-payment \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# Check function logs
supabase functions logs initiate-payment
```

## **SECURITY NOTES**

⚠️ **NEVER commit actual secrets to version control**  
⚠️ **Use INTERNAL_CREDENTIALS.md for actual values (gitignored)**  
⚠️ **Always verify secrets are deployed correctly before going live**  
⚠️ **This is a TEMPLATE - replace placeholders with real values**  

## **EMERGENCY ROLLBACK**

```bash
# Remove all secrets (emergency only)
supabase secrets unset PHONEPE_SALT_KEY
supabase secrets unset TWILIO_AUTH_TOKEN
# ... etc

# Redeploy with new secrets
supabase secrets set --env-file supabase/functions/.env
```

**🚀 DEPLOYMENT STATUS: TEMPLATE READY - USE INTERNAL_CREDENTIALS.md FOR ACTUAL VALUES**

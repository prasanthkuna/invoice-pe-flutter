# ASV Scan Verification for PCI DSS Compliance
## InvoicePe - Approved Scanning Vendor Requirements

**Document Version**: 1.0  
**Date**: January 2025  
**Purpose**: ASV scan compliance for PCI DSS SAQ-A

---

## 📋 **ASV SCAN REQUIREMENTS**

### **What Needs to be Scanned**
For SAQ-A compliance, InvoicePe must conduct quarterly external vulnerability scans on:
- Web servers that host payment redirect pages
- Any externally-facing systems that could affect payment security
- Systems that interact with the PhonePe payment flow

### **Current InvoicePe Infrastructure**
- **Primary Domain**: [Your domain when deployed]
- **Hosting**: Flutter Web (static hosting) + Supabase Edge Functions
- **External Endpoints**: Supabase project endpoints
- **Payment Integration**: PhonePe SDK (client-side integration)

---

## 🆓 **FREE ASV SCAN OPTIONS**

### **1. Qualys VMDR Express (FREE)**
- **Provider**: Qualys Inc. (PCI SSC Approved)
- **Cost**: Free for up to 16 IPs
- **Features**: External vulnerability scanning, PCI compliance reports
- **Registration**: https://www.qualys.com/forms/freescan/
- **Scan Frequency**: Quarterly (required for PCI DSS)

### **2. Rapid7 InsightVM Community (FREE)**
- **Provider**: Rapid7 (PCI SSC Approved)
- **Cost**: Free tier available
- **Features**: Vulnerability scanning, compliance reporting
- **Registration**: https://www.rapid7.com/products/insightvm/
- **Scan Frequency**: Quarterly

### **3. Tenable Nessus Essentials (FREE)**
- **Provider**: Tenable Inc. (PCI SSC Approved)
- **Cost**: Free for up to 16 IPs
- **Features**: Vulnerability assessment, compliance scanning
- **Registration**: https://www.tenable.com/products/nessus/nessus-essentials
- **Scan Frequency**: Quarterly

---

## ⚡ **RECOMMENDED APPROACH FOR INVOICEPE**

### **Option 1: Qualys VMDR Express (RECOMMENDED)**
**Why**: Most straightforward for PCI DSS compliance reporting

**Steps**:
1. Register at Qualys website with business email
2. Verify domain ownership
3. Configure scan targets (your web domain)
4. Run initial scan
5. Generate PCI DSS compliance report
6. Schedule quarterly scans

### **Option 2: Use Supabase Security (ALTERNATIVE)**
Since InvoicePe uses Supabase hosting:
- Supabase handles infrastructure security
- May not require separate ASV scans for hosted services
- Verify with Supabase support for PCI DSS compliance documentation

---

## 📝 **ASV SCAN CHECKLIST**

### **Pre-Scan Preparation**
- [ ] Identify all external-facing domains/IPs
- [ ] Ensure CSP headers are properly configured
- [ ] Verify all security patches are applied
- [ ] Document current security configurations

### **Scan Execution**
- [ ] Register with chosen ASV provider
- [ ] Configure scan targets
- [ ] Run initial vulnerability scan
- [ ] Review scan results
- [ ] Remediate any critical/high vulnerabilities
- [ ] Re-scan to verify fixes

### **Post-Scan Documentation**
- [ ] Generate PCI DSS compliance report
- [ ] Document any exceptions or false positives
- [ ] Store scan results for audit purposes
- [ ] Schedule next quarterly scan

---

## 🎯 **SCAN TARGETS FOR INVOICEPE**

### **Primary Targets**
```
# When deployed, scan these:
- your-domain.com (main app)
- any-api-endpoints.your-domain.com
```

### **Exclusions**
```
# These are handled by third parties:
- *.phonepe.com (PhonePe responsibility)
- *.supabase.co (Supabase responsibility)
```

---

## 📊 **EXPECTED SCAN RESULTS**

### **Should PASS (Green)**
- No critical vulnerabilities
- Proper SSL/TLS configuration
- Security headers implemented (CSP, X-Frame-Options, etc.)
- No exposed sensitive information

### **Common Issues to Address**
- Missing security headers (FIXED in web/index.html)
- Outdated SSL/TLS versions
- Information disclosure vulnerabilities
- Cross-site scripting (XSS) vulnerabilities

---

## 📅 **QUARTERLY SCAN SCHEDULE**

| **Quarter** | **Scan Month** | **Due Date** | **Status** |
|-------------|----------------|--------------|------------|
| Q1 2025 | January | January 31 | Pending |
| Q2 2025 | April | April 30 | Scheduled |
| Q3 2025 | July | July 31 | Scheduled |
| Q4 2025 | October | October 31 | Scheduled |

---

## 🔍 **VERIFICATION PROCESS**

### **For PhonePe Submission**
1. Complete ASV scan with passing results
2. Generate official PCI DSS compliance report
3. Include ASV scan report with SAQ-A submission
4. Maintain quarterly scan schedule

### **Documentation Required**
- ASV scan report (quarterly)
- Vulnerability remediation evidence
- Scan schedule and compliance tracking
- ASV provider certification verification

---

## 💰 **COST SUMMARY**

| **Component** | **Cost** | **Provider** |
|---------------|----------|--------------|
| ASV Scan Service | ₹0 | Free tier (Qualys/Rapid7/Tenable) |
| Scan Frequency | ₹0 | Quarterly (included) |
| Compliance Reports | ₹0 | Included in free tier |
| **Total Annual Cost** | **₹0** | **FREE** |

---

## 📞 **SUPPORT CONTACTS**

### **ASV Provider Support**
- **Qualys**: support@qualys.com
- **Rapid7**: support@rapid7.com  
- **Tenable**: support@tenable.com

### **PCI DSS Questions**
- **PCI Security Standards Council**: https://www.pcisecuritystandards.org/
- **PhonePe Merchant Support**: merchant.support@phonepe.com

---

**Next Action**: Choose ASV provider and complete initial scan setup (15 minutes)

**Status**: Ready to proceed with free ASV scan registration

# 🚀 **LiteRT Operations Runbook**

**Version:** 1.0
**Created:** January 2025
**Last Updated:** January 2025
**Objective:** Production operations and maintenance procedures for LiteRT AI integration

---

## 📋 **Table of Contents**

1. [Overview](#overview)
2. [Daily Operations](#daily-operations)
3. [Monitoring & Alerting](#monitoring--alerting)
4. [Incident Response](#incident-response)
5. [Maintenance Procedures](#maintenance-procedures)
6. [Rollout Management](#rollout-management)
7. [Performance Optimization](#performance-optimization)
8. [Backup & Recovery](#backup--recovery)
9. [Contact Information](#contact-information)

---

## 🎯 **Overview**

### **System Architecture**
- **LiteRT Service**: Core AI inference engine
- **Model Manager**: Handles model loading and versioning
- **Production Manager**: Monitors health and performance
- **Feature Flags**: Controls rollout and feature activation
- **Update Service**: Manages model updates and deployments

### **Key Components**
```
PayslipMax App
├── LiteRT Service (AI Inference)
├── Production Manager (Monitoring)
├── Feature Flags (Rollout Control)
├── Model Update Service (Updates)
└── Rollout Manager (Deployment)
```

### **Production Environments**
- **Development**: Feature development and testing
- **Staging**: Pre-production validation
- **Production**: Live user environment

---

## 📊 **Daily Operations**

### **Morning Health Check** (Daily - 9:00 AM)

#### **1. System Status Verification**
```bash
# Check LiteRT service status
curl -X GET "https://api.payslipmax.com/health/litert" \
  -H "Authorization: Bearer $API_TOKEN"

# Expected Response:
{
  "status": "healthy",
  "models": {
    "table_detection": "v2.1.0",
    "text_recognition": "v3.2.1",
    "document_classifier": "v1.8.5"
  },
  "metrics": {
    "uptime": "99.9%",
    "avg_inference_time": "450ms",
    "error_rate": "0.1%"
  }
}
```

#### **2. Performance Metrics Review**
- Check dashboard for key metrics
- Review error rates and performance trends
- Verify model health status
- Confirm update availability

#### **3. Alert Review**
- Check for any active alerts
- Review overnight error logs
- Verify automated health checks passed

### **Midday Operations** (Daily - 12:00 PM)

#### **1. User Feedback Analysis**
- Review user feedback on LiteRT features
- Check support tickets related to AI functionality
- Monitor app store reviews for AI-related comments

#### **2. Performance Optimization**
- Review and optimize slow-performing models
- Check memory usage patterns
- Verify hardware acceleration utilization

### **Evening Operations** (Daily - 6:00 PM)

#### **1. Update Deployment Preparation**
- Check for available model updates
- Review update priorities and risk levels
- Prepare deployment plan if updates available

#### **2. End-of-Day Reporting**
- Generate daily performance report
- Document any incidents or issues
- Update operational status

---

## 📈 **Monitoring & Alerting**

### **Key Metrics to Monitor**

#### **Performance Metrics**
| Metric | Threshold | Alert Level | Action |
|--------|-----------|-------------|---------|
| Model Load Time | > 5 seconds | ⚠️ Warning | Investigate model caching |
| Inference Time | > 500ms | ⚠️ Warning | Check hardware acceleration |
| Memory Usage | > 200MB | 🚨 Critical | Reduce batch size |
| CPU Usage | > 80% | ⚠️ Warning | Optimize model quantization |
| Error Rate | > 5% | 🚨 Critical | Rollback to previous version |

#### **Business Metrics**
| Metric | Threshold | Alert Level | Action |
|--------|-----------|-------------|---------|
| PCDA Accuracy | < 85% | ⚠️ Warning | Review model performance |
| Processing Speed | > 3 seconds | ⚠️ Warning | Optimize inference pipeline |
| User Satisfaction | < 90% | 🚨 Critical | Immediate investigation |

### **Alert Configuration**

#### **Critical Alerts** (Immediate Response Required)
```
🚨 MODEL_CRITICAL: Model health is critical
🚨 MEMORY_CRITICAL: Memory usage > 300MB
🚨 ERROR_RATE_CRITICAL: Error rate > 10%
🚨 PERFORMANCE_CRITICAL: Inference time > 2s
```

#### **Warning Alerts** (Response Within 1 Hour)
```
⚠️ MODEL_DEGRADED: Model health degraded
⚠️ MEMORY_WARNING: Memory usage > 200MB
⚠️ ERROR_RATE_WARNING: Error rate > 5%
⚠️ PERFORMANCE_WARNING: Inference time > 500ms
```

#### **Info Alerts** (Monitor and Document)
```
ℹ️ MODEL_UPDATE_AVAILABLE: New model version available
ℹ️ PERFORMANCE_OPTIMIZATION: Optimization opportunity identified
ℹ️ USER_FEEDBACK: User feedback received
```

### **Dashboard Access**

#### **Production Dashboard**
- **URL**: `https://dashboard.payslipmax.com/litert`
- **Credentials**: Stored in 1Password (`LiteRT Production Dashboard`)
- **Refresh Rate**: Real-time

#### **Monitoring Tools**
- **Grafana**: `https://monitoring.payslipmax.com`
- **DataDog**: LiteRT performance metrics
- **PagerDuty**: Alert management

---

## 🚨 **Incident Response**

### **Critical Incident Response** (Response Time: 15 minutes)

#### **Step 1: Incident Detection**
1. Receive alert via PagerDuty/Slack
2. Acknowledge alert within 5 minutes
3. Assess impact and severity

#### **Step 2: Initial Assessment** (Within 10 minutes)
```bash
# Check current system status
curl -X GET "https://api.payslipmax.com/health/detailed" \
  -H "Authorization: Bearer $API_TOKEN"

# Check recent error logs
kubectl logs -f deployment/litert-service --since=1h

# Verify model health
curl -X POST "https://api.payslipmax.com/models/health-check" \
  -H "Authorization: Bearer $API_TOKEN"
```

#### **Step 3: Impact Assessment**
- Determine affected user percentage
- Assess business impact
- Identify root cause if possible

#### **Step 4: Response Decision Tree**

```
Is user impact > 10%?
├── YES → Emergency Rollback (See Rollback Procedures)
└── NO → Continue diagnosis

Is this a model performance issue?
├── YES → Model-specific troubleshooting
└── NO → System-wide investigation
```

### **Model-Specific Issues**

#### **Model Loading Failures**
```bash
# Check model file integrity
sha256sum /app/models/*.tflite

# Verify model metadata
cat /app/models/model_metadata.json

# Test model loading
curl -X POST "https://api.payslipmax.com/models/test-load" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"model_type": "table_detection"}'
```

#### **Accuracy Degradation**
1. Compare current vs baseline accuracy
2. Review recent model updates
3. Check input data quality
4. Consider rollback to previous version

#### **Performance Degradation**
1. Check hardware utilization
2. Review memory usage patterns
3. Verify model optimization settings
4. Consider model quantization updates

### **Communication Procedures**

#### **Internal Communication**
- **Slack Channel**: `#litert-incidents`
- **Status Page**: `https://status.payslipmax.com`
- **Incident Timeline**: Maintain in Jira ticket

#### **External Communication**
- **User Communication**: Only for widespread outages
- **Template**: Use predefined communication templates
- **Channels**: App notifications, email, status page

---

## 🔧 **Maintenance Procedures**

### **Weekly Maintenance** (Every Monday - 2:00 AM UTC)

#### **1. Model Performance Review**
```bash
# Generate weekly performance report
curl -X GET "https://api.payslipmax.com/reports/weekly-performance" \
  -H "Authorization: Bearer $API_TOKEN" \
  -o weekly_report.json

# Review accuracy trends
jq '.accuracy_trends' weekly_report.json

# Check error patterns
jq '.error_analysis' weekly_report.json
```

#### **2. System Health Check**
- Verify all models are loading correctly
- Check disk space and memory usage
- Review log file sizes and rotation
- Update system packages and security patches

#### **3. Backup Verification**
```bash
# Verify backup integrity
curl -X GET "https://api.payslipmax.com/backup/verify" \
  -H "Authorization: Bearer $API_TOKEN"

# Test backup restoration
curl -X POST "https://api.payslipmax.com/backup/test-restore" \
  -H "Authorization: Bearer $API_TOKEN"
```

### **Monthly Maintenance** (First Monday of Month - 3:00 AM UTC)

#### **1. Model Update Review**
- Review available model updates
- Plan update deployment schedule
- Test updates in staging environment
- Prepare rollback procedures

#### **2. Performance Optimization**
- Analyze long-term performance trends
- Implement performance improvements
- Update model optimization settings
- Review and optimize resource allocation

#### **3. Security Review**
- Update security certificates
- Review access logs and permissions
- Update security patches
- Conduct security vulnerability assessment

### **Quarterly Maintenance** (End of Quarter)

#### **1. Comprehensive System Review**
- Complete architecture review
- Performance benchmarking
- Security audit
- Disaster recovery testing

#### **2. Technology Updates**
- Evaluate new ML frameworks
- Review hardware optimization options
- Plan technology migration if needed
- Update long-term roadmap

---

## 📈 **Rollout Management**

### **Phased Rollout Process**

#### **Phase 1: Alpha Testing (1%)**
```bash
# Enable Phase 1 features
curl -X POST "https://api.payslipmax.com/features/rollout" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"phase": 1, "percentage": 1}'

# Monitor for 24 hours
# Check success criteria:
# - Model loading successful
# - No crashes reported
# - Performance within 10% of baseline
```

#### **Phase 2: Beta Testing (10%)**
```bash
# Advance to Phase 2
curl -X POST "https://api.payslipmax.com/features/advance-phase" \
  -H "Authorization: Bearer $API_TOKEN"

# Monitor for 48 hours
# Check success criteria:
# - PCDA accuracy > 80%
# - Memory usage < 150MB
# - User feedback positive
```

#### **Phase 3: Limited Production (25%)**
```bash
# Advance to Phase 3
curl -X POST "https://api.payslipmax.com/features/advance-phase" \
  -H "Authorization: Bearer $API_TOKEN"

# Monitor for 72 hours
# Check success criteria:
# - PCDA accuracy > 85%
# - No performance degradation
# - Error rate < 5%
```

#### **Phase 4: Extended Production (50%)**
```bash
# Advance to Phase 4
curl -X POST "https://api.payslipmax.com/features/advance-phase" \
  -H "Authorization: Bearer $API_TOKEN"

# Monitor for 96 hours
# Check success criteria:
# - All models performing optimally
# - Battery impact < 10%
# - User engagement maintained
```

#### **Phase 5: Full Production (100%)**
```bash
# Advance to Phase 5 (Full Production)
curl -X POST "https://api.payslipmax.com/features/advance-phase" \
  -H "Authorization: Bearer $API_TOKEN"

# Ongoing monitoring
# Success criteria:
# - Production metrics stable
# - User satisfaction > 95%
# - Zero critical incidents
```

### **Rollback Procedures**

#### **Emergency Rollback** (Immediate - < 5 minutes)
```bash
# Complete emergency rollback
curl -X POST "https://api.payslipmax.com/features/emergency-rollback" \
  -H "Authorization: Bearer $API_TOKEN"

# Verify rollback
curl -X GET "https://api.payslipmax.com/health/status" \
  -H "Authorization: Bearer $API_TOKEN"
```

#### **Gradual Rollback** (Controlled - 15-30 minutes)
```bash
# Rollback one phase at a time
curl -X POST "https://api.payslipmax.com/features/rollback-phase" \
  -H "Authorization: Bearer $API_TOKEN"

# Monitor impact
# Repeat if necessary
```

### **Success Criteria Monitoring**

#### **Automated Monitoring**
```bash
# Check phase success criteria
curl -X GET "https://api.payslipmax.com/rollout/phase-status" \
  -H "Authorization: Bearer $API_TOKEN"

# Response format:
{
  "current_phase": 2,
  "success_rate": 0.85,
  "criteria_met": {
    "accuracy_target": true,
    "memory_target": true,
    "user_feedback": false
  }
}
```

---

## ⚡ **Performance Optimization**

### **Daily Optimization Tasks**

#### **1. Model Performance Tuning**
```bash
# Analyze slow models
curl -X GET "https://api.payslipmax.com/performance/slow-models" \
  -H "Authorization: Bearer $API_TOKEN"

# Optimize identified models
curl -X POST "https://api.payslipmax.com/models/optimize" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{"model_type": "text_recognition", "optimization": "quantization"}'
```

#### **2. Resource Optimization**
- Monitor CPU and memory usage
- Adjust batch sizes based on load
- Optimize cache settings
- Review hardware utilization

### **Weekly Optimization Review**

#### **1. Performance Benchmarking**
```bash
# Run performance benchmarks
curl -X POST "https://api.payslipmax.com/benchmark/run" \
  -H "Authorization: Bearer $API_TOKEN"

# Compare with previous results
curl -X GET "https://api.payslipmax.com/benchmark/compare" \
  -H "Authorization: Bearer $API_TOKEN"
```

#### **2. Optimization Implementation**
- Implement identified optimizations
- Test optimizations in staging
- Deploy optimizations to production
- Monitor impact and adjust

---

## 💾 **Backup & Recovery**

### **Backup Strategy**

#### **Automated Daily Backups**
```bash
# Model files backup
0 2 * * * /scripts/backup-models.sh

# Configuration backup
0 3 * * * /scripts/backup-config.sh

# Database backup
0 4 * * * /scripts/backup-database.sh
```

#### **Backup Verification**
```bash
# Verify model backups
/scripts/verify-model-backup.sh

# Test restoration
/scripts/test-model-restore.sh

# Verify configuration backups
/scripts/verify-config-backup.sh
```

### **Recovery Procedures**

#### **Model Recovery**
```bash
# Restore from backup
/scripts/restore-models.sh --backup-date 2025-01-15

# Verify restored models
curl -X POST "https://api.payslipmax.com/models/verify" \
  -H "Authorization: Bearer $API_TOKEN"
```

#### **Configuration Recovery**
```bash
# Restore configuration
/scripts/restore-config.sh --backup-date 2025-01-15

# Restart services
kubectl rollout restart deployment/litert-service

# Verify configuration
curl -X GET "https://api.payslipmax.com/config/verify" \
  -H "Authorization: Bearer $API_TOKEN"
```

#### **Complete System Recovery**
1. Restore from latest backup
2. Verify system integrity
3. Run comprehensive tests
4. Gradually increase traffic
5. Monitor for issues

---

## 📞 **Contact Information**

### **Primary Contacts**

#### **24/7 On-Call Engineer**
- **Current**: [Engineer Name]
- **Rotation**: Weekly rotation
- **Contact**: PagerDuty escalation
- **Backup**: [Backup Engineer Name]

#### **Technical Lead**
- **Name**: [Technical Lead Name]
- **Email**: tech-lead@payslipmax.com
- **Phone**: [Phone Number]

#### **Product Manager**
- **Name**: [Product Manager Name]
- **Email**: product@payslipmax.com
- **Slack**: @product-manager

### **Support Teams**

#### **Development Team**
- **Slack Channel**: `#litert-dev`
- **Working Hours**: 9 AM - 6 PM UTC
- **Emergency**: PagerDuty integration

#### **DevOps Team**
- **Slack Channel**: `#platform-ops`
- **Working Hours**: 24/7 rotation
- **Emergency**: Direct PagerDuty

#### **Data Science Team**
- **Slack Channel**: `#ml-team`
- **Working Hours**: 9 AM - 6 PM UTC
- **Emergency**: Technical lead escalation

### **External Support**

#### **Vendor Support**
- **TensorFlow**: tensorflow-support@google.com
- **Cloud Provider**: support@cloudprovider.com

#### **Third-Party Tools**
- **Monitoring**: support@datadog.com
- **Alerting**: support@pagerduty.com

---

## 📝 **Change Log**

| Date | Version | Changes |
|------|---------|---------|
| 2025-01-15 | 1.0 | Initial operations runbook created |
| 2025-01-15 | 1.1 | Added incident response procedures |
| 2025-01-15 | 1.2 | Enhanced monitoring and alerting section |

---

## ✅ **Checklist Templates**

### **Daily Operations Checklist**
- [ ] System health check completed
- [ ] Performance metrics reviewed
- [ ] Alerts acknowledged and addressed
- [ ] User feedback analyzed
- [ ] Update deployment prepared
- [ ] End-of-day report generated

### **Weekly Maintenance Checklist**
- [ ] Model performance review completed
- [ ] System health check passed
- [ ] Backups verified
- [ ] Log rotation confirmed
- [ ] Security patches applied

### **Monthly Maintenance Checklist**
- [ ] Model updates reviewed and planned
- [ ] Performance optimizations implemented
- [ ] Security review completed
- [ ] Documentation updated

---

**This runbook should be reviewed and updated quarterly to ensure it remains current with system changes and best practices.**

**Document Owner:** LiteRT Operations Team
**Review Date:** Next quarterly review

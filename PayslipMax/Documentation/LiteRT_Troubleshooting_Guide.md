# 🔧 **LiteRT Troubleshooting Guide**

**Version:** 1.0
**Created:** January 2025
**Last Updated:** January 2025
**Objective:** Quick diagnosis and resolution of LiteRT production issues

---

## 📋 **Quick Reference**

### **Most Common Issues**
1. **Model Loading Failures** - See [Model Issues](#model-issues)
2. **Performance Degradation** - See [Performance Issues](#performance-issues)
3. **Memory Problems** - See [Memory Issues](#memory-issues)
4. **Accuracy Problems** - See [Accuracy Issues](#accuracy-issues)
5. **User Experience Issues** - See [User Experience Issues](#user-experience-issues)

### **Emergency Contacts**
- **24/7 On-Call**: PagerDuty escalation
- **Technical Lead**: tech-lead@payslipmax.com
- **DevOps Lead**: devops@payslipmax.com

---

## 🚨 **Critical Issues (Immediate Response Required)**

### **System Down** (Response: < 5 minutes)

#### **Symptoms**
- LiteRT service completely unresponsive
- All model inferences failing
- Error rate > 50%
- Users unable to process payslips

#### **Diagnosis**
```bash
# Check service health
curl -X GET "https://api.payslipmax.com/health/litert" \
  -H "Authorization: Bearer $API_TOKEN"

# Check system resources
kubectl top pods -n litert

# Check recent logs
kubectl logs -f deployment/litert-service --since=5m
```

#### **Immediate Actions**
```bash
# 1. Emergency rollback
curl -X POST "https://api.payslipmax.com/features/emergency-rollback" \
  -H "Authorization: Bearer $API_TOKEN"

# 2. Scale up resources if needed
kubectl scale deployment litert-service --replicas=5

# 3. Restart services
kubectl rollout restart deployment/litert-service

# 4. Notify team
# (Handled by PagerDuty automation)
```

### **Data Corruption** (Response: < 15 minutes)

#### **Symptoms**
- Model files corrupted or inaccessible
- Checksum validation failures
- Multiple model loading errors

#### **Diagnosis**
```bash
# Verify model integrity
sha256sum /app/models/*.tflite

# Check file permissions
ls -la /app/models/

# Validate model metadata
cat /app/models/model_metadata.json
```

#### **Resolution Steps**
```bash
# 1. Restore from backup
/scripts/restore-models.sh --latest

# 2. Verify restored models
curl -X POST "https://api.payslipmax.com/models/verify" \
  -H "Authorization: Bearer $API_TOKEN"

# 3. Restart services
kubectl rollout restart deployment/litert-service
```

---

## 🔧 **Model Issues**

### **Model Loading Failures**

#### **Symptoms**
- `ModelLoadError` exceptions
- Inference requests timing out
- Model files not found

#### **Diagnosis Steps**
1. **Check Model Files**
   ```bash
   # Verify model files exist
   ls -la /app/models/
   # Expected: table_detection.tflite, text_recognition.tflite, document_classifier.tflite

   # Check file sizes
   ls -lh /app/models/*.tflite
   # Expected sizes: ~7MB, ~39MB, ~4MB
   ```

2. **Validate Model Metadata**
   ```bash
   # Check metadata file
   cat /app/models/model_metadata.json

   # Verify checksums
   /scripts/validate-model-checksums.sh
   ```

3. **Check File Permissions**
   ```bash
   # Verify read permissions
   ls -l /app/models/*.tflite
   # Should be readable by application user
   ```

#### **Resolution Steps**
```bash
# 1. Fix permissions if needed
chmod 644 /app/models/*.tflite

# 2. Restore corrupted models
if checksums_invalid; then
    /scripts/restore-models.sh --latest
fi

# 3. Restart LiteRT service
kubectl rollout restart deployment/litert-service

# 4. Verify loading
curl -X POST "https://api.payslipmax.com/models/test-load" \
  -H "Authorization: Bearer $API_TOKEN"
```

### **Model Performance Degradation**

#### **Symptoms**
- Inference times > 500ms
- Accuracy dropping
- Memory usage increasing

#### **Diagnosis Steps**
1. **Performance Benchmarking**
   ```bash
   # Run performance test
   /scripts/benchmark-models.sh

   # Compare with baseline
   /scripts/compare-performance.sh --baseline v1.0.0
   ```

2. **Resource Monitoring**
   ```bash
   # Check CPU usage
   kubectl top pods -n litert

   # Check memory usage
   kubectl describe pod litert-service-pod
   ```

3. **Model Health Check**
   ```swift
   // In Xcode debugger
   let healthStatus = await productionManager.checkModelHealth()
   print("Model Health: \(healthStatus)")
   ```

#### **Resolution Steps**
```bash
# 1. Optimize model settings
/scripts/optimize-models.sh --quantization

# 2. Scale resources
kubectl scale deployment litert-service --replicas=3

# 3. Clear model cache
/scripts/clear-model-cache.sh

# 4. Restart with optimizations
kubectl rollout restart deployment/litert-service
```

### **Model Update Failures**

#### **Symptoms**
- Update downloads failing
- Checksum validation errors
- Rollback after update

#### **Diagnosis Steps**
1. **Check Update Service**
   ```bash
   # Check update service status
   curl -X GET "https://api.payslipmax.com/updates/status"

   # Check available updates
   curl -X GET "https://api.payslipmax.com/updates/available"
   ```

2. **Network Connectivity**
   ```bash
   # Test update server connectivity
   curl -I https://api.payslipmax.com/models/updates

   # Check DNS resolution
   nslookup api.payslipmax.com
   ```

3. **Download Issues**
   ```bash
   # Check download progress
   tail -f /var/log/litert-updates.log

   # Verify download directory permissions
   ls -la /tmp/litert-updates/
   ```

#### **Resolution Steps**
```bash
# 1. Retry update manually
curl -X POST "https://api.payslipmax.com/updates/retry" \
  -H "Authorization: Bearer $API_TOKEN"

# 2. Check network connectivity
/scripts/test-network.sh

# 3. Clear update cache
/scripts/clear-update-cache.sh

# 4. Manual model update if needed
/scripts/manual-model-update.sh --version latest
```

---

## ⚡ **Performance Issues**

### **Slow Inference Times**

#### **Symptoms**
- Document processing > 2 seconds
- User complaints about speed
- Timeout errors

#### **Diagnosis Steps**
1. **Performance Profiling**
   ```bash
   # Profile inference performance
   /scripts/profile-inference.sh --model text_recognition

   # Check hardware utilization
   /scripts/check-hardware.sh
   ```

2. **Load Analysis**
   ```bash
   # Check current load
   kubectl top pods -n litert

   # Analyze request patterns
   /scripts/analyze-requests.sh --last-hour
   ```

3. **Bottleneck Identification**
   ```bash
   # Check database performance
   /scripts/db-performance.sh

   # Check network latency
   /scripts/network-latency.sh
   ```

#### **Resolution Steps**
```bash
# 1. Scale horizontally
kubectl scale deployment litert-service --replicas=5

# 2. Enable hardware acceleration
/scripts/enable-hardware-acceleration.sh

# 3. Optimize batch processing
/scripts/optimize-batch-processing.sh

# 4. Clear performance caches
/scripts/clear-performance-cache.sh
```

### **Memory Leaks**

#### **Symptoms**
- Gradual memory increase over time
- OutOfMemory errors
- Service restarts

#### **Diagnosis Steps**
1. **Memory Profiling**
   ```bash
   # Profile memory usage
   /scripts/profile-memory.sh --duration 1h

   # Check memory growth
   /scripts/analyze-memory-growth.sh
   ```

2. **Leak Detection**
   ```bash
   # Run memory leak detector
   /scripts/detect-memory-leaks.sh

   # Analyze heap dumps
   /scripts/analyze-heap-dump.sh
   ```

3. **Resource Limits**
   ```bash
   # Check container limits
   kubectl describe pod litert-service-pod

   # Verify resource requests
   kubectl get pod litert-service-pod -o yaml
   ```

#### **Resolution Steps**
```bash
# 1. Restart service to clear memory
kubectl rollout restart deployment/litert-service

# 2. Adjust memory limits
kubectl patch deployment litert-service \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"litert","resources":{"limits":{"memory":"512Mi"},"requests":{"memory":"256Mi"}}}]}}}}'

# 3. Enable memory optimization
/scripts/enable-memory-optimization.sh

# 4. Monitor memory usage
/scripts/monitor-memory.sh --continuous
```

### **High CPU Usage**

#### **Symptoms**
- CPU usage > 80%
- System slowdowns
- Thermal issues

#### **Diagnosis Steps**
1. **CPU Profiling**
   ```bash
   # Profile CPU usage
   /scripts/profile-cpu.sh --duration 30m

   # Check thread utilization
   /scripts/analyze-threads.sh
   ```

2. **Load Distribution**
   ```bash
   # Check load balancer
   kubectl get svc litert-service

   # Analyze request distribution
   /scripts/analyze-load-distribution.sh
   ```

3. **Optimization Opportunities**
   ```bash
   # Check for inefficient code
   /scripts/code-performance-analysis.sh

   # Verify optimization settings
   /scripts/check-optimizations.sh
   ```

#### **Resolution Steps**
```bash
# 1. Scale vertically (increase CPU)
kubectl patch deployment litert-service \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"litert","resources":{"limits":{"cpu":"2"},"requests":{"cpu":"1"}}}]}}}}'

# 2. Optimize processing
/scripts/optimize-processing.sh

# 3. Enable CPU optimization
/scripts/enable-cpu-optimization.sh

# 4. Load balancing
/scripts/configure-load-balancing.sh
```

---

## 🎯 **Accuracy Issues**

### **PCDA Detection Failures**

#### **Symptoms**
- Low PCDA document accuracy
- Wrong document classification
- Table detection failures

#### **Diagnosis Steps**
1. **Accuracy Testing**
   ```bash
   # Test with known PCDA documents
   /scripts/test-pcda-accuracy.sh --test-set pcda_v1

   # Compare with baseline
   /scripts/compare-accuracy.sh --baseline v1.0.0
   ```

2. **Model Validation**
   ```bash
   # Validate model performance
   /scripts/validate-models.sh --focus pcda

   # Check model training data
   /scripts/analyze-training-data.sh
   ```

3. **Input Quality**
   ```bash
   # Analyze input document quality
   /scripts/analyze-input-quality.sh

   # Check preprocessing pipeline
   /scripts/validate-preprocessing.sh
   ```

#### **Resolution Steps**
```bash
# 1. Update to latest model
/scripts/update-models.sh --latest

# 2. Adjust confidence thresholds
/scripts/calibrate-thresholds.sh --model document_classifier

# 3. Improve preprocessing
/scripts/optimize-preprocessing.sh

# 4. Retrain model if needed
/scripts/retrain-model.sh --model document_classifier
```

### **Text Recognition Errors**

#### **Symptoms**
- OCR accuracy < 90%
- Character recognition failures
- Language detection issues

#### **Diagnosis Steps**
1. **OCR Testing**
   ```bash
   # Test text recognition
   /scripts/test-ocr-accuracy.sh --language hindi

   # Analyze error patterns
   /scripts/analyze-ocr-errors.sh
   ```

2. **Language Support**
   ```bash
   # Check language detection
   /scripts/test-language-detection.sh

   # Validate language models
   /scripts/validate-language-models.sh
   ```

3. **Image Quality**
   ```bash
   # Analyze image preprocessing
   /scripts/analyze-image-quality.sh

   # Test with different image qualities
   /scripts/test-image-variations.sh
   ```

#### **Resolution Steps**
```bash
# 1. Update OCR models
/scripts/update-ocr-models.sh

# 2. Improve image preprocessing
/scripts/optimize-image-preprocessing.sh

# 3. Adjust OCR parameters
/scripts/calibrate-ocr-parameters.sh

# 4. Add language support
/scripts/add-language-support.sh --language hindi
```

---

## 👤 **User Experience Issues**

### **App Crashes**

#### **Symptoms**
- Application crashes during processing
- Force closes on document upload
- Memory-related crashes

#### **Diagnosis Steps**
1. **Crash Analysis**
   ```bash
   # Analyze crash logs
   /scripts/analyze-crash-logs.sh --last-24h

   # Check crash patterns
   /scripts/analyze-crash-patterns.sh
   ```

2. **Device Compatibility**
   ```bash
   # Check device compatibility
   /scripts/check-device-compatibility.sh

   # Analyze device-specific crashes
   /scripts/analyze-device-crashes.sh
   ```

3. **Memory Issues**
   ```bash
   # Check memory-related crashes
   /scripts/analyze-memory-crashes.sh

   # Validate memory management
   /scripts/check-memory-management.sh
   ```

#### **Resolution Steps**
```bash
# 1. Deploy hotfix
/scripts/deploy-hotfix.sh --version 1.0.1

# 2. Add device compatibility checks
/scripts/add-device-checks.sh

# 3. Improve memory management
/scripts/optimize-memory-management.sh

# 4. Rollback if necessary
/scripts/emergency-rollback.sh
```

### **Slow User Interface**

#### **Symptoms**
- UI freezing during processing
- Slow response times
- Unresponsive buttons

#### **Diagnosis Steps**
1. **UI Performance**
   ```bash
   # Profile UI performance
   /scripts/profile-ui-performance.sh

   # Check main thread blocking
   /scripts/analyze-main-thread.sh
   ```

2. **Async Processing**
   ```bash
   # Validate async operations
   /scripts/validate-async-processing.sh

   # Check background processing
   /scripts/analyze-background-processing.sh
   ```

3. **Resource Contention**
   ```bash
   # Check resource conflicts
   /scripts/analyze-resource-contention.sh

   # Validate thread safety
   /scripts/check-thread-safety.sh
   ```

#### **Resolution Steps**
```bash
# 1. Optimize UI thread
/scripts/optimize-ui-thread.sh

# 2. Improve async processing
/scripts/optimize-async-processing.sh

# 3. Add progress indicators
/scripts/add-progress-indicators.sh

# 4. Implement background processing
/scripts/implement-background-processing.sh
```

---

## 🛠️ **Diagnostic Tools**

### **Automated Diagnostics**

#### **System Health Check**
```bash
# Comprehensive health check
/scripts/health-check.sh --comprehensive

# Quick health check
/scripts/health-check.sh --quick
```

#### **Performance Diagnostics**
```bash
# Performance analysis
/scripts/diagnose-performance.sh --duration 1h

# Bottleneck analysis
/scripts/diagnose-bottlenecks.sh
```

#### **Issue Classification**
```bash
# Classify current issues
/scripts/classify-issues.sh

# Generate issue report
/scripts/generate-issue-report.sh
```

### **Manual Debugging**

#### **Log Analysis**
```bash
# Search for specific errors
grep "ERROR" /var/log/litert/*.log

# Analyze error patterns
/scripts/analyze-error-patterns.sh

# Check recent logs
tail -f /var/log/litert/service.log
```

#### **Metrics Analysis**
```bash
# Real-time metrics
/scripts/monitor-metrics.sh --realtime

# Historical metrics
/scripts/analyze-metrics.sh --last-week

# Trend analysis
/scripts/analyze-metrics-trends.sh
```

---

## 📞 **Escalation Procedures**

### **Severity Levels**

#### **SEV 1 (Critical)** - Immediate Response
- **Response Time**: < 5 minutes
- **Examples**: System down, data loss, security breach
- **Escalation**: On-call engineer + management

#### **SEV 2 (High)** - Fast Response
- **Response Time**: < 15 minutes
- **Examples**: Performance degradation, user impact
- **Escalation**: On-call engineer

#### **SEV 3 (Medium)** - Normal Response
- **Response Time**: < 1 hour
- **Examples**: Minor issues, monitoring alerts
- **Escalation**: Development team

#### **SEV 4 (Low)** - Scheduled Response
- **Response Time**: Next business day
- **Examples**: Optimization opportunities
- **Escalation**: Development team

### **Escalation Paths**

#### **Technical Issues**
1. **First Line**: On-call engineer
2. **Second Line**: Technical lead
3. **Third Line**: Development team
4. **Fourth Line**: External vendors

#### **Business Impact**
1. **First Line**: Product manager
2. **Second Line**: Engineering manager
3. **Third Line**: Executive team
4. **Fourth Line**: Customer success

---

## 📋 **Common Resolution Patterns**

### **Pattern 1: Restart and Monitor**
```bash
# For transient issues
kubectl rollout restart deployment/litert-service
/scripts/monitor-health.sh --duration 30m
```

### **Pattern 2: Scale and Optimize**
```bash
# For load-related issues
kubectl scale deployment litert-service --replicas=5
/scripts/optimize-performance.sh
```

### **Pattern 3: Update and Verify**
```bash
# For model or software issues
/scripts/update-models.sh --latest
/scripts/verify-updates.sh
```

### **Pattern 4: Rollback and Investigate**
```bash
# For critical issues
/scripts/emergency-rollback.sh
/scripts/investigate-root-cause.sh
```

---

## 📊 **Post-Incident Analysis**

### **Incident Report Template**
```markdown
# Incident Report

## Incident Summary
- **Date/Time**: [Timestamp]
- **Duration**: [Duration]
- **Severity**: [SEV 1/2/3/4]
- **Affected Systems**: [Systems impacted]

## Timeline
- **Detection**: [When detected]
- **Response**: [Initial response]
- **Resolution**: [When resolved]
- **Communication**: [User notification]

## Root Cause
- **Primary Cause**: [Root cause]
- **Contributing Factors**: [Secondary causes]
- **Impact Assessment**: [Business impact]

## Resolution
- **Actions Taken**: [Resolution steps]
- **Verification**: [Testing performed]
- **Prevention**: [Preventive measures]

## Lessons Learned
- **What went well**: [Positive aspects]
- **What to improve**: [Improvement areas]
- **Action Items**: [Follow-up tasks]
```

### **Follow-up Actions**
1. **Immediate**: Update monitoring and alerting
2. **Short-term**: Implement fixes and improvements
3. **Long-term**: Process and documentation updates

---

## 🔍 **Advanced Troubleshooting**

### **Debug Mode Activation**
```bash
# Enable debug logging
/scripts/enable-debug-mode.sh

# Collect debug information
/scripts/collect-debug-info.sh

# Analyze debug logs
/scripts/analyze-debug-logs.sh
```

### **Performance Profiling**
```bash
# Deep performance analysis
/scripts/deep-performance-profile.sh

# Memory profiling
/scripts/memory-profiler.sh --detailed

# CPU profiling
/scripts/cpu-profiler.sh --threads
```

### **Network Diagnostics**
```bash
# Network connectivity test
/scripts/test-network.sh --comprehensive

# API endpoint testing
/scripts/test-api-endpoints.sh

# Load balancer check
/scripts/check-load-balancer.sh
```

---

## 📚 **Additional Resources**

### **Documentation**
- [LiteRT Operations Runbook](LiteRT_Operations_Runbook.md)
- [LiteRT Phase 5 Rollout Plan](LiteRT_Phase5_Rollout_Plan.md)
- [API Documentation](https://api.payslipmax.com/docs)

### **Tools and Scripts**
- `/scripts/` - All diagnostic and maintenance scripts
- `/tools/` - Additional troubleshooting tools
- `/docs/` - Detailed technical documentation

### **Support Channels**
- **Internal Wiki**: `https://wiki.payslipmax.com/litert`
- **Issue Tracker**: `https://issues.payslipmax.com/projects/LITERT`
- **Knowledge Base**: `https://kb.payslipmax.com/litert`

---

**This troubleshooting guide should be updated after each incident with new patterns and resolutions discovered.**

**Technical Owner:** LiteRT Engineering Team
**Last Reviewed:** January 2025

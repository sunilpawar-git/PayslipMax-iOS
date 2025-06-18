# PayslipMax Pull Request Checklist

Please ensure all items are checked before requesting review:

## 🚫 Critical Quality Gates (Must Pass)

- [ ] **File Size Check**: No files exceed 300 lines
  ```bash
  # Run this command to check:
  find PayslipMax -name "*.swift" -exec wc -l {} + | awk '$1 > 300 {print $2 " (" $1 " lines)"}'
  ```

- [ ] **Concurrency Check**: No `DispatchSemaphore` usage for async/sync conversion
  ```bash
  # Run this command to check:
  grep -r "DispatchSemaphore" PayslipMax --include="*.swift"
  ```

- [ ] **Error Handling**: No new `fatalError` usage for recoverable conditions
  ```bash
  # Run this command to check new fatalError usage:
  git diff main --name-only | xargs grep -l "fatalError" || echo "No new fatalError found"
  ```

- [ ] **Single Responsibility**: Each class/service has one clear responsibility

## ⚠️ Code Quality Standards

- [ ] **Architecture Compliance**: Follows MVVM pattern with clear layer separation
- [ ] **Memory Considerations**: Large data operations use streaming/pagination
- [ ] **Protocol Usage**: New functionality is protocol-based for testability
- [ ] **Dependency Injection**: No direct service instantiation in business logic

## 🧪 Testing Requirements

- [ ] **Unit Tests**: New functionality has corresponding unit tests
- [ ] **Integration Tests**: Complex workflows have integration test coverage
- [ ] **Edge Cases**: Error conditions and edge cases are tested
- [ ] **Performance**: Large data operations have performance considerations

## 📝 Documentation

- [ ] **Code Comments**: Complex logic is documented with clear comments
- [ ] **Public APIs**: All public methods have documentation comments
- [ ] **Architecture Decisions**: Significant changes are documented in ADRs

## 🔍 Self-Review Checklist

- [ ] **Code Quality**: Ran `bash Scripts/debt-monitor.sh` and addressed issues
- [ ] **Build Success**: Project builds without warnings in Debug mode
- [ ] **Functionality**: Manually tested the changes work as expected
- [ ] **Regression**: Verified changes don't break existing functionality

## 📋 Description

### What does this PR do?
<!-- Describe the changes in this PR -->

### Why are these changes needed?
<!-- Explain the business/technical justification -->

### How was this tested?
<!-- Describe your testing approach -->

### Technical Debt Impact
<!-- Does this PR reduce, maintain, or add technical debt? -->

## 🎯 Related Issues

Closes #<!-- issue number -->

## 📸 Screenshots (if applicable)

<!-- Add screenshots for UI changes -->

---

## ✅ Automated Checks

The following will be automatically verified:

- [ ] Quality gates pass (`Scripts/debt-monitor.sh`)
- [ ] Build succeeds in CI
- [ ] Tests pass
- [ ] No merge conflicts

---

**Note**: This checklist helps maintain code quality. If you need to bypass any critical quality gates, please explain why in the PR description and tag a senior developer for review. 
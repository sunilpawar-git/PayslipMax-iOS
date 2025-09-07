#!/bin/bash

# PayslipMax Xcode Integration Script
# Sets up architecture quality gates in Xcode build system
# Part of Phase 4: Bulletproof Prevention System

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
XCODE_PROJECT="PayslipMax.xcodeproj"
BUILD_PHASE_NAME="Architecture Quality Gate"
TEMPLATE_DIR="$HOME/Library/Developer/Xcode/Templates/File Templates/PayslipMax"

echo -e "${BLUE}🔧 PayslipMax Xcode Integration Setup${NC}"
echo "======================================"

# Function to check if Xcode project exists
check_xcode_project() {
    if [ ! -d "$XCODE_PROJECT" ]; then
        echo -e "${RED}❌ Error: $XCODE_PROJECT not found${NC}"
        echo "Make sure you're running this script from the project root directory."
        exit 1
    fi
    echo -e "${GREEN}✅ Found Xcode project: $XCODE_PROJECT${NC}"
}

# Function to install file templates
install_file_templates() {
    echo -e "${BLUE}📄 Installing PayslipMax file templates...${NC}"

    # Create template directory
    mkdir -p "$TEMPLATE_DIR"

    # Swift File Template with architecture reminders
    mkdir -p "$TEMPLATE_DIR/Swift File.xctemplate"

    cat > "$TEMPLATE_DIR/Swift File.xctemplate/___FILEBASENAME___.swift" << 'EOF'
//___FILEHEADER___

import Foundation

/// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
/// Current: [CHECK WITH: wc -l ___FILEBASENAME___.swift]
///
/// 🏗️ Component Extraction Guidelines:
/// - At 250+ lines: Start planning extraction
/// - At 280+ lines: Begin extraction immediately
/// - Extract protocols to separate files
/// - Move complex algorithms to dedicated classes
/// - Separate validation logic to support files
/// - Use composition over large inheritance
///
/// 🔧 Quick Commands:
/// - Check size: wc -l ___FILEBASENAME___.swift
/// - Get help: ./Scripts/component-extraction-helper.sh ___FILEBASENAME___.swift
/// - Architecture check: ./Scripts/architecture-guard.sh

final class ___FILEBASENAMEASIDENTIFIER___ {

    // MARK: - Properties

    // MARK: - Initialization

    init() {

    }

    // MARK: - Public Interface

    // MARK: - Private Implementation

}

// MARK: - Extensions

extension ___FILEBASENAMEASIDENTIFIER___ {

}
EOF

    # Template Info.plist
    cat > "$TEMPLATE_DIR/Swift File.xctemplate/TemplateInfo.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Kind</key>
    <string>Xcode.IDEFoundation.TextSubstitutionFileTemplateKind</string>
    <key>Description</key>
    <string>PayslipMax Swift file with architecture compliance reminders</string>
    <key>Summary</key>
    <string>A Swift file with built-in architecture quality reminders and 300-line rule enforcement</string>
    <key>SortOrder</key>
    <string>1</string>
    <key>AllowedTypes</key>
    <array>
        <string>public.swift-source</string>
    </array>
    <key>DefaultCompletionName</key>
    <string>PayslipMaxFile</string>
    <key>MainTemplateFile</key>
    <string>___FILEBASENAME___.swift</string>
</dict>
</plist>
EOF

    # ViewModel Template
    mkdir -p "$TEMPLATE_DIR/MVVM ViewModel.xctemplate"

    cat > "$TEMPLATE_DIR/MVVM ViewModel.xctemplate/___FILEBASENAME___.swift" << 'EOF'
//___FILEHEADER___

import Foundation
import SwiftUI
import Combine

/// ⚠️ ARCHITECTURE REMINDER: Keep under 300 lines
/// MVVM Compliance: ViewModel coordinates but contains no business logic
/// Use DI for all dependencies, async/await for operations

@MainActor
final class ___FILEBASENAMEASIDENTIFIER___: ObservableObject {

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var error: AppError?

    // MARK: - Dependencies (Injected via DI Container)

    private let service: <#ServiceProtocol#>

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(service: <#ServiceProtocol#>? = nil) {
        self.service = service ?? DIContainer.shared.make<#Service#>()
        setupBindings()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Interface

    /// Example async action
    func performAction() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Delegate to service
            try await service.performAction()
        } catch {
            self.error = error as? AppError ?? AppError.unknown
        }
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Setup any necessary bindings
    }
}

// MARK: - Extensions

extension ___FILEBASENAMEASIDENTIFIER___ {
    // Group related functionality in extensions
}
EOF

    cat > "$TEMPLATE_DIR/MVVM ViewModel.xctemplate/TemplateInfo.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Kind</key>
    <string>Xcode.IDEFoundation.TextSubstitutionFileTemplateKind</string>
    <key>Description</key>
    <string>PayslipMax MVVM-compliant ViewModel with DI and async patterns</string>
    <key>Summary</key>
    <string>A ViewModel that follows PayslipMax MVVM architecture with proper dependency injection</string>
    <key>SortOrder</key>
    <string>2</string>
    <key>AllowedTypes</key>
    <array>
        <string>public.swift-source</string>
    </array>
    <key>DefaultCompletionName</key>
    <string>PayslipMaxViewModel</string>
    <key>MainTemplateFile</key>
    <string>___FILEBASENAME___.swift</string>
</dict>
</plist>
EOF

    # Service Template
    mkdir -p "$TEMPLATE_DIR/Protocol-Based Service.xctemplate"

    cat > "$TEMPLATE_DIR/Protocol-Based Service.xctemplate/___FILEBASENAME___.swift" << 'EOF'
//___FILEHEADER___

import Foundation
// ⚠️ MVVM COMPLIANCE: Never import SwiftUI in services
// Exception: UIAppearanceService only

/// ⚠️ ARCHITECTURE REMINDER: Keep under 300 lines
/// Protocol-first design: Define protocol before implementation
/// Async-first: All I/O operations must be async

// MARK: - Protocol Definition

protocol ___FILEBASENAMEASIDENTIFIER___Protocol {
    func performOperation() async throws -> <#ReturnType#>
    // Add more methods as needed
}

// MARK: - Implementation

final class ___FILEBASENAMEASIDENTIFIER___: ___FILEBASENAMEASIDENTIFIER___Protocol {

    // MARK: - Dependencies

    private let dependency: <#DependencyProtocol#>

    // MARK: - Initialization

    init(dependency: <#DependencyProtocol#>) {
        self.dependency = dependency
    }

    // MARK: - Protocol Implementation

    func performOperation() async throws -> <#ReturnType#> {
        // Implement async operation
        // Use proper error handling
        // Delegate complex operations to specialized helpers

        throw AppError.notImplemented
    }

    // MARK: - Private Methods

    private func helperMethod() {
        // Keep methods focused and single-purpose
    }
}

// MARK: - Extensions

extension ___FILEBASENAMEASIDENTIFIER___ {
    // Group related functionality
}

// MARK: - DI Container Registration

extension DIContainer {
    func make___FILEBASENAMEASIDENTIFIER___() -> ___FILEBASENAMEASIDENTIFIER___Protocol {
        return ___FILEBASENAMEASIDENTIFIER___(
            dependency: makeDependency()
        )
    }
}
EOF

    cat > "$TEMPLATE_DIR/Protocol-Based Service.xctemplate/TemplateInfo.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Kind</key>
    <string>Xcode.IDEFoundation.TextSubstitutionFileTemplateKind</string>
    <key>Description</key>
    <string>PayslipMax protocol-based service with DI integration</string>
    <key>Summary</key>
    <string>A service following protocol-first design with async patterns and DI container registration</string>
    <key>SortOrder</key>
    <string>3</string>
    <key>AllowedTypes</key>
    <array>
        <string>public.swift-source</string>
    </array>
    <key>DefaultCompletionName</key>
    <string>PayslipMaxService</string>
    <key>MainTemplateFile</key>
    <string>___FILEBASENAME___.swift</string>
</dict>
</plist>
EOF

    echo -e "${GREEN}✅ File templates installed successfully${NC}"
    echo "   Templates available in Xcode: File → New → File → PayslipMax"
}

# Function to create build phase script
create_build_phase_script() {
    echo -e "${BLUE}🏗️ Creating build phase script for architecture checking...${NC}"

    local build_script_path="Scripts/xcode-build-phase.sh"

    cat > "$build_script_path" << 'EOF'
#!/bin/bash

# PayslipMax Xcode Build Phase - Architecture Quality Gate
# Integrates architecture checking into Xcode build process

echo "🔍 PayslipMax Architecture Quality Gate"
echo "======================================"

# Ensure we're in the project directory
cd "$PROJECT_DIR" || exit 1

# Check if architecture guard script exists
if [ ! -f "./Scripts/architecture-guard.sh" ]; then
    echo "⚠️ Architecture guard script not found, skipping check"
    exit 0
fi

# Make script executable
chmod +x ./Scripts/architecture-guard.sh

# Run architecture check in build mode (fast check)
echo "Running quick architecture compliance check..."
if ./Scripts/architecture-guard.sh --build-mode; then
    echo "✅ Architecture quality gate passed"
else
    echo "❌ Architecture quality gate failed"
    echo ""
    echo "🔧 Fix violations before building:"
    echo "   1. Check file sizes: find PayslipMax -name '*.swift' -exec wc -l {} + | sort -n"
    echo "   2. Get fix suggestions: ./Scripts/architecture-guard.sh --fix-suggestions"
    echo "   3. Use component extraction: ./Scripts/component-extraction-helper.sh"
    echo ""
    exit 1
fi
EOF

    chmod +x "$build_script_path"
    echo -e "${GREEN}✅ Build phase script created: $build_script_path${NC}"
}

# Function to setup VS Code integration
setup_vscode_integration() {
    echo -e "${BLUE}💻 Setting up VS Code integration...${NC}"

    mkdir -p .vscode

    # VS Code settings for architecture awareness
    cat > .vscode/settings.json << 'EOF'
{
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/node_modules/**": true,
        "**/.architecture-metrics.json": true
    },
    "editor.rulers": [300],
    "editor.renderWhitespace": "boundary",
    "files.associations": {
        "*.swift": "swift"
    },
    "swift.path": "/usr/bin/swift",
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
    "files.insertFinalNewline": true,
    "files.trimTrailingWhitespace": true,
    "editor.formatOnSave": true,
    "workbench.colorCustomizations": {
        "editorRuler.foreground": "#ff000040"
    },
    "editor.wordWrap": "bounded",
    "editor.wordWrapColumn": 300,
    "editor.showFoldingControls": "always"
}
EOF

    # VS Code tasks for architecture commands
    cat > .vscode/tasks.json << 'EOF'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Architecture Guard Check",
            "type": "shell",
            "command": "./Scripts/architecture-guard.sh",
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": []
        },
        {
            "label": "Collect Architecture Metrics",
            "type": "shell",
            "command": "./Scripts/debt-trend-monitor.sh",
            "args": ["--collect"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        },
        {
            "label": "Show Architecture Dashboard",
            "type": "shell",
            "command": "./Scripts/debt-trend-monitor.sh",
            "args": ["--dashboard"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        },
        {
            "label": "Component Extraction Helper",
            "type": "shell",
            "command": "./Scripts/component-extraction-helper.sh",
            "args": ["${file}"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        }
    ]
}
EOF

    echo -e "${GREEN}✅ VS Code integration configured${NC}"
    echo "   Available tasks: Cmd+Shift+P → Tasks: Run Task"
}

# Function to create developer onboarding checklist
create_onboarding_checklist() {
    echo -e "${BLUE}📋 Creating developer onboarding checklist...${NC}"

    cat > "DEVELOPER_ONBOARDING.md" << 'EOF'
# PayslipMax Developer Onboarding - Architecture Quality

Welcome to PayslipMax! This checklist ensures you're set up to maintain our 94+/100 architecture quality score.

## ✅ Setup Checklist

### 1. Quality Gate Activation
- [ ] Verify git pre-commit hook: `ls -la .git/hooks/pre-commit`
- [ ] Test pre-commit hook: `echo "test" > test.swift && git add test.swift && git commit -m "test"`
- [ ] Should see: "🔍 PayslipMax Quality Gate Enforcement..."
- [ ] Clean up: `git reset HEAD~ && rm test.swift`

### 2. IDE Configuration
- [ ] Xcode templates installed (run `./Scripts/xcode-integration.sh`)
- [ ] VS Code configured with 300-line rulers
- [ ] Architecture checking commands available

### 3. Architecture Rules Training
- [ ] Read [Technical Debt Elimination Roadmap](Documentation/TechnicalDebtReduction/DebtEliminationRoadmap2024.md)
- [ ] Understand the 300-line rule (NON-NEGOTIABLE)
- [ ] Review MVVM-SOLID compliance guidelines
- [ ] Practice component extraction patterns

### 4. Quality Tools Training
- [ ] Run `./Scripts/architecture-guard.sh --help`
- [ ] Run `./Scripts/debt-trend-monitor.sh --dashboard`
- [ ] Practice with `./Scripts/component-extraction-helper.sh`
- [ ] Understand violation reporting system

## 🏗️ Architecture Rules (CRITICAL)

### File Size Rule
- **Every Swift file MUST be under 300 lines**
- Check with: `wc -l filename.swift`
- Start extraction at 250+ lines
- **Never compromise on this rule**

### MVVM Compliance
- Views NEVER import business logic directly
- Services NEVER import SwiftUI (except UIAppearanceService)
- All dependencies via DI container
- Use protocol-based design

### Async-First Development
- All I/O operations use async/await
- No DispatchSemaphore or blocking operations
- Background processing through async coordinators

## 🔧 Daily Workflow

### Before Coding
1. Check current status: `./Scripts/architecture-guard.sh`
2. Collect metrics: `./Scripts/debt-trend-monitor.sh --collect`

### During Development
1. Monitor file sizes regularly
2. Use provided Xcode templates for new files
3. Extract components before hitting 280 lines

### Before Committing
1. Architecture check will run automatically
2. Fix any violations before proceeding
3. Use `./Scripts/architecture-guard.sh --fix-suggestions` for help

## 🚨 Emergency Procedures

### When Build Fails Due to Architecture Violations
1. Run `./Scripts/architecture-guard.sh --fix-suggestions`
2. Identify the largest files causing violations
3. Use `./Scripts/component-extraction-helper.sh <filename>` for guidance
4. Follow established refactoring patterns

### When Unsure About Architecture Decisions
1. Check existing similar implementations
2. Review successful refactoring examples in roadmap
3. Follow protocol-first, async-first principles
4. Ask for architecture review if needed

## 📊 Monitoring Tools

### Daily Commands
- `./Scripts/architecture-guard.sh` - Full architecture check
- `./Scripts/debt-trend-monitor.sh --dashboard` - Current status
- `./Scripts/debt-trend-monitor.sh --collect` - Update metrics

### Weekly Commands
- `./Scripts/debt-trend-monitor.sh --report` - Generate trend report
- Review architecture compliance trends

## 🎯 Success Metrics

- **100% of files under 300 lines**
- **Zero MVVM violations**
- **Zero DispatchSemaphore usage**
- **Quality score 94+/100**

## 📚 Resources

- [Architecture Documentation](Documentation/Architecture/)
- [Component Extraction Examples](Documentation/TechnicalDebtReduction/)
- [MVVM-SOLID Guidelines](Documentation/Architecture/MVVMSOLIDCompliancePlan.md)

---

**Remember**: Architecture quality is NOT optional. These rules maintain the codebase quality that enables rapid development and prevents technical debt.

Welcome to the team! 🚀
EOF

    echo -e "${GREEN}✅ Developer onboarding checklist created: DEVELOPER_ONBOARDING.md${NC}"
}

# Function to verify installation
verify_installation() {
    echo -e "${BLUE}🔍 Verifying Xcode integration installation...${NC}"

    local all_good=true

    # Check file templates
    if [ -d "$TEMPLATE_DIR" ]; then
        echo -e "${GREEN}✅ File templates installed${NC}"
    else
        echo -e "${RED}❌ File templates missing${NC}"
        all_good=false
    fi

    # Check build script
    if [ -f "Scripts/xcode-build-phase.sh" ]; then
        echo -e "${GREEN}✅ Build phase script created${NC}"
    else
        echo -e "${RED}❌ Build phase script missing${NC}"
        all_good=false
    fi

    # Check VS Code settings
    if [ -f ".vscode/settings.json" ]; then
        echo -e "${GREEN}✅ VS Code integration configured${NC}"
    else
        echo -e "${RED}❌ VS Code integration missing${NC}"
        all_good=false
    fi

    # Check onboarding checklist
    if [ -f "DEVELOPER_ONBOARDING.md" ]; then
        echo -e "${GREEN}✅ Developer onboarding checklist created${NC}"
    else
        echo -e "${RED}❌ Developer onboarding checklist missing${NC}"
        all_good=false
    fi

    if [ "$all_good" = true ]; then
        echo -e "${GREEN}🎉 Xcode integration setup complete!${NC}"
        echo ""
        echo -e "${CYAN}Next Steps:${NC}"
        echo "1. Restart Xcode to see new file templates"
        echo "2. Add build phase script to Xcode project manually:"
        echo "   - Open $XCODE_PROJECT in Xcode"
        echo "   - Select PayslipMax target → Build Phases"
        echo "   - Add New Run Script Phase → Name: '$BUILD_PHASE_NAME'"
        echo "   - Script: ./Scripts/xcode-build-phase.sh"
        echo "3. Train team with DEVELOPER_ONBOARDING.md"
        echo "4. Test with a commit to verify quality gates work"
    else
        echo -e "${RED}❌ Installation incomplete. Please check errors above.${NC}"
        return 1
    fi
}

# Main function
main() {
    case "$1" in
        --install)
            check_xcode_project
            install_file_templates
            create_build_phase_script
            setup_vscode_integration
            create_onboarding_checklist
            verify_installation
            ;;
        --verify)
            verify_installation
            ;;
        --templates-only)
            install_file_templates
            ;;
        --help)
            cat << EOF
PayslipMax Xcode Integration Script

Usage: $0 [--install|--verify|--templates-only|--help]

Commands:
  --install         Full Xcode integration setup
  --verify          Verify installation status
  --templates-only  Install file templates only
  --help           Show this help message

Description:
  Sets up architecture quality gates and development tools in Xcode:
  - File templates with architecture reminders
  - Build phase scripts for quality checking
  - VS Code integration for enhanced development
  - Developer onboarding documentation

Examples:
  $0 --install      # Full setup
  $0 --verify       # Check installation
EOF
            ;;
        *)
            echo -e "${BLUE}🔧 PayslipMax Xcode Integration${NC}"
            echo "Usage: $0 [--install|--verify|--templates-only|--help]"
            echo "Run '$0 --help' for detailed usage information."
            ;;
    esac
}

# Execute main function
main "$@"

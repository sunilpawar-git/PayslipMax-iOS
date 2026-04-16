#!/usr/bin/env python3
"""
Integrate SwiftLint build phase into Xcode project
Safely adds a Run Script Phase for SwiftLint
"""

import re
import uuid
import sys
import os
from pathlib import Path

def generate_xcode_id():
    """Generate a 24-character hex ID in Xcode format"""
    return uuid.uuid4().hex[:24].upper()

def add_swiftlint_build_phase(project_file_path):
    """Add SwiftLint build phase to Xcode project"""

    project_file = Path(project_file_path)
    if not project_file.exists():
        print(f"❌ Error: {project_file_path} not found")
        return False

    # Read project file
    with open(project_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Check if already exists
    if '/* SwiftLint */' in content and 'PBXShellScriptBuildPhase' in content:
        if re.search(r'PBXShellScriptBuildPhase.*SwiftLint', content):
            print("✅ SwiftLint build phase already exists")
            return True

    # Generate IDs
    build_phase_id = generate_xcode_id()
    print(f"Generated Build Phase ID: {build_phase_id}")

    # Create backup
    backup_path = project_file.with_suffix('.pbxproj.backup')
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Created backup: {backup_path.name}")

    # Find Resources build phase for PayslipMax target
    resources_pattern = r'(10171F662D3FFE010053BAB6 /\* Resources \*/ = \{[^}]*\};)'
    resources_match = re.search(resources_pattern, content, re.DOTALL)

    if not resources_match:
        print("❌ Error: Could not find Resources build phase")
        return False

    # Insert SwiftLint build phase after Resources section
    resources_end = resources_match.end()

    # Build phase definition
    script_path = "${SRCROOT}/Scripts/swiftlint-build-phase.sh"
    build_phase_def = f"""
\t\t{build_phase_id} /* SwiftLint */ = {{
\t\t\tisa = PBXShellScriptBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\tinputFileListPaths = (
\t\t\t);
\t\t\tinputPaths = (
\t\t\t);
\t\t\tname = SwiftLint;
\t\t\toutputFileListPaths = (
\t\t\t);
\t\t\toutputPaths = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t\tshellPath = /bin/sh;
\t\t\tshellScript = "{script_path}";
\t\t\tshowEnvVarsInLog = 0;
\t\t}};"""

    # Insert build phase definition
    content = content[:resources_end] + build_phase_def + content[resources_end:]

    # Add to buildPhases array for PayslipMax target
    # Find: buildPhases = ( ... 10171F662D3FFE010053BAB6 /* Resources */, ... );
    payslipmax_target_pattern = r'(10171F672D3FFE010053BAB6 /\* PayslipMax \*/ = \{[^}]*buildPhases = \(([^)]*10171F662D3FFE010053BAB6 /\* Resources \*/[^)]*)\);)'

    def add_to_build_phases(match):
        build_phases_content = match.group(2)
        # Add SwiftLint after Resources
        new_build_phases = build_phases_content.rstrip()
        if not new_build_phases.endswith(','):
            new_build_phases += ','
        new_build_phases += f'\n\t\t\t\t{build_phase_id} /* SwiftLint */,'
        return match.group(1).replace(match.group(2), new_build_phases)

    content = re.sub(payslipmax_target_pattern, add_to_build_phases, content, flags=re.DOTALL)

    # Write updated content
    with open(project_file, 'w', encoding='utf-8') as f:
        f.write(content)

    print("✅ SwiftLint build phase added successfully!")
    return True

if __name__ == '__main__':
    project_file = 'PayslipMax.xcodeproj/project.pbxproj'
    if len(sys.argv) > 1:
        project_file = sys.argv[1]

    success = add_swiftlint_build_phase(project_file)
    sys.exit(0 if success else 1)



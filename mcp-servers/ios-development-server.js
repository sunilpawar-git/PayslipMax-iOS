#!/usr/bin/env node

/**
 * PayslipMax iOS Development MCP Server
 * Provides iOS-specific development tools for Xcode and Simulator operations
 */

const { Server } = require("@modelcontextprotocol/sdk/server/index.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");
const {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} = require("@modelcontextprotocol/sdk/types.js");
const { exec, spawn } = require('child_process');
const { promisify } = require('util');
const fs = require('fs');
const path = require('path');
const os = require('os');

const execAsync = promisify(exec);

class iOSDevelopmentServer {
  constructor() {
    this.server = new Server(
      {
        name: "payslipmax-ios-dev",
        version: "0.1.0",
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupToolHandlers();
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: "build_project",
          description: "Build the PayslipMax iOS project",
          inputSchema: {
            type: "object",
            properties: {
              scheme: {
                type: "string",
                description: "Build scheme (PayslipMax, PayslipMaxTests, etc.)",
                default: "PayslipMax"
              },
              configuration: {
                type: "string", 
                description: "Build configuration (Debug, Release)",
                default: "Debug"
              },
              destination: {
                type: "string",
                description: "Build destination (simulator, device)",
                default: "platform=iOS Simulator,name=iPhone 15,OS=latest"
              }
            }
          }
        },
        {
          name: "run_tests",
          description: "Run iOS project tests",
          inputSchema: {
            type: "object",
            properties: {
              test_plan: {
                type: "string",
                description: "Test plan to run (unit, integration, ui, all)",
                default: "all"
              },
              coverage: {
                type: "boolean",
                description: "Generate code coverage report",
                default: true
              }
            }
          }
        },
        {
          name: "simulator_operations",
          description: "Control iOS Simulator",
          inputSchema: {
            type: "object",
            properties: {
              operation: {
                type: "string",
                description: "Simulator operation (list, boot, shutdown, reset, install)",
                enum: ["list", "boot", "shutdown", "reset", "install"]
              },
              device_id: {
                type: "string",
                description: "Device UDID for operations"
              },
              app_path: {
                type: "string", 
                description: "Path to .app bundle for installation"
              }
            },
            required: ["operation"]
          }
        },
        {
          name: "analyze_project",
          description: "Analyze Xcode project structure and dependencies",
          inputSchema: {
            type: "object",
            properties: {
              analysis_type: {
                type: "string",
                description: "Type of analysis (structure, dependencies, warnings, build_time)",
                enum: ["structure", "dependencies", "warnings", "build_time"]
              }
            },
            required: ["analysis_type"]
          }
        },
        {
          name: "manage_packages",
          description: "Manage Swift Package dependencies",
          inputSchema: {
            type: "object",
            properties: {
              operation: {
                type: "string",
                description: "Package operation (list, update, add, remove)",
                enum: ["list", "update", "add", "remove"]
              },
              package_url: {
                type: "string",
                description: "Package URL for add/remove operations"
              }
            },
            required: ["operation"]
          }
        },
        {
          name: "performance_profile",
          description: "Profile app performance using Instruments",
          inputSchema: {
            type: "object",
            properties: {
              profile_type: {
                type: "string",
                description: "Profile type (time, allocations, leaks, energy)",
                enum: ["time", "allocations", "leaks", "energy"]
              },
              duration: {
                type: "integer",
                description: "Profiling duration in seconds",
                default: 30
              }
            },
            required: ["profile_type"]
          }
        }
      ]
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      switch (request.params.name) {
        case "build_project":
          return await this.buildProject(request.params.arguments);
        case "run_tests":
          return await this.runTests(request.params.arguments);
        case "simulator_operations":
          return await this.simulatorOperations(request.params.arguments);
        case "analyze_project":
          return await this.analyzeProject(request.params.arguments);
        case "manage_packages":
          return await this.managePackages(request.params.arguments);
        case "performance_profile":
          return await this.performanceProfile(request.params.arguments);
        default:
          throw new Error(`Unknown tool: ${request.params.name}`);
      }
    });
  }

  // Enhanced command execution with better environment setup
  async executeCommand(command, options = {}) {
    const defaultOptions = {
      cwd: this.getProjectPath(),
      timeout: 300000, // 5 minutes default
      maxBuffer: 1024 * 1024 * 10, // 10MB buffer
      env: this.getXcodeEnvironment(),
      ...options
    };

    // Log debugging information
    console.error(`[DEBUG] Executing command: ${command}`);
    console.error(`[DEBUG] Working directory: ${defaultOptions.cwd}`);
    console.error(`[DEBUG] Environment PATH: ${defaultOptions.env.PATH}`);
    console.error(`[DEBUG] Project path exists: ${await this.checkProjectExists(defaultOptions.cwd)}`);

    try {
      // Use a more robust approach for macOS shell execution
      const result = await new Promise((resolve, reject) => {
        console.error(`[DEBUG] Spawning zsh with command: ${command}`);
        
        const child = spawn('/bin/zsh', ['-c', command], defaultOptions);
        
        let stdout = '';
        let stderr = '';
        
        child.stdout.on('data', (data) => {
          stdout += data.toString();
        });
        
        child.stderr.on('data', (data) => {
          stderr += data.toString();
        });
        
        child.on('close', (code) => {
          console.error(`[DEBUG] Command completed with code: ${code}`);
          console.error(`[DEBUG] stdout: ${stdout.substring(0, 200)}...`);
          console.error(`[DEBUG] stderr: ${stderr.substring(0, 200)}...`);
          resolve({ code, stdout, stderr });
        });
        
        child.on('error', (error) => {
          console.error(`[DEBUG] Spawn error: ${error.message}`);
          console.error(`[DEBUG] Error code: ${error.code}`);
          console.error(`[DEBUG] Error stack: ${error.stack}`);
          reject(error);
        });
        
        // Handle timeout
        const timeout = setTimeout(() => {
          console.error(`[DEBUG] Command timed out after ${defaultOptions.timeout}ms`);
          child.kill('SIGTERM');
          reject(new Error(`Command timed out after ${defaultOptions.timeout}ms`));
        }, defaultOptions.timeout);
        
        child.on('close', () => {
          clearTimeout(timeout);
        });
      });

      return { 
        success: result.code === 0, 
        stdout: result.stdout, 
        stderr: result.stderr,
        code: result.code
      };
    } catch (error) {
      console.error(`[DEBUG] executeCommand caught error: ${error.message}`);
      return { 
        success: false, 
        error: error.message, 
        stdout: '', 
        stderr: error.stderr || '',
        code: error.code || -1
      };
    }
  }

  async buildProject(args) {
    const { 
      scheme = "PayslipMax", 
      configuration = "Debug", 
      destination = "platform=iOS Simulator,name=iPhone 15,OS=latest" 
    } = args;

    try {
      // First check if we can find the project
      const projectPath = this.getProjectPath();
      if (!await this.checkProjectExists(projectPath)) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                error_message: `Project not found at ${projectPath}. Please check PAYSLIPMAX_IOS_PATH environment variable.`,
                timestamp: new Date().toISOString()
              }, null, 2)
            }
          ]
        };
      }

      const buildCommand = `xcodebuild -scheme "${scheme}" -configuration "${configuration}" -destination "${destination}" build`;
      
      const result = await this.executeCommand(buildCommand, { timeout: 600000 }); // 10 minutes for build

      if (!result.success) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                error_message: result.error,
                stderr: result.stderr,
                stdout: result.stdout,
                scheme,
                configuration,
                timestamp: new Date().toISOString()
              }, null, 2)
            }
          ]
        };
      }

      // Parse build output for warnings and errors
      const output = result.stdout + result.stderr;
      const warnings = this.extractWarnings(output);
      const errors = this.extractErrors(output);
      const buildTime = this.extractBuildTime(output);

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: errors.length === 0 ? "success" : "failed",
              scheme,
              configuration,
              destination,
              build_time: buildTime,
              warnings: warnings.length,
              errors: errors.length,
              warning_details: warnings.slice(0, 10), // Limit to first 10
              error_details: errors.slice(0, 10),
              timestamp: new Date().toISOString()
            }, null, 2)
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "error",
              error_message: error.message,
              scheme,
              configuration,
              timestamp: new Date().toISOString()
            }, null, 2)
          }
        ]
      };
    }
  }

  async runTests(args) {
    const { test_plan = "all", coverage = true } = args;

    try {
      const projectPath = this.getProjectPath();
      if (!await this.checkProjectExists(projectPath)) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                error_message: `Project not found at ${projectPath}`,
                timestamp: new Date().toISOString()
              }, null, 2)
            }
          ]
        };
      }

      let testCommand = `xcodebuild test -scheme PayslipMax -destination "platform=iOS Simulator,name=iPhone 15,OS=latest"`;
      
      if (coverage) {
        testCommand += " -enableCodeCoverage YES";
      }

      if (test_plan !== "all") {
        testCommand += ` -testPlan ${test_plan}`;
      }

      const result = await this.executeCommand(testCommand, { timeout: 900000 }); // 15 minutes for tests

      if (!result.success) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                error_message: result.error,
                stderr: result.stderr,
                test_plan,
                timestamp: new Date().toISOString()
              }, null, 2)
            }
          ]
        };
      }

      // Parse test results
      const testResults = this.parseTestResults(result.stdout + result.stderr);
      
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: testResults.failed === 0 ? "passed" : "failed",
              test_plan,
              total_tests: testResults.total,
              passed: testResults.passed,
              failed: testResults.failed,
              skipped: testResults.skipped,
              test_duration: testResults.duration,
              coverage_enabled: coverage,
              failed_tests: testResults.failures.slice(0, 10),
              timestamp: new Date().toISOString()
            }, null, 2)
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "error",
              error_message: error.message,
              test_plan,
              timestamp: new Date().toISOString()
            }, null, 2)
          }
        ]
      };
    }
  }

  async simulatorOperations(args) {
    const { operation, device_id, app_path } = args;

    try {
      let command;
      
      switch (operation) {
        case "list":
          command = "xcrun simctl list devices";
          break;
        case "boot":
          if (!device_id) throw new Error("device_id required for boot operation");
          command = `xcrun simctl boot "${device_id}"`;
          break;
        case "shutdown":
          if (!device_id) throw new Error("device_id required for shutdown operation");
          command = `xcrun simctl shutdown "${device_id}"`;
          break;
        case "reset":
          if (!device_id) throw new Error("device_id required for reset operation");
          command = `xcrun simctl erase "${device_id}"`;
          break;
        case "install":
          if (!device_id || !app_path) throw new Error("device_id and app_path required for install operation");
          command = `xcrun simctl install "${device_id}" "${app_path}"`;
          break;
        default:
          throw new Error(`Unknown simulator operation: ${operation}`);
      }

      const result = await this.executeCommand(command, { timeout: 120000 });

      if (!result.success) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                operation,
                error_message: result.error,
                stderr: result.stderr,
                timestamp: new Date().toISOString()
              }, null, 2)
            }
          ]
        };
      }

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "success",
              operation,
              device_id,
              output: result.stdout,
              timestamp: new Date().toISOString()
            }, null, 2)
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "error",
              operation,
              error_message: error.message,
              timestamp: new Date().toISOString()
            }, null, 2)
          }
        ]
      };
    }
  }

  async analyzeProject(args) {
    const { analysis_type } = args;

    try {
      let result;

      switch (analysis_type) {
        case "structure":
          result = await this.analyzeProjectStructure();
          break;
        case "dependencies":
          result = await this.analyzeDependencies();
          break;
        case "warnings":
          result = await this.analyzeWarnings();
          break;
        case "build_time":
          result = await this.analyzeBuildTime();
          break;
        default:
          throw new Error(`Unknown analysis type: ${analysis_type}`);
      }

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              analysis_type,
              ...result,
              timestamp: new Date().toISOString()
            }, null, 2)
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "error",
              analysis_type,
              error_message: error.message,
              timestamp: new Date().toISOString()
            }, null, 2)
          }
        ]
      };
    }
  }

  async managePackages(args) {
    const { operation, package_url } = args;

    try {
      let command;
      
      switch (operation) {
        case "list":
          // Try to find Package.swift or look at Xcode project
          const projectPath = this.getProjectPath();
          const packageSwiftPath = path.join(projectPath, "Package.swift");
          
          if (await this.fileExists(packageSwiftPath)) {
            command = "swift package show-dependencies";
          } else {
            // Look for .xcodeproj and try to extract dependencies
            command = `find "${projectPath}" -name "*.xcodeproj" -exec xcodebuild -project {} -list \\;`;
          }
          break;
        case "update":
          command = "swift package update";
          break;
        case "add":
          if (!package_url) throw new Error("package_url required for add operation");
          // This would typically be done through Xcode, but we can attempt via Package.swift
          throw new Error("Add package operation requires Xcode integration - use Xcode -> File -> Add Package Dependencies");
        case "remove":
          throw new Error("Remove package operation requires Xcode integration - use Xcode project navigator");
        default:
          throw new Error(`Unknown package operation: ${operation}`);
      }

      const result = await this.executeCommand(command, { timeout: 180000 });

      if (!result.success) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "error",
                operation,
                error_message: result.error,
                stderr: result.stderr,
                timestamp: new Date().toISOString()
              }, null, 2)
            }
          ]
        };
      }

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "success",
              operation,
              output: result.stdout,
              timestamp: new Date().toISOString()
            }, null, 2)
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "error",
              operation,
              error_message: error.message,
              timestamp: new Date().toISOString()
            }, null, 2)
          }
        ]
      };
    }
  }

  async performanceProfile(args) {
    // This would require more complex integration with Instruments
    // For now, return a placeholder implementation
    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({
            status: "not_implemented",
            message: "Performance profiling requires Instruments integration",
            recommendation: "Use Xcode -> Product -> Profile for detailed performance analysis",
            available_instruments: [
              "Time Profiler",
              "Allocations", 
              "Leaks",
              "Energy Log",
              "System Trace"
            ],
            timestamp: new Date().toISOString()
          }, null, 2)
        }
      ]
    };
  }

  // Helper methods
  getProjectPath() {
    // Try multiple possible locations for the iOS project
    const possiblePaths = [
      process.env.PAYSLIPMAX_IOS_PATH,
      "/Users/sunil/Desktop/PayslipMax",
      "/Users/sunil/Desktop/PayslipMax-iOS",
      path.join(process.cwd(), "..", "PayslipMax"),
      path.join(os.homedir(), "Desktop", "PayslipMax")
    ].filter(Boolean);

    // Return the first path that exists, or the first option as fallback
    for (const projectPath of possiblePaths) {
      if (fs.existsSync(projectPath)) {
        return projectPath;
      }
    }

    return possiblePaths[1] || "/Users/sunil/Desktop/PayslipMax"; // Default fallback
  }

  // Method to set up proper environment for Xcode commands
  getXcodeEnvironment() {
    const homeDir = os.homedir();
    const currentPath = process.env.PATH || '';
    
    // Build comprehensive PATH for Xcode tools
    const additionalPaths = [
      '/usr/bin',
      '/bin',
      '/usr/sbin',
      '/sbin',
      '/usr/local/bin',
      '/opt/homebrew/bin',
      '/Applications/Xcode.app/Contents/Developer/usr/bin',
      '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin',
      `${homeDir}/.local/bin`
    ];

    const newPath = [...new Set([...currentPath.split(':'), ...additionalPaths])].join(':');

    return {
      ...process.env,
      PATH: newPath,
      SHELL: '/bin/zsh',
      DEVELOPER_DIR: '/Applications/Xcode.app/Contents/Developer',
      LANG: 'en_US.UTF-8',
      LC_ALL: 'en_US.UTF-8'
    };
  }

  // Utility methods
  async checkProjectExists(projectPath) {
    try {
      const stat = await fs.promises.stat(projectPath);
      return stat.isDirectory();
    } catch {
      return false;
    }
  }

  async fileExists(filePath) {
    try {
      await fs.promises.access(filePath);
      return true;
    } catch {
      return false;
    }
  }

  extractWarnings(output) {
    const warningRegex = /warning: (.+)/g;
    const warnings = [];
    let match;
    while ((match = warningRegex.exec(output)) !== null) {
      warnings.push(match[1]);
    }
    return warnings;
  }

  extractErrors(output) {
    const errorRegex = /error: (.+)/g;
    const errors = [];
    let match;
    while ((match = errorRegex.exec(output)) !== null) {
      errors.push(match[1]);
    }
    return errors;
  }

  extractBuildTime(output) {
    const timeRegex = /Build succeeded.*?(\d+\.\d+)\s*seconds/;
    const match = output.match(timeRegex);
    return match ? parseFloat(match[1]) : null;
  }

  parseTestResults(output) {
    // Parse test output for results
    const totalTests = (output.match(/Test Case.*started/g) || []).length;
    const passedTests = (output.match(/Test Case.*passed/g) || []).length;
    const failedTests = (output.match(/Test Case.*failed/g) || []).length;
    const failures = [];
    
    const failureRegex = /Test Case '(.+)' failed/g;
    let match;
    while ((match = failureRegex.exec(output)) !== null) {
      failures.push(match[1]);
    }

    return {
      total: totalTests,
      passed: passedTests,
      failed: failedTests,
      skipped: totalTests - passedTests - failedTests,
      failures,
      duration: this.extractTestDuration(output)
    };
  }

  extractTestDuration(output) {
    const durationRegex = /Test session results.*?(\d+\.\d+)\s*seconds/;
    const match = output.match(durationRegex);
    return match ? parseFloat(match[1]) : null;
  }

  async analyzeProjectStructure() {
    try {
      const projectPath = this.getProjectPath();
      
      const result = await this.executeCommand(`find "${projectPath}" -name "*.swift" | wc -l`, { timeout: 30000 });
      const swiftFiles = parseInt(result.stdout.trim()) || 0;
      
      const testResult = await this.executeCommand(`find "${projectPath}" -name "*Test*.swift" | wc -l`, { timeout: 30000 });
      const testFiles = parseInt(testResult.stdout.trim()) || 0;
      
      const resourceResult = await this.executeCommand(`find "${projectPath}" -type f \\( -name "*.png" -o -name "*.jpg" -o -name "*.json" -o -name "*.plist" \\) | wc -l`, { timeout: 30000 });
      const resourceFiles = parseInt(resourceResult.stdout.trim()) || 0;

      return {
        status: "completed",
        project_path: projectPath,
        total_files: swiftFiles + resourceFiles,
        swift_files: swiftFiles,
        test_files: testFiles,
        resource_files: resourceFiles
      };
    } catch (error) {
      return {
        status: "error",
        error_message: error.message
      };
    }
  }

  async analyzeDependencies() {
    try {
      const projectPath = this.getProjectPath();
      
      // Look for Package.swift
      const packageResult = await this.executeCommand(`find "${projectPath}" -name "Package.swift"`, { timeout: 15000 });
      const hasPackageSwift = packageResult.stdout.trim().length > 0;
      
      // Look for .xcodeproj
      const xcodeprojResult = await this.executeCommand(`find "${projectPath}" -name "*.xcodeproj"`, { timeout: 15000 });
      const xcodeprojFiles = xcodeprojResult.stdout.trim().split('\n').filter(line => line.length > 0);

      return {
        status: "completed",
        has_package_swift: hasPackageSwift,
        xcode_projects: xcodeprojFiles,
        external_dependencies: [],
        internal_dependencies: []
      };
    } catch (error) {
      return {
        status: "error",
        error_message: error.message
      };
    }
  }

  async analyzeWarnings() {
    try {
      const buildResult = await this.executeCommand('xcodebuild -scheme PayslipMax -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" build', { timeout: 300000 });
      
      const warnings = this.extractWarnings(buildResult.stdout + buildResult.stderr);
      const warningCategories = {};
      
      warnings.forEach(warning => {
        const category = this.categorizeWarning(warning);
        warningCategories[category] = (warningCategories[category] || 0) + 1;
      });

      return {
        status: "completed",
        total_warnings: warnings.length,
        warning_categories: warningCategories,
        sample_warnings: warnings.slice(0, 5)
      };
    } catch (error) {
      return {
        status: "error",
        error_message: error.message
      };
    }
  }

  categorizeWarning(warning) {
    if (warning.includes('deprecated')) return 'deprecated';
    if (warning.includes('unused')) return 'unused';
    if (warning.includes('implicit')) return 'implicit';
    if (warning.includes('conversion')) return 'conversion';
    return 'other';
  }

  async analyzeBuildTime() {
    try {
      const startTime = Date.now();
      const buildResult = await this.executeCommand('xcodebuild -scheme PayslipMax -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" build', { timeout: 600000 });
      const endTime = Date.now();
      const buildTimeMs = endTime - startTime;

      return {
        status: "completed",
        build_time_ms: buildTimeMs,
        build_time_seconds: buildTimeMs / 1000,
        build_success: buildResult.success
      };
    } catch (error) {
      return {
        status: "error",
        error_message: error.message
      };
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("PayslipMax iOS Development MCP server running on stdio");
  }
}

const server = new iOSDevelopmentServer();
server.run().catch(console.error); 
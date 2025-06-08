#!/usr/bin/env node

/**
 * PayslipMax HTTP MCP Server
 * Provides HTTP client capabilities for testing PayslipMax APIs
 */

const { Server } = require("@modelcontextprotocol/sdk/server/index.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");
const {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} = require("@modelcontextprotocol/sdk/types.js");
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

class PayslipMaxHTTPServer {
  constructor() {
    this.server = new Server(
      {
        name: "payslipmax-http",
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
          name: "test_upload_api",
          description: "Test PayslipMax upload API endpoint",
          inputSchema: {
            type: "object",
            properties: {
              file_path: {
                type: "string",
                description: "Path to PDF file to upload"
              },
              base_url: {
                type: "string", 
                description: "Base URL for API (default: production)"
              }
            },
            required: ["file_path"]
          }
        },
        {
          name: "test_qr_generation",
          description: "Test QR code generation API",
          inputSchema: {
            type: "object",
            properties: {
              upload_id: {
                type: "string",
                description: "Upload ID to generate QR for"
              },
              filename: {
                type: "string", 
                description: "Original filename"
              },
              base_url: {
                type: "string",
                description: "Base URL for API"
              }
            },
            required: ["upload_id", "filename"]
          }
        },
        {
          name: "test_deep_link",
          description: "Test deep link validation",
          inputSchema: {
            type: "object", 
            properties: {
              deep_link: {
                type: "string",
                description: "Deep link URL to validate"
              }
            },
            required: ["deep_link"]
          }
        },
        {
          name: "monitor_api_health",
          description: "Check API endpoint health and response times",
          inputSchema: {
            type: "object",
            properties: {
              base_url: {
                type: "string",
                description: "Base URL to monitor"
              }
            }
          }
        }
      ]
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      switch (request.params.name) {
        case "test_upload_api":
          return await this.testUploadAPI(request.params.arguments);
        case "test_qr_generation":
          return await this.testQRGeneration(request.params.arguments);
        case "test_deep_link":
          return await this.testDeepLink(request.params.arguments);
        case "monitor_api_health":
          return await this.monitorAPIHealth(request.params.arguments);
        default:
          throw new Error(`Unknown tool: ${request.params.name}`);
      }
    });
  }

  async testUploadAPI(args) {
    const { file_path, base_url = "https://payslipmax.hostinger.site" } = args;
    
    try {
      // Check if file exists
      if (!fs.existsSync(file_path)) {
        throw new Error(`File not found: ${file_path}`);
      }

      const formData = new FormData();
      formData.append('pdf', fs.createReadStream(file_path));

      const response = await axios.post(`${base_url}/api/upload.php`, formData, {
        headers: {
          ...formData.getHeaders(),
        },
        timeout: 30000 // 30 seconds
      });

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "success",
              response_code: response.status,
              response_data: response.data,
              file_uploaded: file_path,
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
              response_code: error.response?.status,
              response_data: error.response?.data,
              timestamp: new Date().toISOString()
            }, null, 2)
          }
        ]
      };
    }
  }

  async testQRGeneration(args) {
    const { upload_id, filename, base_url = "https://payslipmax.hostinger.site" } = args;

    try {
      const response = await axios.post(`${base_url}/api/generate_qr.php`, {
        id: upload_id,
        filename: filename,
        size: 1024,
        timestamp: Date.now()
      }, {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 10000
      });

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "success",
              qr_generated: true,
              response_code: response.status,
              qr_data: response.data,
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
              response_code: error.response?.status,
              timestamp: new Date().toISOString()
            }, null, 2)
          }
        ]
      };
    }
  }

  async testDeepLink(args) {
    const { deep_link } = args;

    try {
      // Parse deep link
      const url = new URL(deep_link);
      const params = Object.fromEntries(url.searchParams);

      // Validate required parameters
      const requiredParams = ['id', 'filename', 'size', 'timestamp', 'hash'];
      const missingParams = requiredParams.filter(param => !params[param]);

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: missingParams.length === 0 ? "valid" : "invalid",
              deep_link: deep_link,
              parsed_params: params,
              missing_params: missingParams,
              validation_notes: {
                scheme: url.protocol === 'payslipmax:' ? 'valid' : 'invalid',
                host: url.hostname === 'upload' ? 'valid' : 'invalid',
                param_count: Object.keys(params).length
              },
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
              error_message: "Invalid deep link format",
              deep_link: deep_link,
              timestamp: new Date().toISOString()
            }, null, 2)
          }
        ]
      };
    }
  }

  async monitorAPIHealth(args) {
    const { base_url = "https://payslipmax.hostinger.site" } = args;

    const endpoints = [
      '/api/upload.php',
      '/api/download.php',
      '/api/generate_qr.php'
    ];

    const results = [];

    for (const endpoint of endpoints) {
      try {
        const start = Date.now();
        const response = await axios.get(`${base_url}${endpoint}`, {
          timeout: 5000
        });
        const responseTime = Date.now() - start;

        results.push({
          endpoint,
          status: 'healthy',
          response_code: response.status,
          response_time_ms: responseTime
        });
      } catch (error) {
        results.push({
          endpoint,
          status: 'unhealthy',
          error: error.message,
          response_code: error.response?.status
        });
      }
    }

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({
            overall_health: results.every(r => r.status === 'healthy') ? 'healthy' : 'degraded',
            base_url,
            endpoints: results,
            timestamp: new Date().toISOString()
          }, null, 2)
        }
      ]
    };
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("PayslipMax HTTP MCP server running on stdio");
  }
}

const server = new PayslipMaxHTTPServer();
server.run().catch(console.error); 
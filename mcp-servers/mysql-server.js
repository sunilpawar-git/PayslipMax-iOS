#!/usr/bin/env node

// Load environment variables from .env file
require('dotenv').config();

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');
const mysql = require('mysql2/promise');

// Debug: Log environment variables (without exposing password)
console.error('DB Host:', process.env.PAYSLIPMAX_DB_HOST);
console.error('DB User:', process.env.PAYSLIPMAX_DB_USER);
console.error('DB Name:', process.env.PAYSLIPMAX_DB_NAME);
console.error('Password set:', !!process.env.MYSQL_PASSWORD);

class PayslipMaxMySQLServer {
  constructor() {
    this.server = new Server(
      {
        name: 'payslipmax-mysql',
        version: '0.1.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupToolHandlers();
    
    // Error handling
    this.server.onerror = (error) => console.error('[MCP Error]', error);
    process.on('SIGINT', async () => {
      await this.server.close();
      process.exit(0);
    });
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'query_database',
          description: 'Execute a SELECT query on the PayslipMax database',
          inputSchema: {
            type: 'object',
            properties: {
              query: {
                type: 'string',
                description: 'SQL SELECT query to execute',
              },
            },
            required: ['query'],
          },
        },
        {
          name: 'inspect_schema',
          description: 'Inspect database schema and table structure',
          inputSchema: {
            type: 'object',
            properties: {
              table: {
                type: 'string',
                description: 'Table name to inspect (optional)',
              },
            },
          },
        },
        {
          name: 'check_health',
          description: 'Check database connection health',
          inputSchema: {
            type: 'object',
            properties: {},
          },
        },
      ],
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'query_database':
            return await this.queryDatabase(args.query);
          case 'inspect_schema':
            return await this.inspectSchema(args.table);
          case 'check_health':
            return await this.checkHealth();
          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: ${error.message}`,
            },
          ],
        };
      }
    });
  }

  async getConnection() {
    // Use working configuration from our tests
    const dbConfig = {
      host: 'srv1552.hstgr.io',
      port: 3306,
      user: 'u795274726_payslipmax_usr',
      password: 'fyrqe9-kYbxon-jifdeb',
      database: 'u795274726_payslipmax_db',
      ssl: false,
      connectTimeout: 20000
    };
    
    console.error('Attempting connection with config:', {
      host: dbConfig.host,
      port: dbConfig.port,
      user: dbConfig.user,
      database: dbConfig.database,
      passwordSet: !!dbConfig.password
    });
    
    return await mysql.createConnection(dbConfig);
  }

  async queryDatabase(query) {
    // Only allow SELECT queries for safety
    if (!query.trim().toLowerCase().startsWith('select')) {
      throw new Error('Only SELECT queries are allowed');
    }

    const connection = await this.getConnection();
    try {
      const [rows] = await connection.execute(query);
      await connection.end();

      return {
        content: [
          {
            type: 'text',
            text: `Query executed successfully. Results:\n${JSON.stringify(rows, null, 2)}`,
          },
        ],
      };
    } catch (error) {
      await connection.end();
      throw error;
    }
  }

  async inspectSchema(tableName) {
    const connection = await this.getConnection();
    try {
      let result = '';

      if (tableName) {
        // Describe specific table
        const [columns] = await connection.execute(`DESCRIBE ${tableName}`);
        result = `Table: ${tableName}\n${JSON.stringify(columns, null, 2)}`;
      } else {
        // List all tables
        const [tables] = await connection.execute('SHOW TABLES');
        result = `Database Tables:\n${JSON.stringify(tables, null, 2)}`;
      }

      await connection.end();

      return {
        content: [
          {
            type: 'text',
            text: result,
          },
        ],
      };
    } catch (error) {
      await connection.end();
      throw error;
    }
  }

  async checkHealth() {
    try {
      const connection = await this.getConnection();
      const [result] = await connection.execute('SELECT 1 as health_check');
      await connection.end();

      return {
        content: [
          {
            type: 'text',
            text: `Database connection healthy. Response: ${JSON.stringify(result)}`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Database connection failed: ${error.message}`,
          },
        ],
      };
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('PayslipMax MySQL MCP server running on stdio');
  }
}

const server = new PayslipMaxMySQLServer();
server.run().catch(console.error); 
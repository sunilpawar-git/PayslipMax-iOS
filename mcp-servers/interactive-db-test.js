const mysql = require('mysql2/promise');
const readline = require('readline');

// Function to securely get password input
function getPassword(prompt) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    // Hide password input
    rl.stdoutMuted = true;
    rl.question(prompt, (password) => {
      rl.stdoutMuted = false;
      rl.close();
      console.log(); // New line after password input
      resolve(password);
    });

    rl._writeToOutput = function _writeToOutput(stringToWrite) {
      if (rl.stdoutMuted) {
        rl.output.write("*");
      } else {
        rl.output.write(stringToWrite);
      }
    };
  });
}

async function interactiveConnectionTest() {
  console.log('=== PayslipMax Database Connection Test ===');
  console.log('Host: srv1552.hstgr.io');
  console.log('Database: u795274726_payslipmax_db');
  console.log('User: u795274726_payslipmax_usr');
  console.log();

  try {
    // Get password from user
    const password = await getPassword('Enter database password: ');
    
    console.log('Testing connection...');
    
    const dbConfig = {
      host: 'srv1552.hstgr.io',
      port: 3306,
      user: 'u795274726_payslipmax_usr',
      password: password.trim(), // Trim any whitespace
      database: 'u795274726_payslipmax_db',
      ssl: false,
      connectTimeout: 20000
    };
    
    const connection = await mysql.createConnection(dbConfig);
    console.log('✅ Connection successful!');
    
    // Test basic query
    const [result] = await connection.execute('SELECT 1 as health_check, NOW() as current_time');
    console.log('✅ Query successful!');
    console.log('Result:', result[0]);
    
    // Test user info
    const [userResult] = await connection.execute('SELECT USER() as current_user');
    console.log('✅ User info:', userResult[0]);
    
    // Test database tables
    console.log('\nChecking database tables...');
    const [tables] = await connection.execute('SHOW TABLES');
    console.log('✅ Tables found:', tables.length);
    if (tables.length > 0) {
      console.log('Available tables:');
      tables.forEach(table => {
        console.log(`  - ${Object.values(table)[0]}`);
      });
    }
    
    await connection.end();
    console.log('✅ Connection closed successfully');
    
    // If we get here, save the working configuration
    console.log('\n🎉 Database connection is working!');
    console.log('The password will be updated in the MCP configuration.');
    
    return password;
    
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    console.error('Error code:', error.code);
    
    if (error.code === 'ER_ACCESS_DENIED_ERROR') {
      console.log('\n💡 Suggestions:');
      console.log('1. Check if the password is correct');
      console.log('2. Verify remote access is enabled in Hostinger');
      console.log('3. Ensure the user has proper permissions');
    }
    
    return null;
  }
}

// Run the interactive test
interactiveConnectionTest().then((workingPassword) => {
  if (workingPassword) {
    console.log('\n✅ Ready to update MCP configuration with working credentials.');
  } else {
    console.log('\n❌ Please check the password and try again.');
  }
}).catch(console.error); 
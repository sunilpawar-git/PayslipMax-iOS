const mysql = require('mysql2/promise');

async function testConnection() {
  const dbConfig = {
    host: 'srv1552.hstgr.io',
    port: 3306,
    user: 'u795274726_payslipmax_usr',
    password: 'fyrqe9-kYbxon-jifdeb',
    database: 'u795274726_payslipmax_db',
    ssl: false,
    connectTimeout: 20000
  };
  
  console.log('Testing database connection...');
  console.log('Host:', dbConfig.host);
  console.log('Port:', dbConfig.port);
  console.log('User:', dbConfig.user);
  console.log('Database:', dbConfig.database);
  
  try {
    const connection = await mysql.createConnection(dbConfig);
    console.log('✅ Connection successful!');
    
    // Test basic query (simplified for MariaDB)
    const [result] = await connection.execute('SELECT 1 as health_check');
    console.log('✅ Query successful:', result);
    
    // Test current time separately
    const [timeResult] = await connection.execute('SELECT NOW() as current_time');
    console.log('✅ Time query successful:', timeResult);
    
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
    console.log('\n🎉 Database connection is working!');
    
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    console.error('Error code:', error.code);
  }
}

testConnection(); 
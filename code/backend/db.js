const mysql = require('mysql2');

// 创建数据库连接池
const pool = mysql.createPool({
  host: '127.0.0.1',        // 数据库地址
  user: 'root',             // 数据库用户名
  password: '123456',      // ⚠️⚠️⚠️ 这里必须改成你刚才在VSCode插件里设置的密码！
  database: 'qin_tian_db',  // 我们建好的库名
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// 测试连接
pool.getConnection((err, conn) => {
  if (err) {
    console.error('❌ 数据库连接失败:', err.message);
  } else {
    console.log('✅ 数据库连接成功！');
    conn.release();
  }
});

module.exports = pool.promise();
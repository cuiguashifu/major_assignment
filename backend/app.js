const express = require('express');
const cors = require('cors');
const db = require('./db'); // 引入刚才写的 db.js

const app = express();
const PORT = 3000;

// 中间件
app.use(cors()); // 允许前端跨域访问
app.use(express.json()); // 解析 JSON 数据

// ==========================================
// 测试接口1：获取所有助农事件
// ==========================================
app.get('/api/events', async (req, res) => {
  try {
    // 直接查询我们之前建好的视图 v_event_details
    const [rows] = await db.query('SELECT * FROM v_event_details');
    res.json({ code: 200, msg: '获取成功', data: rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ code: 500, msg: '服务器错误' });
  }
});

// ==========================================
// 测试接口2：打卡操作（调用我们写好的存储过程）
// ==========================================
app.post('/api/checkin', async (req, res) => {
  const { location_id } = req.body; // 前端传来帮扶地ID
  if (!location_id) return res.status(400).json({ code: 400, msg: '参数缺失' });

  try {
    // 调用存储过程 sp_add_checkin
    await db.query('CALL sp_add_checkin(?)', [location_id]);
    res.json({ code: 200, msg: '打卡成功' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ code: 500, msg: '打卡失败' });
  }
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`🚀 后端服务器已启动: http://localhost:${PORT}`);
});
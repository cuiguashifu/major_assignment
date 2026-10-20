-- ==========================================
-- 大作业题目：十个勤天助农成果展示站
-- 数据库初始化脚本 (MySQL 8.0)
-- 说明：包含建库、建表、视图、存储过程及测试数据
-- ==========================================

-- 1. 创建数据库并切换
USE qin_tian_db;
-- 2.1 成员信息表
CREATE TABLE tb_member (
    member_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '成员编号',
    name VARCHAR(50) NOT NULL COMMENT '姓名',
    role VARCHAR(50) COMMENT '角色/特长',
    avatar VARCHAR(255) COMMENT '头像路径',
    intro TEXT COMMENT '个人简介'
) COMMENT='成员信息表';

-- 2.2 帮扶地信息表 (先建，因为Event表依赖它)
CREATE TABLE tb_location (
    location_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '帮扶地编号',
    location_name VARCHAR(100) NOT NULL COMMENT '地区名称',
    category VARCHAR(50) COMMENT '产品类别（水果/粮油/手作等，用于饼图）',
    description TEXT COMMENT '详细描述',
    before_image VARCHAR(255) COMMENT '帮扶前图片路径',
    after_image VARCHAR(255) COMMENT '帮扶后图片路径'
) COMMENT='帮扶地信息表';

-- 2.3 助农事件表 (依赖Location表)
CREATE TABLE tb_event (
    event_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '事件编号',
    title VARCHAR(100) NOT NULL COMMENT '事件标题',
    event_date DATE NOT NULL COMMENT '发生日期（用于柱状图）',
    content TEXT COMMENT '事件详情',
    cover_image VARCHAR(255) COMMENT '封面图路径',
    location_id INT COMMENT '关联帮扶地编号',
    FOREIGN KEY (location_id) REFERENCES tb_location(location_id) ON DELETE SET NULL
) COMMENT='助农事件表';

-- 2.4 帮扶地打卡表 (一对一，依赖Location表)
CREATE TABLE tb_checkin (
    location_id INT PRIMARY KEY COMMENT '帮扶地编号（主键兼外键）',
    checkin_count INT DEFAULT 0 COMMENT '打卡次数',
    FOREIGN KEY (location_id) REFERENCES tb_location(location_id) ON DELETE CASCADE
) COMMENT='帮扶地打卡表';

-- 2.5 相册信息表 (独立展示)
CREATE TABLE tb_photo (
    photo_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '相册编号',
    title VARCHAR(100) COMMENT '相册标题',
    image_path VARCHAR(255) NOT NULL COMMENT '图片路径',
    category VARCHAR(50) COMMENT '分类（名场面/助农现场/丰收实拍）',
    upload_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间'
) COMMENT='相册信息表';

-- 2.6 留言信息表 (独立展示)
CREATE TABLE tb_message (
    message_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '留言编号',
    nickname VARCHAR(50) NOT NULL COMMENT '访客昵称',
    content VARCHAR(500) NOT NULL COMMENT '留言内容',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '留言时间'
) COMMENT='留言信息表';

-- 2.7 公益周边信息表 (独立展示，无支付)
CREATE TABLE tb_merchandise (
    merch_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '周边编号',
    name VARCHAR(100) NOT NULL COMMENT '商品名称',
    description VARCHAR(255) COMMENT '描述',
    image_path VARCHAR(255) COMMENT '图片路径',
    official_link VARCHAR(255) COMMENT '官方渠道链接'
) COMMENT='公益周边信息表';

-- ==========================================
-- 3. 创建视图 (Views)
-- ==========================================

-- 3.1 助农事件详情视图 (用于前端的助农时间线)
CREATE VIEW v_event_details AS
SELECT 
    e.event_id, e.title AS event_title, e.event_date,
    l.location_name, l.category AS location_category,
    e.content, e.cover_image
FROM tb_event e
LEFT JOIN tb_location l ON e.location_id = l.location_id;

-- 3.2 帮扶地打卡排名视图 (用于前端ECharts饼图或排行榜)
CREATE VIEW v_checkin_rank AS
SELECT 
    l.location_name, l.category, c.checkin_count
FROM tb_location l
JOIN tb_checkin c ON l.location_id = c.location_id
ORDER BY c.checkin_count DESC;

-- ==========================================
-- 4. 创建存储过程 (Stored Procedures)
-- ==========================================

-- 4.1 打卡计数存储过程 (前端点击“我为这里打call”时调用)
DELIMITER //
CREATE PROCEDURE sp_add_checkin(IN p_location_id INT)
BEGIN
    -- 尝试更新打卡次数
    UPDATE tb_checkin SET checkin_count = checkin_count + 1 WHERE location_id = p_location_id;
    -- 如果该帮扶地还没有记录，则插入初始记录
    IF ROW_COUNT() = 0 THEN
        INSERT INTO tb_checkin(location_id, checkin_count) VALUES(p_location_id, 1);
    END IF;
END //
DELIMITER ;

-- 4.2 新增助农事件存储过程 (后台管理员新增记录时调用，自动初始化打卡数据)
DELIMITER //
CREATE PROCEDURE sp_add_event(
    IN p_title VARCHAR(100),
    IN p_date DATE,
    IN p_content TEXT,
    IN p_location_id INT
)
BEGIN
    INSERT INTO tb_event(title, event_date, content, location_id) 
    VALUES(p_title, p_date, p_content, p_location_id);
    
    IF NOT EXISTS (SELECT 1 FROM tb_checkin WHERE location_id = p_location_id) THEN
        INSERT INTO tb_checkin(location_id, checkin_count) VALUES(p_location_id, 0);
    END IF;
END //
DELIMITER ;


-- ==========================================
-- 5. 预置测试数据 (DML) - 方便你立刻跑通前后端项目
-- ==========================================

-- 5.1 插入成员
INSERT INTO tb_member (name, role, intro) VALUES 
('蒋敦豪', '董事长', '十个勤天董事长'),
('鹭卓', '副董事长', '十个勤天副董事长'),
('李耕耘', '基建部部长', '负责基础建设');

-- 5.2 插入帮扶地 (分类包含水果、粮油、手作，供饼图演示)
INSERT INTO tb_location (location_name, category, description) VALUES 
('甘肃民勤', '水果', '沙漠蜜瓜助农'),
('黑龙江五常', '粮油', '五常大米助农'),
('福建屏南', '手作', '非遗手工制品');

-- 5.3 插入助农事件 (日期分布在不同月份，供柱状图演示)
INSERT INTO tb_event (title, event_date, content, location_id) VALUES 
('民勤蜜瓜直播专场', '2024-07-15', '帮助销售沙漠蜜瓜', 1),
('五常大米溯源直播', '2024-08-20', '了解水稻种植与收割', 2),
('屏南非遗手作展示', '2024-09-10', '宣传非遗手工艺品', 3);

-- 5.4 初始化打卡数据 (对应3个帮扶地)
INSERT INTO tb_checkin (location_id, checkin_count) VALUES (1, 125), (2, 86), (3, 42);

-- 5.5 插入相册、留言、周边测试数据
INSERT INTO tb_photo (title, image_path, category) VALUES 
('成员搬肥名场面', '/images/photo1.jpg', '名场面'),
('民勤收瓜现场', '/images/photo2.jpg', '助农现场'),
('丰收的喜悦', '/images/photo3.jpg', '丰收实拍');

INSERT INTO tb_message (nickname, content) VALUES 
('禾伙人', '十个勤天做大做强！'),
('小助理', '希望助农活动越来越好。');

INSERT INTO tb_merchandise (name, description, official_link) VALUES 
('助农大礼包', '包含各地特色农产品', 'https://example.com/goods1'),
('手工纪念品', '屏南非遗手工', 'https://example.com/goods2');
-- Local demonstration database. Importing this file replaces existing mall tables.
-- Brand/model/specification sourced from db/catalog.json. Prices and stock are demo values.
CREATE DATABASE IF NOT EXISTS mall CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE mall;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS `sys_user`;
DROP TABLE IF EXISTS `sms_seckill_session`;
DROP TABLE IF EXISTS `pms_product_img`;
DROP TABLE IF EXISTS `pms_product`;
DROP TABLE IF EXISTS `pms_category`;
DROP TABLE IF EXISTS `oms_order_item`;
DROP TABLE IF EXISTS `oms_order`;
DROP TABLE IF EXISTS `oms_cart`;
DROP TABLE IF EXISTS `cs_session`;
DROP TABLE IF EXISTS `cs_message`;
CREATE TABLE `cs_message` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '消息ID',
  `session_id` bigint NOT NULL COMMENT '关联会话ID (cs_session.id)',
  `type` varchar(16) NOT NULL COMMENT '发送方类型: user(用户) / assistant(客服)',
  `content` text NOT NULL COMMENT '消息文本内容',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  PRIMARY KEY (`id`),
  KEY `idx_session_create` (`session_id`,`create_time`)
) ENGINE=InnoDB AUTO_INCREMENT=62 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='客服消息明细表';

CREATE TABLE `cs_session` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '会话ID',
  `user_id` int NOT NULL COMMENT '用户ID',
  `title` varchar(100) NOT NULL DEFAULT '新对话' COMMENT '会话标题',
  `is_deleted` tinyint NOT NULL DEFAULT '0' COMMENT '逻辑删除: 0未删除 1已删除',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_update` (`user_id`,`update_time` DESC)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='客服会话表';

CREATE TABLE `oms_cart` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `product_id` int NOT NULL,
  `amount` int DEFAULT '1',
  `is_selected` int DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` int DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `oms_order` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '订单ID',
  `user_id` int NOT NULL COMMENT '用户ID',
  `seckill_session_id` int DEFAULT NULL COMMENT '秒杀场次ID（非秒杀订单为NULL）',
  `address_id` int DEFAULT NULL COMMENT '收货地址ID',
  `order_sn` varchar(64) NOT NULL COMMENT '订单编号',
  `payment_sn` varchar(64) DEFAULT '' COMMENT '支付单号',
  `total_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '订单总金额',
  `pay_method` int DEFAULT '0' COMMENT '支付方式（0=未选择，1=微信，2=支付宝）',
  `express_delivery` tinyint DEFAULT '0' COMMENT '快递公司（0=顺丰，1=百世，2=圆通，3=中通）',
  `status` int DEFAULT '0' COMMENT '订单状态（0=待支付，1=已支付，2=已发货，3=已收货，4=已取消）',
  `recipient_name` varchar(32) DEFAULT '' COMMENT '收件人姓名',
  `recipient_phone` varchar(20) DEFAULT '' COMMENT '收件人电话',
  `recipient_address` varchar(255) DEFAULT '' COMMENT '收件人地址',
  `payment_time` datetime DEFAULT NULL COMMENT '支付时间',
  `delivery_time` datetime DEFAULT NULL COMMENT '发货时间',
  `receipt_time` datetime DEFAULT NULL COMMENT '收货时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  `is_deleted` int DEFAULT '0' COMMENT '逻辑删除（0=正常，1=已删除）',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_seckill` (`user_id`,`seckill_session_id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `oms_order_item` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '订单项ID',
  `order_id` int NOT NULL COMMENT '订单ID',
  `product_id` int NOT NULL COMMENT '商品ID',
  `product_name` varchar(128) NOT NULL COMMENT '商品名称（下单时快照）',
  `product_img` varchar(512) DEFAULT '' COMMENT '商品图片',
  `product_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '商品成交单价',
  `amount` int DEFAULT '1' COMMENT '购买数量',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  `is_deleted` int DEFAULT '0' COMMENT '逻辑删除（0=正常，1=已删除）',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `pms_category` (
  `id` int NOT NULL AUTO_INCREMENT,
  `parent_id` int DEFAULT '0',
  `name` varchar(64) NOT NULL,
  `sort` int DEFAULT '0',
  `icon` varchar(255) DEFAULT '',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` int DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `pms_product` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '商品ID',
  `name` varchar(128) NOT NULL COMMENT '商品名称',
  `price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '商品原价',
  `stock` int DEFAULT '0' COMMENT '商品库存（秒杀下单时扣减此字段）',
  `detail` text COMMENT '商品详情',
  `category_id` int DEFAULT '0' COMMENT '分类ID',
  `status` int DEFAULT '1' COMMENT '商品状态（0=下架，1=上架）',
  `version` int DEFAULT '1' COMMENT '乐观锁版本号',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  `is_deleted` int DEFAULT '0' COMMENT '逻辑删除（0=正常，1=已删除）',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `pms_product_img` (
  `id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `url` varchar(512) NOT NULL,
  `sort` int DEFAULT '0',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` int DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `sms_seckill_session` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '场次ID',
  `product_id` int NOT NULL COMMENT '商品ID',
  `seckill_price` decimal(10,2) DEFAULT '0.00' COMMENT '秒杀价格',
  `seckill_stock` int DEFAULT '0' COMMENT '秒杀库存（加载至Redis作为初始库存）',
  `start_time` datetime NOT NULL COMMENT '秒杀开始时间',
  `end_time` datetime NOT NULL COMMENT '秒杀结束时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  `is_deleted` int DEFAULT '0' COMMENT '逻辑删除（0=正常，1=已删除）',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `sys_user` (
  `id` int NOT NULL AUTO_INCREMENT,
  `code` varchar(32) NOT NULL,
  `name` varchar(32) NOT NULL,
  `gender` int DEFAULT '0',
  `address` varchar(255) DEFAULT '',
  `pwd` varchar(255) NOT NULL,
  `avatar` varchar(255) DEFAULT '',
  `birthday` date DEFAULT NULL,
  `phone` varchar(20) DEFAULT '',
  `email` varchar(64) DEFAULT '',
  `remark` text,
  `role` int DEFAULT '0',
  `status` int DEFAULT '1',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_user_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=11000 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (1,0,'食品饮料',1,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (2,0,'生鲜果蔬',2,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (3,0,'家清日用',3,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (4,0,'服饰鞋包',4,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (5,0,'家具家纺',5,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (6,0,'家用电器',6,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (7,0,'数码电子',7,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (11,1,'粮油乳品',1,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (12,1,'零食饮品',2,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (21,2,'水果蔬菜',1,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (22,2,'肉蛋食品',2,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (31,3,'纸品清洁',1,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (32,3,'个护用品',2,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (41,4,'上衣袜品',1,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (42,4,'居家鞋履',2,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (51,5,'家具收纳',1,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (52,5,'床品家纺',2,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (61,6,'厨房小电',1,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (62,6,'大家电',2,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (71,7,'数码配件',1,'',0);
INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES (72,7,'电脑外设',2,'',0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (1,'蒙牛纯牛奶 250mL×24盒',58.90,120,'品牌：蒙牛；品名：纯牛奶；净含量：250mL/盒×24盒；包装：整箱；配料及保质期以实物标签为准。',11,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (1,1,'product-001.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (2,'金龙鱼寒地东北大米 5kg',42.90,95,'品牌：金龙鱼；品名：寒地东北大米；净含量：5kg；类型：粳米；包装：袋装。',11,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (2,2,'product-002.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (3,'鲁花5S压榨一级花生油 5L',189.00,70,'品牌：鲁花；系列：5S压榨；品名：一级花生油；净含量：5L；工艺：物理压榨。',11,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (3,3,'product-003.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (4,'都乐香蕉 约1kg装',19.90,90,'品牌：都乐 Dole；品名：香蕉；销售规格：约1kg/份；生鲜商品实际重量以配送称重为准。',21,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (4,4,'product-004.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (5,'佳沛阳光金果礼盒',89.00,55,'品牌：佳沛 Zespri；品名：阳光金果；包装：礼盒；具体果数、单果重量与产地以实物标签为准。',21,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (5,5,'product-005.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (6,'圣农冷冻鸡胸肉 1kg',39.90,65,'品牌：圣农；品名：冷冻鸡胸肉；净含量：1kg；储存方式：-18℃及以下冷冻；以包装标签为准。',22,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (6,6,'product-006.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (7,'维达超韧抽纸 3层100抽×24包',69.90,130,'品牌：维达；系列：超韧；规格：3层×100抽/包×24包；品类：抽取式面巾纸。',31,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (7,7,'product-007.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (8,'蓝月亮深层洁净洗衣液 自然清香 3kg',59.90,125,'品牌：蓝月亮；品名：深层洁净洗衣液；香型：自然清香；净含量：3kg；包装：瓶装。',31,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (8,8,'product-008.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (9,'云南白药牙膏 210g',29.90,145,'品牌：云南白药；品类：牙膏；净含量：210g；具体香型与功效以商品包装为准。',32,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (9,9,'product-009.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (10,'优衣库男装AIRism棉质圆领T恤 448819 白色',99.00,80,'品牌：优衣库 UNIQLO；商品编号：448819；系列：AIRism棉质圆领短袖T恤；颜色：白色；尺码需下单时确认。',41,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (10,10,'product-010.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (11,'李宁运动短袜 五双装 YWSU043-4',39.90,100,'品牌：李宁；商品编号：YWSU043-4；品类：运动短袜；包装：5双装；颜色和尺码以商品页面选项为准。',41,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (11,11,'product-011.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (12,'回力经典低帮帆布鞋 黑色',79.00,85,'品牌：回力；品类：低帮帆布鞋；颜色：黑色；尺码需下单时确认；具体鞋款以图片及实物为准。',42,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (12,12,'product-012.webp',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (13,'宜家BILLY毕利书柜 80×28×202cm 白色',599.00,30,'品牌：宜家 IKEA；系列：BILLY毕利；规格：宽80×深28×高202cm；颜色：白色；需组装。',51,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (13,13,'product-013.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (14,'宜家LACK拉克边桌 55×55cm 黑色',79.00,60,'品牌：宜家 IKEA；系列：LACK拉克；规格：宽55×深55×高45cm；颜色：黑色；需组装。',51,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (14,14,'product-014.webp',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (15,'宜家KALLAX卡莱克搁架 77×39×147cm',499.00,35,'品牌：宜家 IKEA；系列：KALLAX卡莱克；规格：77×39×147cm；颜色：白色；图片为横放搭配示意，收纳盒需另购。',51,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (15,15,'product-015.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (16,'美的电热水壶 MK-17S36A 1.7L',129.00,70,'品牌：美的 Midea；型号：MK-17S36A；容量：1.7L；额定功率：1500W；壶身：不锈钢。',61,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (16,16,'product-016.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (17,'米家电饭煲 N1 4L',249.00,50,'品牌：米家；型号：N1；容量：4L；品类：电饭煲；颜色：白色。',61,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (17,17,'product-017.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (18,'小米电视 A 55 2025款',2499.00,25,'品牌：小米 Xiaomi；系列：TV A；型号：55英寸2025款；分辨率：4K；具体配置依销售地区版本为准。',62,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (18,18,'product-018.png',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (19,'Redmi Buds 6 真无线耳机',199.00,70,'品牌：Redmi；型号：Buds 6；类型：真无线蓝牙耳机；颜色：薄荷绿；具体续航以官方版本为准。',71,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (19,19,'product-019.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (20,'罗技M185无线鼠标 黑灰色',69.00,100,'品牌：罗技 Logitech；型号：M185；连接：2.4GHz USB接收器；类型：无线光电鼠标；颜色：黑灰色。',72,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (20,20,'product-020.png',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (21,'小米充电宝10000mAh 22.5W Lite',89.00,95,'品牌：小米 Xiaomi；型号：10000mAh 22.5W Lite；标称容量：10000mAh；最大输出：22.5W；颜色：白色。',71,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (21,21,'product-021.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (22,'奥利奥原味夹心饼干 116g',9.90,160,'品牌：奥利奥 Oreo；口味：原味；净含量：116g；品类：夹心饼干；过敏原信息以包装为准。',12,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (22,22,'product-022.jpg',0,0);
INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES (23,'宜家DVALA德瓦拉被套枕套 白色',169.00,50,'品牌：宜家 IKEA；系列：DVALA德瓦拉；被套：150×200cm；枕套：50×80cm；颜色：白色；材质：棉。',52,1,1,0);
INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES (23,23,'product-023.jpg',0,0);
INSERT INTO sys_user (id,code,name,pwd,role,status,is_deleted) VALUES (1,'admin','管理员','$2a$10$lLLBS06gXc.vGYeQto8SEOMciEOY16lfu8o41PMWD12RUpWFpBqwe',1,1,0),(2,'user','演示用户','$2a$10$lLLBS06gXc.vGYeQto8SEOMciEOY16lfu8o41PMWD12RUpWFpBqwe',0,1,0);
SET FOREIGN_KEY_CHECKS=1;

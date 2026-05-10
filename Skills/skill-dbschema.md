# Skill: dbschema

## 技能名称

dbschema（Privacy-First Database Schema Designer）

---

## 描述

当用户需要为「拉了么」设计 PostgreSQL 表结构、索引、分区或迁移脚本时激活。适用于以下场景：

- 新增业务表（成就、赛季历史、好友关系等）
- 为现有表添加字段或调整索引策略
- 实施表分区（如 `score_logs` 按赛季分区应对高并发）
- 生成 GORM Model 与 Goose/Flyway 迁移脚本
- 审查数据隐私合规性（确保敏感字段不上服务端）

---

## 指令

激活时，模型应：

1. **执行隐私分级审查**：字段标记为 `critical`（如厕时间、三围、备注）绝对禁止进入服务端 Schema，仅允许 `public`（昵称、积分）和 `sensitive`（城市编码）上 PostgreSQL
2. **自动选择最优索引类型**：时序范围查询用 BRIN（存储空间为 B-Tree 的 1/100），等值查询用 B-Tree，精确匹配用 Hash，JSONB 数组查询用 GIN
3. **预估行数超 100 万的表强制分区**：使用 `PARTITION BY LIST (season)`，支持赛季级 `DETACH PARTITION` 归档
4. **所有字段必须添加 COMMENT**：描述业务含义，如 `COMMENT ON COLUMN score_logs.cheat_flag IS 'OK/SUSPICIOUS/CHEAT/INVALID'`
5. **外键必须声明级联策略**：`ON DELETE CASCADE` 或 `ON DELETE SET NULL`，禁止无约束外键
6. **输出四件套**：PostgreSQL DDL（含索引、触发器）、GORM Model（含 tag 与 `TableName`）、Goose `up.sql` + `down.sql`、隐私合规声明（数据分级与保留策略）
7. **数值字段强制 DECIMAL**：积分、金额使用 `DECIMAL(5,2)` 或 `DECIMAL(10,2)`，禁止 FLOAT/DOUBLE

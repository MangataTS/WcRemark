# Skill: redisrank

## 技能名称

redisrank（Redis Ranking Operator）

---

## 描述

当用户需要为「拉了么」实现或优化排行榜功能时激活。适用于以下场景：

- 新增排行榜类型（全球榜、同城榜、好友榜、趣味榜）
- 赛季切换时重置或迁移排行榜数据
- 优化高并发积分更新（Pipeline、Lua 原子脚本）
- 实现分页查询、附近排名、滑动窗口限流

---

## 指令

激活时，模型应：

1. **Key 命名严格遵循规范**：`{scope}:{entity}:{identifier}[:{sub_scope}]`，如 `global:ranking:2026-05`、`city:ranking:510100:2026-05`，所有 Key 必须设置 TTL（赛季结束后 30 天）
2. **积分更新必须使用 ZINCRBY**：禁止 ZADD 覆盖，保证并发安全；Member 必须为 string 类型（`fmt.Sprintf("%d", userID)`）
3. **批量操作使用 Pipeline**：赛季初始化、好友榜批量添加时，单次 Pipeline 元素数不超过 1000，防止阻塞 Redis 单线程
4. **赛季切换使用 Lua 原子脚本**：`ZRANGE` 读取旧榜 → `ZADD` 写入新榜 → `EXPIRE` 设置 TTL，三步原子完成
5. **分页查询禁止大偏移**：使用 `ZREVRANGE` 的 start/stop 索引，禁止 `SKIP`；超过 1 亿元素时按 `global:ranking:{season}:{shard}` 拆分
6. **限流使用滑动窗口**：`ZRemRangeByScore` 清理过期窗口 → `ZAdd` 当前请求 → `ZCard` 统计 → `Expire` 续期，拒绝使用 `KEYS` 命令
7. **输出三类内容**：Key 设计文档（含 TTL 策略）、go-redis/v9 Repository 代码（含 `IncrementScore`、`GetTopN`、`GetNearby`）、性能优化建议（本地缓存兜底策略）

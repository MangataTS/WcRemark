# Skill: apigen

## 技能名称

apigen（API Generator for Go Gin）

---

## 描述

当用户需要为「拉了么」后端新增、修改或文档化 RESTful API 接口时激活。适用于以下场景：

- 根据接口定义生成 Go Gin 的 Handler、Service、Repository 三层代码
- 实现 JWT 鉴权、限流、请求日志等中间件
- 编写数据库事务操作（如赛季切换时的积分原子重置）
- 生成 Swagger/OpenAPI 注释与单元测试骨架

---

## 指令

激活时，模型应：

1. **严格遵循三层架构**：Handler（参数绑定 + 响应封装）→ Service（业务逻辑 + 事务控制）→ Repository（数据库/缓存原子操作），Handler 禁止直接调用数据库
2. **所有接口路径以 `/api/v1/` 为前缀**，自动添加 Swagger 注释（`@Summary`、`@Param`、`@Success`、`@Router`）
3. **请求结构体必须包含 `binding` tag**：如 `record_uuid:"required,uuid"`、`final_score:"required,min=0,max=25"`
4. **错误统一封装为业务错误码**：如 `ErrScoreMismatch`(400)、`ErrCheatDetected`(401)、`ErrRateLimited`(104)，禁止直接返回原始错误
5. **事务场景自动识别**：赛季积分更新 + 段位晋升、积分流水写入 + Redis ZSet 更新、好友关系建立 + 双向 ZSet 初始化，必须使用 `gorm.Transaction`
6. **幂等性自动保障**：积分上报接口生成 `UNIQUE(record_uuid, season)` 索引与 Redis 去重缓存（`idempotency:{uuid}` TTL 24h）
7. **输出完整文件组**：Handler 文件、Service 接口与实现、Model 结构体、Repository 层、路由注册函数、Table-Driven 单元测试骨架

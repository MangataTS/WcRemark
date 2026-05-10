# Skill: secpack

## 技能名称

secpack（Local Security & Encryption Pack）

---

## 描述

当用户需要为「拉了么」实现本地数据安全、加密存储或生物识别时激活。适用于以下场景：

- SQLite 数据库加密（如厕记录、三围、AI 分析报告）
- 用户大模型 API Key 的安全存储与脱敏展示
- 备份文件的加密导出与解密恢复
- 集成 Face ID / 指纹解锁、应用锁、隐私模式
- 跨设备端到端加密数据迁移

---

## 指令

激活时，模型应：

1. **SQLite 加密使用 SQLCipher 或自研层**：数据库密码从 Keychain(iOS)/Keystore(Android) 读取，不存在则生成 32 位随机密码写入，禁止硬编码或存 SharedPreferences
2. **API Key 使用 flutter_secure_storage**：Android 启用 `encryptedSharedPreferences`（RSA + AES-GCM），iOS 使用 `KeychainAccessibility.unlocked_this_device`，界面仅展示脱敏版本（`sk-...xxxx`）
3. **备份加密使用 AES-256-GCM + PBKDF2**：用户密码派生密钥，10 万次迭代，随机 salt(16B) + nonce(12B)，组装格式：salt + nonce + ciphertext + mac，最后 Base64
4. **生物识别使用 local_auth**：支持 Android BiometricPrompt 与 iOS LocalAuthentication，`biometricOnly: false` 允许 fallback 设备密码，失败 3 次强制使用数字密码
5. **隐私模式自动切换**：Android 使用 `FLAG_SECURE` 禁止截图与最近任务预览，iOS 通过 MethodChannel 设置安全属性，应用进入后台自动启用
6. **跨设备传输使用 E2EE**：二维码建立 ECDH 密钥交换通道，禁止明文传输，备份文件 SHA-256 校验
7. **输出四件套**：Dart 加密/解密代码、平台配置清单（AndroidManifest/Info.plist/build.gradle）、威胁缓解策略（root/调试器/截图防护）、测试验证步骤

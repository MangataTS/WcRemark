#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
ANDROID_HOME="${PROJECT_ROOT}/android-sdk"
JAVA_HOME="/opt/homebrew/opt/openjdk@17"
FLUTTER_DIR="${PROJECT_ROOT}/la-le-me-app"
DIST_DIR="${PROJECT_ROOT}/dist"
APK_PATH="${DIST_DIR}/la-le-me-app-release.apk"

export JAVA_HOME
export PATH="${JAVA_HOME}/bin:${PATH}"

echo "========================================="
echo "  拉了么 - APP 信息获取脚本"
echo "========================================="
echo ""

# ────────────────────────────────────────
# 1. 获取包名
# ────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  1. 包名 (Package Name)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

GRADLE_FILE="${FLUTTER_DIR}/android/app/build.gradle.kts"
if [ -f "$GRADLE_FILE" ]; then
    PACKAGE_NAME=$(grep -E '^\s*applicationId\s*=' "$GRADLE_FILE" | head -1 | sed 's/.*"\(.*\)".*/\1/')
    if [ -z "$PACKAGE_NAME" ]; then
        PACKAGE_NAME=$(grep -E '^\s*namespace\s*=' "$GRADLE_FILE" | head -1 | sed 's/.*"\(.*\)".*/\1/')
    fi
    echo "  applicationId: $PACKAGE_NAME"
    echo "  来源: build.gradle.kts"
else
    echo "  [错误] 未找到 build.gradle.kts"
    PACKAGE_NAME="未知"
fi

# ────────────────────────────────────────
# 2. 获取 APP 版本信息
# ────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  2. 版本信息"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PUBSPEC="${FLUTTER_DIR}/pubspec.yaml"
if [ -f "$PUBSPEC" ]; then
    VERSION=$(grep '^version:' "$PUBSPEC" | head -1 | awk '{print $2}')
    echo "  version: $VERSION"
    echo "  来源: pubspec.yaml"
fi

# ────────────────────────────────────────
# 3. 签名信息
# ────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  3. 签名证书指纹 (Digital Fingerprint)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

KEY_PROPERTIES="${FLUTTER_DIR}/android/key.properties"
FOUND_CERT=false

# 3a. 尝试从 keystore 提取
if [ -f "$KEY_PROPERTIES" ]; then
    echo "  发现 key.properties，正在读取密钥库信息..."
    
    while IFS='=' read -r key value; do
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        case "$key" in
            storeFile)     STORE_FILE="$value" ;;
            storePassword) STORE_PASS="$value" ;;
            keyAlias)      KEY_ALIAS="$value" ;;
            keyPassword)   KEY_PASS="$value" ;;
        esac
    done < "$KEY_PROPERTIES"
    
    KEY_PROP_DIR="$(dirname "$KEY_PROPERTIES")"
    if [ -n "$STORE_FILE" ]; then
        KEYSTORE_PATH="$(cd "$KEY_PROP_DIR" 2>/dev/null && realpath "$STORE_FILE" 2>/dev/null || echo "${KEY_PROP_DIR}/${STORE_FILE}")"
    fi
    
    # 回退到默认 keystore 位置
    if [ ! -f "${KEYSTORE_PATH:-}" ]; then
        DEFAULT_KEYSTORE="${FLUTTER_DIR}/android/app/kaptree.keystore"
        if [ -f "$DEFAULT_KEYSTORE" ]; then
            KEYSTORE_PATH="$DEFAULT_KEYSTORE"
        fi
    fi
    
    if [ -n "$KEYSTORE_PATH" ] && [ -f "$KEYSTORE_PATH" ]; then
        echo "  密钥库: $KEYSTORE_PATH"
        echo "  别名: ${KEY_ALIAS:-未知}"
        echo ""
        
        if command -v keytool &>/dev/null; then
            CERT_OUTPUT=$(keytool -list -v -keystore "$KEYSTORE_PATH" \
                -alias "$KEY_ALIAS" \
                -storepass "$STORE_PASS" \
                -keypass "$KEY_PASS" 2>/dev/null) || true
            
            if [ -n "$CERT_OUTPUT" ]; then
                # 打印 keytool 输出中的证书信息
                echo "$CERT_OUTPUT" | grep -E "^\s*(所有者|发布者|序列号|生效时间|SHA1|SHA256|签名算法|主体公共密钥|版本)" | sed 's/^/  /'
                
                # 使用 openssl 计算 MD5 + SHA1 + SHA256 指纹
                if command -v openssl &>/dev/null; then
                    TMP_CERT="$(mktemp)"
                    if keytool -exportcert \
                        -keystore "$KEYSTORE_PATH" \
                        -alias "$KEY_ALIAS" \
                        -storepass "$STORE_PASS" \
                        -file "$TMP_CERT" 2>/dev/null; then
                        MD5_FP=$(openssl x509 -inform der -in "$TMP_CERT" -fingerprint -md5 -noout 2>/dev/null | sed 's/.*=//')
                        SHA1_FP=$(openssl x509 -inform der -in "$TMP_CERT" -fingerprint -sha1 -noout 2>/dev/null | sed 's/.*=//')
                        SHA256_FP=$(openssl x509 -inform der -in "$TMP_CERT" -fingerprint -sha256 -noout 2>/dev/null | sed 's/.*=//')
                        rm -f "$TMP_CERT"
                        
                        echo ""
                        echo "  ── 数字指纹摘要（所有算法）──"
                        [ -n "$MD5_FP" ]    && echo "   MD5:    $MD5_FP"
                        [ -n "$SHA1_FP" ]   && echo "   SHA1:   $SHA1_FP"
                        [ -n "$SHA256_FP" ] && echo "   SHA256: $SHA256_FP"
                    else
                        rm -f "$TMP_CERT"
                    fi
                fi
                
                FOUND_CERT=true
            else
                echo "  [错误] keytool 无法读取证书信息"
            fi
        else
            echo "  [提示] 未找到 keytool，请确保 JAVA_HOME 设置正确"
        fi
    else
        echo "  [提示] 未找到密钥库文件: ${KEYSTORE_PATH:-未设置}"
    fi
else
    echo "  未找到 key.properties（签名密钥库配置）"
fi

# 3b. 如果 keystore 不可用，尝试从 APK 提取
if [ "$FOUND_CERT" != true ]; then
    echo ""
    echo "  尝试从已构建的 APK 获取签名信息..."
    
    APK_FOUND=false
    for apk_candidate in \
        "$APK_PATH" \
        "${FLUTTER_DIR}/build/app/outputs/flutter-apk/app-release.apk" \
        "${FLUTTER_DIR}/build/app/outputs/flutter-apk/app-debug.apk"; do
        if [ -f "$apk_candidate" ]; then
            APK_PATH_USE="$apk_candidate"
            APK_FOUND=true
            echo "  找到 APK: $apk_candidate"
            break
        fi
    done
    
    if [ "$APK_FOUND" = true ]; then
        if command -v keytool &>/dev/null; then
            APK_CERT=$(keytool -printcert -jarfile "$APK_PATH_USE" 2>/dev/null) || true
            if [ -n "$APK_CERT" ]; then
                echo ""
                echo "$APK_CERT" | sed 's/^/  /'

                # 通过 openssl 从 APK 提取 MD5/SHA1/SHA256
                if command -v openssl &>/dev/null; then
                    RSA_FILE=$(unzip -l "$APK_PATH_USE" 2>/dev/null | grep -o 'META-INF/.*\.RSA' | head -1)
                    if [ -n "$RSA_FILE" ]; then
                        TMP_CERT="$(mktemp)"
                        if unzip -p "$APK_PATH_USE" "$RSA_FILE" > "$TMP_CERT" 2>/dev/null; then
                            MD5_FP=$(openssl x509 -inform der -in "$TMP_CERT" -fingerprint -md5 -noout 2>/dev/null | sed 's/.*=//')
                            SHA1_FP=$(openssl x509 -inform der -in "$TMP_CERT" -fingerprint -sha1 -noout 2>/dev/null | sed 's/.*=//')
                            SHA256_FP=$(openssl x509 -inform der -in "$TMP_CERT" -fingerprint -sha256 -noout 2>/dev/null | sed 's/.*=//')
                            rm -f "$TMP_CERT"
                            echo ""
                            echo "  ── 数字指纹摘要（所有算法）──"
                            [ -n "$MD5_FP" ]    && echo "   MD5:    $MD5_FP"
                            [ -n "$SHA1_FP" ]   && echo "   SHA1:   $SHA1_FP"
                            [ -n "$SHA256_FP" ] && echo "   SHA256: $SHA256_FP"
                        else
                            rm -f "$TMP_CERT"
                        fi
                    fi
                fi
                FOUND_CERT=true
            else
                echo "  APK 未签名（不是已签名的 jar 文件）"
            fi
        fi
    else
        echo "  未找到已构建的 APK 文件"
    fi
fi

# ────────────────────────────────────────
# 4. 总结
# ────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  4. 说明"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  包名 (applicationId) 在 build.gradle.kts 中定义，除非手动"
echo "  修改，否则不会随代码迭代而变化。"
echo ""
echo "  签名证书指纹（MD5/SHA1/SHA256）绑定于 Keystore 文件中的证书，"
echo "  只要未更换 keystore / 签名证书，这些指纹值永久有效，"
echo "  不受源代码改动影响。"
echo ""
echo "  当前项目使用 RSA 2048-bit 密钥，有效期至 2053-09-26。"

echo ""
echo "========================================="
echo "  完成"
echo "========================================="

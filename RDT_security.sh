#!/system/bin/sh

# ====================================================================
#  脚本名称: XIKIUM Security Suite
#  作者: XIKIUM
#  版本: v9.0
#  核心功能: 
#    1. 使用GitHub验证文件进行第一阶段验证
#    2. 免root环境安全检测
#    3. 自动化修复机制
#  
#  XIKIUM_SIGNATURE: xikium_verified_script_v9
#  XIKIUM_HASH: 5f4dcc3b5aa765d61d8327deb882cf99
# ====================================================================

# 全局设置
WORK_DIR="/sdcard/XIKIUM"  # 使用SD卡避免权限问题
LOG_FILE="$WORK_DIR/xikium.log"
VERIFICATION_URL="https://raw.githubusercontent.com/RobloxOptimizeCloudLibrary/MyShellFile/refs/heads/main/FirstVerifyFile.hpp"
EXPECTED_CONTENT="Successfully passed the first authentication"

# 初始化环境
init_environment() {
    # 创建工作目录
    mkdir -p "$WORK_DIR"
    
    # 初始化日志
    echo "===== XIKIUM Security Suite v9.0 Log =====" > "$LOG_FILE"
    echo "Start Time: $(date)" >> "$LOG_FILE"
    echo "Device: $(getprop ro.product.model)" >> "$LOG_FILE"
    echo "Android: $(getprop ro.build.version.release)" >> "$LOG_FILE"
}

# 高级签名验证系统 2.0 (优化版)
verify_signature() {
    local file="$1"
    echo "[*] 启动XIKIUM-SecureLock v2.0" | tee -a "$LOG_FILE"
    
    # 检查关键签名行
    local signature_line=$(grep "XIKIUM_SIGNATURE" "$file")
    local hash_line=$(grep "XIKIUM_HASH" "$file")
    
    if [ -z "$signature_line" ] || [ -z "$hash_line" ]; then
        echo "[!] 关键签名数据缺失" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # 提取签名值
    local stored_signature=$(echo "$signature_line" | awk -F': ' '{print $2}')
    local stored_hash=$(echo "$hash_line" | awk -F': ' '{print $2}')
    
    # 简单但有效的验证 (免root环境优化)
    if [ "$stored_signature" = "xikium_verified_script_v9" ] && [ "$stored_hash" = "5f4dcc3b5aa765d61d8327deb882cf99" ]; then
        echo "[✓] 签名验证成功" | tee -a "$LOG_FILE"
        return 0
    else
        echo "[!] 签名验证失败" | tee -a "$LOG_FILE"
        echo "  存储签名: $stored_signature" | tee -a "$LOG_FILE"
        echo "  预期签名: xikium_verified_script_v9" | tee -a "$LOG_FILE"
        echo "  存储哈希: $stored_hash" | tee -a "$LOG_FILE"
        echo "  预期哈希: 5f4dcc3b5aa765d61d8327deb882cf99" | tee -a "$LOG_FILE"
        return 1
    fi
}

# 第一阶段验证 - 使用GitHub验证文件
first_verification() {
    echo "[*] 启动第一阶段验证" | tee -a "$LOG_FILE"
    echo "  验证URL: $VERIFICATION_URL" | tee -a "$LOG_FILE"
    
    local temp_file="$WORK_DIR/verify_temp.txt"
    rm -f "$temp_file"
    
    # 尝试使用curl下载
    if command -v curl >/dev/null; then
        echo "  尝试使用curl..." | tee -a "$LOG_FILE"
        curl -s -k -o "$temp_file" "$VERIFICATION_URL" 2>/dev/null
    fi
    
    # 如果curl失败，尝试使用wget
    if [ ! -f "$temp_file" ] || [ ! -s "$temp_file" ]; then
        if command -v wget >/dev/null; then
            echo "  尝试使用wget..." | tee -a "$LOG_FILE"
            wget --no-check-certificate -qO "$temp_file" "$VERIFICATION_URL" 2>/dev/null
        fi
    fi
    
    # 如果wget也失败，尝试使用busybox
    if [ ! -f "$temp_file" ] || [ ! -s "$temp_file" ]; then
        if command -v busybox >/dev/null; then
            echo "  尝试使用busybox wget..." | tee -a "$LOG_FILE"
            busybox wget --no-check-certificate -qO "$temp_file" "$VERIFICATION_URL" 2>/dev/null
        fi
    fi
    
    # 检查下载结果
    if [ ! -f "$temp_file" ] || [ ! -s "$temp_file" ]; then
        echo "[!] 无法下载验证文件" | tee -a "$LOG_FILE"
        echo "  请检查网络连接" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # 检查文件内容
    local content=$(cat "$temp_file")
    if echo "$content" | grep -q "$EXPECTED_CONTENT"; then
        echo "[✓] 第一阶段验证成功" | tee -a "$LOG_FILE"
        rm -f "$temp_file"
        return 0
    else
        echo "[!] 验证文件内容不匹配" | tee -a "$LOG_FILE"
        echo "  预期内容: $EXPECTED_CONTENT" | tee -a "$LOG_FILE"
        echo "  实际内容: $content" | tee -a "$LOG_FILE"
        return 1
    fi
}

# 安全的Root管理器检测 (免root环境)
detect_root_managers() {
    echo "[*] 启动安全Root检测" | tee -a "$LOG_FILE"
    local found=0
    
    # 通过包管理器检测
    echo "  扫描已安装应用..." | tee -a "$LOG_FILE"
    for pkg in "me.weishu.kernelsu" "com.topjohnwu.magisk" "com.sukisu.ultra"; do
        if pm path "$pkg" >/dev/null 2>&1; then
            echo "  [!] 检测到Root管理器: $pkg" | tee -a "$LOG_FILE"
            found=1
        fi
    done
    
    # 通过文件系统检测 (非特权路径)
    echo "  扫描公共存储区域..." | tee -a "$LOG_FILE"
    for dir in "/sdcard" "/sdcard/Download"; do
        for file in "magisk" "kernelsu" "sukisu"; do
            if ls "$dir"/* 2>/dev/null | grep -iq "$file"; then
                echo "  [!] 检测到可疑文件: $dir/$file" | tee -a "$LOG_FILE"
                found=1
            fi
        done
    done
    
    if [ $found -eq 0 ]; then
        echo "  [✓] 未检测到Root管理器" | tee -a "$LOG_FILE"
    fi
    
    return $found
}

# 自动化修复机制
auto_repair() {
    echo "[!] 启动自动修复系统" | tee -a "$LOG_FILE"
    
    # 下载官方脚本
    echo "  下载最新官方版本..." | tee -a "$LOG_FILE"
    local official_url="https://raw.githubusercontent.com/RobloxOptimizeCloudLibrary/MyShellFile/refs/heads/main/xikium_security.sh"
    local download_path="$WORK_DIR/xikium_official.sh"
    
    # 使用系统工具下载
    if command -v curl >/dev/null; then
        curl -s -k -o "$download_path" "$official_url"
    elif command -v wget >/dev/null; then
        wget -q -O "$download_path" "$official_url"
    else
        echo "  [!] 无法下载：缺少网络工具" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # 验证下载
    if [ ! -f "$download_path" ]; then
        echo "  [!] 下载失败" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # 验证签名
    if ! verify_signature "$download_path"; then
        echo "  [!] 下载文件签名验证失败" | tee -a "$LOG_FILE"
        rm -f "$download_path"
        return 1
    fi
    
    # 替换当前脚本
    echo "  更新脚本..." | tee -a "$LOG_FILE"
    cp "$download_path" "$0"
    chmod +x "$0"
    
    echo "  [✓] 自动修复完成" | tee -a "$LOG_FILE"
    return 0
}

# 主界面
show_menu() {
    clear
    echo "╔══════════════════════════════════════════════════╗"
    echo "║            XIKIUM Security Suite v9.0             ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║ 1. 运行安全检查                                  ║"
    echo "║ 2. 检查脚本完整性                                ║"
    echo "║ 3. 更新到最新版本                                ║"
    echo "║ 4. 查看安全日志                                  ║"
    echo "║ 0. 退出                                          ║"
    echo "╚══════════════════════════════════════════════════╝"
}

# 主功能
main() {
    init_environment
    
    # 首次签名验证
    if ! verify_signature "$0"; then
        echo "  [!] 脚本完整性验证失败" | tee -a "$LOG_FILE"
        echo "  尝试自动修复..." | tee -a "$LOG_FILE"
        if ! auto_repair; then
            echo "[!] 自动修复失败，请联系技术支持" | tee -a "$LOG_FILE"
            return 1
        fi
        
        # 重启修复后的脚本
        echo "[*] 重启修复后的脚本..." | tee -a "$LOG_FILE"
        exec "$0"
    fi
    
    # 主界面循环
    while true; do
        show_menu
        echo -n "请选择操作: "
        read choice
        
        case $choice in
            1) # 运行安全检查
                echo "\n[安全检测]" | tee -a "$LOG_FILE"
                
                # 第一阶段验证
                if ! first_verification; then
                    echo "[!] 第一阶段验证失败" | tee -a "$LOG_FILE"
                else
                    # Root检测
                    detect_root_managers
                    echo "\n安全评估:"
                    if [ $? -eq 0 ]; then
                        echo "  ✅ 设备安全 (未检测到Root管理器)" | tee -a "$LOG_FILE"
                    else
                        echo "  ⚠️ 安全风险 (检测到Root管理器)" | tee -a "$LOG_FILE"
                    fi
                fi
                ;;
            2) # 检查脚本完整性
                echo "\n[脚本完整性检查]" | tee -a "$LOG_FILE"
                if verify_signature "$0"; then
                    echo "  ✅ 脚本完整性验证成功" | tee -a "$LOG_FILE"
                else
                    echo "  [!] 脚本完整性验证失败" | tee -a "$LOG_FILE"
                fi
                ;;
            3) # 更新到最新版本
                echo "\n[更新系统]" | tee -a "$LOG_FILE"
                auto_repair
                ;;
            4) # 查看安全日志
                echo "\n[安全日志]"
                cat "$LOG_FILE"
                ;;
            0) # 退出
                echo "感谢使用XIKIUM Security Suite" | tee -a "$LOG_FILE"
                exit 0
                ;;
            *) # 无效选项
                echo "无效选择，请重新输入"
                ;;
        esac
        
        echo -n "\n按回车键继续..."
        read
    done
}

# 主入口
main

# 脚本结束
echo "\n检测结束时间: $(date)" >> "$LOG_FILE"
exit 0

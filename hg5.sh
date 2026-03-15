#!/bin/bash

# ==================================================
# Hg5 恐怖加密系统 (Shell 版) - 200层加密
# 作者: github:Admintt73
# 兼容: Termux/Linux/macOS/Windows (Git Bash)
# 依赖: openssl, xxd (通常预装或可安装)
# ==================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 跨平台清屏
clear_screen() {
    case "$(uname -s)" in
        Linux|Darwin)   clear ;;
        CYGWIN*|MINGW*|MSYS*) clear ;;
        *)              printf "\033c" ;;
    esac
}

# 显示标志
show_logo() {
    echo -e "${RED}"
    echo "  ██╗  ██╗ ██████╗ ███████╗"
    echo "  ██║  ██║██╔════╝ ██╔════╝"
    echo "  ███████║██║  ███╗███████╗"
    echo "  ██╔══██║██║   ██║╚════██║"
    echo "  ██║  ██║╚██████╔╝███████║"
    echo "  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
    echo -e "${YELLOW}"
    echo "  ████████╗███████╗██████╗ ██████╗  ██████╗ ██████╗ "
    echo "  ╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔═══██╗██╔══██╗"
    echo "     ██║   █████╗  ██████╔╝██████╔╝██║   ██║██████╔╝"
    echo "     ██║   ██╔══╝  ██╔══██╗██╔══██╗██║   ██║██╔══██╗"
    echo "     ██║   ███████╗██║  ██║██║  ██║╚██████╔╝██║  ██║"
    echo "     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝"
    echo -e "${NC}"
    echo "  ╔═══════════════════════════════════════════════╗"
    echo -e "  ║     ${GREEN}Hg5 TERROR ENCRYPTION SYSTEM v4.0${NC}        ║"
    echo -e "  ║         ${CYAN}Author: github:Admintt73${NC}             ║"
    echo -e "  ║     ${YELLOW}\"200层加密，恐怖如斯，无人能破\"${NC}          ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    echo ""
}

# 检查依赖
check_deps() {
    if ! command -v openssl &> /dev/null; then
        echo -e "${RED}[-] 错误：未找到 openssl，请先安装。${NC}"
        echo "   Termux: pkg install openssl"
        echo "   Ubuntu: sudo apt install openssl"
        echo "   macOS: 已预装"
        exit 1
    fi
    if ! command -v xxd &> /dev/null; then
        echo -e "${RED}[-] 错误：未找到 xxd，请先安装。${NC}"
        echo "   Termux: pkg install xxd"
        echo "   Ubuntu: sudo apt install xxd"
        exit 1
    fi
}

# 进度条 (显示当前层数)
show_progress() {
    local current=$1
    local total=$2
    local msg=$3
    local bar_width=30
    local percent=$((current * 100 / total))
    local filled=$((current * bar_width / total))
    local empty=$((bar_width - filled))

    printf "\r${msg} ["
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%%  (层 %d/%d)" $percent $current $total
}

# 从主密钥和层号派生 AES-256 密钥 (32字节) 和 IV (16字节)
derive_key_iv() {
    local master_key="$1"
    local layer=$2
    # 使用 sha256 生成密钥: echo -n "master_key_layer_X" | sha256sum
    local combined="${master_key}_layer_${layer}"
    # 取前32字节作为密钥，后16字节作为IV (实际sha256输出64字符 hex = 32字节)
    local hash=$(echo -n "$combined" | openssl dgst -sha256 -binary | xxd -p -c 64)
    # 密钥: 整个hash (32字节)
    local key=$(echo -n "$hash" | cut -c1-64)  # 32字节 hex
    # IV: 再用一次sha256并取前16字节
    local iv=$(echo -n "$combined$key" | openssl dgst -sha256 -binary | xxd -p -c 64 | cut -c1-32)
    echo "$key $iv"
}

# 多层加密
encrypt_file() {
    local in_file="$1"
    local master_key="$2"
    local layers=$3
    local out_file="${in_file}.hg5"

    # 创建临时文件
    local tmp_in=$(mktemp)
    local tmp_out=$(mktemp)
    cp "$in_file" "$tmp_in"

    echo -e "${GREEN}[+]${NC} 原始文件大小: $(stat -c%s "$in_file" 2>/dev/null || stat -f%z "$in_file") 字节"
    echo -e "${GREEN}[+]${NC} 开始 $layers 层加密..."

    for ((layer=0; layer<layers; layer++)); do
        # 派生当前层密钥和IV
        read key_hex iv_hex <<< $(derive_key_iv "$master_key" $layer)

        # 执行加密 (AES-256-CBC, PKCS7填充)
        openssl enc -aes-256-cbc -e -in "$tmp_in" -out "$tmp_out" -K "$key_hex" -iv "$iv_hex" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "${RED}[-] 加密失败，可能文件损坏${NC}"
            rm -f "$tmp_in" "$tmp_out"
            return 1
        fi

        # 交换临时文件
        mv "$tmp_out" "$tmp_in"

        show_progress $((layer+1)) $layers "加密进度"
    done
    echo ""

    # 移动最终结果到输出文件
    mv "$tmp_in" "$out_file"
    echo -e "${GREEN}[+]${NC} 加密完成！输出文件: $out_file"
    return 0
}

# 多层解密
decrypt_file() {
    local in_file="$1"
    local master_key="$2"
    local layers=$3

    # 检查后缀
    if [[ ! "$in_file" =~ \.hg5$ ]]; then
        echo -e "${RED}[-] 错误：输入文件不是 .hg5 加密文件！${NC}"
        return 1
    fi

    local out_file="${in_file%.hg5}"

    # 创建临时文件
    local tmp_in=$(mktemp)
    local tmp_out=$(mktemp)
    cp "$in_file" "$tmp_in"

    echo -e "${GREEN}[+]${NC} 密文大小: $(stat -c%s "$in_file" 2>/dev/null || stat -f%z "$in_file") 字节"
    echo -e "${GREEN}[+]${NC} 开始 $layers 层解密..."

    for ((layer=layers-1; layer>=0; layer--)); do
        # 派生当前层密钥和IV (与加密相同)
        read key_hex iv_hex <<< $(derive_key_iv "$master_key" $layer)

        # 执行解密
        openssl enc -aes-256-cbc -d -in "$tmp_in" -out "$tmp_out" -K "$key_hex" -iv "$iv_hex" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "${RED}[-] 解密失败，可能密钥或层数错误！${NC}"
            rm -f "$tmp_in" "$tmp_out"
            return 1
        fi

        mv "$tmp_out" "$tmp_in"

        show_progress $((layers - layer)) $layers "解密进度"
    done
    echo ""

    # 移动最终结果到输出文件
    mv "$tmp_in" "$out_file"
    echo -e "${GREEN}[+]${NC} 解密完成！输出文件: $out_file"
    return 0
}

# 检查文件是否存在
file_exists() {
    [ -f "$1" ]
}

# 获取输入（修复版：去掉 -n，保证终端正常显示输入）
get_input() {
    local prompt="$1"
    local var
    echo "$prompt"  # 关键修复：把 echo -n 改成 echo，让提示符换行
    read -r var
    echo "$var"
}

# 主程序
main() {
    check_deps
    clear_screen
    show_logo

    echo -e "${CYAN}[系统信息]${NC} 初始化完成，兼容 Termux/Linux/macOS/Windows"
    echo -e "${CYAN}[系统信息]${NC} 无需 root 权限"
    echo -e "${CYAN}[系统信息]${NC} 使用 OpenSSL AES-256-CBC 实现多层加密"
    echo -e "${CYAN}[系统信息]${NC} 支持最高 200 层加密（可自定义层数）\n"

    while true; do
        echo ""
        echo "╔════════════════════════════════════╗"
        echo "║           主菜单                   ║"
        echo "╠════════════════════════════════════╣"
        echo "║  [1] 🔐 加密文件                   ║"
        echo "║  [2] 🔓 解密文件                   ║"
        echo "║  [3] ℹ️  关于系统                   ║"
        echo "║  [0] 🚪 退出系统                   ║"
        echo "╚════════════════════════════════════╝"

        # 修复：直接用 read 读取，避免 get_input 嵌套导致的缓冲问题
        echo  -e "\n[?] 请输入选择 [0-3]: "
        read -r choice

        case $choice in
            0)
                echo -e "\n${YELLOW}[!]${NC} 感谢使用 Hg5 恐怖加密系统！"
                echo -e "${YELLOW}[!]${NC} 作者: github:Admintt73"
                echo -e "${YELLOW}[!]${NC} 再见...\n"
                exit 0
                ;;
            3)
                clear_screen
                show_logo
                echo ""
                echo "╔═══════════════════════════════════════════╗"
                echo "║           关于 Hg5 加密系统              ║"
                echo "╠═══════════════════════════════════════════╣"
                echo "║ 版本: v4.0 (200层恐怖版)                  ║"
                echo "║ 作者: github:Admintt73                    ║"
                echo "║ 算法: AES-256-CBC × 200层                 ║"
                echo "║ 密钥: 每层独立256位密钥 + 128位IV         ║"
                echo "║ 派生: SHA256(主密钥_layer_层号)           ║"
                echo "║ 兼容: Termux/Windows/Linux/macOS         ║"
                echo "║ 权限: 无需Root                           ║"
                echo "╚═══════════════════════════════════════════╝"
                echo -e "\n${YELLOW}[!]${NC} 按回车键返回主菜单..."
                read -r
                clear_screen
                show_logo
                ;;
            1|2)
                echo ""
                echo -n -e "[+] 请输入文件路径: "
                read -r file_path
                if [ ! -f "$file_path" ]; then
                    echo -e "${RED}[-] 错误：文件不存在！${NC}"
                    echo -e "${YELLOW}[!]${NC} 按回车键继续..."
                    read -r
                    clear_screen
                    show_logo
                    continue
                fi

                echo -n -e "[+] 请输入密钥 (任意字符): "
                read -r key

                layers=1
                if [ "$choice" == "1" ]; then
                    echo -n -e "[+] 请输入加密层数 (默认1，推荐200): "
                    read -r layers_str
                else
                    echo -n -e "[+] 请输入加密时使用的层数: "
                    read -r layers_str
                fi
                if [ -n "$layers_str" ]; then
                    if [[ "$layers_str" =~ ^[0-9]+$ ]] && [ "$layers_str" -gt 0 ]; then
                        layers=$layers_str
                        if [ "$layers" -gt 200 ]; then
                            echo -e "${YELLOW}[!]${NC} 层数过大，可能耗时极长，是否继续？(y/N): "
                            read -r confirm
                            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                                echo -e "${YELLOW}[!]${NC} 操作已取消"
                                echo -e "${YELLOW}[!]${NC} 按回车键继续..."
                                read -r
                                clear_screen
                                show_logo
                                continue
                            fi
                        fi
                    else
                        echo -e "${RED}[-] 层数无效，使用默认1层${NC}"
                    fi
                fi

                echo ""
                if [ "$choice" == "1" ]; then
                    encrypt_file "$file_path" "$key" $layers
                else
                    decrypt_file "$file_path" "$key" $layers
                fi

                echo -e "\n${YELLOW}[!]${NC} 按回车键继续..."
                read -r
                clear_screen
                show_logo
                ;;
            *)
                echo -e "${RED}[-] 无效选择，请重新输入！${NC}"
                ;;
        esac
    done
}

# 启动主程序
main "$@"

# Hg5  
恐怖加密系统 - 200层文件加密器  

## 支持平台  
- Termux (Android)  
- Linux (Ubuntu/Debian/CentOS)  
- macOS  
- Windows (Git Bash/Cygwin/WSL)  

## 特性  
- 🔐 **200层加密** - 每层使用独立密钥，总计6400轮加密  
- 🚀 **超强安全** - 每层密钥基于主密钥+层号派生，暴力破解几乎不可能  
- 📦 **文件加密** - 支持任意类型文件，自动添加 `.hg5` 后缀  
- 🎨 **炫酷界面** - ASCII艺术标志，实时进度条显示  
- 👤 **作者信息** - github:Admintt73  

## 快速开始  
请注意，需要先安装依赖  

### 0. 安装依赖  
```bash
# Termux
pkg install openssl xxd

# Ubuntu/Debian
sudo apt install openssl xxd

# macOS (通常已预装openssl)
brew install xxd  # 如需安装xxd
```

1. 下载脚本到本地

```bash
curl -sSL https://raw.githubusercontent.com/Admintt73/hg5/main/hg5.sh -o hg5.sh
```

2. 添加执行权限

```bash
chmod +x hg5.sh
```

3. 运行脚本

```bash
./hg5.sh
```
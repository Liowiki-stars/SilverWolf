#!/bin/bash
# 银狼 iOS App 一键编译脚本
# 使用方法：在 Mac 终端运行 ./build.sh

set -e

echo "🐺 银狼智能交互精灵 - 编译脚本"
echo "================================"

# 检查是否在项目目录
if [ ! -f "SilverWolf.xcodeproj/project.pbxproj" ]; then
    echo "❌ 错误：请在 SilverWolf 项目根目录运行此脚本"
    exit 1
fi

# 检查 Xcode 是否安装
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 错误：未安装 Xcode，请先从 App Store 安装 Xcode 15.0+"
    exit 1
fi

echo "✅ Xcode 已安装"

# 清理
echo ""
echo "🧹 清理旧构建..."
xcodebuild clean -project SilverWolf.xcodeproj -scheme SilverWolf -configuration Release 2>/dev/null || true

# 编译
echo ""
echo "🔨 开始编译..."
xcodebuild \
    -project SilverWolf.xcodeproj \
    -scheme SilverWolf \
    -configuration Release \
    -sdk iphoneos \
    -derivedDataPath build \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    build

echo ""
echo "✅ 编译完成！"

# 查找 .app 文件
APP_PATH=$(find build -name "SilverWolf.app" -type d | head -1)

if [ -n "$APP_PATH" ]; then
    echo "📦 App 路径：$APP_PATH"

    # 创建 Payload 并打包 IPA
    echo ""
    echo "📦 正在打包 IPA..."
    rm -rf Payload SilverWolf.ipa
    mkdir Payload
    cp -r "$APP_PATH" Payload/
    zip -r SilverWolf.ipa Payload > /dev/null
    rm -rf Payload

    IPA_SIZE=$(du -h SilverWolf.ipa | cut -f1)
    echo "✅ IPA 已生成：SilverWolf.ipa ($IPA_SIZE)"
    echo ""
    echo "📱 安装方式："
    echo "   1. Xcode 直接安装（推荐）：用 Xcode 打开项目，连手机点运行"
    echo "   2. Sideloadly：打开 Sideloadly，拖入 SilverWolf.ipa"
    echo "   3. TrollStore：打开 TrollStore，点 + 选择 SilverWolf.ipa"
else
    echo "❌ 未找到编译产物，请检查上方错误信息"
    exit 1
fi

echo ""
echo "🐺 编译完成，祝你和银狼相处愉快~"

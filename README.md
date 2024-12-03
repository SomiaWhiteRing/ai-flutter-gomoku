# AI Flutter Gomoku (五子棋)

一个使用 Flutter 开发的五子棋游戏，支持人机对战和双人对战模式。

## 特性

- 🎮 支持人机对战和双人对战
- 🤖 三种 AI 难度（简单/中等/困难）
- 🎯 支持悔棋功能
- 🎨 多种主题（经典/现代/暗黑）
- 📱 响应式设计，支持多种屏幕尺寸
- 🌐 支持 Web 平台部署
- 🔄 显示最后一手和手数
- 🎵 音效开关（待实现）

## 技术特点

### AI 实现
- 极小化极大算法（Minimax Algorithm）
- Alpha-Beta 剪枝优化
- 动态搜索深度
- 启发式评估函数
- 威胁局面检测
- 性能优化缓存

### 状态管理
- 使用 Riverpod 进行状态管理
- 清晰的代码结构和关注点分离
- 响应式更新和性能优化

### 用户界面
- Material Design 3 设计语言
- 响应式布局适配
- 流畅的动画效果
- 多主题支持

## 本地运行

确保您已安装以下工具：
- Flutter SDK (3.0.0 或更高版本)
- Dart SDK (3.0.0 或更高版本)
- IDE (推荐 VS Code 或 Android Studio)

## 在线体验

访问 [在线演示](your-demo-url) 立即开始游戏！

## 依赖项

- flutter_riverpod: ^2.4.9 - 状态管理
- shared_preferences: ^2.2.2 - 本地数据存储
- http: ^1.1.0 - 网络请求（待用于在线功能）
- go_router: ^13.0.0 - 路由管理（待用于多页面导航）

## 待实现功能

1. 音效系统
   - 落子音效
   - 胜利音效
   - 背景音乐

2. 在线对战
   - 实时对战
   - 排行榜
   - 用户系统

3. 游戏记录
   - 对局回放
   - 导出棋谱
   - 历史记录

4. AI 优化
   - 深度学习模型
   - 开局库
   - 更智能的评估函数

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 开发者调试

在调试模式下，右上角会显示一个调试按钮，点击可以打印当前棋局信息到控制台，包括：
- 当前游戏模式
- 当前回合
- 完整的移动历史
- 棋盘状态

## 许可证

本项目基于 MIT 许可证开源，详见 [LICENSE](LICENSE) 文件。

## 致谢

- [Flutter](https://flutter.dev/) - UI 框架
- [Riverpod](https://riverpod.dev/) - 状态管理
- [Material Design](https://material.io/) - 设计语言

## 联系方式

如有问题或建议，请提交 Issue 或通过以下方式联系：

- Email: your-email@example.com
- GitHub: [your-username](https://github.com/your-username)
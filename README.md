# Detent

Windows 托盘小工具，给杂牌鼠标分档调节系统指针速度。界面走 Material Expressive：圆角、大触控目标、档位一眼能看清。WinUI 3 自带主题来铺这套样子。

## 现在能用的

- 默认 6 档，对应系统指针速度 1–20
- 全局快捷键：Ctrl+Alt+↑ 上一档，Ctrl+Alt+↓ 下一档
- 关掉窗口会收进托盘，快捷键继续有效
- 托盘图标点一下打开窗口，空闲时只在改档时动系统接口
- Logo 在 `src/Detent/Assets/logo.png`

开机自启还没做。

## 环境

- Windows 10 1809 或更高
- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- [Windows App SDK 2.5 运行时](https://learn.microsoft.com/windows/apps/windows-app-sdk/downloads)。运行时单独装，托盘进程保持小。

```bash
dotnet build src/Detent/Detent.csproj -c Release
```

## 许可

MIT

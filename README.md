# Detent

Windows 托盘小工具。给没有官方驱动的杂牌鼠标分档调节**系统指针速度**，不是硬件 DPI。

界面按 Material Expressive 来做（圆角、大触控目标、明确的档位）。WinUI 3 没有现成的 Material 控件库，第一版用 WinUI 主题自己铺，不假装接了 Google 的 Material 包。

## 第一版

- 多档灵敏度，默认 6 档，对应系统指针速度 1–20
- 全局快捷键：Ctrl+Alt+↑ 上一档，Ctrl+Alt+↓ 下一档。关掉窗口只会藏到托盘，快捷键还在
- 托盘常驻，点开看当前档位并切换
- 空闲时不做轮询，改档才调用系统接口
- 开机自启以后再加

不做：硬件 DPI、宏、按键映射、云同步、应用内更新。

## 环境

- Windows 10 1809 或更高
- [.NET 8 SDK](https://dotnet.microsoft.com/download)
- [Windows App SDK 2.5 运行时](https://learn.microsoft.com/windows/apps/windows-app-sdk/downloads)（项目不是自包含，这样托盘进程更小）

```bash
dotnet build src/Detent/Detent.csproj -c Release
```

## 许可

MIT

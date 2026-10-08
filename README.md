# Detent

Windows 托盘小工具，用来给杂牌鼠标分档调节系统指针速度。窗口用 WinUI 3。指针速度范围是 1 到 20。

程序启动后停在托盘里。左键点托盘图标打开窗口，右键菜单有「打开」和「退出」。点窗口关闭会回到托盘，全局快捷键继续有效。从托盘选「退出」后进程结束，托盘图标一并去掉。

## 档位

默认 6 档，系统指针速度依次是 4、6、8、10、14、18。窗口里可以改当前档的速度，也可以添加或删除档位。档位数量保持在 2 到 9 之间。改动会立刻作用到系统指针速度，并立刻写入本机设置。

## 快捷键

- Ctrl+Alt+↑ 上一档
- Ctrl+Alt+↓ 下一档
- Ctrl+Alt+1 到 Ctrl+Alt+6 跳到对应档。这一档还在时会切过去；档位数量少于按下的数字时，保持当前档

到两端就停住。某个组合注册不上时，窗口里的状态文字会列出注册失败的快捷键，程序继续运行。

## 开机启动

窗口里有开机启动开关。打开后，当前用户的启动项里会写入 `Detent`，数值是正在运行的程序路径。关掉开关会删掉这个启动项。

## 设置文件

`%LOCALAPPDATA%\Detent\settings.json`

里面有各档速度 `speeds`、当前档 `index`（从 0 计）、开机启动 `startWithWindows`。文件不存在时，程序写入默认 6 档再按第 1 档启动。文件内容读不出来或档位不在允许范围内时，用同一组默认值继续运行。

## 编译

在 Windows 10 1809 或更高版本上安装 [.NET 10 SDK](https://dotnet.microsoft.com/download)，并单独安装 [Windows App SDK 2.5 运行时](https://learn.microsoft.com/windows/apps/windows-app-sdk/downloads)。

```bash
dotnet build src/Detent/Detent.csproj -c Release
```

托盘图标读取程序目录下的 `Assets/logo.png`。

## 许可

MIT

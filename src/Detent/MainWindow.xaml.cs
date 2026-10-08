using System.Windows.Input;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media.Imaging;
using WinRT.Interop;

namespace Detent;

public sealed partial class MainWindow : Window
{
    readonly HotkeyHook _hotkeys;
    readonly List<int> _speeds;
    readonly RelayCommand _showWindow;
    readonly RelayCommand _exit;
    bool _applying;
    bool _ready;
    bool _exiting;
    bool _shownFromTray;
    int _index;

    public MainWindow()
    {
        _showWindow = new RelayCommand(ShowFromTray);
        _exit = new RelayCommand(ExitFromTray);

        var settings = SettingsStore.Load();
        _speeds = new List<int>(settings.Speeds);
        _index = settings.Index;

        InitializeComponent();
        OpenMenuItem.Command = _showWindow;
        ExitMenuItem.Command = _exit;
        TrayIcon.LeftClickCommand = _showWindow;
        LoadTrayIcon();

        var hwnd = WindowNative.GetWindowHandle(this);
        _hotkeys = new HotkeyHook(hwnd);
        _hotkeys.Previous += () => Step(-1);
        _hotkeys.Next += () => Step(1);
        _hotkeys.Jump += JumpTo;
        Closed += (_, _) => _hotkeys.Dispose();
        AppWindow.Closing += OnClosing;

        PointerSpeed.Set(_speeds[_index]);
        StartupRegistration.Set(settings.StartWithWindows);
        StartupSwitch.IsOn = settings.StartWithWindows;
        Refresh();
        AppWindow.Resize(new Windows.Graphics.SizeInt32(440, 680));
        var queue = Microsoft.UI.Dispatching.DispatcherQueue.GetForCurrentThread();
        if (queue is null)
        {
            _ready = true;
        }
        else
        {
            queue.TryEnqueue(() => _ready = true);
        }
    }

    void LoadTrayIcon()
    {
        try
        {
            var path = Path.Combine(AppContext.BaseDirectory, "Assets", "logo.png");
            if (!File.Exists(path))
            {
                return;
            }

            TrayIcon.IconSource = new BitmapImage(new Uri(path, UriKind.Absolute));
        }
        catch
        {
            // The tray entry still works if the logo file cannot be read.
        }
    }

    void OnClosing(Microsoft.UI.Windowing.AppWindow sender, Microsoft.UI.Windowing.AppWindowClosingEventArgs args)
    {
        if (!_exiting)
        {
            args.Cancel = true;
            AppWindow.Hide();
            return;
        }

        try
        {
            TrayIcon.Dispose();
        }
        catch
        {
            // Closing still has to finish so the process can leave.
        }
    }

    public void HideAtLaunch()
    {
        if (_shownFromTray)
        {
            return;
        }

        AppWindow.Hide();
    }

    void ShowFromTray()
    {
        _shownFromTray = true;
        AppWindow.Show();
        Activate();
    }

    void ExitFromTray()
    {
        if (_exiting)
        {
            return;
        }

        _exiting = true;
        var queue = Microsoft.UI.Dispatching.DispatcherQueue.GetForCurrentThread();
        if (queue is null)
        {
            FinishExit();
            return;
        }

        queue.TryEnqueue(FinishExit);
    }

    void FinishExit()
    {
        Close();
        try
        {
            Application.Current.Exit();
        }
        catch
        {
            // Close already started shutdown.
        }
    }

    void Step(int delta)
    {
        ApplyIndex(_index + delta);
    }

    void JumpTo(int index)
    {
        if (index < 0 || index >= _speeds.Count)
        {
            return;
        }

        ApplyIndex(index);
    }

    void ApplyIndex(int index)
    {
        var clamped = Math.Clamp(index, 0, _speeds.Count - 1);
        if (clamped == _index)
        {
            return;
        }

        _index = clamped;
        PointerSpeed.Set(_speeds[_index]);
        Persist();
        Refresh();
    }

    void Refresh()
    {
        _applying = true;
        var labels = new List<string>(_speeds.Count);
        for (var i = 0; i < _speeds.Count; i++)
        {
            labels.Add($"第 {i + 1} 档    速度 {_speeds[i]}");
        }

        LevelList.ItemsSource = labels;
        LevelList.SelectedIndex = _index;
        SpeedBox.Value = _speeds[_index];
        AddButton.IsEnabled = _speeds.Count < LevelLimits.MaxCount;
        RemoveButton.IsEnabled = _speeds.Count > LevelLimits.MinCount;
        CurrentSpeedText.Text = $"第 {_index + 1} 档，系统指针速度 {_speeds[_index]}\n{DescribeHotkeys()}";
        TrayIcon.ToolTipText = $"Detent  第 {_index + 1} 档";
        _applying = false;
    }

    string DescribeHotkeys()
    {
        var failed = new List<string>();
        if (!_hotkeys.PreviousRegistered)
        {
            failed.Add("Ctrl+Alt+↑");
        }

        if (!_hotkeys.NextRegistered)
        {
            failed.Add("Ctrl+Alt+↓");
        }

        for (var i = 0; i < LevelLimits.DirectHotkeyCount; i++)
        {
            if (!_hotkeys.IsDirectRegistered(i))
            {
                failed.Add($"Ctrl+Alt+{i + 1}");
            }
        }

        if (failed.Count == 0)
        {
            return "Ctrl+Alt+↑ 上一档，Ctrl+Alt+↓ 下一档，Ctrl+Alt+1 到 6 跳到对应档";
        }

        return "快捷键注册失败，可能被别的程序占用了：" + string.Join("、", failed);
    }

    void Persist()
    {
        SettingsStore.Save(new AppSettings
        {
            Speeds = _speeds.ToArray(),
            Index = _index,
            StartWithWindows = StartupSwitch.IsOn,
        });
    }

    void LevelList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (!_ready || _applying || LevelList.SelectedIndex < 0 || LevelList.SelectedIndex == _index)
        {
            return;
        }

        ApplyIndex(LevelList.SelectedIndex);
    }

    void SpeedBox_ValueChanged(NumberBox sender, NumberBoxValueChangedEventArgs args)
    {
        if (!_ready || _applying || _speeds.Count == 0 || double.IsNaN(args.NewValue))
        {
            return;
        }

        var speed = (int)Math.Clamp(Math.Round(args.NewValue), LevelLimits.MinSpeed, LevelLimits.MaxSpeed);
        if (speed == _speeds[_index])
        {
            return;
        }

        _speeds[_index] = speed;
        PointerSpeed.Set(speed);
        Persist();
        Refresh();
    }

    void AddLevel_Click(object sender, RoutedEventArgs e)
    {
        if (!_ready || _speeds.Count >= LevelLimits.MaxCount)
        {
            return;
        }

        _speeds.Add(10);
        Persist();
        Refresh();
    }

    void RemoveLevel_Click(object sender, RoutedEventArgs e)
    {
        if (!_ready || _speeds.Count <= LevelLimits.MinCount)
        {
            return;
        }

        _speeds.RemoveAt(_index);
        if (_index >= _speeds.Count)
        {
            _index = _speeds.Count - 1;
        }

        PointerSpeed.Set(_speeds[_index]);
        Persist();
        Refresh();
    }

    void StartupSwitch_Toggled(object sender, RoutedEventArgs e)
    {
        if (!_ready || _applying)
        {
            return;
        }

        StartupRegistration.Set(StartupSwitch.IsOn);
        Persist();
    }
}

sealed class RelayCommand(Action action) : ICommand
{
    public event EventHandler? CanExecuteChanged
    {
        add { }
        remove { }
    }

    public bool CanExecute(object? parameter) => true;

    public void Execute(object? parameter) => action();
}

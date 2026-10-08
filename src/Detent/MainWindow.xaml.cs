using System.Windows.Input;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using WinRT.Interop;

namespace Detent;

public sealed partial class MainWindow : Window
{
    readonly HotkeyHook _hotkeys;
    bool _applying;
    int _index;

    public ICommand ShowWindowCommand { get; }

    public MainWindow()
    {
        InitializeComponent();
        ShowWindowCommand = new RelayCommand(ShowFromTray);
        LevelList.ItemsSource = DefaultLevels.All;

        var hwnd = WindowNative.GetWindowHandle(this);
        _hotkeys = new HotkeyHook(hwnd);
        _hotkeys.Previous += () => Step(-1);
        _hotkeys.Next += () => Step(1);
        Closed += (_, _) => _hotkeys.Dispose();

        AppWindow.Closing += (_, args) =>
        {
            args.Cancel = true;
            AppWindow.Hide();
        };

        _index = NearestIndex(PointerSpeed.Get());
        ApplyIndex(_index, setSpeed: false);
        AppWindow.Resize(new Windows.Graphics.SizeInt32(420, 560));
    }

    void ShowFromTray()
    {
        AppWindow.Show();
        Activate();
    }

    void Step(int delta)
    {
        var next = Math.Clamp(_index + delta, 0, DefaultLevels.All.Count - 1);
        ApplyIndex(next, setSpeed: true);
    }

    void ApplyIndex(int index, bool setSpeed)
    {
        _index = index;
        var level = DefaultLevels.All[index];
        if (setSpeed)
        {
            PointerSpeed.Set(level.PointerSpeed);
        }

        _applying = true;
        LevelList.SelectedIndex = index;
        _applying = false;

        var keys = _hotkeys.PreviousRegistered && _hotkeys.NextRegistered
            ? "Ctrl+Alt+↑ 上一档，Ctrl+Alt+↓ 下一档"
            : "快捷键注册失败，可能被别的程序占用了";
        CurrentSpeedText.Text = $"第 {level.Name} 档，系统指针速度 {level.PointerSpeed}\n{keys}";
        TrayIcon.ToolTipText = $"Detent  第 {level.Name} 档";
    }

    static int NearestIndex(int speed)
    {
        var best = 0;
        var bestDistance = int.MaxValue;
        for (var i = 0; i < DefaultLevels.All.Count; i++)
        {
            var distance = Math.Abs(DefaultLevels.All[i].PointerSpeed - speed);
            if (distance < bestDistance)
            {
                best = i;
                bestDistance = distance;
            }
        }

        return best;
    }

    void LevelList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_applying || LevelList.SelectedIndex < 0)
        {
            return;
        }

        ApplyIndex(LevelList.SelectedIndex, setSpeed: true);
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

using System.Windows.Input;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace Detent;

public sealed partial class MainWindow : Window
{
    public ICommand ShowWindowCommand { get; }

    public MainWindow()
    {
        InitializeComponent();
        ShowWindowCommand = new RelayCommand(ShowFromTray);
        LevelList.ItemsSource = DefaultLevels.All;
        CurrentSpeedText.Text = $"当前系统指针速度 {PointerSpeed.Get()}";
        AppWindow.Resize(new Windows.Graphics.SizeInt32(420, 560));
    }

    void ShowFromTray()
    {
        AppWindow.Show();
        Activate();
    }

    void LevelList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (LevelList.SelectedItem is not SensitivityLevel level)
        {
            return;
        }

        PointerSpeed.Set(level.PointerSpeed);
        CurrentSpeedText.Text = $"当前系统指针速度 {level.PointerSpeed}";
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

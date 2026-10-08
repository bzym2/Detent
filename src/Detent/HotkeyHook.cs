using System.Runtime.InteropServices;

namespace Detent;

public sealed class HotkeyHook : IDisposable
{
    const int WmHotkey = 0x0312;
    const uint ModAlt = 0x0001;
    const uint ModControl = 0x0002;
    const uint ModNoRepeat = 0x4000;
    const uint VkUp = 0x26;
    const uint VkDown = 0x28;
    const int IdPrevious = 1;
    const int IdNext = 2;

    readonly IntPtr _hwnd;
    readonly SubclassProc _proc;
    bool _subclassed;

    public bool PreviousRegistered { get; }
    public bool NextRegistered { get; }

    public event Action? Previous;
    public event Action? Next;

    public HotkeyHook(IntPtr hwnd)
    {
        _hwnd = hwnd;
        _proc = OnMessage;
        _subclassed = SetWindowSubclass(hwnd, _proc, 1, 0);
        var mods = ModControl | ModAlt | ModNoRepeat;
        PreviousRegistered = RegisterHotKey(hwnd, IdPrevious, mods, VkUp);
        NextRegistered = RegisterHotKey(hwnd, IdNext, mods, VkDown);
    }

    public void Dispose()
    {
        UnregisterHotKey(_hwnd, IdPrevious);
        UnregisterHotKey(_hwnd, IdNext);
        if (_subclassed)
        {
            RemoveWindowSubclass(_hwnd, _proc, 1);
            _subclassed = false;
        }
    }

    IntPtr OnMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam, nuint id, nint data)
    {
        if (msg == WmHotkey)
        {
            var hotkeyId = wParam.ToInt32();
            if (hotkeyId == IdPrevious)
            {
                Previous?.Invoke();
            }
            else if (hotkeyId == IdNext)
            {
                Next?.Invoke();
            }
        }

        return DefSubclassProc(hWnd, msg, wParam, lParam);
    }

    delegate IntPtr SubclassProc(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam, nuint idSubclass, nint refData);

    [DllImport("comctl32.dll", SetLastError = true)]
    static extern bool SetWindowSubclass(IntPtr hWnd, SubclassProc pfnSubclass, nuint idSubclass, nuint refData);

    [DllImport("comctl32.dll", SetLastError = true)]
    static extern bool RemoveWindowSubclass(IntPtr hWnd, SubclassProc pfnSubclass, nuint idSubclass);

    [DllImport("comctl32.dll")]
    static extern IntPtr DefSubclassProc(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true)]
    static extern bool RegisterHotKey(IntPtr hWnd, int id, uint modifiers, uint vk);

    [DllImport("user32.dll")]
    static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}

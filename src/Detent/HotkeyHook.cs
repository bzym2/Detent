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
    const uint VkDigit1 = 0x31;
    const int IdPrevious = 1;
    const int IdNext = 2;
    const int IdDirectFirst = 3;

    readonly IntPtr _hwnd;
    // Field keeps the subclass delegate alive for the HWND lifetime.
    readonly SubclassProc _proc;
    readonly bool[] _directOk = new bool[LevelLimits.DirectHotkeyCount];
    bool _subclassed;
    bool _disposed;

    public bool PreviousRegistered { get; }
    public bool NextRegistered { get; }

    public event Action? Previous;
    public event Action? Next;
    public event Action<int>? Jump;

    public HotkeyHook(IntPtr hwnd)
    {
        _hwnd = hwnd;
        _proc = OnMessage;
        _subclassed = SetWindowSubclass(hwnd, _proc, 1, 0);
        var mods = ModControl | ModAlt | ModNoRepeat;
        PreviousRegistered = RegisterHotKey(hwnd, IdPrevious, mods, VkUp);
        NextRegistered = RegisterHotKey(hwnd, IdNext, mods, VkDown);
        for (var i = 0; i < LevelLimits.DirectHotkeyCount; i++)
        {
            _directOk[i] = RegisterHotKey(hwnd, IdDirectFirst + i, mods, VkDigit1 + (uint)i);
        }
    }

    public bool IsDirectRegistered(int index) =>
        index >= 0 && index < _directOk.Length && _directOk[index];

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        _disposed = true;
        UnregisterHotKey(_hwnd, IdPrevious);
        UnregisterHotKey(_hwnd, IdNext);
        for (var i = 0; i < LevelLimits.DirectHotkeyCount; i++)
        {
            UnregisterHotKey(_hwnd, IdDirectFirst + i);
        }

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
            else if (hotkeyId >= IdDirectFirst && hotkeyId < IdDirectFirst + LevelLimits.DirectHotkeyCount)
            {
                Jump?.Invoke(hotkeyId - IdDirectFirst);
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

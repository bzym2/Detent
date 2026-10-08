using System.Runtime.InteropServices;

namespace Detent;

public static class PointerSpeed
{
    const uint SpiGetMouseSpeed = 0x0070;
    const uint SpiSetMouseSpeed = 0x0071;
    const uint SpifUpdateIniFile = 0x01;
    const uint SpifSendChange = 0x02;

    public static int Get()
    {
        int speed = 10;
        SystemParametersInfoGet(SpiGetMouseSpeed, 0, ref speed, 0);
        return speed;
    }

    public static void Set(int speed)
    {
        speed = Math.Clamp(speed, 1, 20);
        // SPI_SETMOUSESPEED takes the speed in pvParam itself, not a pointer to it.
        SystemParametersInfoSet(SpiSetMouseSpeed, 0, speed, SpifUpdateIniFile | SpifSendChange);
    }

    [DllImport("user32.dll", EntryPoint = "SystemParametersInfoW", SetLastError = true)]
    static extern bool SystemParametersInfoGet(uint action, uint param, ref int value, uint winIni);

    [DllImport("user32.dll", EntryPoint = "SystemParametersInfoW", SetLastError = true)]
    static extern bool SystemParametersInfoSet(uint action, uint param, nuint value, uint winIni);
}

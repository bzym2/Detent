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
        SystemParametersInfo(SpiGetMouseSpeed, 0, ref speed, 0);
        return speed;
    }

    public static void Set(int speed)
    {
        speed = Math.Clamp(speed, 1, 20);
        SystemParametersInfo(SpiSetMouseSpeed, 0, ref speed, SpifUpdateIniFile | SpifSendChange);
    }

    [DllImport("user32.dll", SetLastError = true)]
    static extern bool SystemParametersInfo(uint action, uint param, ref int value, uint winIni);
}

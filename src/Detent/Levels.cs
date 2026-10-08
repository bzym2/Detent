namespace Detent;

public sealed record SensitivityLevel(string Name, int PointerSpeed);

public static class LevelLimits
{
    public const int MinCount = 2;
    public const int MaxCount = 9;
    public const int MinSpeed = 1;
    public const int MaxSpeed = 20;
    public const int DirectHotkeyCount = 6;
}

public static class DefaultLevels
{
    // Windows pointer speed is 1 through 20. 10 is the system default.
    public static IReadOnlyList<SensitivityLevel> All { get; } = new SensitivityLevel[]
    {
        new("1", 4),
        new("2", 6),
        new("3", 8),
        new("4", 10),
        new("5", 14),
        new("6", 18),
    };
}

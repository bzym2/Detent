namespace Detent;

public sealed record SensitivityLevel(string Name, int PointerSpeed);

public static class DefaultLevels
{
    // Windows pointer speed is 1 through 20. 10 is the system default.
    public static SensitivityLevel[] All { get; } =
    [
        new("1", 4),
        new("2", 6),
        new("3", 8),
        new("4", 10),
        new("5", 14),
        new("6", 18),
    ];
}

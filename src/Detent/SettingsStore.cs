using System.Text.Json;
using System.Text.Json.Serialization;

namespace Detent;

public sealed class AppSettings
{
    [JsonPropertyName("speeds")]
    public int[] Speeds { get; set; } = [];

    [JsonPropertyName("index")]
    public int Index { get; set; }

    [JsonPropertyName("startWithWindows")]
    public bool StartWithWindows { get; set; }
}

public static class SettingsStore
{
    static readonly JsonSerializerOptions Options = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
        WriteIndented = true,
    };

    public static string FilePath { get; } = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Detent",
        "settings.json");

    public static AppSettings CreateDefault() => new()
    {
        Speeds = DefaultLevels.All.Select(level => level.PointerSpeed).ToArray(),
        Index = 0,
        StartWithWindows = false,
    };

    public static AppSettings Load()
    {
        try
        {
            if (!File.Exists(FilePath))
            {
                var created = CreateDefault();
                Save(created);
                return created;
            }

            var parsed = JsonSerializer.Deserialize<AppSettings>(File.ReadAllText(FilePath), Options);
            if (parsed is not null && IsValid(parsed))
            {
                return parsed;
            }
        }
        catch
        {
            // Missing or unreadable settings fall through to the defaults.
        }

        return CreateDefault();
    }

    public static void Save(AppSettings settings)
    {
        try
        {
            var directory = Path.GetDirectoryName(FilePath);
            if (!string.IsNullOrEmpty(directory))
            {
                Directory.CreateDirectory(directory);
            }

            var temp = FilePath + ".tmp";
            File.WriteAllText(temp, JsonSerializer.Serialize(settings, Options));
            File.Move(temp, FilePath, overwrite: true);
        }
        catch
        {
            // Keep the running levels if the disk write fails.
        }
    }

    public static bool IsValid(AppSettings settings)
    {
        if (settings.Speeds is null)
        {
            return false;
        }

        if (settings.Speeds.Length is < LevelLimits.MinCount or > LevelLimits.MaxCount)
        {
            return false;
        }

        foreach (var speed in settings.Speeds)
        {
            if (speed is < LevelLimits.MinSpeed or > LevelLimits.MaxSpeed)
            {
                return false;
            }
        }

        return settings.Index >= 0 && settings.Index < settings.Speeds.Length;
    }
}

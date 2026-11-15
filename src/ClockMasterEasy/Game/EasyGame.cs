namespace ClockMasterEasy.Game;

/// <summary>What the round is about: only the hour hand, only the minute hand, or both.</summary>
public enum Topic { Hours, Minutes, Both }

/// <summary>Set the hands to a shown time, or read the hands and pick the time.</summary>
public enum Direction { Set, Read }

/// <summary>A time on the clock. Hour is 1–23 (never 0, so there is no midnight to explain), minutes a whole five.</summary>
public readonly record struct ClockTime(int Hour, int Minute)
{
    /// <summary>Where the hour hand points on the 12-hour face, 1–12.</summary>
    public int FaceHour => (Hour - 1) % 12 + 1;

    /// <summary>"3:05" or "15:05": no leading zero on the hour, like most Danish digital clocks.</summary>
    public string HourText => Hour.ToString();
    public string MinuteText => Minute.ToString("00");
    public override string ToString() => $"{HourText}:{MinuteText}";
}

public sealed class EasyGame
{
    private readonly Random _random = new();

    public Topic Topic { get; private set; } = Topic.Hours;

    /// <summary>Whether hours 13–23 are asked as well as 1–12.</summary>
    public bool DayHours { get; private set; }

    public ClockTime Time { get; private set; }

    /// <summary>The three answers to choose between when reading the clock, in random order.</summary>
    public IReadOnlyList<ClockTime> Choices { get; private set; } = [];

    /// <summary>Picks a new time, never the same as the last one.</summary>
    public void NewRound(Topic topic, bool dayHours)
    {
        Topic = topic;
        DayHours = dayHours;

        ClockTime time;
        do
        {
            var hour = _random.Next(1, dayHours ? 24 : 13);
            var minute = topic == Topic.Hours ? 0 : _random.Next(12) * 5;
            time = new ClockTime(hour, minute);
        } while (time == Time);

        Time = time;
        Choices = MakeChoices(time);
    }

    /// <summary>Whether the hands show the time. The face only has 12 hours, so 15:00 is set with the hour hand on 3.</summary>
    public bool HourIsRight(int faceHour) => faceHour == Time.FaceHour;
    public bool MinuteIsRight(int minute) => minute == Time.Minute;

    // ---------- Wrong answers for "read the clock" ----------

    private List<ClockTime> MakeChoices(ClockTime right)
    {
        // The likely mistakes come first, then near misses, then anything; the first two that differ are used.
        var candidates = Topic switch
        {
            Topic.Hours => [Hour(right, right.Hour + 1), Hour(right, right.Hour - 1), RandomHour(right), RandomHour(right)],
            Topic.Minutes => [Misread(right), Minute(right, right.Minute + 5), Minute(right, right.Minute - 5), RandomMinute(right), RandomMinute(right)],
            _ => new List<ClockTime> { Swapped(right), Misread(right), Hour(right, right.Hour + 1), Hour(right, right.Hour - 1), RandomHour(RandomMinute(right)) },
        };

        var choices = new List<ClockTime> { right };
        foreach (var candidate in candidates)
        {
            if (choices.Count == 3) break;
            if (!choices.Contains(candidate)) choices.Add(candidate);
        }
        while (choices.Count < 3)
        {
            var extra = Topic == Topic.Minutes ? RandomMinute(right) : RandomHour(right);
            if (!choices.Contains(extra)) choices.Add(extra);
        }

        return choices.OrderBy(_ => _random.Next()).ToList();
    }

    /// <summary>The classic mistake: reading the number the minute hand points at (4) instead of the minutes (20).</summary>
    private static ClockTime Misread(ClockTime t)
    {
        var number = t.Minute == 0 ? 12 : t.Minute / 5;
        return t with { Minute = number };
    }

    /// <summary>Mixing up the hands: the minute hand read as the hour and the hour hand as the minutes.</summary>
    private ClockTime Swapped(ClockTime t)
    {
        var hour = t.Minute == 0 ? 12 : t.Minute / 5;
        return Hour(t, hour) with { Minute = t.FaceHour % 12 * 5 };
    }

    /// <summary>The same time with another hour, kept in the same half of the day so the answers all fit the sun or moon.</summary>
    private ClockTime Hour(ClockTime t, int faceHour)
    {
        faceHour = (faceHour - 1 + 12) % 12 + 1;
        var afternoon = DayHours && t.Hour >= 12;
        var hour = afternoon ? (faceHour == 12 ? 12 : faceHour + 12) : faceHour;
        if (DayHours && !afternoon && hour == 12) hour = 11; // 12 belongs to the afternoon half
        return t with { Hour = hour };
    }

    private static ClockTime Minute(ClockTime t, int minute) => t with { Minute = (minute + 60) % 60 };

    private ClockTime RandomHour(ClockTime t) => Hour(t, _random.Next(1, 13));

    private ClockTime RandomMinute(ClockTime t) => t with { Minute = _random.Next(12) * 5 };

    // ---------- Part of the day, for the 24-hour clock ----------

    /// <summary>A picture for the part of the day, so 3 and 15 can be told apart without words.</summary>
    public static string DayIcon(int hour) => hour switch
    {
        <= 5 => "🌙",
        <= 11 => "🌅",
        <= 17 => "☀️",
        _ => "🌆",
    };

    public static string DayName(int hour) => hour switch
    {
        <= 5 => "nat",
        <= 11 => "morgen og formiddag",
        <= 17 => "eftermiddag",
        _ => "aften",
    };
}

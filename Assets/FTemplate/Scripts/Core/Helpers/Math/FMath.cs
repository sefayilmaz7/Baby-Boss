
public static class FMath
{
    public static float GetPercent(float min, float max, float value)
    {
        return 100f * (value / (max - min));
    }

    public static string GetPercentAsText(float min, float max, float value)
    {
        return string.Format("{0}%", GetPercent(min, max, value));
    }
}

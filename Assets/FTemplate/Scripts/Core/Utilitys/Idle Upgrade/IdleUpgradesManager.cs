using UnityEngine;

public static class IdleUpgradesManager
{
    private static int RequiredUpgradeCount = 2;
    private static string PLAYER_PREFS_SAVE_NAME => nameof(IdleUpgradesManager) + "_Save";
    private static string PLAYER_PREFS_UPGRADE_LEVEL_NAME(IdleUpgradeType idleUpgrade) => nameof(IdleUpgradeMonitor) + "_" + ((int)idleUpgrade);
    private static string PLAYER_PREFS_SESSION_UPGRADE_LEVEL_NAME(IdleUpgradeType idleUpgrade) => nameof(IdleUpgradesManager) + "_Save_" + ((int)idleUpgrade);

    public static int GetUpgradeLevel(IdleUpgradeType idleUpgrade)
    {
        return PlayerPrefs.GetInt(PLAYER_PREFS_UPGRADE_LEVEL_NAME(idleUpgrade), 0);
    }

    public static int GetSessionUpgradeLevel(IdleUpgradeType idleUpgrade)
    {
        int sessionUpgradeTypeLevel = PlayerPrefs.GetInt(PLAYER_PREFS_SESSION_UPGRADE_LEVEL_NAME(idleUpgrade), 0);
        return GetUpgradeLevel(idleUpgrade) - sessionUpgradeTypeLevel;
    }

    public static bool CheckSessionUpgradeLevel(IdleUpgradeType idleUpgrade)
    {
        return GetSessionUpgradeLevel(idleUpgrade) >= RequiredUpgradeCount;
    }

    public static float GetSessionUpgradeLevelPercentage(IdleUpgradeType idleUpgrade)
    {
        float currentSessionUpgradeLevel = GetSessionUpgradeLevel(idleUpgrade);
        return Mathf.Clamp01(currentSessionUpgradeLevel / RequiredUpgradeCount);
    }

    private static void SaveUpgradeTypeLevels()
    {
        bool saved = bool.Parse(PlayerPrefs.GetString(PLAYER_PREFS_SAVE_NAME, false.ToString()));
        if (saved) return;
        PlayerPrefs.SetString(PLAYER_PREFS_SAVE_NAME, true.ToString());

        foreach (IdleUpgradeType upgradeType in (IdleUpgradeType[]) System.Enum.GetValues(typeof(IdleUpgradeType)))
        {
            PlayerPrefs.SetInt(PLAYER_PREFS_SESSION_UPGRADE_LEVEL_NAME(upgradeType), GetUpgradeLevel(upgradeType));
        }
    }

    public static void LevelInitialized(int requiredUpgradeCount = 2)
    {
        RequiredUpgradeCount = requiredUpgradeCount;

        SaveUpgradeTypeLevels();
    }

    public static void LevelFinished(bool success)
    {
        if (!success) return;
        PlayerPrefs.SetString(PLAYER_PREFS_SAVE_NAME, false.ToString());
    }
}
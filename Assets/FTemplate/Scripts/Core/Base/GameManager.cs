using DG.Tweening;
using FTemplateNamespace;
using UnityEngine;
using MoreMountains.NiceVibrations;

#if !UNITY_EDITOR
using UnityEngine.SceneManagement;
#endif

public sealed class GameManager : SingletonBehaviour<GameManager>
{
    private bool GameStarted = false;
    public bool IsGamePlaying => GameStarted;

    public System.Action GameStartedEvent;
    public System.Action<bool> GameOverEvent;

    protected override void Awake()
    {
        base.Awake();

        FTemplate.UI.HideAllUIElements(0f);
    }

    private void Start()
    {
        Application.targetFrameRate = 60;

#if !UNITY_EDITOR
        bool isSceneActiveLevel = SceneManager.GetActiveScene().name == FTemplate.Gallery.ActiveLevel.ID;
        if (!isSceneActiveLevel)
        {
            LoadActiveLevel();
            return;
        }
#endif

        FTemplate.UI.Show(UIElementType.MainMenu);

        FTemplate.UI.StartLevelButtonClicked = StartLevelClickEvent;
        FTemplate.UI.NextLevelButtonClicked = NextLevelClickEvent;
        FTemplate.UI.SkipLevelButtonClicked = SkipLevelClickEvent;
        FTemplate.UI.RestartLevelButtonClicked = RestartLevelClickEvent;

        FTemplate.UI.LevelCompleteMenuType = UIModule.LevelCompleteMenu.ShowTextThenFadeOut;
        FTemplate.UI.LevelFailedMenuType = UIModule.LevelFailedMenu.RestartOnly;
        FTemplate.UI.BonusLevelRewardMenuType = UIModule.BonusLevelRewardMenu.RotatingStick;

        FTemplate.Ads.ShowBannerAd(true);
        FTemplate.UI.SetTotalCoins(FTemplate.Shop.Coins, false);

        FTemplate.Audio.ButtonClickSoundEnabled = false;
    }

    private void Update()
    {
        AutoQualityDecreaser.Update(Time.time);
    }

    public void StartLevel()
    {
        GameStarted = true;

        FTemplate.Analytics.LevelStartedEvent(new AnalyticsModule.Progression("LEVEL_" + (FTemplate.Gallery.TotalPlayedLevelCount + 1) + "_STARTED"));

        FTemplate.UI.HideAllHUDElements();
        FTemplate.UI.HideAllMenus();
        MMVibrationManager.Haptic(HapticTypes.Selection);
        FTemplate.UI.TopCurrentLevelLabel = "LEVEL " + (FTemplate.Gallery.TotalPlayedLevelCount + 1);
        // FTemplate.UI.Show(UIElementType.FPSCounter);
        FTemplate.UI.Show(UIElementType.TopRestartButton);
        // FTemplate.UI.Show(UIElementType.TopSkipLevelButton);
        FTemplate.UI.Show(UIElementType.TopCurrentLevelText);
        FTemplate.UI.Show(UIElementType.TotalCoinsText);

        TriggerLevelStarted();

        GameStartedEvent?.Invoke();
    }

    public void CompleteLevel(float uiDelay = 0f)
    {
        if (!GameStarted) return;
        GameStarted = false;

        FTemplate.Analytics.LevelCompletedEvent(new AnalyticsModule.Progression("LEVEL_" + (FTemplate.Gallery.TotalPlayedLevelCount + 1) + "_COMPLETED"));
        FTemplate.Ads.ShowInterstitialAd("COMPLETED_LEVEL");

        FTemplate.UI.HideAllHUDElements();
        FTemplate.UI.HideAllMenus();
        MMVibrationManager.Haptic(HapticTypes.Success);
        FTemplate.UI.Show(UIElementType.LevelCompletedMenu, delay: uiDelay);

        GameOverEvent?.Invoke(true);
    }

    public void FailLevel(float uiDelay = 0f)
    {
        if (!GameStarted) return;
        GameStarted = false;

        FTemplate.Analytics.LevelFailedEvent(new AnalyticsModule.Progression("LEVEL_" + (FTemplate.Gallery.TotalPlayedLevelCount + 1) + "_FAILED"));
        FTemplate.Ads.ShowInterstitialAd("FAILED_LEVEL");

        FTemplate.UI.HideAllHUDElements();
        FTemplate.UI.HideAllMenus();
        MMVibrationManager.Haptic(HapticTypes.Failure);
        FTemplate.UI.Show(UIElementType.LevelFailedMenu, delay: uiDelay);

        GameOverEvent?.Invoke(false);
    }

    public void SkipLevel()
    {
        FTemplate.Analytics.LevelSkippedEvent(new AnalyticsModule.Progression("LEVEL_" + FTemplate.Gallery.ActiveLevelIndex + "_SKIPPED"));
        FTemplate.Ads.ShowRewardedAd((watched) => CompleteLevel(), "LEVEL_SKIPPED");
    }

    public void LoadActiveLevel(bool levelRestarted = false)
    {
        Time.timeScale = 1f;
        FTemplate.UI.FadeToScene(FTemplate.Gallery.ActiveLevel.ID);
    }

    public void IncrementCoin(Vector3 screenPos)
    {
        int gainedCoins = Random.Range(50, 150);
        FTemplate.UI.SpawnCollectedCoins(screenPos, 10, gainedCoins);
        FTemplate.Shop.IncrementCoins(gainedCoins);
    }

    protected override void OnLevelFinished(bool success)
    {
        base.OnLevelFinished(success);
        if (!success)
        {
            FailLevel(0.2f);
        }
        else
        {
            CompleteLevel(1f);
        }
    }

    #region Button Events
    private bool StartLevelClickEvent()
    {
        StartLevel();
        return true;
    }

    private bool NextLevelClickEvent()
    {
        FTemplate.Gallery.IncrementActiveLevel();
        LoadActiveLevel();
        return true;
    }

    private bool SkipLevelClickEvent()
    {
        SkipLevel();
        return true;
    }

    private bool RestartLevelClickEvent()
    {
        LoadActiveLevel(levelRestarted: true);
        return true;
    }
#endregion
}
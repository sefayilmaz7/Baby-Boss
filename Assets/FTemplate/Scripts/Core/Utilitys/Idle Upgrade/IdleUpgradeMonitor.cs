using TMPro;
using UnityEngine;
using MoreMountains.NiceVibrations;

public class IdleUpgradeMonitor : MonoBehaviour
{
    private Animator _animator;
    private int ANIMATOR_TRIGGER_UPGRADE;

    [SerializeField] private IdleUpgradeType UpgradeType;
    [SerializeField] private TMP_Text Text_Level;
    [SerializeField] private TMP_Text Text_Cost;
    [SerializeField] private TMP_Text Text_UpgradeButton;
    [SerializeField] private GameObject Image_UpgradeAdIcon;

    private int[] _costOrder = new int[3] { 100, 200, 300 };
    private int _currentLevel => PlayerPrefs.GetInt(PLAYERPREFS_SAVE_NAME, 0);
    private int _upgradeCost => _currentLevel >= _costOrder.Length ? _costOrder[_costOrder.Length - 1] : _costOrder[_currentLevel];
    private bool _isCoinEnough => FTemplate.Shop.Coins >= _upgradeCost;

    private string PLAYERPREFS_SAVE_NAME => nameof(IdleUpgradeMonitor) + "_" + ((int)UpgradeType);

    private void Awake()
    {
        string[] costOrder = FTemplate.Analytics.GetRemoteStringValue("IDLE_UPGRADES_COST_ORDER", "[100,200,400,600]").Replace("[", "").Replace("]", "").Split(',');
        if (costOrder.Length > 0)
        {
            int[] costOrders = new int[costOrder.Length];
            for (int i = 0; i < costOrder.Length; i++)
                costOrders[i] = (int)(int.TryParse(costOrder[i], out int _price) ? _price : 100L);

            _costOrder = costOrders;
        }

        _animator = GetComponent<Animator>();
        ANIMATOR_TRIGGER_UPGRADE = Animator.StringToHash("Upgrade");

        PrepareUI();
    }

    private void OnEnable()
    {
        FTemplate.Shop.IncrementCoinEvent += PrepareUI;
        PrepareUI();
    }

    private void OnDisable()
    {
        FTemplate.Shop.IncrementCoinEvent -= PrepareUI;
    }

    public void PrepareUI()
    {
        Text_Level.SetText("LEVEL " + (_currentLevel + 1));
        Text_Cost.SetText("" + _upgradeCost);
        Text_UpgradeButton.SetText(_isCoinEnough ? "UPGRADE" : "GET");
        Image_UpgradeAdIcon.SetActive(!_isCoinEnough);
    }

    public void ButtonUpgrade()
    {
        if (_isCoinEnough)
        {
            FTemplate.Shop.IncrementCoins(-_upgradeCost);
            FTemplate.UI.SetTotalCoins(FTemplate.Shop.Coins, true);
            Upgrade();
        }
        else
        {
            FTemplate.Ads.ShowRewardedAd((rewarded) => Upgrade(), "UPGRADE_BUTTON");
        }
    }

    private void Upgrade()
    {
        _animator.SetTrigger(ANIMATOR_TRIGGER_UPGRADE);
        FTemplate.UI.PlayCelebrationParticles();
        MMVibrationManager.Haptic(HapticTypes.Success);

        PlayerPrefs.SetInt(PLAYERPREFS_SAVE_NAME, _currentLevel + 1);
        PrepareUI();
    }
}
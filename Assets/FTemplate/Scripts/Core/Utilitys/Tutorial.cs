using System.Collections;
using UnityEngine;

public class Tutorial : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private GameObject UI;

    [Header("Properties")]
    [SerializeField] private bool StartOnAwake = false;
    [SerializeField] private string NameForSave = "GAMEPLAY";
    [SerializeField] private bool MouseButtonDownChecker = true;
    [SerializeField] private bool ShowAlways = false;

    private string _playerPrefsName => "TUTORIAL_" + NameForSave;

    private void OnEnable()
    {
        Hide();
        // EXAMPLE: if (StartOnAwake) GameManager.Instance.GameStartedEvent += Show;
        if (StartOnAwake) Show();
    }

    private void OnDisable()
    {
        // EXAMPLE: if (StartOnAwake) GameManager.Instance.GameStartedEvent -= Show;
    }

    public void Show()
    {
        if (IsItShown && !ShowAlways) return;
        UI.SetActive(true);
        if (MouseButtonDownChecker) StartCoroutine(MouseButtonDownCheckerCoroutine());
        SaveAsShown();
    }

    public void Hide()
    {
        UI.SetActive(false);
    }

    private IEnumerator MouseButtonDownCheckerCoroutine()
    {
        float time = Time.realtimeSinceStartup + 1f;
        while (UI.activeSelf)
        {
            if (time > Time.realtimeSinceStartup || !Input.GetMouseButtonDown(0)) yield return null;
            else UI.SetActive(false);
        }
    }

    private bool IsItShown => PlayerPrefs.GetInt(_playerPrefsName, 0) == 0 ? false : true;

    private void SaveAsShown()
    {
        PlayerPrefs.SetInt(_playerPrefsName, 1);
    }
}
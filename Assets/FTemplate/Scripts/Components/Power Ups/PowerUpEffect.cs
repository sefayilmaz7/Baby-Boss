using System.Collections;
using UnityEngine;
using TMPro;

public class PowerUpEffect : MonoBehaviour
{
    public TMP_Text powerUpText;

    public void SetText(string text)
    {
        powerUpText.text = text;
    }
}
using System.Collections;
using UnityEngine;
using TMPro;

public class SetMultiplierText : MonoBehaviour
{
    public Multiplier multiplier;
    public TMP_Text text;

    private void OnValidate()
    {
        text.text = multiplier.Text;
    }
}
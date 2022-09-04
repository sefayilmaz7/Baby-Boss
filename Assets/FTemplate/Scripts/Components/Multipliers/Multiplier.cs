using System.Collections;
using UnityEngine;

public class Multiplier : MonoBehaviour
{
    public MathOperation operation;
    public int value;

    public string Text {
        get {
            return MultiplierHelpers.GetText(this);
        }
    }

    public int GetValue(int baseValue)
    {
        return MultiplierHelpers.ApplyMultiplier(baseValue, value, operation);
    }
}
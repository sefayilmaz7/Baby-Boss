using System;
using UnityEngine;

public static class MultiplierHelpers
{
    public static int ApplyMultiplier(int baseValue, int value, MathOperation operation)
    {
        return operation switch
        {
            MathOperation.Add => baseValue + value,
            MathOperation.Divide => baseValue / value,
            MathOperation.Multiply => baseValue * value,
            MathOperation.Subtract => baseValue - value,
            _ => throw new Exception(),
        };
    }

    public static string GetText(Multiplier multiplier)
    {
        return multiplier.operation switch
        {
            MathOperation.Add => string.Format("+{0}", multiplier.value),
            MathOperation.Divide => string.Format("%{0}", multiplier.value),
            MathOperation.Multiply => string.Format("{0}x", multiplier.value),
            MathOperation.Subtract => string.Format("-{0}", multiplier.value),
            _ => throw new Exception(),
        };
    }
}
using System;
using UnityEngine;

[Serializable]
public class ColorRange
{
    public Color[] colors;
    
    private int currentColorIndex;
    private float colorSegment;

    public void Init()
    {
        colorSegment = (1f / colors.Length);
    }

    public Color GetValueAtPercent(float value)
    {            
        var colorMaxIndex = Mathf.Min(colors.Length-1, currentColorIndex + 1);

        if (value >= (colorSegment * (currentColorIndex + 1)))
        {
            currentColorIndex = colorMaxIndex;
        }
        
        return Color.Lerp(colors[currentColorIndex], colors[(colorMaxIndex)], value);
    }
}
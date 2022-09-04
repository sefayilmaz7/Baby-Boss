using UnityEngine;

[System.Serializable]
public class IntRange
{
    public int min;
    public int max;

    public int Value => Random.Range(min, max);
}
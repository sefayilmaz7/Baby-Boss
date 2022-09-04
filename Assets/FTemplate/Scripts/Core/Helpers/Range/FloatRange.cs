using UnityEngine;

[System.Serializable]
public class FloatRange
{
    public float min;
    public float max;

    public float GetRandomValue => Random.Range(min, max);
    public float Diff => max > min ? max - min : 0f;
}
using System;
using FluffyUnderware.Curvy.Generator;
using FluffyUnderware.DevTools;
using UnityEngine;

[Serializable]
public class ObjectGroupData
{
    [ReadOnly]public ObjectGenerator ObjectGenerator;

    [RangeEx(0f, "MaxSplineLenght")]
    public float placeAt = 0;

    [RangeEx(0f, "MaxSplineLenght")]
    public float groupLenght;

    [RangeEx(0f, "MaxSplineLenght")]
    public float distanceBetween = 10;

    [Header("Scale")]
    public bool uniformScaling;
    public Vector3 scale = Vector3.one;
    [Header("Translation")]
    public bool relativeTranslation;
    public Vector3 translation;
    [Header("Rotation")]
    public CGBoundsGroup.RotationModeEnum rotationMode;
    public Vector3 rotation = Vector3.zero;
    public float MaxSplineLenght => ObjectGenerator.GetSplineLenght();


    public ObjectGroupData(ObjectGenerator objectGenerator)
    {
        ObjectGenerator = objectGenerator;
    }
}
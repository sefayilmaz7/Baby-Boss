using System.Collections;
using UnityEngine;

public interface IPowerUp : ITimer
{
    public string EffectText { get; }

    void OnLoad();
    void OnUnload();
}
using System.Collections;
using UnityEngine;

abstract public class PowerUp : Timer, IPowerUp
{
    public PowerUp(float duration) : base(duration) { }

    abstract public string EffectText { get; }

    virtual public void OnLoad()
    {
        Start();
    }

    virtual public void OnUnload()
    {

    }
}

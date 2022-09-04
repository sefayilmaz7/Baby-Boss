using System.Collections.Generic;
using UnityEngine;
using System;

public class PowerUpUser : SingletonBehaviour<PowerUpUser>
{
    public event Action<IPowerUp> OnPowerUpAdd;
    public event Action<IPowerUp> OnPowerUpRemove;

    private List<IPowerUp> timedEffects = new List<IPowerUp>();
    private List<IPowerUp> disposables = new List<IPowerUp>();

    private void Update()
    {
        foreach (var timedEffect in timedEffects)
        {
            timedEffect.Tick(Time.deltaTime);

            if (timedEffect.Stopped)
                disposables.Add(timedEffect);
        }
    }

    private void LateUpdate()
    {
        foreach (var disposable in disposables)
        {
            OnRemove(disposable);
            timedEffects.Remove(disposable);
        }

        disposables.Clear();
    }

    public void Add(IPowerUp effect)
    {
        foreach (var timedEffect in timedEffects)
        {
            if (timedEffect.Equals(effect))
            {
                OnAdd(effect);
                timedEffect.Restart();
                return;
            }
        }

        OnAdd(effect);
        timedEffects.Add(effect);
    }

    private void OnAdd(IPowerUp effect)
    {
        effect.OnLoad();
        OnPowerUpAdd?.Invoke(effect);
    }

    private void OnRemove(IPowerUp effect)
    {
        effect.OnUnload();
        OnPowerUpRemove?.Invoke(effect);
    }
}
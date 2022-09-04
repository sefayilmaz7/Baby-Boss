using System;
using UnityEngine;

public class TapDetector : MonoBehaviour
{
    protected float tapTimeThreshold = 0.1f;

    public static event Action OnTap = delegate { };

    private bool fingerDown = false;
    private float timer = 0f;

    virtual protected void Update()
    {
        if (fingerDown)
            timer += Time.deltaTime;

        if (Input.GetMouseButtonDown(0))
        {
            fingerDown = true;
            timer = 0f;
        }

        if (Input.GetMouseButtonUp(0))
        {
            fingerDown = false;

            if (timer >= tapTimeThreshold)
                OnTap?.Invoke();
        }
    }
}

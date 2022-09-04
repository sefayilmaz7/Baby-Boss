using UnityEngine;

public static class AutoQualityDecreaser
{
    private static float _lowFPSThreshold = 30f;
    private static float _checkTime = .1f;
    private static float _totalCheckCount = 60f;
    private static float _totalFPS = 0;
    private static float _addedFPS = 0;
    private static float _timestamp = 0;

    public static void Update(float t)
    {
        if (t - _timestamp > _checkTime)
        {
            _timestamp = t;
            CheckFPS();
        }
    }

    private static float GetAverageFPS(float FPS)
    {
        ++_addedFPS;
        _totalFPS += FPS;
        return _totalFPS / _addedFPS;
    }

    private static void CheckFPS()
    {
        if (GetAverageFPS(1 / Time.deltaTime) < _lowFPSThreshold && _addedFPS > _totalCheckCount)
        {
            QualitySettings.DecreaseLevel(true);

            _addedFPS = 0f;
            _totalFPS = 0f;
        }
    }
}
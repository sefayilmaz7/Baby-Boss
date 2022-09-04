
[System.Serializable]
public class Timer : ITimer
{
    public bool IsRunning { get; private set; }
    public bool Stopped { get; private set; }

    public float Duration { get; private set; }

    private float baseDuration;

    public Timer(float duration)
    {
        Duration = duration;
        baseDuration = duration;
        IsRunning = false;
    }

    public void Tick(float deltaTime)
    {
        if (Stopped) return;

        if (IsRunning)
        {
            Duration -= deltaTime;

            if (Duration <= 0f)
                Stop();
        }
    }

    public void Start()
    {
        IsRunning = true;
    }

    public void Pause()
    {
        IsRunning = false;
    }

    public void Restart()
    {
        IsRunning = true;
        Stopped = false;

        Duration = baseDuration;
    }

    public void Resume()
    {
        if (!Stopped) IsRunning = true;
    }

    public void Stop()
    {
        IsRunning = false;
        Stopped = true;
    }
}
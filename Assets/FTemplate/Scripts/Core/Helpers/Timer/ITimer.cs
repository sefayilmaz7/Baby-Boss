
public interface ITimer
{
    bool IsRunning { get; }
    bool Stopped { get; }

    void Tick(float deltaTime);
    void Start();
    void Pause();
    void Resume();
    void Restart();
    void Stop();
}
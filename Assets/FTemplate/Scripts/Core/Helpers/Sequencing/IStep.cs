
public interface IStep
{
    bool IsComplete { get; }

    void Start();
    void Tick(float deltaTime);
}

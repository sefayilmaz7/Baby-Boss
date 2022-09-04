public interface IState
{
    bool IsComplete { get; set; }

    void OnEnter();
    void Tick();
    void OnExit();
}
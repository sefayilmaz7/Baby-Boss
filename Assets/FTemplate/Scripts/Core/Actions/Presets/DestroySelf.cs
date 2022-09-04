
public class DestroySelf : MonoAction
{
    public float delay = 0.5f;

    public override void Execute()
    {
        Destroy(gameObject, delay);
    }
}
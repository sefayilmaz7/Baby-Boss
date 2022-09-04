using UnityEngine;

public class SlideInputManager : MonoBehaviour
{
    private SlideController slideController;

    private void Awake()
    {
        slideController = new SlideController();
    }

    private void Update()
    {
        slideController.Tick();
    }
}

using System.Collections;
using UnityEngine;

abstract public class MonoInputListener : FBehaviour, IInputListener
{
    public InputManager InputManager;

    virtual protected void OnEnable()
    {
        InputManager.Subscribe(this);
    }

    virtual protected void OnDisable()
    {
        InputManager.Unsubscribe(this);
    }

    virtual public void OnSlide(SlideData data)
    {
        // print("Slide detected: " + data.movement.ToString());
    }

    virtual public void OnSwipe(SwipeData data)
    {
        // print("Swipe detected: " + data.Direction.ToString());
    }
}
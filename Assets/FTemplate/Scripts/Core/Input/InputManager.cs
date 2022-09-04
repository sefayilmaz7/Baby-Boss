using System.Collections.Generic;
using UnityEngine;

public enum InputType
{
    Slide,
    Swipe
}

public class InputManager : MonoBehaviour
{
    public InputType InputType;

    public List<IInputListener> listeners;

    private void OnEnable()
    {
        if (InputType == InputType.Swipe)
            SwipeDetector.OnSwipe += NotifyListenersOfSwipe;
        if (InputType == InputType.Slide)
            SlideController.OnSlide += NotifyListenersOfSlide;
    }

    private void OnDisable()
    {
        if (InputType == InputType.Swipe)
            SwipeDetector.OnSwipe -= NotifyListenersOfSwipe;
        if (InputType == InputType.Slide)
            SlideController.OnSlide -= NotifyListenersOfSlide;
    }

    public void Initialize()
    {
        
    }

    public void Subscribe(IInputListener listener)
    {
        if (listeners == null)
            listeners = new List<IInputListener>();

        if (!listeners.Contains(listener))
            listeners.Add(listener);
    }

    public void Unsubscribe(IInputListener listener)
    {
        listeners.Remove(listener);
    }

    public void NotifyListenersOfSwipe(SwipeData data)
    {
        foreach (var listener in listeners)
            listener.OnSwipe(data);
    }

    public void NotifyListenersOfSlide(SlideData data)
    {
        foreach (var listener in listeners)
            listener.OnSlide(data);
    }
}
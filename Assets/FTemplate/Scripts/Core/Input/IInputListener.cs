using System.Collections;
using UnityEngine;

public interface IInputListener
{
    void OnSwipe(SwipeData data);
    void OnSlide(SlideData data);
}
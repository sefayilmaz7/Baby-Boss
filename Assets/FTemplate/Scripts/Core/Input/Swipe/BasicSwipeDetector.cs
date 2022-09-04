using System.Collections;
using UnityEngine;

public class BasicSwipeDetector : SwipeDetector
{
    [SerializeField]
    protected bool Swiping = false;

    override protected void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            Swiping = true;
            fingerDownPosition = Input.mousePosition;
        }

        if (Input.GetMouseButtonUp(0))
        {
            Swiping = false;
            fingerUpPosition = Input.mousePosition;
            DetectSwipe();
        }
    }
}
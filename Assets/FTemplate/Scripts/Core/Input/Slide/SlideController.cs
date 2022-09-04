using System;
using UnityEngine;

public class SlideController
{
    public static event Action<SlideData> OnSlide = delegate { };

    private bool fingerDown = false;

    private Vector3 startPosition;
    private Vector3 endPosition;

    private Vector2 Movement {
        get {
            if (!fingerDown) return Vector2.zero;
            return Input.mousePosition - startPosition;
        }
    }

    public void Tick()
    {
        if (Input.GetMouseButtonDown(0))
        {
            fingerDown = true;
            startPosition = Input.mousePosition;
        }

        if (Input.GetMouseButton(0))
        {
            SendSlide();
        }

        if (Input.GetMouseButtonUp(0))
        {
            fingerDown = false;
            endPosition = Input.mousePosition;
        }
    }

    private void SendSlide()
    {
        OnSlide(new SlideData()
        {
            movement = Movement,
            normalizedMovement = Vector3.Normalize(Movement)
        });
    }
    
}
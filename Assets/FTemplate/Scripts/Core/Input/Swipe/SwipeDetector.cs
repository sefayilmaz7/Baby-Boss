using System;
using UnityEngine;

public class SwipeDetector : MonoBehaviour
{
    protected Vector2 fingerDownPosition;
    protected Vector2 fingerUpPosition;

    [SerializeField]
    protected bool detectSwipeOnlyAfterRelease = false;

    [SerializeField]
    protected float minDistanceForSwipe = 20f;
    public float minTapDuration;

    public static event Action<SwipeData> OnSwipe = delegate { };

    virtual protected void Update()
    {
        foreach (Touch touch in Input.touches)
        {
            if (touch.phase == TouchPhase.Began)
            {
                fingerUpPosition = touch.position;
                fingerDownPosition = touch.position;
            }

            if (!detectSwipeOnlyAfterRelease && touch.phase == TouchPhase.Moved)
            {
                fingerDownPosition = touch.position;
                DetectSwipe();
            }

            if (touch.phase == TouchPhase.Ended)
            {
                fingerDownPosition = touch.position;
                DetectSwipe();
            }
        }
    }

    protected void DetectSwipe()
    {
        if (SwipeDistanceCheckMet())
        {
            if (IsVerticalSwipe())
            {
                var direction = fingerDownPosition.y - fingerUpPosition.y > 0 ? SwipeDirection.Down : SwipeDirection.Up;
                SendSwipe(direction);
            }
            else
            {
                var direction = fingerDownPosition.x - fingerUpPosition.x > 0 ? SwipeDirection.Left : SwipeDirection.Right;
                SendSwipe(direction);
            }
            fingerUpPosition = fingerDownPosition;
        }
    }

    protected bool IsVerticalSwipe()
    {
        return VerticalMovementDistance() > HorizontalMovementDistance();
    }

    protected bool SwipeDistanceCheckMet()
    {
        return VerticalMovementDistance() > minDistanceForSwipe || HorizontalMovementDistance() > minDistanceForSwipe;
    }

    protected float VerticalMovementDistance()
    {
        return Mathf.Abs(fingerDownPosition.y - fingerUpPosition.y);
    }

    protected float HorizontalMovementDistance()
    {
        return Mathf.Abs(fingerDownPosition.x - fingerUpPosition.x);
    }

    protected void SendSwipe(SwipeDirection direction)
    {
        SwipeData swipeData = new SwipeData()
        {
            Direction = direction,
            StartPosition = fingerDownPosition,
            EndPosition = fingerUpPosition
        };
        OnSwipe(swipeData);
    }
}

public struct SwipeData
{
    public Vector2 StartPosition;
    public Vector2 EndPosition;
    public SwipeDirection Direction;

    public float DirectionalMagnitude {
        get {
            if (Direction == SwipeDirection.Left || Direction == SwipeDirection.Right)
                return Mathf.Abs(EndPosition.x - StartPosition.x) / Screen.width;
            return Mathf.Abs(EndPosition.y - StartPosition.y) / Screen.height;
        }
    }
}

public enum SwipeDirection
{
    Up,
    Down,
    Left,
    Right
}
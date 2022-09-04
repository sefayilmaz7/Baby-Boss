using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RunnerController : FBehaviour, IInputListener
{
    public InputManager inputManager;

    private Movable movementComponent;

    private void Start()
    {
        movementComponent = GetComponent<Movable>();
    }

    protected override void OnLevelStarted()
    {
        movementComponent.enabled = true;
    }

    protected override void OnLevelFinished(bool success)
    {
        movementComponent.enabled = false;
    }

    virtual protected void OnEnable()
    {
        inputManager.Subscribe(this);
    }

    virtual protected void OnDisable()
    {
        inputManager.Unsubscribe(this);
    }

    public void OnSwipe(SwipeData data)
    {
        if (data.Direction == SwipeDirection.Left)
        {
            movementComponent.AddVelocity(Vector3.left);
        }
        else if (data.Direction == SwipeDirection.Right)
        {
            movementComponent.AddVelocity(Vector3.right);
        }
    }

    public void OnSlide(SlideData data)
    {
        // set target position
    }
}

using System.Collections;
using UnityEngine;

abstract public class Movable : MonoBehaviour, IMovable
{
    public RunnerAnimator animator;

    abstract public Vector3 Velocity { get; set; }

    abstract public void SetTargetPosition(Vector3 position);
    abstract public void AddVelocity(Vector3 amount);
}
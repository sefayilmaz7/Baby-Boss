using System.Collections;
using UnityEngine;

public class SimpleTransformMovement : Movable
{
    [Header("References")]
    public Transform mainBody;

    [Header("Settings")]
    public float speed;
    public float horizontalSpeed;

    [Header("Boundaries")]
    public FloatRange xRange;

    public override Vector3 Velocity { get; set; }

    private Vector3 horizontalVelocity = Vector3.zero;

    private Vector3 VerticalMovement => Vector3.forward * speed * Time.deltaTime;
    private Vector3 HorizontalMovement => horizontalVelocity * horizontalSpeed * Time.deltaTime;

    private void Update()
    {
        var targetPosition = mainBody.position + VerticalMovement + HorizontalMovement;
        targetPosition.x = Mathf.Clamp(targetPosition.x, xRange.min, xRange.max);
        mainBody.position = targetPosition;
    }

    private void OnEnable()
    {
        animator.Speed = 1f;
    }

    private void OnDisable()
    {
        animator.Speed = 0f;
    }

    public override void SetTargetPosition(Vector3 position)
    {
        
    }

    public override void AddVelocity(Vector3 amount)
    {
        horizontalVelocity = new Vector3(amount.x, 0f, 0f);
    }
}

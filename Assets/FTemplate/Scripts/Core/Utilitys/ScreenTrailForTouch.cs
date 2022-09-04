using UnityEngine;

public class ScreenTrailForTouch : MonoBehaviour
{
    [SerializeField] private TrailRenderer Effect;
    [SerializeField] private float MousePositionZ = .33f;

    private bool _enabling = true;

    private void Update()
    {
        if (Input.GetMouseButton(0))
        {
            Vector3 mousePos = Input.mousePosition;
            mousePos.z = MousePositionZ;
            Effect.transform.position = Camera.main.ScreenToWorldPoint(mousePos);
        }

        if (Input.GetMouseButtonDown(0))
        {
            ChangeTrailGameObjectEnabling(true);
        }

        if (Input.GetMouseButtonUp(0))
        {
            ChangeTrailGameObjectEnabling(false);
        }
    }

    public void ChangeEnabling(bool value)
    {
        ChangeTrailGameObjectEnabling(false);
        _enabling = value;
    }

    public void ChangeTrailGameObjectEnabling(bool value)
    {
        if (!_enabling) return;

        Effect.Clear();
        Effect.gameObject.SetActive(value);
    }
}
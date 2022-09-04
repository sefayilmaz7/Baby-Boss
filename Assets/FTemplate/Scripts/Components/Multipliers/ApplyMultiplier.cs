using System.Collections;
using UnityEngine;

public class ApplyMultiplier : MonoBehaviour
{
    private Multiplier multiplier;
    private bool executed = false;

    private void Awake()
    {
        multiplier = GetComponent<Multiplier>();
    }

    private void OnTriggerEnter(Collider other)
    {
        if (!executed && other.CompareTag(Tags.PLAYER))
        {
            other.GetComponent<IMultipliable>().ApplyMultiplier(multiplier);
            executed = true;
        }
    }
}
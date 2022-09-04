using System.Collections;
using UnityEngine;

public class EndGameOnCollision : FBehaviour
{
    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag(Tags.PLAYER))
            EndLevel(true);
    }

    private void EndLevel(bool success)
    {
        TriggerLevelFinished(success);
        GetComponent<Collider>().enabled = false;
    }
}
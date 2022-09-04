using UnityEngine;

public class SpawnPrefab : MonoAction
{
    public Transform spawnPoint;
    public GameObject prefab;

    public override void Execute()
    {
        Instantiate(prefab, spawnPoint);
    }
}
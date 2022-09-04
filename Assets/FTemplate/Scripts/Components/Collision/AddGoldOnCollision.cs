using System.Collections.Generic;
using UnityEngine;

public class AddGoldOnCollision : MonoBehaviour
{
    [Header("Animation Settings")]
    public IntRange coinCount;

    [Header("VFX")]
    public GameObject collectEffect;

    [Header("Settings")]
    public int amount;

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag(Tags.PLAYER))
        {
            FTemplate.Shop.IncrementCoins(amount);
            FTemplate.UI.SpawnCollectedCoins(Camera.main.WorldToScreenPoint(Game.Player.mainBody.position), coinCount.Value, amount);

            if (collectEffect != null)
            {
                var effect = Instantiate(collectEffect);
                effect.transform.position = transform.position;
            }

            Destroy(gameObject);
        }
    }
}

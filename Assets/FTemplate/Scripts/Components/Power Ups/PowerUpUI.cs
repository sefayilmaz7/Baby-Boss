using System.Collections;
using UnityEngine;

public class PowerUpUI : MonoBehaviour
{
    public PowerUpUser user;

    public GameObject prefab;
    public Transform container;

    private void Awake()
    {
        user.OnPowerUpAdd += DisplayPowerUpEffect;
    }

    private void DisplayPowerUpEffect(IPowerUp obj)
    {
        var effectVFX = Instantiate(prefab, container);
        effectVFX.GetComponent<PowerUpEffect>().SetText(obj.EffectText);
    }
}
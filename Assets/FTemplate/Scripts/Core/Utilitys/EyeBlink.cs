using DG.Tweening;
using System.Collections;
using UnityEngine;

public class EyeBlink : MonoBehaviour
{
    [SerializeField] private SkinnedMeshRenderer eye;
    [SerializeField] private int BlendShapeIndex = 0;

    private void Start()
    {
        StartCoroutine(BlinkCoroutine());
    }

    private IEnumerator BlinkCoroutine()
    {
        while (true)
        {
            float blinkWeight = eye.GetBlendShapeWeight(BlendShapeIndex);
            float initialWeight = blinkWeight;

            yield return BetterWaitForSeconds.Wait(Random.Range(1.5f, 4f));
            yield return DOTween.To(() => blinkWeight, (value) =>
            {
                blinkWeight = value;
                eye.SetBlendShapeWeight(BlendShapeIndex, blinkWeight);
            }, 100f, Random.Range(0.05f, 0.1f)).SetEase(Ease.Linear).SetLoops(2, LoopType.Yoyo).WaitForCompletion();

            // For some reason when FPS drops substantially while blinking, blinkWeight's value won't return back to initialWeight. Do it manually
            blinkWeight = initialWeight;
            eye.SetBlendShapeWeight(BlendShapeIndex, blinkWeight);
        }
    }
}
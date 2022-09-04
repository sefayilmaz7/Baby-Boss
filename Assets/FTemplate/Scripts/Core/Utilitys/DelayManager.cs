using System.Collections;
using UnityEngine;

public class DelayManager : MonoBehaviour
{
    private static MonoBehaviour mono = null;

    private static MonoBehaviour GetMono
    {
        get
        {
            if (mono == null)
            {
                var obj = new GameObject("Delay Manager");
                DontDestroyOnLoad(obj);
                mono = obj.AddComponent<DelayManager>();
            }
            return mono;
        }
    }

    public static void WaitAndInvoke(System.Action callback, float t = 1f, bool realtime = false, int repeat = 0)
    {
        if (callback == null || t <= 0) return;
        GetMono.StartCoroutine(WaitAndInvokeCoroutine(callback, t, realtime, repeat));
    }

    private static IEnumerator WaitAndInvokeCoroutine(System.Action callback, float t, bool realtime, int repeat)
    {
        yield return realtime ? BetterWaitForSeconds.WaitRealtime(t) : BetterWaitForSeconds.Wait(t);
        callback.Invoke();

        if (repeat-- != 0) WaitAndInvoke(callback, t, realtime, repeat);
    }

    public static void WaitAndInvoke<T>(System.Action<T> callback, T parameterValue, float t = 1f, bool realtime = false, int repeat = 0)
    {
        if (callback == null || t <= 0) return;
        GetMono.StartCoroutine(WaitAndInvokeCoroutine(callback, parameterValue, t, realtime, repeat));
    }

    private static IEnumerator WaitAndInvokeCoroutine<T>(System.Action<T> callback, T parameterValue, float t, bool realtime, int repeat)
    {
        yield return realtime ? BetterWaitForSeconds.WaitRealtime(t) : BetterWaitForSeconds.Wait(t);
        callback.Invoke(parameterValue);

        if (repeat-- != 0) WaitAndInvoke(callback, parameterValue, t, realtime, repeat);
    }
}
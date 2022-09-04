using System.Collections;
using UnityEngine;

public class RunnerAnimator : MonoBehaviour
{
    [Header("References")]
    public Animator animator;

    public float Speed {
        get { return animator.GetFloat(Animations.SPEED); }
        set { animator.SetFloat(Animations.SPEED, value); }
    }

    public float ActionSpeed {
        get { return animator.GetFloat(Animations.ACTION_SPEED); }
        set {
            if (value < 0f)
                Debug.Log("ActionSpeed smaller than 0");
            animator.SetFloat(Animations.ACTION_SPEED, value);
        }
    }

    public void SetJump(bool status)
    {
        animator.SetBool(Animations.JUMP, status);
    }

    public void SetDead()
    {
        animator.SetTrigger(Animations.DEAD);
    }
}

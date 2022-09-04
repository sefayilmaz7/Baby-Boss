using UnityEngine;
using UnityEngine.UI;

abstract public class ExecuteOnButtonClick : MonoBehaviour
{
    private Button btn;

    private void Awake()
    {
        btn = GetComponent<Button>();
        btn.onClick.AddListener(Execute);
    }

    abstract protected void Execute();
}
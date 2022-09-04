using MonoObjects.Interactable.Core;
using UnityEditor;
using UnityEngine;


[CustomEditor(typeof(MachineBase),true)]
public class MachineBaseEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        var machineBase = (MachineBase) target;

        if (GUILayout.Button("Get Palate"))
        {
            machineBase.GetPalate();
            
            EditorUtility.SetDirty(target);
        }
        
        if (GUILayout.Button("Update Material Modifier"))
        {
            var materialModifier = machineBase.UpdateMaterialModifier();
            EditorUtility.SetDirty(target);
            EditorUtility.SetDirty(materialModifier);
        }
    }
}
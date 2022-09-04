using MonoObjects.Interactable.Core;
using UnityEditor;
using UnityEngine;


[CustomEditor(typeof(HandBase),true)]
public class HandBaseEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        var handBase = (HandBase) target;

        if (GUILayout.Button("Get Palate"))
        {
            handBase.GetPalate();
            
            EditorUtility.SetDirty(target);
        }
        
        if (GUILayout.Button("Update Material Modifier"))
        {
            var materialModifier = handBase.UpdateMaterialModifier();
            EditorUtility.SetDirty(target);
            EditorUtility.SetDirty(materialModifier);
        }
    }
}
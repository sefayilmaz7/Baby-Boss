using UnityEditor;
using UnityEngine;


[CustomEditor(typeof(GeneratorPartBase),true)]
[CanEditMultipleObjects]
public class GeneratorPartEditor : UnityEditor.Editor
{
    public override void OnInspectorGUI()
    {
        var generatorPart = (GeneratorPartBase) target;

        DrawDefaultInspector();
    
        if (GUILayout.Button("Delete"))
        {
            EditorUtility.SetDirty(target);
            generatorPart.DeletePart();
        }
    }
}
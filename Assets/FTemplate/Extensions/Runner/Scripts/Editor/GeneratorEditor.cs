using UnityEditor;
using UnityEngine;


[CustomEditor(typeof(GeneratorBase),true)]
[CanEditMultipleObjects]
public class GeneratorEditor : Editor
{
    public override void OnInspectorGUI()
    {
        var generator = (GeneratorBase) target;

        if (generator.autoRefresh)
        {
            generator.AutoUpdate();
        }
    
        if (GUILayout.Button("Generate"))
        {
            generator.Generate();
            EditorUtility.SetDirty(target);
        }

        if (GUILayout.Button("Delete All"))
        {
            generator.DeleteAll();
            EditorUtility.SetDirty(target);
        }

        if (generator.GetType() == typeof(RoadGenerator))
        {        
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("Add Object Placer"))
            {
                ((RoadGenerator) generator).AddObjectPlacer();
            }
            if (GUILayout.Button("Remove Object Placer"))
            {
                ((RoadGenerator) generator).RemoveObjectPlacer();
            }
        
            GUILayout.EndHorizontal();
        
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("Add Path Creator"))
            {
                ((RoadGenerator) generator).AddPathCreator();
            }
        
            if (GUILayout.Button("Remove Path Creator"))
            {
                ((RoadGenerator) generator).RemovePathCreator();
            }
            GUILayout.EndHorizontal();

        }        
        DrawDefaultInspector();
    
        if (GUILayout.Button("Add New"))
        {
            generator.AddNew();
            EditorUtility.SetDirty(target);
        }
        if (GUILayout.Button("Remove Last"))
        {
            generator.RemoveLast();
            EditorUtility.SetDirty(target);
        }

    }
}

// =====================================================================
// Copyright 2013-2017 Fluffy Underware
// All rights reserved
// 
// http://www.fluffyunderware.com
// =====================================================================

using UnityEngine;
using UnityEditor;
using FluffyUnderware.DevTools;


[CustomEditor(typeof(ComponentPool))]
public class ComponentPoolEditor : DTEditor<ComponentPool>
{
    protected override void OnCustomInspectorGUIBefore()
    {
        PoolManagerEditor.showBar(Target);
    }
}